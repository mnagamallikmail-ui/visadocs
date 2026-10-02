package com.provaluer.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;

public class SubmitPaymentRequest {

    @NotBlank(message = "UTR / Transaction Reference number is mandatory")
    @Size(min = 6, max = 30, message = "UTR must be between 6 and 30 characters")
    @Pattern(regexp = "^[a-zA-Z0-9]+$", message = "UTR must be alphanumeric without special characters")
    private String utrNumber;

    @NotBlank(message = "Payment method is mandatory")
    @Pattern(regexp = "^(UPI|NEFT|RTGS|IMPS|BANK_TRANSFER)$", message = "Payment method must be UPI, NEFT, RTGS, IMPS, or BANK_TRANSFER")
    private String paymentMethod;

    @NotNull(message = "Payment date is mandatory")
    private LocalDate paymentDate;

    @NotNull(message = "Amount paid is mandatory")
    @DecimalMin(value = "1.00", message = "Amount paid must be greater than zero")
    private BigDecimal amountPaid;

    @Size(max = 500, message = "Client notes cannot exceed 500 characters")
    private String notes;

    public SubmitPaymentRequest() {}

    public String getUtrNumber() { return utrNumber; }
    public void setUtrNumber(String utrNumber) { this.utrNumber = utrNumber; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public LocalDate getPaymentDate() { return paymentDate; }
    public void setPaymentDate(LocalDate paymentDate) { this.paymentDate = paymentDate; }

    public BigDecimal getAmountPaid() { return amountPaid; }
    public void setAmountPaid(BigDecimal amountPaid) { this.amountPaid = amountPaid; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}
