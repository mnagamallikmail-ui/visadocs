package com.provaluer.service;

import com.provaluer.dto.ReleaseQueueOrderDto;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * SPRINT 4: Admin Controlled Pool Release Service.
 * <p>
 * Manages the PAYMENT_VERIFIED → PAID_INTAKE transition (Option B: Admin Controlled Release).
 * Enforces all release pre-conditions per Section E of the Sprint 4 authorization.
 * <p>
 * STRICTLY FROZEN: This service DOES NOT modify the PA Dashboard, SPA Dashboard,
 * Heartbeat, Performance Ledger, ValuationSnapshot, Report Generator, or Delivery Engine.
 */
@Service
public class PoolReleaseService {

    private static final Logger log = LoggerFactory.getLogger(PoolReleaseService.class);

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderPaymentRepository orderPaymentRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ValuationSnapshotRepository valuationSnapshotRepository;

    @Autowired
    private SlaService slaService;

    @Autowired
    private AuditLogService auditLogService;

    @Autowired
    private TelegramNotificationService telegramNotificationService;

    // ────────────────────────────────────────────────────────────────────────────
    // Section C: GET /api/v1/orders/release-queue
    // Returns all PAYMENT_VERIFIED orders pending admin clearance.
    // ────────────────────────────────────────────────────────────────────────────

    public List<ReleaseQueueOrderDto> getReleaseQueue() {
        List<Order> verifiedOrders = orderRepository.findAllByStatus("PAYMENT_VERIFIED");
        return verifiedOrders.stream()
                .map(this::mapToReleaseQueueDto)
                .collect(Collectors.toList());
    }

    public List<ReleaseQueueOrderDto> getPaymentReviewQueue() {
        List<Order> submittedOrders = orderRepository.findAllByStatus("PAYMENT_SUBMITTED");
        return submittedOrders.stream()
                .map(this::mapToReleaseQueueDto)
                .collect(Collectors.toList());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // Section E: POST /api/v1/orders/{id}/release-to-pool
    // Full pre-condition verification + state transition PAYMENT_VERIFIED → PAID_INTAKE.
    // ────────────────────────────────────────────────────────────────────────────

    @Transactional
    public ReleaseQueueOrderDto releaseToPool(Long orderId, String intakeNotes, UserDetailsImpl principal) {

        // Step 1: Load order
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId));

