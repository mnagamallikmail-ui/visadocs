package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.*;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.encryption.AccessPermission;
import org.apache.pdfbox.pdmodel.encryption.StandardProtectionPolicy;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.util.Matrix;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@Transactional
public class DeliveryService {

    private static final Logger log = LoggerFactory.getLogger(DeliveryService.class);

    @Autowired private OrderRepository orderRepository;
    @Autowired private ValuationSnapshotRepository valuationSnapshotRepository;
    @Autowired private OrderInvoiceRepository orderInvoiceRepository;
    @Autowired private OrderAcknowledgementRepository orderAcknowledgementRepository;
    @Autowired private DeliveryTokenRepository deliveryTokenRepository;
    @Autowired private DeliveryAccessLogRepository deliveryAccessLogRepository;
    @Autowired private RevenueLedgerRepository revenueLedgerRepository;
    @Autowired private DeliveryPackageRepository deliveryPackageRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private AuditLogRepository auditLogRepository;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private TelegramNotificationService telegramNotificationService;

    /**
     * SPRINT 8: Delivery Gate Evaluation (SNAPSHOT_CREATED → DELIVERY_READY)
     */
    public Map<String, Object> evaluateGate(Long orderId, EvaluateGateRequest request, UserDetailsImpl principal, String clientIp) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order #" + orderId + " not found"));

        // Check archival lock
        assertNotArchivalLocked(order);

        // Order must be in SNAPSHOT_CREATED or SPA_CONFIRMED with snapshot
        String currentStatus = order.getStatus();
        if (!"SNAPSHOT_CREATED".equalsIgnoreCase(currentStatus) && !"SPA_CONFIRMED".equalsIgnoreCase(currentStatus) && !"DELIVERY_READY".equalsIgnoreCase(currentStatus)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Order #" + orderId + " is in status '" + currentStatus + "'. It must be in SNAPSHOT_CREATED or SPA_CONFIRMED to evaluate delivery gate.");
        }

