package com.provaluer.service;

import com.provaluer.dto.*;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class PaymentWorkflowService {

    private static final Logger log = LoggerFactory.getLogger(PaymentWorkflowService.class);

    @Value("${app.payment.beneficiary-name:ProValuer Valuation & Advisory Services Pvt Ltd}")
    private String beneficiaryName;

    @Value("${app.payment.bank-name:HDFC Bank Ltd}")
    private String bankName;

    @Value("${app.payment.account-number:50200088912345}")
    private String accountNumber;

    @Value("${app.payment.ifsc:HDFC0001234}")
    private String ifsc;

    @Value("${app.payment.upi-id:provaluer.commercial@hdfcbank}")
    private String upiId;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderPaymentRepository orderPaymentRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PaymentNotificationService paymentNotificationService;

    @Autowired
    private AuditLogService auditLogService;

    private static final Set<String> ALLOWED_PAYMENT_PROOF_EXT = Set.of("pdf", "png", "jpg", "jpeg");

    public PaymentDetailsResponse.BankDetailsDto getBankDetails(BigDecimal amount, String referenceCode) {
        String qrPayload = "";
        try {
            qrPayload = String.format("upi://pay?pa=%s&pn=%s&am=%.2f&cu=INR&tn=%s",
                    URLEncoder.encode(upiId != null ? upiId : "", StandardCharsets.UTF_8),
                    URLEncoder.encode(beneficiaryName != null ? beneficiaryName : "ProValuer", StandardCharsets.UTF_8),
                    amount != null ? amount.doubleValue() : 0.0,
                    URLEncoder.encode(referenceCode != null ? referenceCode : "Valuation", StandardCharsets.UTF_8));
        } catch (Exception e) {
            qrPayload = "upi://pay?pa=" + upiId;
        }

        return new PaymentDetailsResponse.BankDetailsDto(
                beneficiaryName,
                bankName,
                accountNumber,
                ifsc,
                upiId,
                qrPayload
        );
    }

    @Transactional
    public PaymentDetailsResponse.PaymentRecordDto submitPaymentProof(
            Long orderId,
            MultipartFile file,
            SubmitPaymentRequest request,
            UserDetailsImpl principal) throws IOException {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found"));

        // Ownership Check
        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        if (!isAdmin && !order.getClientId().equals(principal.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied: You do not own this order");
        }

        // State Guard: Allowed only for QUOTE_PROVIDED or PAYMENT_REJECTED
        String currentStatus = order.getStatus();
        if (!"QUOTE_PROVIDED".equals(currentStatus) && !"PAYMENT_REJECTED".equals(currentStatus)) {
            if ("PAYMENT_VERIFIED".equals(currentStatus)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "Payment for this order has already been verified and locked");
            }
            if ("PAYMENT_SUBMITTED".equals(currentStatus)) {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "A payment submission is already pending verification for this order");
            }
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Cannot submit payment proof in current state: " + currentStatus);
        }

        // Validate Payment Date
        LocalDate today = LocalDate.now();
        if (request.getPaymentDate().isAfter(today)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment date cannot be in the future");
        }
        if (order.getQuotedAt() != null && request.getPaymentDate().isBefore(order.getQuotedAt().toLocalDate())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment date cannot be before quotation issuance date (" + order.getQuotedAt().toLocalDate() + ")");
        }

        // Normalized UTR Duplication Guard
        String cleanUtr = request.getUtrNumber().trim().toUpperCase(Locale.ROOT);
        boolean isDuplicate = orderPaymentRepository.existsActiveUtr(cleanUtr, Set.of("SUBMITTED", "VERIFIED"));
        if (isDuplicate) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "UTR number '" + cleanUtr + "' has already been claimed on active or verified record");
        }

        // File validation
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment proof receipt file is mandatory");
        }
        if (file.getSize() > 10 * 1024 * 1024) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment proof exceeds maximum allowed limit of 10 MB");
        }

        String filename = file.getOriginalFilename();
        if (filename == null || filename.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Filename is invalid");
        }

        String ext = "";
        int dotIdx = filename.lastIndexOf('.');
        if (dotIdx >= 0 && dotIdx < filename.length() - 1) {
            ext = filename.substring(dotIdx + 1).toLowerCase(Locale.ROOT);
        }
        if (!ALLOWED_PAYMENT_PROOF_EXT.contains(ext)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unsupported payment proof format: ." + ext + ". Allowed: PDF, PNG, JPG, JPEG");
        }

        byte[] fileBytes = file.getBytes();
        if (!validateMagicBytes(ext, fileBytes)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File signature mismatch: Content does not match declared extension: ." + ext);
        }

        User uploader = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        // Persist payment proof document
        OrderDocument doc = new OrderDocument();
        doc.setOrder(order);
        doc.setCategory("PAYMENT_PROOF");
        doc.setFilename(filename);
        doc.setFileContent(fileBytes);
        doc.setUploadedBy(uploader);
        OrderDocument savedDoc = orderDocumentRepository.save(doc);

        // Create OrderPayment entity
        OrderPayment payment = new OrderPayment();
        payment.setOrderId(order.getId());
        payment.setQuoteNumber(order.getQuoteNumber() != null ? order.getQuoteNumber() : "QTE-" + order.getId());
        payment.setUtrNumber(cleanUtr);
        payment.setPaymentMethod(request.getPaymentMethod());
        payment.setPaymentDate(request.getPaymentDate());
        payment.setAmountExpected(order.getQuoteTotal() != null ? order.getQuoteTotal() : BigDecimal.ZERO);
        payment.setAmountPaid(request.getAmountPaid());
        payment.setReceiptDocumentId(savedDoc.getId());
        payment.setClientNotes(request.getNotes());
        payment.setStatus("SUBMITTED");
        payment.setSubmittedBy(principal.getUsername());
        payment.setSubmittedAt(LocalDateTime.now());

        OrderPayment savedPayment = orderPaymentRepository.save(payment);

        // Transition Order State to PAYMENT_SUBMITTED
        order.setStatus("PAYMENT_SUBMITTED");
        order.setPaymentStatus("SUBMITTED");
        order.setLatestPaymentId(savedPayment.getId());
        orderRepository.save(order);

        // Required Audit Event: PAYMENT_SUBMITTED
        try {
            auditLogService.log(
                    principal.getId(),
                    principal.getEmail() != null ? principal.getEmail() : principal.getUsername(),
                    principal.getAuthorities().stream().findFirst().map(a -> a.getAuthority().replace("ROLE_", "")).orElse("CLIENT"),
                    "PAYMENT_SUBMITTED",
                    "ORDER",
                    String.valueOf(order.getId()),
                    currentStatus,
                    "PAYMENT_SUBMITTED",
                    "Payment proof submitted for order " + order.getReferenceCode() + " | UTR: " + cleanUtr + " | Amount: INR " + request.getAmountPaid()
            );
        } catch (Exception e) {
            log.warn("Failed to write audit log for PAYMENT_SUBMITTED on order #{}: {}", order.getId(), e.getMessage());
        }

        // Trigger Notifications asynchronously
        User clientUser = userRepository.findById(order.getClientId()).orElse(uploader);
        paymentNotificationService.notifyPaymentSubmitted(order, savedPayment, clientUser);

        return mapToRecordDto(savedPayment, filename);
    }

    @Transactional
    public PaymentDetailsResponse.PaymentRecordDto verifyPayment(
            Long orderId,
            VerifyPaymentRequest request,
            UserDetailsImpl principal) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found"));

        // State Guard: Allowed only when PAYMENT_SUBMITTED
        if (!"PAYMENT_SUBMITTED".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Cannot verify payment in current state: " + order.getStatus() + ". Must be PAYMENT_SUBMITTED.");
        }

        OrderPayment payment = null;
        if (order.getLatestPaymentId() != null) {
            payment = orderPaymentRepository.findById(order.getLatestPaymentId()).orElse(null);
        }
        if (payment == null) {
            payment = orderPaymentRepository.findTopByOrderIdOrderBySubmittedAtDesc(orderId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "No submitted payment found for order"));
        }

        BigDecimal verifiedAmt = (request != null && request.getVerifiedAmount() != null)
                ? request.getVerifiedAmount()
                : payment.getAmountPaid();

        String notes = (request != null && request.getAdminNotes() != null) ? request.getAdminNotes() : null;

        payment.setStatus("VERIFIED");
        payment.setVerifiedAmount(verifiedAmt);
        payment.setVerifiedBy(principal.getEmail() != null ? principal.getEmail() : principal.getUsername());
        payment.setVerifiedAt(LocalDateTime.now());
        if (notes != null) {
            payment.setAdminNotes(notes);
        }
        orderPaymentRepository.save(payment);

        // Transition Order State to PAYMENT_VERIFIED
        order.setStatus("PAYMENT_VERIFIED");
        order.setPaymentStatus("VERIFIED");
        orderRepository.save(order);

        // Required Audit Event: PAYMENT_VERIFIED
        try {
            auditLogService.log(
                    principal.getId(),
                    principal.getEmail() != null ? principal.getEmail() : principal.getUsername(),
                    principal.getAuthorities().stream().findFirst().map(a -> a.getAuthority().replace("ROLE_", "")).orElse("ADMIN"),
                    "PAYMENT_VERIFIED",
                    "ORDER",
                    String.valueOf(order.getId()),
                    "PAYMENT_SUBMITTED",
                    "PAYMENT_VERIFIED",
                    "Payment verified for order " + order.getReferenceCode() + " | UTR: " + payment.getUtrNumber() + " | Verified Amount: INR " + verifiedAmt
            );
        } catch (Exception e) {
            log.warn("Failed to write audit log for PAYMENT_VERIFIED on order #{}: {}", order.getId(), e.getMessage());
        }

        // Trigger notifications
        User clientUser = userRepository.findById(order.getClientId()).orElse(null);
        paymentNotificationService.notifyPaymentVerified(order, payment, clientUser, payment.getVerifiedBy());

        // STOP CONDITION: No release to Common Pool. No PAID_INTAKE.
        log.info("[SPRINT 3 COMPLETE] Order id={} refCode={} successfully verified at PAYMENT_VERIFIED. Pipeline stopped.",
                order.getId(), order.getReferenceCode());

        String filename = getDocumentFilename(payment.getReceiptDocumentId());
        return mapToRecordDto(payment, filename);
    }

    @Transactional
    public PaymentDetailsResponse.PaymentRecordDto rejectPayment(
            Long orderId,
            RejectPaymentRequest request,
            UserDetailsImpl principal) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found"));

        // State Guard: Allowed only when PAYMENT_SUBMITTED
        if (!"PAYMENT_SUBMITTED".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Cannot reject payment in current state: " + order.getStatus() + ". Must be PAYMENT_SUBMITTED.");
        }

        OrderPayment payment = null;
        if (order.getLatestPaymentId() != null) {
            payment = orderPaymentRepository.findById(order.getLatestPaymentId()).orElse(null);
        }
        if (payment == null) {
            payment = orderPaymentRepository.findTopByOrderIdOrderBySubmittedAtDesc(orderId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "No submitted payment found for order"));
        }

        payment.setStatus("REJECTED");
        payment.setRejectionReason(request.getRejectionReason());
        payment.setAdminNotes(request.getAdminNotes());
        payment.setVerifiedBy(principal.getEmail() != null ? principal.getEmail() : principal.getUsername());
        payment.setVerifiedAt(LocalDateTime.now());
        orderPaymentRepository.save(payment);

        // Transition Order State to PAYMENT_REJECTED (allowing client re-submission)
        order.setStatus("PAYMENT_REJECTED");
        order.setPaymentStatus("REJECTED");
        orderRepository.save(order);

        // Required Audit Event: PAYMENT_REJECTED
        try {
            auditLogService.log(
                    principal.getId(),
                    principal.getEmail() != null ? principal.getEmail() : principal.getUsername(),
                    principal.getAuthorities().stream().findFirst().map(a -> a.getAuthority().replace("ROLE_", "")).orElse("ADMIN"),
                    "PAYMENT_REJECTED",
                    "ORDER",
                    String.valueOf(order.getId()),
                    "PAYMENT_SUBMITTED",
                    "PAYMENT_REJECTED",
                    "Payment rejected for order " + order.getReferenceCode() + " | Reason: " + request.getRejectionReason()
            );
        } catch (Exception e) {
            log.warn("Failed to write audit log for PAYMENT_REJECTED on order #{}: {}", order.getId(), e.getMessage());
        }

        // Trigger notifications
        User clientUser = userRepository.findById(order.getClientId()).orElse(null);
        paymentNotificationService.notifyPaymentRejected(order, payment, clientUser, request.getRejectionReason(), payment.getVerifiedBy());

        log.info("[PAYMENT REJECTED] Order id={} refCode={} rejected with reason: {}. Awaiting re-submission.",
                order.getId(), order.getReferenceCode(), request.getRejectionReason());

        String filename = getDocumentFilename(payment.getReceiptDocumentId());
        return mapToRecordDto(payment, filename);
    }

    public PaymentDetailsResponse getPaymentDetails(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found"));

        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN") || a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        if (!isAdmin && !order.getClientId().equals(principal.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied: You do not own this order");
        }

        PaymentDetailsResponse res = new PaymentDetailsResponse();
        res.setOrderId(order.getId());
        res.setReferenceCode(order.getReferenceCode());
        res.setOrderStatus(order.getStatus());
        res.setPaymentStatus(order.getPaymentStatus());

        res.setQuoteNumber(order.getQuoteNumber());
        res.setQuoteAmount(order.getQuoteAmount());
        res.setQuoteTax(order.getQuoteTax());
        res.setQuoteTotal(order.getQuoteTotal());
        res.setQuoteTurnaround(order.getQuoteTurnaround());
        res.setQuoteValidUntil(order.getQuoteValidUntil());

        res.setBankDetails(getBankDetails(order.getQuoteTotal(), order.getReferenceCode()));

        List<OrderPayment> paymentList = orderPaymentRepository.findAllByOrderIdOrderBySubmittedAtDesc(orderId);
        List<PaymentDetailsResponse.PaymentRecordDto> recordDtos = paymentList.stream()
                .map(p -> mapToRecordDto(p, getDocumentFilename(p.getReceiptDocumentId())))
                .collect(Collectors.toList());
        res.setPayments(recordDtos);

        return res;
    }

    private String getDocumentFilename(Long docId) {
        if (docId == null) return null;
        return orderDocumentRepository.findById(docId).map(OrderDocument::getFilename).orElse(null);
    }

    private PaymentDetailsResponse.PaymentRecordDto mapToRecordDto(OrderPayment p, String receiptFilename) {
        PaymentDetailsResponse.PaymentRecordDto dto = new PaymentDetailsResponse.PaymentRecordDto();
        dto.setId(p.getId());
        dto.setUtrNumber(p.getUtrNumber());
        dto.setPaymentMethod(p.getPaymentMethod());
        dto.setPaymentDate(p.getPaymentDate());
        dto.setAmountExpected(p.getAmountExpected());
        dto.setAmountPaid(p.getAmountPaid());
        dto.setVerifiedAmount(p.getVerifiedAmount());
        dto.setReceiptDocumentId(p.getReceiptDocumentId());
        dto.setReceiptFilename(receiptFilename);
        dto.setStatus(p.getStatus());
        dto.setSubmittedBy(p.getSubmittedBy());
        dto.setSubmittedAt(p.getSubmittedAt());
        dto.setVerifiedBy(p.getVerifiedBy());
        dto.setVerifiedAt(p.getVerifiedAt());
        dto.setRejectionReason(p.getRejectionReason());
        dto.setAdminNotes(p.getAdminNotes());
        dto.setClientNotes(p.getClientNotes());
        return dto;
    }

    private boolean validateMagicBytes(String ext, byte[] bytes) {
        if (bytes == null || bytes.length < 4) return false;
        switch (ext) {
            case "pdf":
                return bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46; // %PDF
            case "png":
                if (bytes.length < 8) return false;
                return (bytes[0] & 0xFF) == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47;
            case "jpg":
            case "jpeg":
                return (bytes[0] & 0xFF) == 0xFF && (bytes[1] & 0xFF) == 0xD8 && (bytes[2] & 0xFF) == 0xFF;
            default:
                return false;
        }
    }
}
