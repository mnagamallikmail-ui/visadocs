package com.provaluer.controller;

import com.provaluer.dto.ProvideQuoteRequest;
import com.provaluer.dto.QuoteResponseDto;
import com.provaluer.dto.SubmitPaymentRequest;
import com.provaluer.dto.VerifyPaymentRequest;
import com.provaluer.dto.RejectPaymentRequest;
import com.provaluer.dto.PaymentDetailsResponse;
import com.provaluer.dto.ReleaseQueueOrderDto;
import com.provaluer.dto.ReleaseToPoolRequest;
import com.provaluer.dto.HoldIntakeRequest;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import org.springframework.format.annotation.DateTimeFormat;
import java.time.LocalDate;
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
import org.springframework.web.server.ResponseStatusException;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.security.MessageDigest;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(OrderController.class);

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;



    @Autowired
    private com.provaluer.service.AuditLogService auditLogService;

    @Autowired
    private com.provaluer.service.TelegramNotificationService telegramNotificationService;

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
    private TemplateVersionRepository templateVersionRepository;

    @Autowired
    private DocxTemplateEngine docxTemplateEngine;

    @Autowired
    private SystemSettingRepository systemSettingRepository;

    @Autowired
    private com.provaluer.service.DocumentWorkspaceService documentWorkspaceService;

    @Autowired
    private com.provaluer.service.QuotePdfGeneratorService quotePdfGeneratorService;

    @Autowired
    private com.provaluer.service.QuotationNotificationService quotationNotificationService;

    @Autowired
    private com.provaluer.service.ReportNumberGeneratorService reportNumberGeneratorService;

    @Autowired
    private com.provaluer.service.PaymentWorkflowService paymentWorkflowService;

    @Autowired
    private com.provaluer.service.PoolReleaseService poolReleaseService;

    // In-memory cache for paused orders remaining SLA business hours
    private final Map<Long, Double> pausedSlaHoursCache = new HashMap<>();

    @PostMapping("/draft")
    @Transactional
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN')")
    public ResponseEntity<?> saveDraft(@RequestBody OrderDraftRequest request) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        
        final Order order;
        if (request.getId() != null) {
            Optional<Order> existingOpt = orderRepository.findById(request.getId());
            if (existingOpt.isPresent()) {
                Order existing = existingOpt.get();
                boolean isAdmin = principal.getAuthorities().stream().anyMatch(a ->
                        a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
                if (!isAdmin && (existing.getClientId() == null || !existing.getClientId().equals(principal.getId()))) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN)
                            .body(Map.of("error", "Access denied: Cannot modify or adopt another user's draft order"));
                }
                order = existing;
            } else {
                order = new Order();
                order.setClientId(principal.getId());
            }
        } else {
            order = new Order();
            order.setClientId(principal.getId());
        }
        if (order.getClientName() == null || order.getClientName().isBlank()) {
            User u = userRepository.findById(principal.getId()).orElse(null);
            if (u != null) {
                order.setClientName(u.getFullName() != null && !u.getFullName().isBlank() ? u.getFullName() : u.getUsername());
            }
        }
        if (request.getPropertyCategory() != null && !request.getPropertyCategory().isBlank()) {
            order.setPropertyCategory(request.getPropertyCategory());
        } else if (order.getPropertyCategory() == null) {
            order.setPropertyCategory("LAND_AND_BUILDING");
        }

        if (request.getServiceCategory() != null && !request.getServiceCategory().isBlank()) {
            order.setServiceCategory(request.getServiceCategory());
        }

        if (request.getPurpose() != null && !request.getPurpose().isBlank()) {
            order.setPurpose(request.getPurpose());
        } else if (order.getPurpose() == null) {
            order.setPurpose("VALUATION");
        }

        order.setEstimatedValue(request.getEstimatedValue());
        order.setTemplateId(request.getTemplateId());
        if (order.getStatus() == null || "DRAFT".equals(order.getStatus())) {
            order.setStatus("DRAFT");
        }
        
        if (request.getTemplateId() != null && order.getFieldMappingSnapshot() == null) {
            templateRepository.findById(request.getTemplateId()).ifPresent(t -> {
                order.setFieldMappingSnapshot(t.getFieldMapping());
                if (t.getDocumentDom() != null) {
                    order.setDocumentDomSnapshot(t.getDocumentDom());
                }
                order.setTemplateVersion(t.getVersion());
            });
        }
        
        Order savedOrder = orderRepository.save(order);

        // Delete existing inputs and rewrite
        List<OrderInput> existingInputs = orderInputRepository.findAllByOrderId(savedOrder.getId());
        orderInputRepository.deleteAll(existingInputs);

        if (request.getServiceCategory() != null && !request.getServiceCategory().isBlank()) {
            saveOrUpdateInput(savedOrder.getId(), "SERVICE_CATEGORY", request.getServiceCategory());
        }

        if (request.getInputs() != null) {
            for (Map.Entry<String, String> entry : request.getInputs().entrySet()) {
                saveOrUpdateInput(savedOrder.getId(), entry.getKey(), entry.getValue());
            }
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

    @DeleteMapping("/{id}")
    @Transactional
    public ResponseEntity<?> deleteOrder(@PathVariable Long id) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (!orderOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isSuperAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));

        if (order.isArchivalLocked() || "CLOSED".equalsIgnoreCase(order.getStatus())) {
            return ResponseEntity.status(HttpStatus.LOCKED)
                    .body(Map.of("error", "Order #" + id + " is permanently CLOSED and under 10-year archival lock. Deletion is strictly prohibited."));
        }

        boolean isFinalized = "FINALIZED".equalsIgnoreCase(order.getValuationStatus())
                || "LOCKED".equalsIgnoreCase(order.getValuationStatus())
                || "SPA_CONFIRMED".equalsIgnoreCase(order.getStatus())
                || "FINAL_DELIVERY".equalsIgnoreCase(order.getStatus())
                || "CLIENT_DOWNLOADED".equalsIgnoreCase(order.getStatus());

        if (isFinalized) {
            if (!isSuperAdmin) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Only Super Admin can delete finalized reports"));
            }
        } else {
            boolean isAdminCreated = auditLogRepository.existsByEntityTypeAndEntityIdAndActionTypeAndActorRole(
                    "ORDER", String.valueOf(order.getId()), "ORDER_CREATE", "SUPER_ADMIN");

            if (isAdminCreated) {
                if (!isSuperAdmin) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN)
                            .body(Map.of("error", "This report was initiated by Administration and can only be deleted by Super Admin"));
                }
            } else {
                boolean isCreator = order.getClientId() != null && order.getClientId().equals(principal.getId());
                if (!isCreator && !isSuperAdmin) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN)
                            .body(Map.of("error", "You can only delete reports created by yourself"));
                }
            }
        }

        order.setDeleted(true);
        order.setDeletedAt(LocalDateTime.now());
        order.setDeletedBy(principal.getId());
        orderRepository.save(order);
        return ResponseEntity.ok(Map.of("status", "SUCCESS", "message", "Report deleted successfully"));
    }

    @PostMapping("/{id}/submit")
    @Transactional
    public ResponseEntity<?> submitIntake(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            boolean isAdmin = principal.getAuthorities().stream().anyMatch(a ->
                    a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
            if (!isAdmin && (order.getClientId() == null || !order.getClientId().equals(principal.getId()))) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied to submit order #" + id));
            }
            // Client pays intake deposit fee -> moves to PAID_INTAKE
            order.setStatus("PAID_INTAKE");
            
            // Generate report number using atomic sequence allocator
            order.setReportNumber(reportNumberGeneratorService.generateNextReportNumber());
            LocalDateTime now = LocalDateTime.now();
            
            // Calculate initial SLA Expiry
            LocalDateTime expiry = slaService.calculateExpiry(order.getPurpose(), now);
            order.setSlaExpiryTime(expiry);

            Order saved = orderRepository.save(order);
            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }

    /**
     * SPRINT 1: POST /api/v1/orders/{id}/submit-request
     * Client Request Submission with mandatory document validation,
     * reference code generation (REQ-YYYY-XXXX), status transition to QUOTE_PENDING,
     * and async Telegram operations alert.
     */
    @PostMapping("/{id}/submit-request")
    @Transactional
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> submitRequest(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required to submit request"));
        }

        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        if (!isAdmin && !order.getClientId().equals(principal.getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied to submit this request"));
        }

        // FIX 4 & 5: Submission State Guard & Telegram Duplicate Prevention
        // Only allow submission when status == DRAFT. Any other status returns 409 Conflict.
        if (order.getStatus() == null || !"DRAFT".equalsIgnoreCase(order.getStatus())) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                    "error", "This request has already been submitted.",
                    "message", "This request has already been submitted.",
                    "status", order.getStatus() != null ? order.getStatus() : "UNKNOWN"
            ));
        }

        // 1. Validate mandatory documents: Title Deed, Plan/Layout, Tax Receipt
        List<OrderDocument> docs = orderDocumentRepository.findAllByOrderId(id);
        Set<String> categories = docs.stream()
                .map(d -> d.getCategory() != null ? d.getCategory().toUpperCase() : "")
                .collect(Collectors.toSet());

        List<String> missing = new ArrayList<>();
        if (!categories.contains("TITLE_DEED") && !categories.contains("SALE_DEED") && !categories.contains("OWNERSHIP_PROOF")) {
            missing.add("Title Deed / Ownership Proof");
        }
        if (!categories.contains("SANCTION_PLAN") && !categories.contains("PLAN_LAYOUT") && !categories.contains("APPROVED_PLAN")) {
            missing.add("Plan / Layout");
        }
        if (!categories.contains("TAX_RECEIPT") && !categories.contains("PROPERTY_TAX")) {
            missing.add("Tax Receipt");
        }

        if (!missing.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Mandatory documents missing: " + String.join(", ", missing),
                    "missingCategories", missing
            ));
        }

        // 2. Generate reference code: REQ-YYYY-XXXX
        if (order.getReferenceCode() == null || order.getReferenceCode().trim().isEmpty()) {
            int year = LocalDateTime.now().getYear();
            String prefix = "REQ-" + year + "-";
            String refCode;
            int attempts = 0;
            do {
                refCode = prefix + String.format("%04d", (int)(Math.random() * 9000) + 1000);
                attempts++;
            } while (orderRepository.existsByReferenceCode(refCode) && attempts < 100);
            order.setReferenceCode(refCode);
        }

        // 3. Update status: REQUEST_SUBMITTED -> QUOTE_PENDING
        order.setStatus("QUOTE_PENDING");
        order.setUpdatedAt(LocalDateTime.now());
        Order savedOrder = orderRepository.save(order);

        // Fetch client details for telegram message
        User clientUser = userRepository.findById(order.getClientId()).orElse(null);
        String clientName = (clientUser != null && clientUser.getFullName() != null && !clientUser.getFullName().isBlank())
                ? clientUser.getFullName() : principal.getUsername();
        String clientMobile = (clientUser != null && clientUser.getMobileNumber() != null && !clientUser.getMobileNumber().isBlank())
                ? clientUser.getMobileNumber() : "N/A";

        // Extract Service Category, Asset Category, Purpose
        String serviceCategory = order.getServiceCategory();
        if (serviceCategory == null || serviceCategory.isBlank()) {
            Optional<OrderInput> sInput = orderInputRepository.findByOrderIdAndFieldKey(id, "SERVICE_CATEGORY");
            serviceCategory = sInput.map(OrderInput::getFieldValue).orElse("Valuation Report");
        }
        String assetCategory = order.getPropertyCategory() != null ? order.getPropertyCategory() : "Land & Building";
        String purpose = order.getPurpose() != null ? order.getPurpose() : "Bank Collateral / Loan";

        // 4. Trigger Telegram async notification (Non-blocking, retryable, safe)
        telegramNotificationService.sendNewRequestNotification(
                savedOrder.getReferenceCode(),
                clientName,
                serviceCategory,
                assetCategory,
                purpose,
                docs.size(),
                clientMobile
        );

        // Log audit trail
        try {
            auditLogService.log(
                    principal.getId(),
                    principal.getUsername(),
                    principal.getAuthorities().iterator().next().getAuthority(),
                    "SUBMIT_REQUEST",
                    "orders",
                    String.valueOf(savedOrder.getId()),
                    "Valuation request submitted with reference " + savedOrder.getReferenceCode() + " and transitioned to QUOTE_PENDING"
            );
        } catch (Exception e) {
            log.warn("Failed to write audit log for submit-request order #{}: {}", id, e.getMessage());
        }

        return ResponseEntity.ok(Map.of(
                "orderId", savedOrder.getId(),
                "referenceCode", savedOrder.getReferenceCode(),
                "status", savedOrder.getStatus(),
                "documentCount", docs.size(),
                "message", "Your request has been received and is under review. A quotation will be issued through the portal after document review."
        ));
    }

    /**
     * SPRINT 1.1: GET /api/v1/orders/by-reference/{refCode}
     * Retrieves order summary by reference code with strict ownership verification.
     * Allowed only for order owner (clientId == principal.id) or ROLE_ADMIN / ROLE_SUPER_ADMIN.
     * All others receive 403 Forbidden.
     */
    @GetMapping("/by-reference/{refCode}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getOrderByReferenceCode(@PathVariable String refCode) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        Optional<Order> orderOpt = orderRepository.findByReferenceCode(refCode);
        if (orderOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));

        if (!isAdmin && (order.getClientId() == null || !order.getClientId().equals(principal.getId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                    "error", "Access denied: you do not have permission to access order " + refCode
            ));
        }

        return ResponseEntity.ok(order);
    }

    /**
     * GET /api/v1/orders/{id}
     * Retrieves order by ID with strict ownership verification.
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getOrderById(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        boolean isOwner = order.getClientId() != null && order.getClientId().equals(principal.getId());

        if (!isAdmin && !isOwner) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Access Denied: Not authorized to view order #" + id));
        }

        return ResponseEntity.ok(order);
    }

    /**
     * SPRINT 2: POST /api/v1/orders/{id}/provide-quote
     * Admin issues formal valuation quotation for orders in QUOTE_PENDING status.
     * Transitions status: QUOTE_PENDING -> QUOTE_PROVIDED.
     * Dispatches multi-channel notifications (Email, Portal, Telegram).
     */
    @PostMapping("/{id}/provide-quote")
    @Transactional
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> provideQuote(@PathVariable Long id, @RequestBody ProvideQuoteRequest request) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        if (!isAdmin) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied: Only administrators can issue quotations"));
        }

        // Status guard: ONLY allow when status == QUOTE_PENDING
        if (!"QUOTE_PENDING".equalsIgnoreCase(order.getStatus())) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                    "error", "Cannot issue quote: Order is in status: " + order.getStatus() + ". Only orders in QUOTE_PENDING status can receive a quote.",
                    "status", order.getStatus()
            ));
        }

        if (request.getQuoteAmount() == null || request.getQuoteAmount().compareTo(BigDecimal.ZERO) <= 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Quote amount must be greater than zero"));
        }
        if (request.getTurnaroundTime() == null || request.getTurnaroundTime().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Turnaround time is required"));
        }
        if (request.getScopeNotes() == null || request.getScopeNotes().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Scope notes are required"));
        }

        // Calculate GST (default 18.00% if not specified)
        BigDecimal gstRate = (request.getGstRate() != null && request.getGstRate().compareTo(BigDecimal.ZERO) >= 0)
                ? request.getGstRate() : BigDecimal.valueOf(18.00);

        BigDecimal quoteTax = request.getQuoteTax();
        if (quoteTax == null) {
            quoteTax = request.getQuoteAmount().multiply(gstRate).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        }

        BigDecimal quoteTotal = request.getQuoteTotal();
        if (quoteTotal == null) {
            quoteTotal = request.getQuoteAmount().add(quoteTax);
        }

        // Generate unique quoteNumber: QTE-YYYY-XXXX
        if (order.getQuoteNumber() == null || order.getQuoteNumber().trim().isEmpty()) {
            int year = LocalDateTime.now().getYear();
            String prefix = "QTE-" + year + "-";
            String quoteNum;
            int attempts = 0;
            do {
                quoteNum = prefix + String.format("%04d", (int)(Math.random() * 9000) + 1000);
                attempts++;
            } while (orderRepository.existsByQuoteNumber(quoteNum) && attempts < 100);
            order.setQuoteNumber(quoteNum);
        }

        int validityDays = (request.getValidityDays() != null && request.getValidityDays() > 0)
                ? request.getValidityDays() : 15;

        order.setQuoteAmount(request.getQuoteAmount());
        order.setQuoteTax(quoteTax);
        order.setQuoteTotal(quoteTotal);
        order.setQuoteTurnaround(request.getTurnaroundTime().trim());
        order.setQuoteNotes(request.getScopeNotes().trim());
        order.setQuoteTerms(request.getTermsConditions() != null ? request.getTermsConditions().trim() : null);
        order.setQuoteValidUntil(LocalDateTime.now().plusDays(validityDays));
        order.setQuotedBy(principal.getId());
        order.setQuotedAt(LocalDateTime.now());
        order.setStatus("QUOTE_PROVIDED");
        order.setUpdatedAt(LocalDateTime.now());

        Order savedOrder = orderRepository.save(order);

        // Fetch client user & admin user
        User clientUser = userRepository.findById(savedOrder.getClientId()).orElse(null);
        User adminUser = userRepository.findById(principal.getId()).orElse(null);

        // Multi-channel notifications
        try {
            quotationNotificationService.notifyQuotationIssued(savedOrder, clientUser, adminUser);
        } catch (Exception e) {
            log.warn("Failed to dispatch quotation notifications for Order #{}: {}", id, e.getMessage());
        }

        // Audit Log
        try {
            auditLogService.log(
                    principal.getId(),
                    principal.getUsername(),
                    principal.getAuthorities().iterator().next().getAuthority(),
                    "PROVIDE_QUOTE",
                    "orders",
                    String.valueOf(savedOrder.getId()),
                    "Issued quotation " + savedOrder.getQuoteNumber() + " for Rs " + savedOrder.getQuoteTotal() + " (Turnaround: " + savedOrder.getQuoteTurnaround() + ")"
            );
        } catch (Exception e) {
            log.warn("Failed to write audit log for provide-quote #{}: {}", id, e.getMessage());
        }

        QuoteResponseDto dto = buildQuoteResponseDto(savedOrder, clientUser, adminUser, gstRate);
        return ResponseEntity.ok(dto);
    }

    /**
     * SPRINT 2: GET /api/v1/orders/{id}/quote
     * Client or Admin views formal valuation quotation particulars.
     */
    @GetMapping("/{id}/quote")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getOrderQuote(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));

        if (!isAdmin && (order.getClientId() == null || !order.getClientId().equals(principal.getId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied: you do not have permission to view quotation for order #" + id));
        }

        if (order.getQuoteNumber() == null || order.getQuoteAmount() == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Quotation has not been issued for this order yet."));
        }

        User clientUser = userRepository.findById(order.getClientId()).orElse(null);
        User adminUser = order.getQuotedBy() != null ? userRepository.findById(order.getQuotedBy()).orElse(null) : null;
        BigDecimal gstRate = BigDecimal.valueOf(18.00);

        return ResponseEntity.ok(buildQuoteResponseDto(order, clientUser, adminUser, gstRate));
    }

    /**
     * SPRINT 2: GET /api/v1/orders/{id}/quote-pdf
     * Generates and downloads the official branded PDF quotation with authorization checks.
     */
    @GetMapping("/{id}/quote-pdf")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getOrderQuotePdf(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));

        if (!isAdmin && (order.getClientId() == null || !order.getClientId().equals(principal.getId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied: you do not have permission to download quotation for order #" + id));
        }

        if (order.getQuoteNumber() == null || order.getQuoteAmount() == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Quotation has not been issued for this order yet."));
        }

        try {
            User clientUser = userRepository.findById(order.getClientId()).orElse(null);
            User adminUser = order.getQuotedBy() != null ? userRepository.findById(order.getQuotedBy()).orElse(null) : null;
            byte[] pdfBytes = quotePdfGeneratorService.generateQuotePdf(order, clientUser, adminUser);

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"Quotation_" + order.getQuoteNumber() + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(pdfBytes);
        } catch (Exception e) {
            log.error("Failed to generate Quote PDF for order #{}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "Failed to generate Quote PDF: " + e.getMessage()));
        }
    }

    /**
     * SPRINT 3: POST /api/v1/orders/{id}/submit-payment
     * Client owner uploads payment proof (receipt, UTR, date, amount) for an order in QUOTE_PROVIDED or PAYMENT_REJECTED.
     * Transitions status to PAYMENT_SUBMITTED.
     */
    @PostMapping(value = "/{id}/submit-payment", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> submitPayment(
            @PathVariable Long id,
            @RequestParam("file") org.springframework.web.multipart.MultipartFile file,
            @RequestParam("utrNumber") String utrNumber,
            @RequestParam("paymentMethod") String paymentMethod,
            @RequestParam("paymentDate") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate paymentDate,
            @RequestParam("amountPaid") BigDecimal amountPaid,
            @RequestParam(value = "notes", required = false) String notes) {

        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        SubmitPaymentRequest req = new SubmitPaymentRequest();
        req.setUtrNumber(utrNumber);
        req.setPaymentMethod(paymentMethod);
        req.setPaymentDate(paymentDate);
        req.setAmountPaid(amountPaid);
        req.setNotes(notes);

        try {
            PaymentDetailsResponse.PaymentRecordDto record = paymentWorkflowService.submitPaymentProof(id, file, req, principal);
            return ResponseEntity.ok(record);
        } catch (org.springframework.web.server.ResponseStatusException rse) {
            return ResponseEntity.status(rse.getStatusCode()).body(Map.of("error", rse.getReason()));
        } catch (Exception e) {
            log.error("Failed to submit payment for order #{}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "Failed to submit payment: " + e.getMessage()));
        }
    }

    /**
     * SPRINT 3: POST /api/v1/orders/{id}/verify-payment
     * Admin confirms bank receipt and transitions status to PAYMENT_VERIFIED.
     */
    @PostMapping("/{id}/verify-payment")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> verifyPayment(
            @PathVariable Long id,
            @RequestBody(required = false) VerifyPaymentRequest request) {

        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        try {
            PaymentDetailsResponse.PaymentRecordDto record = paymentWorkflowService.verifyPayment(id, request, principal);
            return ResponseEntity.ok(record);
        } catch (org.springframework.web.server.ResponseStatusException rse) {
            return ResponseEntity.status(rse.getStatusCode()).body(Map.of("error", rse.getReason()));
        } catch (Exception e) {
            log.error("Failed to verify payment for order #{}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "Failed to verify payment: " + e.getMessage()));
        }
    }

    /**
     * SPRINT 3: POST /api/v1/orders/{id}/reject-payment
     * Admin rejects submitted proof and transitions status to PAYMENT_REJECTED.
     */
    @PostMapping("/{id}/reject-payment")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> rejectPayment(
            @PathVariable Long id,
            @RequestBody RejectPaymentRequest request) {

        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        if (request == null || request.getRejectionReason() == null || request.getRejectionReason().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Rejection reason is mandatory"));
        }

        try {
            PaymentDetailsResponse.PaymentRecordDto record = paymentWorkflowService.rejectPayment(id, request, principal);
            return ResponseEntity.ok(record);
        } catch (org.springframework.web.server.ResponseStatusException rse) {
            return ResponseEntity.status(rse.getStatusCode()).body(Map.of("error", rse.getReason()));
        } catch (Exception e) {
            log.error("Failed to reject payment for order #{}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "Failed to reject payment: " + e.getMessage()));
        }
    }

    /**
     * SPRINT 3: GET /api/v1/orders/{id}/payment-details
     * Retrieves order payment details, quote summary, dynamic bank/UPI instructions, and payment history.
     */
    @GetMapping("/{id}/payment-details")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getPaymentDetails(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        try {
            PaymentDetailsResponse response = paymentWorkflowService.getPaymentDetails(id, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.web.server.ResponseStatusException rse) {
            return ResponseEntity.status(rse.getStatusCode()).body(Map.of("error", rse.getReason()));
        } catch (Exception e) {
            log.error("Failed to fetch payment details for order #{}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "Failed to fetch payment details: " + e.getMessage()));
        }
    }

    // ════════════════════════════════════════════════════════════════════════════
    // SPRINT 4: Admin Controlled Pool Release Endpoints
    // ════════════════════════════════════════════════════════════════════════════

    /**
     * SPRINT 3/4 Fix: GET /api/v1/orders/payment-review-queue
     * Returns all PAYMENT_SUBMITTED orders awaiting admin payment verification.
     * Restricted to ROLE_ADMIN and ROLE_SUPER_ADMIN only.
     */
    @GetMapping("/payment-review-queue")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> getPaymentReviewQueue() {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        try {
            java.util.List<ReleaseQueueOrderDto> queue = poolReleaseService.getPaymentReviewQueue();
            return ResponseEntity.ok(queue);
        } catch (Exception e) {
            log.error("Failed to fetch payment review queue: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch payment review queue: " + e.getMessage()));
        }
    }

    /**
     * SPRINT 4 — Section C: GET /api/v1/orders/release-queue
     * Returns all PAYMENT_VERIFIED orders awaiting admin release to Common Pool.
     * Restricted to ROLE_ADMIN and ROLE_SUPER_ADMIN only.
     */
    @GetMapping("/release-queue")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> getReleaseQueue() {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        try {
            java.util.List<ReleaseQueueOrderDto> queue = poolReleaseService.getReleaseQueue();
            return ResponseEntity.ok(queue);
        } catch (Exception e) {
            log.error("Failed to fetch release queue: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to fetch release queue: " + e.getMessage()));
        }
    }

    /**
     * SPRINT 4 — Section E: POST /api/v1/orders/{id}/release-to-pool
     * Admin performs a full 10-step pre-condition check then transitions
     * a PAYMENT_VERIFIED order to PAID_INTAKE, making it visible in Common Pool.
     * Generates PV-YYMM-XXXX report number and starts SLA timer.
     * Restricted to ROLE_ADMIN and ROLE_SUPER_ADMIN.
     */
    @PostMapping("/{id}/release-to-pool")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> releaseToPool(
            @PathVariable Long id,
            @RequestBody(required = false) ReleaseToPoolRequest request) {

        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        String intakeNotes = (request != null) ? request.getIntakeNotes() : null;

        try {
            ReleaseQueueOrderDto result = poolReleaseService.releaseToPool(id, intakeNotes, principal);
            return ResponseEntity.ok(result);
        } catch (org.springframework.web.server.ResponseStatusException rse) {
            return ResponseEntity.status(rse.getStatusCode()).body(Map.of("error", rse.getReason()));
        } catch (Exception e) {
            log.error("Failed to release order #{} to pool: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to release order to pool: " + e.getMessage()));
        }
    }

    /**
     * SPRINT 4 — Section D: POST /api/v1/orders/{id}/hold-intake
     * Admin places a PAYMENT_VERIFIED order on intake hold, preventing accidental release.
     * Restricted to ROLE_ADMIN and ROLE_SUPER_ADMIN.
     */
    @PostMapping("/{id}/hold-intake")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> holdIntake(
            @PathVariable Long id,
            @RequestBody HoldIntakeRequest request) {

        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        if (request == null || request.getHoldReason() == null || request.getHoldReason().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Hold reason is mandatory"));
        }

        try {
            ReleaseQueueOrderDto result = poolReleaseService.holdIntake(id, request.getHoldReason(), principal);
            return ResponseEntity.ok(result);
        } catch (org.springframework.web.server.ResponseStatusException rse) {
            return ResponseEntity.status(rse.getStatusCode()).body(Map.of("error", rse.getReason()));
        } catch (Exception e) {
            log.error("Failed to hold intake for order #{}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to hold intake: " + e.getMessage()));
        }
    }

    private QuoteResponseDto buildQuoteResponseDto(Order order, User clientUser, User adminUser, BigDecimal gstRate) {
        QuoteResponseDto dto = new QuoteResponseDto();
        dto.setOrderId(order.getId());
        dto.setReferenceCode(order.getReferenceCode());
        dto.setQuoteNumber(order.getQuoteNumber());
        dto.setStatus(order.getStatus());
        dto.setServiceCategory(order.getServiceCategory());
        dto.setAssetCategory(order.getPropertyCategory());
        dto.setPurpose(order.getPurpose());

        if (clientUser != null) {
            dto.setClientName(clientUser.getFullName() != null && !clientUser.getFullName().isBlank() ? clientUser.getFullName() : clientUser.getUsername());
            dto.setClientEmail(clientUser.getEmail());
            dto.setClientMobile(clientUser.getMobileNumber());
        }

        dto.setQuoteAmount(order.getQuoteAmount());
        dto.setGstRate(gstRate);
        dto.setQuoteTax(order.getQuoteTax());
        dto.setQuoteTotal(order.getQuoteTotal());
        dto.setTurnaroundTime(order.getQuoteTurnaround());
        dto.setScopeNotes(order.getQuoteNotes());
        dto.setTermsConditions(order.getQuoteTerms());
        dto.setValidUntil(order.getQuoteValidUntil());
        dto.setQuotedAt(order.getQuotedAt());

        if (adminUser != null) {
            dto.setQuotedByName(adminUser.getFullName() != null && !adminUser.getFullName().isBlank() ? adminUser.getFullName() : adminUser.getUsername());
        }

        return dto;
    }

    @GetMapping("/client")
    public ResponseEntity<List<Order>> getClientOrders() {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        List<Order> orders = orderRepository.findAllByClientId(principal.getId());
        for (Order o : orders) {
            boolean isAdminCreated = auditLogRepository.existsByEntityTypeAndEntityIdAndActionTypeAndActorRole(
                    "ORDER", String.valueOf(o.getId()), "ORDER_CREATE", "SUPER_ADMIN");
            o.setAdminCreated(isAdminCreated);
        }
        return ResponseEntity.ok(orders);
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
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> telemetryHeartbeat(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            boolean isAdminOrSpa = principal.getAuthorities().stream().anyMatch(a ->
                    a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SPA"));
            boolean isAssignedPa = order.getPaId() != null && order.getPaId().equals(principal.getId());
            if (!isAdminOrSpa && !isAssignedPa) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied: Not assigned to order #" + id));
            }
            order.setLastHeartbeat(LocalDateTime.now());
            orderRepository.save(order);
            return ResponseEntity.ok(Map.of(
                "orderId", order.getId(),
                "status", order.getStatus() != null ? order.getStatus() : "",
                "paId", order.getPaId() != null ? order.getPaId() : -1L,
                "workspaceRevision", order.getWorkspaceRevision() != null ? order.getWorkspaceRevision() : 1,
                "isPaused", order.isPaused()
            ));
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/pause")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> pauseOrder(
            @PathVariable Long id,
            @RequestParam("reason") String reason,
            @RequestParam(value = "description", required = false) String description) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

            boolean isStaff = principal.getAuthorities().stream().anyMatch(a ->
                    a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SPA"));
            if (!isStaff && (order.getPaId() == null || !order.getPaId().equals(principal.getId()))) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied.");
            }

            String previousStatus = order.getStatus();
            order.setPrePauseStatus(previousStatus);
            order.setPaused(true);
            order.setStatus("ACTION_NEEDED");
            order.setPauseReason(reason);
            order.setUpdatedAt(LocalDateTime.now());

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

            // Audit log
            String actorRole = principal.getAuthorities().stream().map(a -> a.getAuthority().replace("ROLE_", "")).findFirst().orElse("USER");
            auditLogService.log(
                    principal.getId(),
                    principal.getEmail(),
                    actorRole,
                    "ASSIGNMENT_PAUSED",
                    "ORDER",
                    String.valueOf(order.getId()),
                    previousStatus,
                    "ACTION_NEEDED",
                    "Paused due to: " + reason + (description != null ? " - " + description : "")
            );

            // Telegram alert
            telegramNotificationService.sendActionNeededNotification(
                    order.getReferenceCode(),
                    order.getReportNumber(),
                    reason,
                    description != null ? description : reason,
                    principal.getUsername()
            );

            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/{id}/resume")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> resumeOrder(@PathVariable Long id) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();

            boolean isStaff = principal.getAuthorities().stream().anyMatch(a ->
                    a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SPA"));
            if (!isStaff && (order.getPaId() == null || !order.getPaId().equals(principal.getId()))) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied.");
            }

            String restoredStatus = order.getPrePauseStatus() != null ? order.getPrePauseStatus() : "ASSIGNED";
            order.setPaused(false);
            order.setStatus(restoredStatus);
            order.setPrePauseStatus(null);
            order.setPauseReason(null);
            order.setUpdatedAt(LocalDateTime.now());

            // Recalculate SLA expiry based on remaining cached hours
            double remainingHours = pausedSlaHoursCache.getOrDefault(order.getId(), 36.0);
            LocalDateTime newExpiry = slaService.addBusinessHours(LocalDateTime.now(), remainingHours);
            order.setSlaExpiryTime(newExpiry);

            Order saved = orderRepository.save(order);

            // Audit log
            String actorRole = principal.getAuthorities().stream().map(a -> a.getAuthority().replace("ROLE_", "")).findFirst().orElse("USER");
            auditLogService.log(
                    principal.getId(),
                    principal.getEmail(),
                    actorRole,
                    "ASSIGNMENT_RESUMED",
                    "ORDER",
                    String.valueOf(order.getId()),
                    "ACTION_NEEDED",
                    restoredStatus,
                    "Resumed order back to status " + restoredStatus + " with remaining SLA hours: " + remainingHours
            );

            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }



    @PostMapping("/{id}/submit-draft")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> submitDraftForVerification(@PathVariable Long id, @RequestBody Map<String, String> inputs) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            boolean isSpaOrAdmin = principal.getAuthorities().stream().anyMatch(a ->
                    a.getAuthority().equals("ROLE_SPA") || a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
            boolean isAssignedPa = order.getPaId() != null && order.getPaId().equals(principal.getId());
            if (!isSpaOrAdmin && !isAssignedPa) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied: You are not assigned to Order #" + id));
            }
            
            // Save final fields
            for (Map.Entry<String, String> entry : inputs.entrySet()) {
                saveOrUpdateInput(order.getId(), entry.getKey(), entry.getValue());
            }

            if (order.getTemplateId() != null && order.getFieldMappingSnapshot() == null) {
                templateRepository.findById(order.getTemplateId()).ifPresent(t -> {
                    order.setFieldMappingSnapshot(t.getFieldMapping());
                    if (t.getDocumentDom() != null) {
                        order.setDocumentDomSnapshot(t.getDocumentDom());
                    }
                    order.setTemplateVersion(t.getVersion());
                });
            }

            // SPA/Admin only saves inputs — status is preserved so the order stays visible in review queue.
            // Only a PA submission advances the status to SPA_GATE.
            if (!isSpaOrAdmin) {
                order.setStatus("SPA_GATE");
            }
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

    @PostMapping("/{id}/revert-to-review")
    @Transactional
    @PreAuthorize("hasAnyRole('SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> revertToReview(@PathVariable Long id) {
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            // Super Admin override: push an approved report back to SPA review
            order.setStatus("SPA_GATE");
            return ResponseEntity.ok(orderRepository.save(order));
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
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            
            boolean isSuperAdmin = principal.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
            boolean isOwner = order.getClientId() != null && order.getClientId().equals(principal.getId());

            if (!isSuperAdmin && !isOwner) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied: You do not own this valuation report."));
            }

            boolean isDeliveryState = "FINAL_DELIVERY".equalsIgnoreCase(order.getStatus())
                    || "CLIENT_DOWNLOADED".equalsIgnoreCase(order.getStatus())
                    || "CLOSED".equalsIgnoreCase(order.getStatus());

            if (!isDeliveryState && !isSuperAdmin) {
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
                Template template = templateId != null ? templateRepository.findById(templateId).orElse(null) : null;
                byte[] templateBytes = documentWorkspaceService.resolveOrderTemplateBytes(order, template);
                if (templateBytes == null || templateBytes.length == 0) {
                    return ResponseEntity.badRequest().body("Template content not found for order #" + id);
                }

                Map<String, String> inputsMap = documentWorkspaceService.getConsolidatedValues(id);
                Map<String, byte[]> imagesMap = new HashMap<>();
                List<OrderInput> inputsList = orderInputRepository.findAllByOrderId(id);
                for (OrderInput input : inputsList) {
                    String key = input.getFieldKey().toUpperCase();
                    String val = input.getFieldValue();
                    if ((key.contains("DATE_") || key.contains("_DATE") || key.equals("DATE")) && (val == null || val.trim().isEmpty())) {
                        inputsMap.put(key, java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy")));
                    }
                    if (input.getImageValue() != null) {
                        imagesMap.put(key, input.getImageValue());
                    }
                }

                try {
                    // 1. Hydrate the DOCX template
                    byte[] docxBytes = docxTemplateEngine.generateReport(templateBytes, inputsMap, imagesMap);
                    
                    // 2. Convert Hydrated DOCX to PDF (no digital signature)
                    reportBytes = docxTemplateEngine.convertDocxToPdf(docxBytes);
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
            result.put("passwordHint", "First 4 digits of your registered mobile number");
            result.put("dataStream", encryptedBase64);

            try {
                auditLogService.log(principal.getId(), principal.getUsername(),
                        principal.getAuthorities().iterator().next().getAuthority(),
                        "REPORT_DOWNLOADED", "ORDER", String.valueOf(id), "Report downloaded via secure direct endpoint");
            } catch (Exception ignored) {}

            return ResponseEntity.ok(result);
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/{id}/download-docx")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> downloadReportDocx(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            boolean isSpaOrAdmin = principal.getAuthorities().stream().anyMatch(a ->
                    a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SPA"));
            boolean isAssignedPa = order.getPaId() != null && order.getPaId().equals(principal.getId());
            if (!isSpaOrAdmin && !isAssignedPa) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied: You are not assigned to Order #" + id));
            }
            boolean isDocxAllowed = "SPA_GATE".equals(order.getStatus())
                    || "SPA_CONFIRMED".equals(order.getStatus())
                    || "FINAL_DELIVERY".equals(order.getStatus())
                    || "CLIENT_DOWNLOADED".equals(order.getStatus())
                    || "CLOSED".equals(order.getStatus())
                    || "SUPER_ADMIN_GATE".equals(order.getStatus());

            if (!isDocxAllowed) {
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
            Template template = templateId != null ? templateRepository.findById(templateId).orElse(null) : null;
            byte[] templateBytes = documentWorkspaceService.resolveOrderTemplateBytes(order, template);
            if (templateBytes == null || templateBytes.length == 0) {
                return ResponseEntity.badRequest().body("Template content not found for order #" + id);
            }

            Map<String, String> inputsMap = documentWorkspaceService.getConsolidatedValues(id);
            Map<String, byte[]> imagesMap = new HashMap<>();
            List<OrderInput> inputsList = orderInputRepository.findAllByOrderId(id);
            for (OrderInput input : inputsList) {
                String key = input.getFieldKey().toUpperCase();
                String val = input.getFieldValue();
                if ((key.contains("DATE_") || key.contains("_DATE") || key.equals("DATE")) && (val == null || val.trim().isEmpty())) {
                    inputsMap.put(key, java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("dd-MM-yyyy")));
                }
                if (input.getImageValue() != null) {
                    imagesMap.put(key, input.getImageValue());
                }
            }

            try {
                // 1. Hydrate the DOCX template (Word-first, no digital signature)
                byte[] docxBytes = docxTemplateEngine.generateReport(templateBytes, inputsMap, imagesMap);

                return ResponseEntity.ok()
                        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Report_" + id + ".docx\"")
                        .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
                        .contentLength(docxBytes.length)
                        .body(docxBytes);
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
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            boolean isAdmin = principal.getAuthorities().stream().anyMatch(a ->
                    a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
            boolean isAssignedPa = order.getPaId() != null && order.getPaId().equals(principal.getId());
            if (!isAdmin && !isAssignedPa) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied: You are not assigned to Order #" + id));
            }
            order.setTemplateId(templateId);
            templateRepository.findById(templateId).ifPresent(t -> {
                order.setFieldMappingSnapshot(t.getFieldMapping());
                if (t.getDocumentDom() != null) {
                    order.setDocumentDomSnapshot(t.getDocumentDom());
                }
                order.setTemplateVersion(t.getVersion());
            });
            Order saved = orderRepository.save(order);
            return ResponseEntity.ok(saved);
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/{id}/inputs")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<?> getOrderInputs(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();
        boolean isStaffOrAdmin = principal.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SPA"));
        boolean isOwner = order.getClientId() != null && order.getClientId().equals(principal.getId());
        boolean isAssignedPa = order.getPaId() != null && order.getPaId().equals(principal.getId());

        if (!isStaffOrAdmin && !isOwner && !isAssignedPa) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied to inputs for Order #" + id));
        }

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
        private String serviceCategory;
        private String purpose;
        private BigDecimal estimatedValue;
        private Long templateId;
        private Map<String, String> inputs;

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getPropertyCategory() { return propertyCategory; }
        public void setPropertyCategory(String propertyCategory) { this.propertyCategory = propertyCategory; }
        public String getServiceCategory() { return serviceCategory; }
        public void setServiceCategory(String serviceCategory) { this.serviceCategory = serviceCategory; }
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

        @Override
        public String toString() {
            return "CreateStaffReportRequest{clientName='" + clientName + "', bankName='" + bankName + "', branchName='" + branchName + "', templateId=" + templateId + "}";
        }
    }

    @PostMapping("/create-by-staff")
    @Transactional
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> createStaffReport(@RequestBody CreateStaffReportRequest request) {
        log.info("Create report request: {}", request);
        log.info("Template ID: {}", request != null ? request.getTemplateId() : null);

        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", "Authentication required to create report."));
        }

        if (request == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Request payload cannot be null."));
        }

        String clientName = (request.getClientName() != null) ? request.getClientName().trim() : "";
        String bankName = (request.getBankName() != null) ? request.getBankName().trim() : "";
        String branchName = (request.getBranchName() != null) ? request.getBranchName().trim() : "";

        if (clientName.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Client Name is required."));
        }
        if (bankName.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Bank Name is required."));
        }
        if (branchName.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Branch Name is required."));
        }

        // ========================================================================
        // REPORT CREATION VALIDATION GOVERNANCE
        // ========================================================================
        Long templateId = request.getTemplateId();
        if (templateId == null || templateId <= 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Template ID is required. Cannot create report with missing template."));
        }

        Optional<Template> templateOpt = templateRepository.findById(templateId);
        log.info("Template found: {}", templateOpt.isPresent());
        if (templateOpt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Template #" + templateId + " not found. Cannot create report with missing template."));
        }

        Template template = templateOpt.get();
        log.info("Template status: {}", template.getStatus());

        // 1. Do not allow report creation with Deleted template
        if (Template.STATUS_DELETED.equalsIgnoreCase(template.getStatus()) || template.getDeletedAt() != null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Template #" + templateId + " is deleted. Cannot create report with deleted template."));
        }

        // 2. Do not allow report creation with Inactive template
        if (!"Y".equalsIgnoreCase(template.getIsActive()) || Template.STATUS_ARCHIVED.equalsIgnoreCase(template.getStatus())) {
            return ResponseEntity.badRequest().body(Map.of("error", "Template #" + templateId + " is inactive. Cannot create report with inactive template."));
        }

        // 3. Do not allow report creation with Template in PARSING state
        if ("PARSING".equalsIgnoreCase(template.getStatus()) || "PENDING".equalsIgnoreCase(template.getStatus())) {
            return ResponseEntity.badRequest().body(Map.of("error", "Template #" + templateId + " is currently in PARSING state. Cannot create report until parsing completes."));
        }

        // 4. Do not allow report creation with Template in FAILED state
        if ("FAILED".equalsIgnoreCase(template.getStatus()) || "ERROR".equalsIgnoreCase(template.getStatus())
                || (template.getProcessingError() != null && !template.getProcessingError().trim().isEmpty())) {
            String errorDetail = (template.getProcessingError() != null && !template.getProcessingError().trim().isEmpty())
                    ? template.getProcessingError()
                    : "Processing failed";
            return ResponseEntity.badRequest().body(Map.of("error", "Template #" + templateId + " is in FAILED state (" + errorDetail + "). Cannot create report with failed template."));
        }

        Order order = new Order();
        order.setClientId(principal.getId());
        order.setPaId(principal.getId());
        order.setClientName(clientName);
        order.setBankName(bankName);
        order.setBranchName(branchName);
        order.setTemplateId(template.getId());

        order.setPropertyCategory("VALUATION");
        order.setPurpose("VALUATION");
        order.setStatus("ASSIGNED");
        order.setClaimedAt(LocalDateTime.now());
        order.setLastHeartbeat(LocalDateTime.now());

        order.setFieldMappingSnapshot(template.getFieldMapping());
        if (template.getDocumentDom() != null) {
            order.setDocumentDomSnapshot(template.getDocumentDom());
        }
        order.setTemplateVersion(template.getVersion());

        // Link immutable template_version_id for Option A historical preservation
        templateVersionRepository.findByTemplateIdAndVersion(template.getId(), template.getVersion())
                .ifPresent(tv -> order.setTemplateVersionId(tv.getId()));

        // Generate report number using atomic sequence allocator
        order.setReportNumber(reportNumberGeneratorService.generateNextReportNumber());

        Order savedOrder = orderRepository.save(order);

        orderInputRepository.save(new OrderInput(savedOrder.getId(), "CLIENT_NAME", clientName));
        orderInputRepository.save(new OrderInput(savedOrder.getId(), "BANK_NAME", bankName));
        orderInputRepository.save(new OrderInput(savedOrder.getId(), "BRANCH_NAME", branchName));

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
                bytes = com.provaluer.util.ImageOptimizationUtil.compressAndResizeImage(bytes);
                field.setImageValue(bytes);
                field.setFieldValue("[IMAGE]");
            } catch (Exception e) {
                field.setFieldValue(value);
            }
        }
        orderInputRepository.save(field);
    }

    private UserDetailsImpl getCurrentPrincipal() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof UserDetailsImpl) {
            return (UserDetailsImpl) principal;
        }
        return null;
    }

    /**
     * GET /api/v1/orders/{id}/document-workspace
     * Document Workspace API returning authentic visual preview and active values.
     */
    @GetMapping("/{id}/document-workspace")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> getDocumentWorkspace(@PathVariable Long id) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.getDocumentWorkspace(id, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason() != null ? e.getReason() : e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/initialize-workspace
     * SPRINT 6: Transitions status from INSPECTION_COMPLETED to WORKSPACE_READY.
     */
    @PostMapping("/{id}/initialize-workspace")
    @PreAuthorize("hasAnyRole('PA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> initializeWorkspace(@PathVariable Long id) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.initializeWorkspace(id, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason() != null ? e.getReason() : e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/bind-template
     * SPRINT 6: Locks template version permanently and records snapshots.
     */
    @PostMapping("/{id}/bind-template")
    @PreAuthorize("hasAnyRole('PA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> bindTemplate(@PathVariable Long id, @RequestBody(required = false) com.provaluer.dto.BindTemplateRequest request) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.bindTemplate(id, request, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason() != null ? e.getReason() : e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/v1/orders/{id}/validate-draft
     * SPRINT 6: Evaluates mandatory fields, photos, calculations, and placeholders.
     */
    @GetMapping("/{id}/validate-draft")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> validateDraft(@PathVariable Long id) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.validateDraft(id, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason() != null ? e.getReason() : e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/save-document-values
     * Delta persistence of in-document input values without synthetic questions.
     */
    @PostMapping("/{id}/save-document-values")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> saveDocumentValues(@PathVariable Long id, @RequestBody com.provaluer.dto.SaveDocumentValuesRequest request) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.saveDocumentValues(id, request, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason() != null ? e.getReason() : e.getMessage()));
        } catch (org.springframework.orm.ObjectOptimisticLockingFailureException | jakarta.persistence.OptimisticLockException e) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                "error", "Concurrent update detected. Workspace was modified by another session. Please refresh."
            ));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * PUT /api/v1/orders/{id}/text-overrides
     * SPA order-level question and label override persistence.
     */
    @PutMapping("/{id}/text-overrides")
    @PreAuthorize("hasAnyRole('SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> saveOrderTextOverrides(@PathVariable Long id, @RequestBody Map<String, String> overrides) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.saveOrderTextOverrides(id, overrides, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason() != null ? e.getReason() : e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/submit-to-spa
     * SPRINT 6: Advances order status from DRAFTING to SPA_GATE after validating all mandatory gates.
     */
    @PostMapping("/{id}/submit-to-spa")
    @PreAuthorize("hasAnyRole('PA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> submitToSpa(@PathVariable Long id) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.submitToSpa(id, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason() != null ? e.getReason() : e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/spa-approve
     * Approves report, computes fees, and triggers binary DOCX/PDF report compilation.
     */
    @PostMapping("/{id}/spa-approve")
    @PreAuthorize("hasAnyRole('SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> spaApproveDocument(@PathVariable Long id, @RequestBody(required = false) com.provaluer.dto.SpaApproveDocumentRequest request) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.spaApprove(id, request, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.web.server.ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason() != null ? e.getReason() : e.getMessage()));
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/generate-pdf
     * On-demand PDF compilation. Completely separate action from approval flow.
     */
    @PostMapping("/{id}/generate-pdf")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> generatePdf(@PathVariable Long id) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.generatePdfOnDemand(id, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.web.server.ResponseStatusException e) {
            return ResponseEntity.status(e.getStatusCode()).body(Map.of("error", e.getReason() != null ? e.getReason() : e.getMessage()));
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/v1/orders/{id}/download-pdf
     * Direct binary PDF download for authorized roles once generated on demand.
     */
    @GetMapping("/{id}/download-pdf")
    public ResponseEntity<?> downloadPdfReport(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }
        Optional<Order> orderOpt = orderRepository.findById(id);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            boolean isSpaOrAdmin = principal.getAuthorities().stream().anyMatch(a ->
                    a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SPA"));
            boolean isAssignedPa = order.getPaId() != null && order.getPaId().equals(principal.getId());
            boolean isOwner = order.getClientId() != null && order.getClientId().equals(principal.getId());
            if (!isSpaOrAdmin && !isAssignedPa && !isOwner) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied: You are not authorized for Order #" + id));
            }

            List<OrderDocument> docs = orderDocumentRepository.findAllByOrderId(id);
            Optional<OrderDocument> finalPdfOpt = docs.stream()
                    .filter(d -> "FINAL_SIGNED_PDF".equalsIgnoreCase(d.getCategory()))
                    .findFirst();

            if (finalPdfOpt.isPresent() && finalPdfOpt.get().getFileContent() != null) {
                byte[] pdfContent = finalPdfOpt.get().getFileContent();
                return ResponseEntity.ok()
                        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Report_" + id + ".pdf\"")
                        .contentType(MediaType.APPLICATION_PDF)
                        .contentLength(pdfContent.length)
                        .body(pdfContent);
            }

            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "PDF not generated yet. Please generate PDF first."));
        }
        return ResponseEntity.notFound().build();
    }

    /**
     * POST /api/v1/orders/{id}/compile-live-preview
     * Compiles true final hydrated PDF preview with unique session nonce.
     */
    @PostMapping("/{id}/compile-live-preview")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> compileLivePreview(@PathVariable Long id) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var response = documentWorkspaceService.compileLivePreview(id, principal);
            return ResponseEntity.ok(response);
        } catch (org.springframework.security.access.AccessDeniedException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/v1/orders/{id}/live-preview/{previewSessionId}/pages/{pageIndex}.png
     * TASK 3: Streams session-nonced live hydrated preview page tiles.
     */
    @GetMapping(value = "/{id}/live-preview/{previewSessionId}/pages/{pageIndex}.png", produces = MediaType.IMAGE_PNG_VALUE)
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN', 'CLIENT')")
    public ResponseEntity<byte[]> getLivePreviewSessionPageImage(
            @PathVariable Long id,
            @PathVariable String previewSessionId,
            @PathVariable int pageIndex) {
        try {
            byte[] imageBytes = documentWorkspaceService.getLivePreviewSessionPageImage(id, previewSessionId, pageIndex);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"live_" + previewSessionId + "_p" + pageIndex + ".png\"")
                    .body(imageBytes);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/v1/orders/{id}/live-pages/{pageIndex}.png
     * Legacy streaming fallback for unversioned live page tiles.
     */
    @GetMapping(value = "/{id}/live-pages/{pageIndex}.png", produces = MediaType.IMAGE_PNG_VALUE)
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN', 'CLIENT')")
    public ResponseEntity<byte[]> getLivePageImage(@PathVariable Long id, @PathVariable int pageIndex) {
        try {
            byte[] imageBytes = documentWorkspaceService.getLivePageImage(id, pageIndex);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"live_page_" + pageIndex + ".png\"")
                    .body(imageBytes);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/v1/orders/{id}/revisions
     * Returns all immutable revision records for the order under Option A.
     */
    @GetMapping("/{id}/revisions")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN', 'CLIENT')")
    public ResponseEntity<?> getOrderRevisions(@PathVariable Long id) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            var list = documentWorkspaceService.getOrderRevisions(id, principal);
            return ResponseEntity.ok(list);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * GET /api/v1/orders/{id}/revisions/{revNumber}/pdf
     * Downloads immutable historical revision PDF without destroying history.
     */
    @GetMapping("/{id}/revisions/{revNumber}/pdf")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN', 'CLIENT')")
    public ResponseEntity<byte[]> getRevisionPdf(@PathVariable Long id, @PathVariable int revNumber) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            byte[] bytes = documentWorkspaceService.getRevisionDocumentBytes(id, revNumber, "pdf", principal);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Report_" + id + "_Rev" + revNumber + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(bytes);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * GET /api/v1/orders/{id}/revisions/{revNumber}/docx
     * Downloads immutable historical revision DOCX without destroying history.
     */
    @GetMapping("/{id}/revisions/{revNumber}/docx")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN', 'CLIENT')")
    public ResponseEntity<byte[]> getRevisionDocx(@PathVariable Long id, @PathVariable int revNumber) {
        try {
            UserDetailsImpl principal = getCurrentPrincipal();
            byte[] bytes = documentWorkspaceService.getRevisionDocumentBytes(id, revNumber, "docx", principal);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"Report_" + id + "_Rev" + revNumber + ".docx\"")
                    .header(HttpHeaders.CONTENT_TYPE, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
                    .body(bytes);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
