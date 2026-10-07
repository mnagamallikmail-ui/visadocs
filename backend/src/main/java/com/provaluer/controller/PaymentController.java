package com.provaluer.controller;

import com.provaluer.model.Order;
import com.provaluer.model.Transaction;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.PerformanceLedgerRepository;
import com.provaluer.repository.TransactionRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.AuditLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private TransactionRepository transactionRepository;

    @Autowired
    private PerformanceLedgerRepository performanceLedgerRepository;

    @Autowired
    private AuditLogService auditLogService;

    private UserDetailsImpl getCurrentPrincipal() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof UserDetailsImpl) {
            return (UserDetailsImpl) principal;
        }
        return null;
    }

    /**
     * POST /api/v1/payments/process-deposit
     * Processes verified deposit payment with ownership and state guards. Sets order to PAID_INTAKE.
     */
    @PostMapping("/process-deposit")
    @Transactional
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> processDepositPayment(@RequestParam("orderId") Long orderId, @RequestParam("amount") BigDecimal amount) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        boolean isOwner = order.getClientId() != null && order.getClientId().equals(principal.getId());

        if (!isAdmin && !isOwner) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Access denied: You do not own Order #" + orderId));
        }

        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Payment amount must be greater than zero"));
        }

        String currentStatus = order.getStatus() != null ? order.getStatus() : "DRAFT";
        boolean isDepositEligible = "DRAFT".equalsIgnoreCase(currentStatus)
                || "QUOTE_PROVIDED".equalsIgnoreCase(currentStatus)
                || "QUOTE_ACCEPTED".equalsIgnoreCase(currentStatus)
                || "PAYMENT_REJECTED".equalsIgnoreCase(currentStatus);

        if (!isDepositEligible && !isAdmin) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Cannot process deposit for order in status: " + currentStatus));
        }

        Transaction tx = new Transaction(orderId, amount, "DEPOSIT", "SUCCESS", "TXN-" + UUID.randomUUID().toString().substring(0,8).toUpperCase());
        transactionRepository.save(tx);

        order.setStatus("PAID_INTAKE");
        order.setPaymentStatus("DEPOSIT_PAID");
        orderRepository.save(order);

        try {
            auditLogService.log(principal.getId(), principal.getUsername(),
                    principal.getAuthorities().iterator().next().getAuthority(),
                    "PAYMENT_DEPOSIT_VERIFIED", "ORDER", String.valueOf(orderId),
                    currentStatus, "PAID_INTAKE", "Deposit payment processed for INR " + amount + " | Ref: " + tx.getTransactionRef());
        } catch (Exception ignored) {}

        return ResponseEntity.ok(tx);
    }

    /**
     * POST /api/v1/payments/process-balance
     * Processes verified final balance payment with ownership and state guards.
     */
    @PostMapping("/process-balance")
    @Transactional
    @PreAuthorize("hasAnyRole('CLIENT', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> processBalancePayment(@RequestParam("orderId") Long orderId, @RequestParam("amount") BigDecimal amount) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        Order order = orderOpt.get();

        boolean isAdmin = principal.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        boolean isOwner = order.getClientId() != null && order.getClientId().equals(principal.getId());

        if (!isAdmin && !isOwner) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Access denied: You do not own Order #" + orderId));
        }

        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            return ResponseEntity.badRequest().body(Map.of("error", "Payment amount must be greater than zero"));
        }

        String currentStatus = order.getStatus() != null ? order.getStatus() : "";
        boolean isBalanceEligible = "SPA_CONFIRMED".equalsIgnoreCase(currentStatus)
                || "PAYMENT_LOCK".equalsIgnoreCase(currentStatus)
                || "DELIVERY_READY".equalsIgnoreCase(currentStatus);

        if (!isBalanceEligible && !isAdmin) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(Map.of("error", "Order is not ready for balance settlement in current status: " + currentStatus));
        }

        Transaction tx = new Transaction(orderId, amount, "BALANCE", "SUCCESS", "TXN-" + UUID.randomUUID().toString().substring(0,8).toUpperCase());
        transactionRepository.save(tx);

        order.setBalanceDue(BigDecimal.ZERO);
        order.setStatus("FINAL_DELIVERY");
        order.setPaymentStatus("SETTLED");
        orderRepository.save(order);

        // Increment PA files completed in Performance Ledger
        if (order.getPaId() != null) {
            performanceLedgerRepository.findById(order.getPaId()).ifPresent(ledger -> {
                ledger.setActiveAllocations(Math.max(0, ledger.getActiveAllocations() - 1));
                ledger.setFilesCompleted(ledger.getFilesCompleted() + 1);
                performanceLedgerRepository.save(ledger);
            });
        }

        try {
            auditLogService.log(principal.getId(), principal.getUsername(),
                    principal.getAuthorities().iterator().next().getAuthority(),
                    "PAYMENT_BALANCE_SETTLED", "ORDER", String.valueOf(orderId),
                    currentStatus, "FINAL_DELIVERY", "Final balance settled for INR " + amount + " | Ref: " + tx.getTransactionRef());
        } catch (Exception ignored) {}

        return ResponseEntity.ok(tx);
    }
}
