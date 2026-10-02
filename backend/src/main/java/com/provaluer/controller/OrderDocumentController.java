package com.provaluer.controller;

import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.AuditLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.*;

@RestController
@RequestMapping("/api/v1/orders")
public class OrderDocumentController {

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuditLogService auditLogService;

    @GetMapping("/{orderId}/documents")
    public ResponseEntity<?> getDocuments(@PathVariable Long orderId) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (!orderOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        boolean isPa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_PA"));
        boolean isSpa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SPA"));

        if (!isAdmin && !isPa && !isSpa) {
            if (!order.getClientId().equals(principal.getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied to this order's documents");
            }
        }

        List<OrderDocument> docs = orderDocumentRepository.findAllByOrderId(orderId);
        List<Map<String, Object>> response = new ArrayList<>();
        for (OrderDocument d : docs) {
            // Explicitly deny PA and SPA from viewing PAYMENT_PROOF documents
            if ("PAYMENT_PROOF".equalsIgnoreCase(d.getCategory()) && (isPa || isSpa) && !isAdmin) {
                continue;
            }
            Map<String, Object> map = new HashMap<>();
            map.put("id", d.getId());
            map.put("category", d.getCategory());
            map.put("filename", d.getFilename());
            map.put("uploadedBy", d.getUploadedBy().getEmail());
            map.put("createdAt", d.getCreatedAt());
            response.add(map);
        }
        return ResponseEntity.ok(response);
    }

    @Autowired
    private PerformanceLedgerRepository performanceLedgerRepository;

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(
            "pdf", "png", "jpg", "jpeg", "docx", "xlsx", "doc", "xls"
    );

    private static final Set<String> ALLOWED_PAYMENT_PROOF_EXTENSIONS = Set.of(
            "pdf", "png", "jpg", "jpeg"
    );

    private static final Set<String> REJECTED_EXTENSIONS = Set.of(
            "exe", "bat", "cmd", "com", "dll", "js", "ps1", "scr", "zip", "rar", "7z", "sh", "vbs", "msi"
    );

    private boolean isPdf(byte[] bytes) {
        if (bytes == null || bytes.length < 4) return false;
        return bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46; // %PDF
    }

    private boolean isPng(byte[] bytes) {
        if (bytes == null || bytes.length < 8) return false;
        return (bytes[0] & 0xFF) == 0x89 &&
                bytes[1] == 0x50 &&
                bytes[2] == 0x4E &&
                bytes[3] == 0x47 &&
                bytes[4] == 0x0D &&
                bytes[5] == 0x0A &&
                bytes[6] == 0x1A &&
                bytes[7] == 0x0A;
    }

    private boolean isJpeg(byte[] bytes) {
        if (bytes == null || bytes.length < 3) return false;
        return (bytes[0] & 0xFF) == 0xFF &&
                (bytes[1] & 0xFF) == 0xD8 &&
                (bytes[2] & 0xFF) == 0xFF;
    }

    private boolean isZipBasedOffice(byte[] bytes) {
        if (bytes == null || bytes.length < 4) return false;
        return bytes[0] == 0x50 && bytes[1] == 0x4B &&
                ((bytes[2] == 0x03 && bytes[3] == 0x04) ||
                 (bytes[2] == 0x05 && bytes[3] == 0x06) ||
                 (bytes[2] == 0x07 && bytes[3] == 0x08));
    }

    private boolean isOleOffice(byte[] bytes) {
        if (bytes == null || bytes.length < 4) return false;
        return (bytes[0] & 0xFF) == 0xD0 &&
                (bytes[1] & 0xFF) == 0xCF &&
                (bytes[2] & 0xFF) == 0x11 &&
                (bytes[3] & 0xFF) == 0xE0;
    }

    private boolean isExecutable(byte[] bytes) {
        if (bytes == null) return false;
        if (bytes.length >= 2 && bytes[0] == 0x4D && bytes[1] == 0x5A) {
            return true; // MZ header
        }
        if (bytes.length >= 4 && (bytes[0] & 0xFF) == 0x7F && bytes[1] == 0x45 && bytes[2] == 0x4C && bytes[3] == 0x46) {
            return true; // ELF header
        }
        return false;
    }

    @PostMapping("/{orderId}/documents/upload")
    public ResponseEntity<?> uploadDocument(@PathVariable Long orderId,
                                            @RequestParam("file") MultipartFile file,
                                            @RequestParam("category") String category) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (!orderOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        boolean isPa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_PA"));
        boolean isSpa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SPA"));

        if ("PAYMENT_PROOF".equalsIgnoreCase(category)) {
            if (isPa || isSpa || (!isAdmin && !order.getClientId().equals(principal.getId()))) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only the client owner or Admin can upload payment proof");
            }
            if (file.getSize() > 10 * 1024 * 1024) {
                return ResponseEntity.badRequest().body("Payment proof exceeds strict 10 MB limit");
            }
        } else {
            if (!isAdmin && !isPa && !isSpa) {
                if (!order.getClientId().equals(principal.getId())) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied to upload documents to this order");
                }
            }
            if (file.getSize() > 20 * 1024 * 1024) {
                return ResponseEntity.badRequest().body("File size exceeds strict 20 MB limit");
            }
        }

