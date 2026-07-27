package com.provaluer.controller;

import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.SlaService;
import com.provaluer.service.PricingService;
import com.provaluer.util.DocxTemplateEngine;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.security.MessageDigest;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderInputRepository orderInputRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PerformanceLedgerRepository performanceLedgerRepository;

    @Autowired
    private SlaService slaService;

    @Autowired
    private PricingService pricingService;

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private DocxTemplateEngine docxTemplateEngine;

    @Autowired
    private SystemSettingRepository systemSettingRepository;

    // In-memory cache for paused orders remaining SLA business hours
    private final Map<Long, Double> pausedSlaHoursCache = new HashMap<>();

    @PostMapping("/draft")
    @Transactional
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN')")
    public ResponseEntity<?> saveDraft(@RequestBody OrderDraftRequest request) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        
        final Order order = (request.getId() != null)
                ? orderRepository.findById(request.getId()).orElse(new Order())
                : new Order();
        
        order.setClientId(principal.getId());
        order.setPropertyCategory(request.getPropertyCategory());
        order.setPurpose(request.getPurpose());
        order.setEstimatedValue(request.getEstimatedValue());
        order.setTemplateId(request.getTemplateId());
        order.setStatus("DRAFT");
        
        if (request.getTemplateId() != null && order.getFieldMappingSnapshot() == null) {
            templateRepository.findById(request.getTemplateId()).ifPresent(t -> {
                order.setFieldMappingSnapshot(t.getFieldMapping());
            });
        }
        
        Order savedOrder = orderRepository.save(order);

        // Delete existing inputs and rewrite
        List<OrderInput> existingInputs = orderInputRepository.findAllByOrderId(savedOrder.getId());
        orderInputRepository.deleteAll(existingInputs);

        for (Map.Entry<String, String> entry : request.getInputs().entrySet()) {
            saveOrUpdateInput(savedOrder.getId(), entry.getKey(), entry.getValue());
        }

        return ResponseEntity.ok(savedOrder);
    }

    @DeleteMapping("/{id}/draft")
    @Transactional
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> deleteDraft(@PathVariable Long id) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (!orderOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        if (!isAdmin && !order.getClientId().equals(principal.getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied to delete this draft order");
        }

        if (!"DRAFT".equals(order.getStatus())) {
            return ResponseEntity.badRequest().body("Only orders in DRAFT status can be deleted");
        }

        List<OrderInput> existingInputs = orderInputRepository.findAllByOrderId(id);
        orderInputRepository.deleteAll(existingInputs);

        List<OrderDocument> existingDocs = orderDocumentRepository.findAllByOrderId(id);
        orderDocumentRepository.deleteAll(existingDocs);

        orderRepository.delete(order);
        return ResponseEntity.ok("Draft order deleted successfully");
    }

    @PostMapping("/{id}/submit")
    @Transactional
    public ResponseEntity<?> submitIntake(@PathVariable Long id) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            // Client pays intake deposit fee -> moves to PAID_INTAKE
            order.setStatus("PAID_INTAKE");
            
            // Generate report number in PV-yymm-xxxx format
            LocalDateTime now = LocalDateTime.now();
            int yy = now.getYear() % 100;
            int mm = now.getMonthValue();
            String prefix = String.format("PV-%02d%02d-", yy, mm);
            long seq = orderRepository.countByReportNumberStartingWith(prefix) + 1;
            String reportNumber = String.format("%s%04d", prefix, seq);
            order.setReportNumber(reportNumber);
            
            // Calculate initial SLA Expiry
            LocalDateTime expiry = slaService.calculateExpiry(order.getPurpose(), now);
            order.setSlaExpiryTime(expiry);

            Order saved = orderRepository.save(order);
            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/client")
    public ResponseEntity<List<Order>> getClientOrders() {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return ResponseEntity.ok(orderRepository.findAllByClientId(principal.getId()));
    }

    @GetMapping("/unassigned")
    @PreAuthorize("hasAnyRole('PA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<List<Order>> getUnassignedPool() {
        return ResponseEntity.ok(orderRepository.findAllByStatus("PAID_INTAKE"));
    }

    @GetMapping("/pa")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<List<Order>> getPaOrders() {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return ResponseEntity.ok(orderRepository.findAllByPaId(principal.getId()));
    }

    @GetMapping("/all")
    @PreAuthorize("hasAnyRole('SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<List<Order>> getAllOrders() {
        return ResponseEntity.ok(orderRepository.findAllOrderedByCreatedAt());
    }

    @PostMapping("/{id}/claim")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> claimOrder(@PathVariable Long id) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Optional<Order> orderOpt = orderRepository.findById(id);
        
        if (orderOpt.isPresent() && "PAID_INTAKE".equals(orderOpt.get().getStatus())) {
            Order order = orderOpt.get();
            order.setPaId(principal.getId());
            order.setClaimedAt(LocalDateTime.now());
            order.setLastHeartbeat(LocalDateTime.now());
            order.setStatus("ASSIGNED");

            Order saved = orderRepository.save(order);

            // Increment allocations in ledger
            performanceLedgerRepository.findById(principal.getId()).ifPresent(ledger -> {
                ledger.setActiveAllocations(ledger.getActiveAllocations() + 1);
                performanceLedgerRepository.save(ledger);
            });

            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.status(HttpStatus.CONFLICT).body("Order is not available for claiming.");
    }

    @PostMapping("/{id}/heartbeat")
    @Transactional
    public ResponseEntity<?> telemetryHeartbeat(@PathVariable Long id) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            order.setLastHeartbeat(LocalDateTime.now());
            orderRepository.save(order);
            return ResponseEntity.ok().build();
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/pause")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> pauseOrder(@PathVariable Long id, @RequestParam("reason") String reason) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            order.setPaused(true);
            order.setStatus("ACTION_NEEDED");
            order.setPauseReason(reason);

            // Freeze Sla Timer: calculate and cache remaining business hours
            double remainingHours = slaService.getRemainingBusinessHours(LocalDateTime.now(), order.getSlaExpiryTime());
            pausedSlaHoursCache.put(order.getId(), remainingHours);

            // Record freeze count in ledger
            if (order.getPaId() != null) {
                performanceLedgerRepository.findById(order.getPaId()).ifPresent(ledger -> {
                    ledger.setFreezeCounts(ledger.getFreezeCounts() + 1);
                    performanceLedgerRepository.save(ledger);
                });
            }

            Order saved = orderRepository.save(order);
            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/resume")
    @Transactional
    public ResponseEntity<?> resumeOrder(@PathVariable Long id) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            order.setPaused(false);
            order.setStatus("ASSIGNED");
            order.setPauseReason(null);

            // Recalculate SLA expiry based on remaining cached hours
            double remainingHours = pausedSlaHoursCache.getOrDefault(order.getId(), 36.0);
            LocalDateTime newExpiry = slaService.addBusinessHours(LocalDateTime.now(), remainingHours);
            order.setSlaExpiryTime(newExpiry);

            Order saved = orderRepository.save(order);
            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/submit-draft")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN')")
    public ResponseEntity<?> submitDraftForVerification(@PathVariable Long id, @RequestBody Map<String, String> inputs) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            
            // Save final fields
            for (Map.Entry<String, String> entry : inputs.entrySet()) {
                saveOrUpdateInput(order.getId(), entry.getKey(), entry.getValue());
            }

            if (order.getTemplateId() != null && order.getFieldMappingSnapshot() == null) {
                templateRepository.findById(order.getTemplateId()).ifPresent(t -> {
                    order.setFieldMappingSnapshot(t.getFieldMapping());
                });
            }

            UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            boolean isSpaOrAdmin = principal.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_SPA") || a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));

            order.setStatus(isSpaOrAdmin ? "SUPER_ADMIN_GATE" : "SPA_GATE");
            Order saved = orderRepository.save(order);
            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @PostMapping("/{id}/spa-verify")
    @Transactional
    @PreAuthorize("hasAnyRole('SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> spaVerifyReport(@PathVariable Long id, @RequestParam(value = "finalValue", required = false) BigDecimal finalValue) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            if (finalValue != null) {
                order.setFinalValue(finalValue);
            }

            BigDecimal chargedFee = pricingService.calculateFee(order.getPurpose(), order.getEstimatedValue(), finalValue);
            order.setFeeCharged(chargedFee);
            order.setBalanceDue(BigDecimal.ZERO);
            order.setStatus("SPA_CONFIRMED");

            Order saved = orderRepository.save(order);
            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/release-gate")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> releasePaymentLock(@PathVariable Long id) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            if ("PAYMENT_LOCK".equals(order.getStatus())) {
                order.setStatus("FINAL_DELIVERY");
                
                // Track complete files in ledger
                if (order.getPaId() != null) {
                    performanceLedgerRepository.findById(order.getPaId()).ifPresent(ledger -> {
                        ledger.setActiveAllocations(Math.max(0, ledger.getActiveAllocations() - 1));
                        ledger.setFilesCompleted(ledger.getFilesCompleted() + 1);
                        performanceLedgerRepository.save(ledger);
                    });
                }
                
                Order saved = orderRepository.save(order);
                return ResponseEntity.ok(saved);
            }
        }
        return ResponseEntity.badRequest().body("Gate cannot be released.");
    }

    private byte[] encryptPayload(byte[] data, String password) throws Exception {
        MessageDigest sha = MessageDigest.getInstance("SHA-256");
        byte[] key = sha.digest(password.getBytes("UTF-8"));
        SecretKeySpec keySpec = new SecretKeySpec(key, "AES");
        
        Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
        cipher.init(Cipher.ENCRYPT_MODE, keySpec);
        return cipher.doFinal(data);
    }

    @GetMapping("/{id}/download")
    public ResponseEntity<?> downloadReportSecure(@PathVariable Long id) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            
            boolean isSuperAdmin = SecurityContextHolder.getContext().getAuthentication().getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));

            if (!"FINAL_DELIVERY".equals(order.getStatus()) && !isSuperAdmin) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Report is currently locked.");
            }

            // Secure Encryption: Decryption password matches first 4 digits of user's mobile number
            User client = userRepository.findById(order.getClientId()).orElseThrow();
            String mobile = client.getMobileNumber() != null ? client.getMobileNumber() : "0000";
            String password = mobile.length() >= 4 ? mobile.substring(0, 4) : "0000";

            List<OrderDocument> docs = orderDocumentRepository.findAllByOrderId(id);
            Optional<OrderDocument> signedPdfOpt = docs.stream()
                    .filter(d -> "FINAL_SIGNED_PDF".equalsIgnoreCase(d.getCategory()))
                    .findFirst();

            byte[] reportBytes;
            if (signedPdfOpt.isPresent()) {
                reportBytes = signedPdfOpt.get().getFileContent();
            } else {
                Long templateId = order.getTemplateId();
                if (templateId == null) {
                    return ResponseEntity.badRequest().body("No template associated with this order.");
                }
                Optional<Template> templateOpt = templateRepository.findById(templateId);
                if (templateOpt.isEmpty()) {
                    return ResponseEntity.badRequest().body("Template not found.");
                }
                Template template = templateOpt.get();
                byte[] templateBytes = template.getTemplateContent();

                List<OrderInput> inputsList = orderInputRepository.findAllByOrderId(id);
                Map<String, String> inputsMap = new HashMap<>();
                Map<String, byte[]> imagesMap = new HashMap<>();
                for (OrderInput input : inputsList) {
                    String key = input.getFieldKey().toUpperCase();
                    String val = input.getFieldValue();
                    if ((key.contains("DATE_") || key.contains("_DATE") || key.equals("DATE")) && (val == null || val.trim().isEmpty())) {
                        val = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy"));
                    }
                    inputsMap.put(key, val);
                    if (input.getImageValue() != null) {
                        imagesMap.put(key, input.getImageValue());
                    }
                }

                try {
                    // 1. Hydrate the DOCX template
                    byte[] docxBytes = docxTemplateEngine.generateReport(templateBytes, inputsMap, imagesMap);
                    
                    // 2. Stamp the visual digital signature block
                    String signerName = "Senior Property Analyst (SPA)";
                    String timestamp = java.time.LocalDateTime.now().toString();
                    byte[] signedDocxBytes = docxTemplateEngine.stampDigitalSignature(docxBytes, signerName, timestamp);
                    
                    // 3. Convert Hydrated DOCX to PDF
                    reportBytes = docxTemplateEngine.convertDocxToPdf(signedDocxBytes);
                } catch (Exception e) {
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Report compilation or PDF conversion failed: " + e.getMessage());
                }
            }

            // Save report file to localized storage with sequential versioning
            try {
                saveReportFile(id, reportBytes, isSuperAdmin);
            } catch (Exception e) {
                System.err.println("Warning: failed to save versioned report file: " + e.getMessage());
            }

            byte[] encryptedBytes;
            try {
                encryptedBytes = encryptPayload(reportBytes, password);
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Encryption failed: " + e.getMessage());
            }
            String encryptedBase64 = Base64.getEncoder().encodeToString(encryptedBytes);

            Map<String, Object> result = new HashMap<>();
            result.put("message", "Report compiled and encrypted successfully.");
            result.put("encryptionPassword", password);
            result.put("dataStream", encryptedBase64);

            return ResponseEntity.ok(result);
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/{id}/download-docx")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> downloadReportDocx(@PathVariable Long id) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            if (!"SPA_GATE".equals(order.getStatus()) && !"SPA_CONFIRMED".equals(order.getStatus()) && !"FINAL_DELIVERY".equals(order.getStatus()) && !"SUPER_ADMIN_GATE".equals(order.getStatus())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Report is not submitted or confirmed yet.");
            }

            List<OrderDocument> docs = orderDocumentRepository.findAllByOrderId(id);
            Optional<OrderDocument> finalDocxOpt = docs.stream()
                    .filter(d -> "FINAL_DOCX".equalsIgnoreCase(d.getCategory()))
                    .findFirst();

            if (finalDocxOpt.isPresent()) {
                byte[] docxContent = finalDocxOpt.get().getFileContent();
                return ResponseEntity.ok()
                        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Report_" + id + ".docx\"")
                        .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                        .contentLength(docxContent.length)
                        .body(docxContent);
            }

            Long templateId = order.getTemplateId();
            if (templateId == null) {
                return ResponseEntity.badRequest().body("No template associated with this order.");
            }
            Optional<Template> templateOpt = templateRepository.findById(templateId);
            if (templateOpt.isEmpty()) {
                return ResponseEntity.badRequest().body("Template not found.");
            }
            Template template = templateOpt.get();
            byte[] templateBytes = template.getTemplateContent();

            List<OrderInput> inputsList = orderInputRepository.findAllByOrderId(id);
            Map<String, String> inputsMap = new HashMap<>();
            Map<String, byte[]> imagesMap = new HashMap<>();
            for (OrderInput input : inputsList) {
                String key = input.getFieldKey().toUpperCase();
                String val = input.getFieldValue();
                if ((key.contains("DATE_") || key.contains("_DATE") || key.equals("DATE")) && (val == null || val.trim().isEmpty())) {
                    val = java.time.LocalDate.now().toString();
                }
                inputsMap.put(key, val);
                if (input.getImageValue() != null) {
                    imagesMap.put(key, input.getImageValue());
                }
            }

            try {
                // 1. Hydrate the DOCX template
                byte[] docxBytes = docxTemplateEngine.generateReport(templateBytes, inputsMap, imagesMap);

                // 2. Stamp the visual digital signature block
                String signerName = "Senior Property Analyst (SPA)";
                String timestamp = java.time.LocalDateTime.now().toString();
                byte[] signedDocxBytes = docxTemplateEngine.stampDigitalSignature(docxBytes, signerName, timestamp);

                return ResponseEntity.ok()
                        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Report_" + id + ".docx\"")
                        .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                        .contentLength(signedDocxBytes.length)
                        .body(signedDocxBytes);
            } catch (Exception e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("DOCX compilation failed: " + e.getMessage());
            }
        }
        return ResponseEntity.notFound().build();
    }

    private String saveReportFile(Long orderId, byte[] reportBytes, boolean isSuperAdmin) {
        String storageDirStr = systemSettingRepository.findById("document_storage_dir")
                .map(SystemSetting::getSettingValue)
                .orElse("stored_reports");
        
        java.io.File storageDir = new java.io.File(storageDirStr);
        if (!storageDir.exists()) {
            storageDir.mkdirs();
        }

        int maxVersion = 0;
        java.io.File[] files = storageDir.listFiles((dir, name) -> name.startsWith("Report_" + orderId + "_v") && name.endsWith(".pdf"));
        if (files != null) {
            for (java.io.File file : files) {
                String name = file.getName();
                try {
                    int vIdx = name.indexOf("_v");
                    if (vIdx != -1) {
                        int endIdx = name.indexOf("_", vIdx + 2);
                        if (endIdx == -1) {
                            endIdx = name.indexOf(".pdf", vIdx + 2);
                        }
                        if (endIdx != -1) {
                            String vStr = name.substring(vIdx + 2, endIdx);
                            int ver = Integer.parseInt(vStr);
                            if (ver > maxVersion) {
                                maxVersion = ver;
                            }
                        }
                    }
                } catch (Exception e) {
                    // Ignore parsing error
                }
            }
        }

        int versionToUse;
        String filename;
        if (isSuperAdmin) {
            versionToUse = maxVersion > 0 ? maxVersion : 1;
            filename = "Report_" + orderId + "_v" + versionToUse + "_SuperAdmin.pdf";
        } else {
            versionToUse = maxVersion + 1;
            filename = "Report_" + orderId + "_v" + versionToUse + ".pdf";
        }

        java.io.File reportFile = new java.io.File(storageDir, filename);
        try (java.io.FileOutputStream fos = new java.io.FileOutputStream(reportFile)) {
            fos.write(reportBytes);
        } catch (Exception e) {
            throw new RuntimeException("Failed to save versioned report: " + e.getMessage(), e);
        }
        return reportFile.getAbsolutePath();
    }

    @PostMapping("/{id}/template")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> associateTemplate(@PathVariable Long id, @RequestParam("templateId") Long templateId) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            order.setTemplateId(templateId);
            templateRepository.findById(templateId).ifPresent(t -> {
                order.setFieldMappingSnapshot(t.getFieldMapping());
            });
            Order saved = orderRepository.save(order);
            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/{id}/inputs")
    public ResponseEntity<Map<String, String>> getOrderInputs(@PathVariable Long id) {
        List<OrderInput> inputs = orderInputRepository.findAllByOrderId(id);
        Map<String, String> map = new HashMap<>();
        for (OrderInput input : inputs) {
            if (input.getImageValue() != null) {
                String base64Data = "data:image/png;base64," + Base64.getEncoder().encodeToString(input.getImageValue());
                map.put(input.getFieldKey(), base64Data);
            } else {
                map.put(input.getFieldKey(), input.getFieldValue());
            }
        }
        return ResponseEntity.ok(map);
    }

    // Input DTO
    public static class OrderDraftRequest {
        private Long id;
        private String propertyCategory;
        private String purpose;
        private BigDecimal estimatedValue;
        private Long templateId;
        private Map<String, String> inputs;

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getPropertyCategory() { return propertyCategory; }
        public void setPropertyCategory(String propertyCategory) { this.propertyCategory = propertyCategory; }
        public String getPurpose() { return purpose; }
        public void setPurpose(String purpose) { this.purpose = purpose; }
        public BigDecimal getEstimatedValue() { return estimatedValue; }
        public void setEstimatedValue(BigDecimal estimatedValue) { this.estimatedValue = estimatedValue; }
        public Long getTemplateId() { return templateId; }
        public void setTemplateId(Long templateId) { this.templateId = templateId; }
        public Map<String, String> getInputs() { return inputs; }
        public void setInputs(Map<String, String> inputs) { this.inputs = inputs; }
    }

    public static class CreateStaffReportRequest {
        private String clientName;
        private String bankName;
        private String branchName;
        private Long templateId;

        public String getClientName() { return clientName; }
        public void setClientName(String clientName) { this.clientName = clientName; }
        public String getBankName() { return bankName; }
        public void setBankName(String bankName) { this.bankName = bankName; }
        public String getBranchName() { return branchName; }
        public void setBranchName(String branchName) { this.branchName = branchName; }
        public Long getTemplateId() { return templateId; }
        public void setTemplateId(Long templateId) { this.templateId = templateId; }
    }

    @PostMapping("/create-by-staff")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> createStaffReport(@RequestBody CreateStaffReportRequest request) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

        Order order = new Order();
        order.setClientId(principal.getId());
        order.setPaId(principal.getId());
        order.setClientName(request.getClientName());
        order.setBankName(request.getBankName());
        order.setBranchName(request.getBranchName());
        order.setTemplateId(request.getTemplateId());

        order.setPropertyCategory("VALUATION");
        order.setPurpose("VALUATION");
        order.setStatus("ASSIGNED");
        order.setClaimedAt(LocalDateTime.now());
        order.setLastHeartbeat(LocalDateTime.now());

        if (request.getTemplateId() != null) {
            templateRepository.findById(request.getTemplateId()).ifPresent(t -> {
                order.setFieldMappingSnapshot(t.getFieldMapping());
            });
        }

        LocalDateTime now = LocalDateTime.now();
        int yy = now.getYear() % 100;
        int mm = now.getMonthValue();
        String prefix = String.format("PV-%02d%02d-", yy, mm);
        long seq = orderRepository.countByReportNumberStartingWith(prefix) + 1;
        String reportNumber = String.format("%s%04d", prefix, seq);
        order.setReportNumber(reportNumber);

        Order savedOrder = orderRepository.save(order);

        orderInputRepository.save(new OrderInput(savedOrder.getId(), "CLIENT_NAME", request.getClientName()));
        orderInputRepository.save(new OrderInput(savedOrder.getId(), "BANK_NAME", request.getBankName()));
        orderInputRepository.save(new OrderInput(savedOrder.getId(), "BRANCH_NAME", request.getBranchName()));

        performanceLedgerRepository.findById(principal.getId()).ifPresent(ledger -> {
            ledger.setActiveAllocations(ledger.getActiveAllocations() + 1);
            performanceLedgerRepository.save(ledger);
        });

        return ResponseEntity.ok(savedOrder);
    }

    private void saveOrUpdateInput(Long orderId, String key, String value) {
        Optional<OrderInput> existing = orderInputRepository.findByOrderIdAndFieldKey(orderId, key);
        OrderInput field = existing.orElseGet(() -> new OrderInput(orderId, key, ""));
        
        if (value != null && value.startsWith("data:image/") && value.contains(";base64,")) {
            try {
                String base64Data = value.substring(value.indexOf(";base64,") + 8);
                byte[] bytes = Base64.getDecoder().decode(base64Data);
                field.setImageValue(bytes);
                field.setFieldValue("[IMAGE]");
            } catch (Exception e) {
                field.setFieldValue(value);
            }
        } else {
            field.setFieldValue(value);
            field.setImageValue(null);
        }
        orderInputRepository.save(field);
    }
}
