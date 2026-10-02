package com.provaluer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class RejectPaymentRequest {

    @NotBlank(message = "Rejection reason is mandatory")
    @Size(max = 255, message = "Rejection reason must be under 255 characters")
    private String rejectionReason;

    @Size(max = 2000, message = "Admin notes cannot exceed 2000 characters")
    private String adminNotes;

    public RejectPaymentRequest() {}

    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }

    public String getAdminNotes() { return adminNotes; }
    public void setAdminNotes(String adminNotes) { this.adminNotes = adminNotes; }
}