        String filename = file.getOriginalFilename();
        if (filename == null || filename.trim().isEmpty()) {
            return ResponseEntity.badRequest().body("Filename is invalid");
        }

        // FIX 2: Document Type Whitelist
        String ext = "";
        int dotIdx = filename.lastIndexOf('.');
        if (dotIdx >= 0 && dotIdx < filename.length() - 1) {
            ext = filename.substring(dotIdx + 1).toLowerCase(Locale.ROOT);
        }

        if ("PAYMENT_PROOF".equalsIgnoreCase(category)) {
            if (ext.isEmpty() || !ALLOWED_PAYMENT_PROOF_EXTENSIONS.contains(ext)) {
                return ResponseEntity.badRequest().body("Unsupported payment proof type: ." + ext + ". Allowed formats: PDF, PNG, JPG, JPEG");
            }
        } else {
            if (ext.isEmpty() || !ALLOWED_EXTENSIONS.contains(ext) || REJECTED_EXTENSIONS.contains(ext)) {
                return ResponseEntity.badRequest().body("Unsupported file type: ." + ext + ". Allowed formats: PDF, PNG, JPG, JPEG, DOCX, XLSX, DOC, XLS");
            }
        }

        // FIX 3: File Content Validation using Magic Bytes
        byte[] fileBytes;
        try {
            fileBytes = file.getBytes();
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error reading uploaded file: " + e.getMessage());
        }

        if (fileBytes == null || fileBytes.length < 4) {
            return ResponseEntity.badRequest().body("File is empty or too small to be valid");
        }

        if (isExecutable(fileBytes)) {
            return ResponseEntity.badRequest().body("Executable binary content detected. File rejected for security.");
        }

        boolean signatureMatches;
        switch (ext) {
            case "pdf":
                signatureMatches = isPdf(fileBytes);
                break;
            case "png":
                signatureMatches = isPng(fileBytes);
                break;
            case "jpg":
            case "jpeg":
                signatureMatches = isJpeg(fileBytes);
                break;
            case "docx":
            case "xlsx":
                signatureMatches = isZipBasedOffice(fileBytes);
                break;
            case "doc":
            case "xls":
                signatureMatches = isOleOffice(fileBytes);
                break;
            default:
                signatureMatches = false;
        }

        if (!signatureMatches) {
            return ResponseEntity.badRequest().body("File signature mismatch: Content does not match declared extension: ." + ext);
        }

