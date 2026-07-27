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

        if (!isAdmin && !isPa && !isSpa) {
            if (!order.getClientId().equals(principal.getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied to upload documents to this order");
            }
        }

        if (file.getSize() > 20 * 1024 * 1024) {
            return ResponseEntity.badRequest().body("File size exceeds strict 20 MB limit");
        }

        String filename = file.getOriginalFilename();
        if (filename == null) {
            return ResponseEntity.badRequest().body("Filename is invalid");
        }

        try {
            User user = userRepository.findById(principal.getId()).orElseThrow(() -> new RuntimeException("User not found"));
            OrderDocument doc = new OrderDocument();
            doc.setOrder(order);
            doc.setCategory(category);
            doc.setFilename(filename);
            doc.setFileContent(file.getBytes());
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
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Error reading uploaded file: " + e.getMessage());
        }
    }

    @GetMapping("/documents/{documentId}/download")
    public ResponseEntity<?> downloadDocument(@PathVariable Long documentId) {
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

        if (!isAdmin && !isPa && !isSpa) {
            if (!order.getClientId().equals(principal.getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Access denied to this document");
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
