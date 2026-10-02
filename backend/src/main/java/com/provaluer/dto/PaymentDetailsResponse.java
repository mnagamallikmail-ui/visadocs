package com.provaluer.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public class PaymentDetailsResponse {

    private Long orderId;
    private String referenceCode;
    private String orderStatus;
    private String paymentStatus;

    private String quoteNumber;
    private BigDecimal quoteAmount;
    private BigDecimal quoteTax;
    private BigDecimal quoteTotal;
    private String quoteTurnaround;
    private LocalDateTime quoteValidUntil;

    // Configured Bank Details (Dynamic from backend application config)
    private BankDetailsDto bankDetails;

    // Payment History Records
    private List<PaymentRecordDto> payments;

    public PaymentDetailsResponse() {}

    public static class BankDetailsDto {
        private String beneficiaryName;
        private String bankName;
        private String accountNumber;
        private String ifsc;
        private String upiId;
        private String upiQrString;

        public BankDetailsDto() {}

        public BankDetailsDto(String beneficiaryName, String bankName, String accountNumber, String ifsc, String upiId, String upiQrString) {
            this.beneficiaryName = beneficiaryName;
            this.bankName = bankName;
            this.accountNumber = accountNumber;
            this.ifsc = ifsc;
            this.upiId = upiId;
            this.upiQrString = upiQrString;
        }

        public String getBeneficiaryName() { return beneficiaryName; }
        public void setBeneficiaryName(String beneficiaryName) { this.beneficiaryName = beneficiaryName; }

        public String getBankName() { return bankName; }
        public void setBankName(String bankName) { this.bankName = bankName; }

        public String getAccountNumber() { return accountNumber; }
        public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }

        public String getIfsc() { return ifsc; }
        public void setIfsc(String ifsc) { this.ifsc = ifsc; }

        public String getUpiId() { return upiId; }
        public void setUpiId(String upiId) { this.upiId = upiId; }

        public String getUpiQrString() { return upiQrString; }
        public void setUpiQrString(String upiQrString) { this.upiQrString = upiQrString; }
    }

    public static class PaymentRecordDto {
        private Long id;
        private String utrNumber;
        private String paymentMethod;
        private LocalDate paymentDate;
        private BigDecimal amountExpected;
        private BigDecimal amountPaid;
        private BigDecimal verifiedAmount;
        private Long receiptDocumentId;
        private String receiptFilename;
        private String status;
        private String submittedBy;
        private LocalDateTime submittedAt;
        private String verifiedBy;
        private LocalDateTime verifiedAt;
        private String rejectionReason;
        private String adminNotes;
        private String clientNotes;

        public PaymentRecordDto() {}

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }

        public String getUtrNumber() { return utrNumber; }
        public void setUtrNumber(String utrNumber) { this.utrNumber = utrNumber; }

        public String getPaymentMethod() { return paymentMethod; }
        public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

        public LocalDate getPaymentDate() { return paymentDate; }
        public void setPaymentDate(LocalDate paymentDate) { this.paymentDate = paymentDate; }

        public BigDecimal getAmountExpected() { return amountExpected; }
        public void setAmountExpected(BigDecimal amountExpected) { this.amountExpected = amountExpected; }

        public BigDecimal getAmountPaid() { return amountPaid; }
        public void setAmountPaid(BigDecimal amountPaid) { this.amountPaid = amountPaid; }

        public BigDecimal getVerifiedAmount() { return verifiedAmount; }
        public void setVerifiedAmount(BigDecimal verifiedAmount) { this.verifiedAmount = verifiedAmount; }

        public Long getReceiptDocumentId() { return receiptDocumentId; }
        public void setReceiptDocumentId(Long receiptDocumentId) { this.receiptDocumentId = receiptDocumentId; }

        public String getReceiptFilename() { return receiptFilename; }
        public void setReceiptFilename(String receiptFilename) { this.receiptFilename = receiptFilename; }

        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }

        public String getSubmittedBy() { return submittedBy; }
        public void setSubmittedBy(String submittedBy) { this.submittedBy = submittedBy; }

        public LocalDateTime getSubmittedAt() { return submittedAt; }
        public void setSubmittedAt(LocalDateTime submittedAt) { this.submittedAt = submittedAt; }

        public String getVerifiedBy() { return verifiedBy; }
        public void setVerifiedBy(String verifiedBy) { this.verifiedBy = verifiedBy; }

        public LocalDateTime getVerifiedAt() { return verifiedAt; }
        public void setVerifiedAt(LocalDateTime verifiedAt) { this.verifiedAt = verifiedAt; }

        public String getRejectionReason() { return rejectionReason; }
        public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }

        public String getAdminNotes() { return adminNotes; }
        public void setAdminNotes(String adminNotes) { this.adminNotes = adminNotes; }

        public String getClientNotes() { return clientNotes; }
        public void setClientNotes(String clientNotes) { this.clientNotes = clientNotes; }
    }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getReferenceCode() { return referenceCode; }
    public void setReferenceCode(String referenceCode) { this.referenceCode = referenceCode; }

    public String getOrderStatus() { return orderStatus; }
    public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public String getQuoteNumber() { return quoteNumber; }
    public void setQuoteNumber(String quoteNumber) { this.quoteNumber = quoteNumber; }

    public BigDecimal getQuoteAmount() { return quoteAmount; }
    public void setQuoteAmount(BigDecimal quoteAmount) { this.quoteAmount = quoteAmount; }

    public BigDecimal getQuoteTax() { return quoteTax; }
    public void setQuoteTax(BigDecimal quoteTax) { this.quoteTax = quoteTax; }

    public BigDecimal getQuoteTotal() { return quoteTotal; }
    public void setQuoteTotal(BigDecimal quoteTotal) { this.quoteTotal = quoteTotal; }

    public String getQuoteTurnaround() { return quoteTurnaround; }
    public void setQuoteTurnaround(String quoteTurnaround) { this.quoteTurnaround = quoteTurnaround; }

    public LocalDateTime getQuoteValidUntil() { return quoteValidUntil; }
    public void setQuoteValidUntil(LocalDateTime quoteValidUntil) { this.quoteValidUntil = quoteValidUntil; }

    public BankDetailsDto getBankDetails() { return bankDetails; }
    public void setBankDetails(BankDetailsDto bankDetails) { this.bankDetails = bankDetails; }

    public List<PaymentRecordDto> getPayments() { return payments; }
    public void setPayments(List<PaymentRecordDto> payments) { this.payments = payments; }
}