        try {
            User user = userRepository.findById(principal.getId()).orElseThrow(() -> new RuntimeException("User not found"));
            OrderDocument doc = new OrderDocument();
            doc.setOrder(order);
            doc.setCategory(category);
            doc.setFilename(filename);
            doc.setFileContent(fileBytes);
            doc.setUploadedBy(user);

            OrderDocument saved = orderDocumentRepository.save(doc);

            // Transition to FINAL_DELIVERY if both corrected docx and signed pdf are uploaded
            if ("FINAL_DOCX".equalsIgnoreCase(category) || "FINAL_SIGNED_PDF".equalsIgnoreCase(category)) {
                List<OrderDocument> orderDocs = orderDocumentRepository.findAllByOrderId(orderId);
                boolean hasFinalDocx = orderDocs.stream().anyMatch(d -> "FINAL_DOCX".equalsIgnoreCase(d.getCategory()));
                boolean hasFinalSignedPdf = orderDocs.stream().anyMatch(d -> "FINAL_SIGNED_PDF".equalsIgnoreCase(d.getCategory()));
                
                if (hasFinalDocx && hasFinalSignedPdf) {
                    if ("SPA_CONFIRMED".equals(order.getStatus()) || "SPA_GATE".equals(order.getStatus())) {
                        order.setStatus("FINAL_DELIVERY");
                        
                        // Update Performance Ledger
                        if (order.getPaId() != null) {
                            performanceLedgerRepository.findById(order.getPaId()).ifPresent(ledger -> {
                                ledger.setActiveAllocations(Math.max(0, ledger.getActiveAllocations() - 1));
                                ledger.setFilesCompleted(ledger.getFilesCompleted() + 1);
                                performanceLedgerRepository.save(ledger);
                            });
                        }
                        orderRepository.save(order);
                    }
                }
            }

            auditLogService.log(principal.getId(), principal.getUsername(), principal.getAuthorities().iterator().next().getAuthority(),
                    "UPLOAD_DOCUMENT", "order_documents", saved.getId().toString(),
                    "Uploaded document '" + filename + "' for category '" + category + "' on Order #" + orderId);

            Map<String, Object> res = new HashMap<>();
            res.put("id", saved.getId());
            res.put("category", saved.getCategory());
            res.put("filename", saved.getFilename());
            res.put("uploadedBy", saved.getUploadedBy().getEmail());
            res.put("createdAt", saved.getCreatedAt());

            return ResponseEntity.ok(res);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error processing uploaded file: " + e.getMessage());
        }
    }

    @GetMapping({"/documents/{documentId}/download", "/{orderId}/documents/{documentId}/download"})
    public ResponseEntity<?> downloadDocument(@PathVariable(value = "orderId", required = false) Long orderId,
                                              @PathVariable("documentId") Long documentId) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Optional<OrderDocument> docOpt = orderDocumentRepository.findById(documentId);
        if (!docOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        OrderDocument doc = docOpt.get();
        Order order = doc.getOrder();

        boolean isAdmin = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        boolean isPa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_PA"));
        boolean isSpa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SPA"));

        if ("PAYMENT_PROOF".equalsIgnoreCase(doc.getCategory())) {
            // Explicitly deny PA and SPA. Allow only client owner or Admin/SuperAdmin.
            if (!isAdmin && !order.getClientId().equals(principal.getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied to payment proof document");
            }
        } else {
            if (!isAdmin && !isPa && !isSpa) {
                if (!order.getClientId().equals(principal.getId())) {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied to this document");
                }
            }
        }

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + doc.getFilename() + "\"")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(doc.getFileContent());
    }

    @DeleteMapping("/documents/{documentId}")
    public ResponseEntity<?> deleteDocument(@PathVariable Long documentId) {
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Optional<OrderDocument> docOpt = orderDocumentRepository.findById(documentId);
        if (!docOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        OrderDocument doc = docOpt.get();

        boolean isAdmin = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        if (!isAdmin) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only administrators can delete uploaded documents");
        }

        orderDocumentRepository.delete(doc);

        auditLogService.log(principal.getId(), principal.getUsername(), principal.getAuthorities().iterator().next().getAuthority(),
                "DELETE_DOCUMENT", "order_documents", documentId.toString(),
                "Deleted document '" + doc.getFilename() + "' for category '" + doc.getCategory() + "' on Order #" + doc.getOrder().getId());

        return ResponseEntity.ok("Document deleted successfully");
    }
}
