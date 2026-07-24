package com.provaluer.controller;

import com.provaluer.model.Order;
import com.provaluer.model.Transaction;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.PerformanceLedgerRepository;
import com.provaluer.repository.TransactionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
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

    /**
     * POST /api/v1/payments/process-deposit
     * Processes simulated deposit payment. Sets order to PAID_INTAKE.
     */
    @PostMapping("/process-deposit")
    @Transactional
    public ResponseEntity<?> processDepositPayment(@RequestParam("orderId") Long orderId, @RequestParam("amount") BigDecimal amount) {
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            
            Transaction tx = new Transaction(orderId, amount, "DEPOSIT", "SUCCESS", "TXN-" + UUID.randomUUID().toString().substring(0,8).toUpperCase());
            transactionRepository.save(tx);
            
            order.setStatus("PAID_INTAKE");
            orderRepository.save(order);
            
            return ResponseEntity.ok(tx);
        }
        return ResponseEntity.notFound().build();
    }

    /**
     * POST /api/v1/payments/process-balance
     * Processes simulated final balance delta payment, releasing the reports from balance gate blocks.
     */
    @PostMapping("/process-balance")
    @Transactional
    public ResponseEntity<?> processBalancePayment(@RequestParam("orderId") Long orderId, @RequestParam("amount") BigDecimal amount) {
        Optional<Order> orderOpt = orderRepository.findById(orderId);
        if (orderOpt.isPresent()) {
            Order order = orderOpt.get();
            
            Transaction tx = new Transaction(orderId, amount, "BALANCE", "SUCCESS", "TXN-" + UUID.randomUUID().toString().substring(0,8).toUpperCase());
            transactionRepository.save(tx);
            
            order.setBalanceDue(BigDecimal.ZERO);
            order.setStatus("FINAL_DELIVERY");
            orderRepository.save(order);

            // Increment PA files completed in Performance Ledger
            if (order.getPaId() != null) {
                performanceLedgerRepository.findById(order.getPaId()).ifPresent(ledger -> {
                    ledger.setActiveAllocations(Math.max(0, ledger.getActiveAllocations() - 1));
                    ledger.setFilesCompleted(ledger.getFilesCompleted() + 1);
                    performanceLedgerRepository.save(ledger);
                });
            }

            return ResponseEntity.ok(tx);
        }
        return ResponseEntity.notFound().build();
    }
}