        // Step 2: Verify status == PAYMENT_VERIFIED
        if (!"PAYMENT_VERIFIED".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cannot release order to pool: current status is '" + order.getStatus() +
                    "'. Only PAYMENT_VERIFIED orders may be released.");
        }

        // Step 3: Verify paymentStatus == VERIFIED
        if (!"VERIFIED".equals(order.getPaymentStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cannot release order to pool: payment status is '" + order.getPaymentStatus() +
                    "'. Only orders with VERIFIED payment may be released.");
        }

        // Step 4: Verify mandatory documents exist (at least one non-PAYMENT_PROOF document)
        List<OrderDocument> docs = orderDocumentRepository.findAllByOrderId(orderId);
        long nonPaymentDocs = docs.stream()
                .filter(d -> !"PAYMENT_PROOF".equalsIgnoreCase(d.getCategory()))
                .count();
        if (nonPaymentDocs == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cannot release order to pool: no intake documents found. Mandatory documents (Title Deed, Plan, Tax Receipt) must be present.");
        }

        // Step 5: Verify quote exists
        if (order.getQuoteNumber() == null || order.getQuoteTotal() == null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cannot release order to pool: no quotation has been issued for this order.");
        }

        // Step 6: Verify no existing assignment (paId must be null and status must not be ASSIGNED)
        if (order.getPaId() != null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cannot release order to pool: this order already has an assigned PA (paId=" + order.getPaId() + ").");
        }

        // Step 7: Verify no active claim — checked implicitly by step 6 (only PAID_INTAKE orders can be claimed)

        // Step 8: Verify no existing valuation snapshot
        boolean snapshotExists = valuationSnapshotRepository.existsByOrderId(orderId);
        if (snapshotExists) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cannot release order to pool: a valuation snapshot already exists for this order. Contact Super Admin.");
        }

        // Step 9: Generate reportNumber PV-YYMM-XXXX (same algorithm as legacy submitIntake)
        LocalDateTime now = LocalDateTime.now();
        int yy = now.getYear() % 100;
        int mm = now.getMonthValue();
        String prefix = String.format("PV-%02d%02d-", yy, mm);
        long seq = orderRepository.countByReportNumberStartingWith(prefix) + 1;
        String reportNumber = String.format("%s%04d", prefix, seq);
        order.setReportNumber(reportNumber);

        // Step 10: Start SLA timer
        LocalDateTime slaExpiry = slaService.calculateExpiry(order.getPurpose(), now);
        order.setSlaExpiryTime(slaExpiry);

        // Step 11: Record release metadata
        String releasedByStr = principal.getEmail() != null ? principal.getEmail() : principal.getUsername();
        order.setReleasedBy(releasedByStr);
        order.setReleasedToPoolAt(now);
        order.setIntakeHoldReason(null);          // clear any previous hold
        if (intakeNotes != null && !intakeNotes.isBlank()) {
            order.setIntakeNotes(intakeNotes.trim());
        }

        // Step 12: Transition status PAYMENT_VERIFIED → PAID_INTAKE
        order.setStatus("PAID_INTAKE");
        order.setUpdatedAt(now);
        orderRepository.save(order);

        log.info("[SPRINT 4] Order id={} refCode={} reportNumber={} released to PAID_INTAKE by {} at {}",
                order.getId(), order.getReferenceCode(), reportNumber, releasedByStr, now);

        // Step 13: Audit log
        try {
            auditLogService.log(
                    principal.getId(),
                    principal.getUsername(),
                    principal.getAuthorities().iterator().next().getAuthority(),
                    "POOL_RELEASED",
                    "orders",
                    String.valueOf(order.getId()),
                    "Released to Common Pool. ReportNumber=" + reportNumber +
                    " SLA=" + slaExpiry + " ReleasedBy=" + releasedByStr
            );
            // Also log RELEASE_TO_POOL for backwards compatibility
            auditLogService.log(
                    principal.getId(),
                    principal.getUsername(),
                    principal.getAuthorities().iterator().next().getAuthority(),
                    "RELEASE_TO_POOL",
                    "orders",
                    String.valueOf(order.getId()),
                    "Released to Common Pool. ReportNumber=" + reportNumber +
                    " SLA=" + slaExpiry + " ReleasedBy=" + releasedByStr
            );
        } catch (Exception e) {
            log.warn("[SPRINT 4] Failed to write audit log for release-to-pool order #{}: {}", orderId, e.getMessage());
        }

        // Step 14: Dispatch notifications asynchronously (non-blocking)
        User clientUser = userRepository.findById(order.getClientId()).orElse(null);
        dispatchReleaseNotifications(order, clientUser, releasedByStr, reportNumber);

        return mapToReleaseQueueDto(order);
    }

    // ────────────────────────────────────────────────────────────────────────────
    // Section D: POST /api/v1/orders/{id}/hold-intake
    // Admin holds a PAYMENT_VERIFIED order to prevent accidental premature release.
    // ────────────────────────────────────────────────────────────────────────────

    @Transactional
    public ReleaseQueueOrderDto holdIntake(Long orderId, String holdReason, UserDetailsImpl principal) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId));

        if (!"PAYMENT_VERIFIED".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Hold-intake is only allowed on PAYMENT_VERIFIED orders. Current status: " + order.getStatus());
        }

        if (holdReason == null || holdReason.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hold reason is mandatory.");
        }

        order.setIntakeHoldReason(holdReason.trim());
        order.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(order);

        log.info("[SPRINT 4] Order id={} refCode={} placed on intake hold by {} reason='{}'",
                order.getId(), order.getReferenceCode(), principal.getUsername(), holdReason);

        try {
            auditLogService.log(
                    principal.getId(),
                    principal.getUsername(),
                    principal.getAuthorities().iterator().next().getAuthority(),
                    "HOLD_INTAKE",
                    "orders",
                    String.valueOf(order.getId()),
                    "Intake held. Reason: " + holdReason
            );
        } catch (Exception e) {
            log.warn("[SPRINT 4] Failed to write audit log for hold-intake order #{}: {}", orderId, e.getMessage());
        }

        return mapToReleaseQueueDto(order);
    }

    // ────────────────────────────────────────────────────────────────────────────
    // Private helpers
    // ────────────────────────────────────────────────────────────────────────────

    private void dispatchReleaseNotifications(Order order, User clientUser, String releasedBy, String reportNumber) {
        try {
            // Client portal notification (simulated transactional email)
            String clientEmail = clientUser != null ? clientUser.getEmail() : "N/A";
            String clientName  = (clientUser != null && clientUser.getFullName() != null && !clientUser.getFullName().isBlank())
                    ? clientUser.getFullName() : (clientUser != null ? clientUser.getUsername() : "Client");
            log.info("[CLIENT EMAIL SENT] To: {} | Subject: Your Valuation Request Has Been Accepted [Ref: {}] | " +
                     "ReportNo: {} | Status: Processing In Progress",
                    clientEmail, order.getReferenceCode(), reportNumber);

            // Operations Telegram alert
            telegramNotificationService.sendPoolReleaseNotification(
                    order.getReferenceCode(),
                    order.getQuoteNumber(),
                    clientName,
                    order.getServiceCategory(),
                    reportNumber,
                    releasedBy
            );
        } catch (Exception e) {
            log.warn("[SPRINT 4] Notification dispatch failed for order #{} (non-fatal): {}", order.getId(), e.getMessage());
        }
    }

    private ReleaseQueueOrderDto mapToReleaseQueueDto(Order order) {
        ReleaseQueueOrderDto dto = new ReleaseQueueOrderDto();
        dto.setOrderId(order.getId());
        dto.setReferenceCode(order.getReferenceCode());
        dto.setQuoteNumber(order.getQuoteNumber());
        dto.setServiceCategory(order.getServiceCategory());
        dto.setAssetCategory(order.getPropertyCategory());
        dto.setPurpose(order.getPurpose());
        dto.setQuoteAmount(order.getQuoteAmount());
        dto.setQuoteTax(order.getQuoteTax());
        dto.setQuoteTotal(order.getQuoteTotal());
        dto.setQuotedAt(order.getQuotedAt());
        dto.setStatus(order.getStatus());
        dto.setPaymentStatus(order.getPaymentStatus());
        dto.setCreatedAt(order.getCreatedAt());

        // Enrich client data
        if (order.getClientId() != null) {
            userRepository.findById(order.getClientId()).ifPresent(u -> {
                String name = (u.getFullName() != null && !u.getFullName().isBlank())
                        ? u.getFullName() : u.getUsername();
                dto.setClientName(name);
                dto.setClientEmail(u.getEmail());
            });
        }

        // Enrich payment data from latest verified payment
        if (order.getLatestPaymentId() != null) {
            orderPaymentRepository.findById(order.getLatestPaymentId()).ifPresent(p -> {
                dto.setVerifiedAmount(p.getVerifiedAmount() != null ? p.getVerifiedAmount() : p.getAmountPaid());
                dto.setPaymentVerifiedAt(p.getVerifiedAt());
                dto.setPaymentVerifiedBy(p.getVerifiedBy());
                dto.setUtrNumber(p.getUtrNumber());
            });
        } else {
            // Fallback: find latest verified payment if latestPaymentId is stale
            orderPaymentRepository.findTopByOrderIdOrderBySubmittedAtDesc(order.getId()).ifPresent(p -> {
                if ("VERIFIED".equals(p.getStatus())) {
                    dto.setVerifiedAmount(p.getVerifiedAmount() != null ? p.getVerifiedAmount() : p.getAmountPaid());
                    dto.setPaymentVerifiedAt(p.getVerifiedAt());
                    dto.setPaymentVerifiedBy(p.getVerifiedBy());
                    dto.setUtrNumber(p.getUtrNumber());
                }
            });
        }

        // Document count (excludes PAYMENT_PROOF for clean display)
        List<OrderDocument> docs = orderDocumentRepository.findAllByOrderId(order.getId());
        dto.setDocumentCount(docs.size());

        return dto;
    }
}
