package com.provaluer.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;

public class VerifyPaymentRequest {

    @DecimalMin(value = "0.01", message = "Verified amount must be greater than zero")
    private BigDecimal verifiedAmount;

    @Size(max = 2000, message = "Admin notes cannot exceed 2000 characters")
    private String adminNotes;

    public VerifyPaymentRequest() {}

    public BigDecimal getVerifiedAmount() { return verifiedAmount; }
    public void setVerifiedAmount(BigDecimal verifiedAmount) { this.verifiedAmount = verifiedAmount; }

    public String getAdminNotes() { return adminNotes; }
    public void setAdminNotes(String adminNotes) { this.adminNotes = adminNotes; }
}
