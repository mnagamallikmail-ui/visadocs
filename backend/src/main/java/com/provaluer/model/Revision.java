package com.provaluer.model;

import jakarta.persistence.*;

@Entity
@Table(name = "revisions")
public class Revision {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "error_classification", nullable = false)
    private String errorClassification;

    @Column(nullable = false, length = 500)
    private String feedback;

    @Column(name = "attachment_path")
    private String attachmentPath;

    @Column(name = "round_number", nullable = false)
    private int roundNumber;

    @Column(nullable = false)
    private String status; // PENDING, COMPLETED

    public Revision() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getErrorClassification() { return errorClassification; }
    public void setErrorClassification(String errorClassification) { this.errorClassification = errorClassification; }

    public String getFeedback() { return feedback; }
    public void setFeedback(String feedback) { this.feedback = feedback; }

    public String getAttachmentPath() { return attachmentPath; }
    public void setAttachmentPath(String attachmentPath) { this.attachmentPath = attachmentPath; }

    public int getRoundNumber() { return roundNumber; }
    public void setRoundNumber(int roundNumber) { this.roundNumber = roundNumber; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
