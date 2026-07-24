package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "transactions")
public class Transaction {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private String stage; // DEPOSIT, BALANCE

    @Column(nullable = false)
    private String status; // PENDING, SUCCESS, FAILED

    @Column(name = "transaction_ref")
    private String transactionRef;

    public Transaction() {}

    public Transaction(Long orderId, BigDecimal amount, String stage, String status, String transactionRef) {
        this.orderId = orderId;
        this.amount = amount;
        this.stage = stage;
        this.status = status;
        this.transactionRef = transactionRef;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getStage() { return stage; }
    public void setStage(String stage) { this.stage = stage; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getTransactionRef() { return transactionRef; }
    public void setTransactionRef(String transactionRef) { this.transactionRef = transactionRef; }
}
