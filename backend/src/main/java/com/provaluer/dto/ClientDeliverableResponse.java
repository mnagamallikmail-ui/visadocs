package com.provaluer.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public class ClientDeliverableResponse {
    private Long orderId;
    private String referenceCode;
    private String clientName;
    private String propertyCategory;
    private String status;
    private BigDecimal finalValue;
    private BigDecimal feeCharged;
    private BigDecimal balanceDue;
    private boolean delivered;
    private LocalDateTime deliveredAt;
    private boolean downloaded;
    private LocalDateTime downloadedAt;
    private boolean disputed;
    private boolean closed;
    private LocalDateTime closedAt;
    private String passwordHint;
    private List<String> availableFiles;
    private InvoiceSummaryDto invoice;
    private List<AcknowledgementSummaryDto> acknowledgements;

    public ClientDeliverableResponse() {}

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getReferenceCode() { return referenceCode; }
    public void setReferenceCode(String referenceCode) { this.referenceCode = referenceCode; }

    public String getClientName() { return clientName; }
    public void setClientName(String clientName) { this.clientName = clientName; }

    public String getPropertyCategory() { return propertyCategory; }
    public void setPropertyCategory(String propertyCategory) { this.propertyCategory = propertyCategory; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public BigDecimal getFinalValue() { return finalValue; }
    public void setFinalValue(BigDecimal finalValue) { this.finalValue = finalValue; }

    public BigDecimal getFeeCharged() { return feeCharged; }
    public void setFeeCharged(BigDecimal feeCharged) { this.feeCharged = feeCharged; }

    public BigDecimal getBalanceDue() { return balanceDue; }
    public void setBalanceDue(BigDecimal balanceDue) { this.balanceDue = balanceDue; }

    public boolean isDelivered() { return delivered; }
    public void setDelivered(boolean delivered) { this.delivered = delivered; }

    public LocalDateTime getDeliveredAt() { return deliveredAt; }
    public void setDeliveredAt(LocalDateTime deliveredAt) { this.deliveredAt = deliveredAt; }

    public boolean isDownloaded() { return downloaded; }
    public void setDownloaded(boolean downloaded) { this.downloaded = downloaded; }

    public LocalDateTime getDownloadedAt() { return downloadedAt; }
    public void setDownloadedAt(LocalDateTime downloadedAt) { this.downloadedAt = downloadedAt; }

    public boolean isDisputed() { return disputed; }
    public void setDisputed(boolean disputed) { this.disputed = disputed; }

    public boolean isClosed() { return closed; }
    public void setClosed(boolean closed) { this.closed = closed; }

    public LocalDateTime getClosedAt() { return closedAt; }
    public void setClosedAt(LocalDateTime closedAt) { this.closedAt = closedAt; }

    public String getPasswordHint() { return passwordHint; }
    public void setPasswordHint(String passwordHint) { this.passwordHint = passwordHint; }

    public List<String> getAvailableFiles() { return availableFiles; }
    public void setAvailableFiles(List<String> availableFiles) { this.availableFiles = availableFiles; }

    public InvoiceSummaryDto getInvoice() { return invoice; }
    public void setInvoice(InvoiceSummaryDto invoice) { this.invoice = invoice; }

    public List<AcknowledgementSummaryDto> getAcknowledgements() { return acknowledgements; }
    public void setAcknowledgements(List<AcknowledgementSummaryDto> acknowledgements) { this.acknowledgements = acknowledgements; }

    public static class InvoiceSummaryDto {
        private String invoiceNumber;
        private LocalDate invoiceDate;
        private BigDecimal grandTotal;
        private BigDecimal amountPaid;
        private BigDecimal balanceDue;
        private String status;

        public InvoiceSummaryDto() {}

        public InvoiceSummaryDto(String invoiceNumber, LocalDate invoiceDate, BigDecimal grandTotal, BigDecimal amountPaid, BigDecimal balanceDue, String status) {
            this.invoiceNumber = invoiceNumber;
            this.invoiceDate = invoiceDate;
            this.grandTotal = grandTotal;
            this.amountPaid = amountPaid;
            this.balanceDue = balanceDue;
            this.status = status;
        }

        public String getInvoiceNumber() { return invoiceNumber; }
        public void setInvoiceNumber(String invoiceNumber) { this.invoiceNumber = invoiceNumber; }

        public LocalDate getInvoiceDate() { return invoiceDate; }
        public void setInvoiceDate(LocalDate invoiceDate) { this.invoiceDate = invoiceDate; }

        public BigDecimal getGrandTotal() { return grandTotal; }
        public void setGrandTotal(BigDecimal grandTotal) { this.grandTotal = grandTotal; }

        public BigDecimal getAmountPaid() { return amountPaid; }
        public void setAmountPaid(BigDecimal amountPaid) { this.amountPaid = amountPaid; }

        public BigDecimal getBalanceDue() { return balanceDue; }
        public void setBalanceDue(BigDecimal balanceDue) { this.balanceDue = balanceDue; }

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
    }

    public static class AcknowledgementSummaryDto {
        private String action;
        private String actorRole;
        private LocalDateTime timestamp;
        private String notes;

        public AcknowledgementSummaryDto() {}

        public AcknowledgementSummaryDto(String action, String actorRole, LocalDateTime timestamp, String notes) {
            this.action = action;
            this.actorRole = actorRole;
            this.timestamp = timestamp;
            this.notes = notes;
        }

        public String getAction() { return action; }
        public void setAction(String action) { this.action = action; }

        public String getActorRole() { return actorRole; }
        public void setActorRole(String actorRole) { this.actorRole = actorRole; }

        public LocalDateTime getTimestamp() { return timestamp; }
        public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }

        public String getNotes() { return notes; }
        public void setNotes(String notes) { this.notes = notes; }
    }
}