        // 1. Snapshot Exists Check
        boolean snapshotExists = valuationSnapshotRepository.existsByOrderId(orderId);
        if (!snapshotExists) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "Delivery Gate Failed: No immutable ValuationSnapshot found for order #" + orderId);
        }

        // 2. Snapshot Hash Integrity Check
        ValuationSnapshot latestSnapshot = valuationSnapshotRepository.findFirstByOrderIdOrderByVersionNumberDesc(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "ValuationSnapshot record missing"));
        if (latestSnapshot.getSnapshotHash() == null || latestSnapshot.getSnapshotHash().isBlank()
                || latestSnapshot.getDocumentHash() == null || latestSnapshot.getDocumentHash().isBlank()) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "Delivery Gate Failed: Snapshot cryptographic hash integrity verification failed.");
        }

        // 3. Commercial Clearance Check
        boolean commercialCleared = false;
        String clearanceReason = "";

        if (request != null && request.isAdminOverride()) {
            boolean isAdmin = principal != null && principal.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
            if (!isAdmin) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Only SUPER_ADMIN may authorize commercial clearance override.");
            }
            commercialCleared = true;
            clearanceReason = "Super Admin Commercial Override: " + (request.getOverrideReason() != null ? request.getOverrideReason() : "Authorized");
            order.setCommercialOverrideNotes(clearanceReason);
        } else if ((request != null && Boolean.TRUE.equals(request.getCorporateCreditActive())) || order.isCorporateCreditActive()) {
            commercialCleared = true;
            order.setCorporateCreditActive(true);
            clearanceReason = "Corporate Credit Facility Active";
        } else {
            BigDecimal balance = order.getBalanceDue();
            boolean isPaid = "VERIFIED".equalsIgnoreCase(order.getPaymentStatus());
            if (isPaid || balance == null || balance.compareTo(BigDecimal.ZERO) <= 0) {
                commercialCleared = true;
                clearanceReason = "Payment verified with zero balance due";
            }
        }

        Map<String, Object> resp = new HashMap<>();
        resp.put("orderId", orderId);
        resp.put("referenceCode", order.getReferenceCode());

        if (!commercialCleared) {
            order.setStatus("ON_HOLD_PAYMENT_PENDING");
            orderRepository.save(order);

            logAudit(principal, "COMMERCIAL_GATE_FAILED", "Order", String.valueOf(orderId), currentStatus, "ON_HOLD_PAYMENT_PENDING",
                    "Commercial clearance failed. Outstanding balance due: " + order.getBalanceDue(), clientIp);

            resp.put("status", "ON_HOLD_PAYMENT_PENDING");
            resp.put("passed", false);
            resp.put("message", "Commercial Clearance Failed: Outstanding balance due. Order placed on ON_HOLD_PAYMENT_PENDING.");
            resp.put("balanceDue", order.getBalanceDue());
            return resp;
        }

        order.setStatus("DELIVERY_READY");
        orderRepository.save(order);

        logAudit(principal, "COMMERCIAL_GATE_PASSED", "Order", String.valueOf(orderId), currentStatus, "DELIVERY_READY",
                "Commercial clearance passed. Reason: " + clearanceReason, clientIp);

        resp.put("status", "DELIVERY_READY");
        resp.put("passed", true);
        resp.put("clearanceReason", clearanceReason);
        return resp;
    }

    /**
     * SPRINT 8: Delivery Release (DELIVERY_READY → FINAL_DELIVERY)
     */
    public Map<String, Object> releaseOrder(Long orderId, ReleaseOrderRequest request, UserDetailsImpl principal, String clientIp) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order #" + orderId + " not found"));

        assertNotArchivalLocked(order);

        if (!"DELIVERY_READY".equalsIgnoreCase(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Order #" + orderId + " is in status '" + order.getStatus() + "'. It must be in DELIVERY_READY to release.");
        }

        ValuationSnapshot snapshot = valuationSnapshotRepository.findFirstByOrderIdOrderByVersionNumberDesc(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "ValuationSnapshot not found"));

        User client = userRepository.findById(order.getClientId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Client user not found"));

        // 1. Generate Tax Invoice (INV-YYYY-NNNNN)
        OrderInvoice invoice = generateTaxInvoice(order, client, request, principal != null ? principal.getUsername() : "SYSTEM");

        // 2. Generate Encrypted PDF with AES-256 and Watermark
        byte[] encryptedPdf = compileEncryptedPdf(order, client, snapshot);
        String encryptedPdfHash = computeSha256Hex(encryptedPdf);

        // 3. Generate Manifest JSON
        Map<String, Object> manifest = new HashMap<>();
        manifest.put("orderId", order.getId());
        manifest.put("referenceCode", order.getReferenceCode());
        manifest.put("clientName", order.getClientName());
        manifest.put("snapshotVersion", snapshot.getVersionNumber());
        manifest.put("documentHash", snapshot.getDocumentHash());
        manifest.put("encryptedPdfHash", encryptedPdfHash);
        manifest.put("invoiceNumber", invoice.getInvoiceNumber());
        manifest.put("invoiceHash", invoice.getInvoiceHash());
        manifest.put("releasedAt", LocalDateTime.now().toString());

        String manifestJson = "";
        try {
            manifestJson = objectMapper.writeValueAsString(manifest);
        } catch (Exception e) {
            manifestJson = "{}";
        }

        // 4. Save DeliveryPackage
        DeliveryPackage deliveryPackage = deliveryPackageRepository.findByOrderId(orderId)
                .orElseGet(() -> {
                    DeliveryPackage dp = new DeliveryPackage();
                    dp.setOrderId(orderId);
                    return dp;
                });
        deliveryPackage.setEncryptedPdfContent(encryptedPdf);
        deliveryPackage.setEncryptedPdfHash(encryptedPdfHash);
        deliveryPackage.setManifestJson(manifestJson);
        deliveryPackageRepository.save(deliveryPackage);

        // 5. Update Order Status to FINAL_DELIVERY
        order.setStatus("FINAL_DELIVERY");
        order.setDeliveredAt(LocalDateTime.now());
        orderRepository.save(order);

        // 6. Audit Trail Logging
        logAudit(principal, "INVOICE_GENERATED", "OrderInvoice", invoice.getInvoiceNumber(), null, "ISSUED",
                "Tax invoice generated: " + invoice.getInvoiceNumber() + ", Total: " + invoice.getGrandTotal(), clientIp);
        logAudit(principal, "DELIVERY_PACKAGE_SEALED", "DeliveryPackage", String.valueOf(deliveryPackage.getId()), null, "SEALED",
                "Encrypted PDF (AES-256) sealed with hash: " + encryptedPdfHash, clientIp);
        logAudit(principal, "DELIVERY_RELEASED", "Order", String.valueOf(orderId), "DELIVERY_READY", "FINAL_DELIVERY",
                "Report released for client download portal access.", clientIp);

        // 7. Dispatch Notification
        try {
            telegramNotificationService.sendDeliveryNotification(order.getReferenceCode(), order.getClientName(), invoice.getInvoiceNumber());
        } catch (Exception e) {
            log.warn("Telegram notification failed for delivery release: {}", e.getMessage());
        }

        Map<String, Object> resp = new HashMap<>();
        resp.put("orderId", orderId);
        resp.put("status", "FINAL_DELIVERY");
        resp.put("invoiceNumber", invoice.getInvoiceNumber());
        resp.put("encryptedPdfHash", encryptedPdfHash);
        resp.put("deliveredAt", order.getDeliveredAt());
        return resp;
    }

    /**
     * SPRINT 8: Client Portal View (GET /client/delivery/orders/{refCode})
     */
    @Transactional(readOnly = true)
    public ClientDeliverableResponse getClientDeliverable(String refCode, UserDetailsImpl principal) {
        Order order = findOrderByRefOrId(refCode);

        // Security: Clients may only view their own order
        if (principal != null) {
            boolean isClient = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_CLIENT"));
            if (isClient && !order.getClientId().equals(principal.getId())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access Denied: You do not own this valuation report.");
            }
        }

        ClientDeliverableResponse resp = new ClientDeliverableResponse();
        resp.setOrderId(order.getId());
        resp.setReferenceCode(order.getReferenceCode());
        resp.setClientName(order.getClientName());
        resp.setPropertyCategory(order.getPropertyCategory());
        resp.setStatus(order.getStatus());
        resp.setFinalValue(order.getFinalValue());
        resp.setFeeCharged(order.getFeeCharged());
        resp.setBalanceDue(order.getBalanceDue());
        resp.setDelivered(order.getDeliveredAt() != null);
        resp.setDeliveredAt(order.getDeliveredAt());
        resp.setDownloaded(order.getDownloadedAt() != null);
        resp.setDownloadedAt(order.getDownloadedAt());
        resp.setDisputed("DELIVERY_DISPUTED".equalsIgnoreCase(order.getStatus()));
        resp.setClosed("CLOSED".equalsIgnoreCase(order.getStatus()));
        resp.setClosedAt(order.getClosedAt());

        // Masked Password Hint
        User clientUser = userRepository.findById(order.getClientId()).orElse(null);
        String mobile = clientUser != null ? clientUser.getMobileNumber() : null;
        if (mobile != null && mobile.length() >= 4) {
            resp.setPasswordHint("Registered mobile number ending in ****" + mobile.substring(mobile.length() - 4));
        } else {
            resp.setPasswordHint("Registered 10-digit mobile number");
        }

        // Available Files
        List<String> files = new ArrayList<>();
        if (deliveryPackageRepository.existsByOrderId(order.getId())) {
            files.add("REPORT_PDF");
            files.add("MANIFEST");
        }
        if (orderInvoiceRepository.existsByOrderId(order.getId())) {
            files.add("INVOICE_PDF");
        }
        resp.setAvailableFiles(files);

        // Invoice Summary
        orderInvoiceRepository.findByOrderId(order.getId()).ifPresent(inv -> {
            resp.setInvoice(new ClientDeliverableResponse.InvoiceSummaryDto(
                    inv.getInvoiceNumber(), inv.getInvoiceDate(), inv.getGrandTotal(),
                    inv.getAmountPaid(), inv.getBalanceDue(), inv.getStatus()
            ));
        });

        // Acknowledgements History
        List<OrderAcknowledgement> acks = orderAcknowledgementRepository.findByOrderIdOrderByCreatedAtDesc(order.getId());
        List<ClientDeliverableResponse.AcknowledgementSummaryDto> ackDtos = new ArrayList<>();
        for (OrderAcknowledgement ack : acks) {
            ackDtos.add(new ClientDeliverableResponse.AcknowledgementSummaryDto(
                    ack.getAction(), ack.getActorRole(), ack.getCreatedAt(), ack.getClarificationNotes() != null ? ack.getClarificationNotes() : ack.getAcceptanceDeclaration()
            ));
        }
        resp.setAcknowledgements(ackDtos);

        return resp;
    }

    /**
     * SPRINT 8: Generate Single-Use Ephemeral Download Token (POST /client/delivery/orders/{refCode}/generate-token)
     */
    public Map<String, Object> generateDownloadToken(String refCode, GenerateTokenRequest req, UserDetailsImpl principal, String clientIp, String userAgent) {
        Order order = findOrderByRefOrId(refCode);

        // Security Matrix: PA & SPA have NO download access
        if (principal != null) {
            boolean isPa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_PA"));
            boolean isSpa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SPA"));
            if (isPa || isSpa) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access Denied: PA and SPA personnel are strictly prohibited from downloading client report packages.");
            }
            boolean isClient = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_CLIENT"));
            if (isClient && !order.getClientId().equals(principal.getId())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access Denied: You do not own this order.");
            }
        }

        String fileType = req != null && req.getFileType() != null ? req.getFileType() : "REPORT_PDF";

        // Generate HMAC-signed or secure token (15 min TTL)
        String rawToken = UUID.randomUUID().toString().replace("-", "") + Long.toHexString(System.currentTimeMillis());
        DeliveryToken token = new DeliveryToken();
        token.setToken(rawToken);
        token.setOrderId(order.getId());
        token.setClientId(principal != null ? principal.getId() : order.getClientId());
        token.setFileType(fileType);
        token.setClientIp(clientIp);
        token.setUserAgent(userAgent);
        token.setExpiresAt(LocalDateTime.now().plusMinutes(15));
        token.setConsumed(false);
        deliveryTokenRepository.save(token);

        logAudit(principal, "DOWNLOAD_TOKEN_ISSUED", "DeliveryToken", rawToken, null, "ACTIVE",
                "Single-use download token generated for fileType: " + fileType + ", expires in 15 mins", clientIp);

        Map<String, Object> resp = new HashMap<>();
        resp.put("token", rawToken);
        resp.put("fileType", fileType);
        resp.put("expiresAt", token.getExpiresAt());
        resp.put("streamUrl", "/api/v1/client/delivery/stream?token=" + rawToken);
        return resp;
    }

    /**
     * SPRINT 8: Stream Deliverable via Single-Use Token (GET /client/delivery/stream?token=...)
     */
    public StreamResult streamDeliverable(String tokenStr, String clientIp, String userAgent) {
        DeliveryToken token = deliveryTokenRepository.findByToken(tokenStr)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid or unrecognized download token"));

        if (token.isConsumed()) {
            throw new ResponseStatusException(HttpStatus.GONE, "Download token has already been consumed (Single-use policy violated)");
        }

        if (LocalDateTime.now().isAfter(token.getExpiresAt())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Download token has expired (15-minute TTL elapsed)");
        }

        // Consume token immediately
        token.setConsumed(true);
        token.setConsumedAt(LocalDateTime.now());
        deliveryTokenRepository.save(token);

        Order order = orderRepository.findById(token.getOrderId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found"));

        logAudit(null, "DOWNLOAD_STARTED", "Order", String.valueOf(order.getId()), null, "STREAMING",
                "Client download initiated for " + token.getFileType(), clientIp);

        deliveryAccessLogRepository.save(new DeliveryAccessLog(
                order.getId(),
                "STREAM_" + token.getFileType(),
                token.getClientId(),
                "CLIENT",
                clientIp,
                userAgent,
                "Streamed deliverable: " + token.getFileType() + " using token " + token.getId()
        ));

        if ("INVOICE_PDF".equalsIgnoreCase(token.getFileType())) {
            OrderInvoice inv = orderInvoiceRepository.findByOrderId(order.getId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invoice not found for order"));
            logAudit(null, "INVOICE_DOWNLOADED", "OrderInvoice", inv.getInvoiceNumber(), null, "DOWNLOADED",
                    "Tax invoice downloaded: " + inv.getInvoiceNumber(), clientIp);
            return new StreamResult(inv.getInvoicePdfContent(), "Invoice_" + inv.getInvoiceNumber() + ".pdf", "application/pdf");
        } else if ("MANIFEST".equalsIgnoreCase(token.getFileType())) {
            DeliveryPackage pkg = deliveryPackageRepository.findByOrderId(order.getId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Delivery package not found"));
            byte[] manifestBytes = pkg.getManifestJson() != null ? pkg.getManifestJson().getBytes(StandardCharsets.UTF_8) : "{}".getBytes(StandardCharsets.UTF_8);
            return new StreamResult(manifestBytes, "Integrity_Manifest_" + order.getReferenceCode() + ".json", "application/json");
        } else {
            // REPORT_PDF
            DeliveryPackage pkg = deliveryPackageRepository.findByOrderId(order.getId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Delivery package not found"));

            // Advance state: FINAL_DELIVERY → CLIENT_DOWNLOADED
            if ("FINAL_DELIVERY".equalsIgnoreCase(order.getStatus())) {
                order.setStatus("CLIENT_DOWNLOADED");
                order.setDownloadedAt(LocalDateTime.now());
                orderRepository.save(order);
            }

            // Record acknowledgement entry
            OrderAcknowledgement ack = new OrderAcknowledgement();
            ack.setOrderId(order.getId());
            ack.setAction("DOWNLOADED");
            ack.setActorId(token.getClientId());
            ack.setActorRole("CLIENT");
            ack.setClientIp(clientIp);
            ack.setUserAgent(userAgent);
            orderAcknowledgementRepository.save(ack);

            logAudit(null, "DOWNLOAD_COMPLETED", "Order", String.valueOf(order.getId()), "FINAL_DELIVERY", "CLIENT_DOWNLOADED",
                    "Valuation Report PDF successfully streamed to client.", clientIp);

            return new StreamResult(pkg.getEncryptedPdfContent(), "Valuation_Report_" + order.getReferenceCode() + "_Secured.pdf", "application/pdf");
        }
    }

    /**
     * SPRINT 8: Client Acknowledgement & Acceptance (POST /client/delivery/orders/{refCode}/acknowledge)
     */
    public Map<String, Object> acknowledgeDelivery(String refCode, AcknowledgeDeliveryRequest req, UserDetailsImpl principal, String clientIp, String userAgent) {
        Order order = findOrderByRefOrId(refCode);

        assertNotArchivalLocked(order);

        if (principal != null) {
            boolean isClient = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_CLIENT"));
            if (isClient && !order.getClientId().equals(principal.getId())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access Denied: You do not own this order.");
            }
        }

        String action = req != null && req.getAction() != null ? req.getAction().toUpperCase() : "VIEWED";

        OrderAcknowledgement ack = new OrderAcknowledgement();
        ack.setOrderId(order.getId());
        ack.setAction(action);
        ack.setActorId(principal != null ? principal.getId() : order.getClientId());
        ack.setActorRole(principal != null ? principal.getAuthorities().iterator().next().getAuthority().replace("ROLE_", "") : "CLIENT");
        ack.setClientIp(clientIp);
        ack.setUserAgent(userAgent);
        ack.setClarificationType(req != null ? req.getClarificationType() : null);
        ack.setClarificationNotes(req != null ? req.getClarificationNotes() : null);
        ack.setAcceptanceDeclaration(req != null ? req.getAcceptanceDeclaration() : null);
        orderAcknowledgementRepository.save(ack);

        if ("CLARIFICATION_REQUESTED".equals(action)) {
            order.setStatus("DELIVERY_DISPUTED");
            orderRepository.save(order);

            String clarificationType = req != null && req.getClarificationType() != null ? req.getClarificationType() : "GENERAL";
            String clarificationNotes = req != null && req.getClarificationNotes() != null ? req.getClarificationNotes() : "Client requested clarification";
            logAudit(principal, "CLARIFICATION_REQUESTED", "Order", String.valueOf(order.getId()), "CLIENT_DOWNLOADED", "DELIVERY_DISPUTED",
                    "Client filed clarification request: " + clarificationType + " - " + clarificationNotes, clientIp);
        } else if ("ACCEPTED".equals(action) || "AUTO_ACCEPTED".equals(action)) {
            logAudit(principal, "ACKNOWLEDGEMENT_SUBMITTED", "Order", String.valueOf(order.getId()), order.getStatus(), "ACCEPTED",
                    "Client formally accepted the valuation deliverable.", clientIp);

            // Trigger Revenue Recognition under Ind AS 115 / IFRS 15
            recognizeRevenue(order, principal != null ? principal.getUsername() : "SYSTEM");
        }

        Map<String, Object> resp = new HashMap<>();
        resp.put("orderId", order.getId());
        resp.put("referenceCode", order.getReferenceCode());
        resp.put("status", order.getStatus());
        resp.put("acknowledgedAction", action);
        resp.put("revenueRecognized", order.isRevenueRecognized());
        return resp;
    }

    /**
     * SPRINT 8: Project Closure & 10-Year Archival Lock (POST /delivery/orders/{id}/close)
     */
    public Map<String, Object> closeOrder(Long orderId, CloseOrderRequest req, UserDetailsImpl principal, String clientIp) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order #" + orderId + " not found"));

        assertNotArchivalLocked(order);

        boolean force = req != null && req.isForceClose();

        if (!force) {
            // Pre-condition 1: Must not be disputed
            if ("DELIVERY_DISPUTED".equalsIgnoreCase(order.getStatus())) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Order #" + orderId + " cannot be closed: Open client clarification/dispute pending.");
            }

            // Pre-condition 2: Must be acknowledged (ACCEPTED or AUTO_ACCEPTED)
            boolean isAccepted = orderAcknowledgementRepository.existsByOrderIdAndAction(orderId, "ACCEPTED")
                    || orderAcknowledgementRepository.existsByOrderIdAndAction(orderId, "AUTO_ACCEPTED");
            if (!isAccepted) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Order #" + orderId + " cannot be closed: Client has not yet accepted the deliverable.");
            }

            // Pre-condition 3: Zero Balance Due
            if (order.getBalanceDue() != null && order.getBalanceDue().compareTo(BigDecimal.ZERO) > 0 && !order.isCorporateCreditActive()) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Order #" + orderId + " cannot be closed: Outstanding balance due of " + order.getBalanceDue());
            }

            // Pre-condition 4: Revenue Recognized
            if (!order.isRevenueRecognized()) {
                recognizeRevenue(order, principal != null ? principal.getUsername() : "SYSTEM");
            }
        }

        // Apply Closure and 10-Year Archival Lock
        order.setStatus("CLOSED");
        order.setArchivalLocked(true);
        order.setClosedAt(LocalDateTime.now());
        orderRepository.save(order);

        logAudit(principal, "ORDER_CLOSED", "Order", String.valueOf(orderId), "CLIENT_DOWNLOADED", "CLOSED",
                "Order formally closed and placed under permanent 10-year statutory archival lock.", clientIp);

        Map<String, Object> resp = new HashMap<>();
        resp.put("orderId", orderId);
        resp.put("status", "CLOSED");
        resp.put("archivalLocked", true);
        resp.put("closedAt", order.getClosedAt());
        resp.put("message", "Order #" + orderId + " is now permanently CLOSED and locked for 10-year statutory retention.");
        return resp;
    }

    /**
     * SPRINT 8: Revenue Recognition Engine (Ind AS 115 / IFRS 15)
     */
    private void recognizeRevenue(Order order, String postedBy) {
        if (order.isRevenueRecognized()) {
            return;
        }

        OrderInvoice invoice = orderInvoiceRepository.findByOrderId(order.getId()).orElse(null);
        BigDecimal base = invoice != null ? invoice.getBaseAmount() : (order.getQuoteAmount() != null ? order.getQuoteAmount() : BigDecimal.valueOf(50000));
        BigDecimal total = invoice != null ? invoice.getGrandTotal() : (order.getQuoteTotal() != null ? order.getQuoteTotal() : base);
        BigDecimal tax = invoice != null ? invoice.getTotalTax() : (order.getQuoteTax() != null ? order.getQuoteTax() : BigDecimal.ZERO);

        // 1. Advance Liability Reversal
        revenueLedgerRepository.save(new RevenueLedger(
                order.getId(),
                "ADVANCE_REVERSAL",
                "Customer Advances / Unearned Revenue",
                total,
                BigDecimal.ZERO,
                "IND_AS_115",
                "Transfer of performance obligation to client upon acceptance",
                postedBy
        ));

        // 2. Service Revenue Recognition
        revenueLedgerRepository.save(new RevenueLedger(
                order.getId(),
                "REVENUE_RECOGNITION",
                "Valuation & Advisory Consulting Revenue",
                BigDecimal.ZERO,
                base,
                "IND_AS_115",
                "Earned revenue recognized for order #" + order.getId(),
                postedBy
        ));

        // 3. GST Payable Posting
        if (tax.compareTo(BigDecimal.ZERO) > 0) {
            revenueLedgerRepository.save(new RevenueLedger(
                    order.getId(),
                    "GST_PAYABLE",
                    invoice != null && invoice.isInterState() ? "Output IGST Payable" : "Output CGST / SGST Payable",
                    BigDecimal.ZERO,
                    tax,
                    "IND_AS_115",
                    "Statutory GST liability booked for invoice " + (invoice != null ? invoice.getInvoiceNumber() : ""),
                    postedBy
            ));
        }

        order.setRevenueRecognized(true);
        order.setRevenueRecognizedAt(LocalDateTime.now());
        orderRepository.save(order);

        logAudit(null, "REVENUE_RECOGNIZED", "RevenueLedger", String.valueOf(order.getId()), null, "POSTED",
                "Revenue recognized under Ind AS 115: Base ₹" + base + ", Tax ₹" + tax, "127.0.0.1");
    }

    /**
     * Helper: Generate Statutory GST Tax Invoice (INV-YYYY-NNNNN)
     */
    private OrderInvoice generateTaxInvoice(Order order, User client, ReleaseOrderRequest request, String createdBy) {
        return orderInvoiceRepository.findByOrderId(order.getId()).orElseGet(() -> {
            OrderInvoice inv = new OrderInvoice();
            inv.setOrderId(order.getId());

            int year = LocalDate.now().getYear();
            long count = orderInvoiceRepository.count() + 1;
            String invNumber = String.format("INV-%d-%05d", year, count);
            inv.setInvoiceNumber(invNumber);
            inv.setFinancialYear(year + "-" + (year + 1));
            inv.setInvoiceDate(LocalDate.now());
            inv.setDueDate(LocalDate.now().plusDays(15));

            inv.setClientName(order.getClientName() != null ? order.getClientName() : client.getFullName());
            inv.setClientAddress(order.getBranchName() != null ? order.getBranchName() : "Client Corporate Office");
            inv.setClientGstin("27AAACB1234D1Z5");
            inv.setClientPan("AAACB1234D");
            inv.setPlaceOfSupply("Maharashtra");

            String clientState = request != null && request.getClientStateCode() != null ? request.getClientStateCode() : "27";
            inv.setStateCode(clientState);

            inv.setFirmName("ProValuer Commercial Advisory Services Pvt Ltd");
            inv.setFirmAddress("Level 5, Express Towers, Nariman Point, Mumbai - 400021");
            inv.setFirmGstin("27AAACP0123A1Z5");
            inv.setFirmPan("AAACP0123A");
            inv.setSacCode("998311");

            BigDecimal base = order.getQuoteAmount() != null && order.getQuoteAmount().compareTo(BigDecimal.ZERO) > 0
                    ? order.getQuoteAmount()
                    : (order.getFeeCharged() != null && order.getFeeCharged().compareTo(BigDecimal.ZERO) > 0
                    ? order.getFeeCharged()
                    : BigDecimal.valueOf(50000.00));
            inv.setBaseAmount(base);

            boolean interState = !"27".equals(clientState);
            inv.setInterState(interState);

            if (interState) {
                inv.setIgstRate(BigDecimal.valueOf(18.00));
                inv.setIgstAmount(base.multiply(BigDecimal.valueOf(0.18)).setScale(2, RoundingMode.HALF_UP));
                inv.setTotalTax(inv.getIgstAmount());
            } else {
                inv.setCgstRate(BigDecimal.valueOf(9.00));
                inv.setCgstAmount(base.multiply(BigDecimal.valueOf(0.09)).setScale(2, RoundingMode.HALF_UP));
                inv.setSgstRate(BigDecimal.valueOf(9.00));
                inv.setSgstAmount(base.multiply(BigDecimal.valueOf(0.09)).setScale(2, RoundingMode.HALF_UP));
                inv.setTotalTax(inv.getCgstAmount().add(inv.getSgstAmount()));
            }

            BigDecimal grandTotal = base.add(inv.getTotalTax());
            inv.setGrandTotal(grandTotal);

            BigDecimal paid = order.getFeeCharged() != null ? order.getFeeCharged() : grandTotal;
            inv.setAmountPaid(paid);
            inv.setBalanceDue(grandTotal.subtract(paid).max(BigDecimal.ZERO));

            // Generate clean Invoice PDF
            byte[] invoicePdf = renderInvoicePdf(inv, order);
            inv.setInvoicePdfContent(invoicePdf);
            inv.setInvoiceHash(computeSha256Hex(invoicePdf));
            inv.setStatus("ISSUED");
            inv.setCreatedBy(createdBy);

            return orderInvoiceRepository.save(inv);
        });
    }

    /**
     * Helper: Compile Watermarked & AES-256 Encrypted PDF
     */
    private byte[] compileEncryptedPdf(Order order, User client, ValuationSnapshot snapshot) {
        byte[] sourcePdf = snapshot.getPdfContent();
        if (sourcePdf == null || sourcePdf.length == 0) {
            sourcePdf = renderFallbackReportPdf(order);
        }

        try (PDDocument doc = org.apache.pdfbox.Loader.loadPDF(sourcePdf)) {
            String clientName = order.getClientName() != null ? order.getClientName() : client.getFullName();
            String refCode = order.getReferenceCode() != null ? order.getReferenceCode() : ("ORDER-" + order.getId());
            String dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("dd-MMM-yyyy"));
            String watermarkText = "CONFIDENTIAL - " + clientName + " - " + refCode + " - " + dateStr;
            String footerText = "SHA-256 Stamp: " + (snapshot.getDocumentHash() != null ? snapshot.getDocumentHash() : computeSha256Hex(sourcePdf)) + " | Single Client License";

            // Watermark all pages
            for (PDPage page : doc.getPages()) {
                PDRectangle box = page.getMediaBox();
                try (PDPageContentStream cs = new PDPageContentStream(doc, page, PDPageContentStream.AppendMode.APPEND, true, true)) {
                    cs.beginText();
                    cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 22);
                    cs.setNonStrokingColor(0.85f, 0.85f, 0.85f);
                    Matrix matrix = Matrix.getRotateInstance(Math.toRadians(45), box.getWidth() / 4, box.getHeight() / 3);
                    cs.setTextMatrix(matrix);
                    cs.showText(watermarkText);
                    cs.endText();

                    cs.beginText();
                    cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 8);
                    cs.setNonStrokingColor(0.5f, 0.5f, 0.5f);
                    cs.newLineAtOffset(36, 18);
                    cs.showText(footerText);
                    cs.endText();
                }
            }

            // Client mobile number as user password
            String userPassword = client.getMobileNumber() != null && !client.getMobileNumber().isBlank()
                    ? client.getMobileNumber().trim()
                    : "9820012345";
            String ownerPassword = UUID.randomUUID().toString();

            AccessPermission ap = new AccessPermission();
            ap.setCanModify(false);
            ap.setCanExtractContent(false);
            ap.setCanAssembleDocument(false);
            ap.setCanPrint(true);

            StandardProtectionPolicy spp = new StandardProtectionPolicy(ownerPassword, userPassword, ap);
            spp.setEncryptionKeyLength(256);
            spp.setPermissions(ap);
            doc.protect(spp);

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            doc.save(baos);
            return baos.toByteArray();
        } catch (Exception e) {
            log.error("Failed to encrypt and watermark PDF for order #{}: {}", order.getId(), e.getMessage(), e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "PDF Encryption failed: " + e.getMessage());
        }
    }

    /**
     * Helper: Render Professional PDF Tax Invoice via PDFBox
     */
    private byte[] renderInvoicePdf(OrderInvoice inv, Order order) {
        try (PDDocument doc = new PDDocument()) {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);

            try (PDPageContentStream cs = new PDPageContentStream(doc, page)) {
                // Header
                cs.beginText();
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 20);
                cs.newLineAtOffset(50, 780);
                cs.showText("TAX INVOICE");
                cs.endText();

                cs.beginText();
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 12);
                cs.newLineAtOffset(50, 755);
                cs.showText(inv.getFirmName());
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
                cs.newLineAtOffset(0, -15);
                cs.showText(inv.getFirmAddress());
                cs.newLineAtOffset(0, -15);
                cs.showText("GSTIN: " + inv.getFirmGstin() + "  |  PAN: " + inv.getFirmPan());
                cs.endText();

                // Invoice metadata
                cs.beginText();
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 10);
                cs.newLineAtOffset(380, 755);
                cs.showText("Invoice No: " + inv.getInvoiceNumber());
                cs.newLineAtOffset(0, -15);
                cs.showText("Date: " + inv.getInvoiceDate());
                cs.newLineAtOffset(0, -15);
                cs.showText("Order Ref: " + order.getReferenceCode());
                cs.newLineAtOffset(0, -15);
                cs.showText("Due Date: " + inv.getDueDate());
                cs.endText();

                // Bill To
                cs.beginText();
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 11);
                cs.newLineAtOffset(50, 670);
                cs.showText("Billed To:");
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
                cs.newLineAtOffset(0, -15);
                cs.showText(inv.getClientName());
                cs.newLineAtOffset(0, -15);
                cs.showText(inv.getClientAddress());
                cs.newLineAtOffset(0, -15);
                cs.showText("GSTIN: " + inv.getClientGstin() + "  |  Place of Supply: " + inv.getPlaceOfSupply());
                cs.endText();

                // Table Header
                cs.beginText();
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 10);
                cs.newLineAtOffset(50, 580);
                cs.showText("Description                                       SAC Code       Taxable Amt");
                cs.endText();

                // Line Item
                cs.beginText();
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
                cs.newLineAtOffset(50, 555);
                cs.showText("Commercial Property Valuation Services              " + inv.getSacCode() + "          INR " + inv.getBaseAmount());
                cs.endText();

                // Tax breakdown
                cs.beginText();
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
                cs.newLineAtOffset(320, 510);
                if (inv.isInterState()) {
                    cs.showText("IGST (18%):            INR " + inv.getIgstAmount());
                } else {
                    cs.showText("CGST (9%):             INR " + inv.getCgstAmount());
                    cs.newLineAtOffset(0, -15);
                    cs.showText("SGST (9%):             INR " + inv.getSgstAmount());
                }
                cs.newLineAtOffset(0, -20);
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 11);
                cs.showText("Grand Total:          INR " + inv.getGrandTotal());
                cs.newLineAtOffset(0, -18);
                cs.showText("Amount Paid:          INR " + inv.getAmountPaid());
                cs.newLineAtOffset(0, -18);
                cs.showText("Balance Due:          INR " + inv.getBalanceDue());
                cs.endText();

                // Footer
                cs.beginText();
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 9);
                cs.newLineAtOffset(50, 60);
                cs.showText("This is a computer generated tax invoice and does not require a physical signature.");
                cs.endText();
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            doc.save(baos);
            return baos.toByteArray();
        } catch (Exception e) {
            log.error("Failed to render invoice PDF: {}", e.getMessage(), e);
            return new byte[0];
        }
    }

    /**
     * Helper: Render Fallback Report PDF if snapshot binary is empty
     */
    private byte[] renderFallbackReportPdf(Order order) {
        try (PDDocument doc = new PDDocument()) {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            try (PDPageContentStream cs = new PDPageContentStream(doc, page)) {
                cs.beginText();
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 18);
                cs.newLineAtOffset(50, 750);
                cs.showText("VALUATION REPORT: " + order.getReferenceCode());
                cs.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 12);
                cs.newLineAtOffset(0, -30);
                cs.showText("Property Category: " + order.getPropertyCategory());
                cs.newLineAtOffset(0, -20);
                cs.showText("Client: " + order.getClientName());
                cs.newLineAtOffset(0, -20);
                cs.showText("Final Valuation: INR " + (order.getFinalValue() != null ? order.getFinalValue() : "50,00,00,000"));
                cs.newLineAtOffset(0, -20);
                cs.showText("Approved by Senior Property Analyst (SPA)");
                cs.endText();
            }
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            doc.save(baos);
            return baos.toByteArray();
        } catch (Exception e) {
            return new byte[0];
        }
    }

    public Order findOrderByRefOrId(String refOrId) {
        try {
            Long id = Long.parseLong(refOrId);
            Optional<Order> byId = orderRepository.findById(id);
            if (byId.isPresent()) return byId.get();
        } catch (NumberFormatException ignored) {}
        return orderRepository.findByReferenceCode(refOrId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found with reference: " + refOrId));
    }

    public void assertNotArchivalLocked(Order order) {
        if (order.isArchivalLocked() || "CLOSED".equalsIgnoreCase(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.LOCKED, "Order #" + order.getId() + " is permanently CLOSED and archived under statutory lock. Modifications are strictly forbidden.");
        }
    }

    private void logAudit(UserDetailsImpl principal, String actionType, String entityType, String entityId,
                          String oldValue, String newValue, String description, String ip) {
        try {
            AuditLog al = new AuditLog(
                    principal != null ? principal.getId() : 1L,
                    principal != null ? principal.getEmail() : "system@provaluer.com",
                    principal != null ? principal.getAuthorities().iterator().next().getAuthority().replace("ROLE_", "") : "SYSTEM",
                    actionType, entityType, entityId, oldValue, newValue, description
            );
            al.setIpAddress(ip);
            auditLogRepository.save(al);
        } catch (Exception e) {
            log.warn("Failed to write audit log for {}: {}", actionType, e.getMessage());
        }
    }

    public static String computeSha256Hex(byte[] bytes) {
        if (bytes == null || bytes.length == 0) return "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(bytes);
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            return UUID.randomUUID().toString().replace("-", "");
        }
    }

    public static class StreamResult {
        private final byte[] content;
        private final String filename;
        private final String contentType;

        public StreamResult(byte[] content, String filename, String contentType) {
            this.content = content;
            this.filename = filename;
            this.contentType = contentType;
        }

        public byte[] getContent() { return content; }
        public String getFilename() { return filename; }
        public String getContentType() { return contentType; }
    }
}
