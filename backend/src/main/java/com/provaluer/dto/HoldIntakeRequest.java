package com.provaluer.dto;

/**
 * SPRINT 4: Request body for POST /api/v1/orders/{id}/hold-intake.
 */
public class HoldIntakeRequest {

    private String holdReason;

    public String getHoldReason() { return holdReason; }
    public void setHoldReason(String holdReason) { this.holdReason = holdReason; }
}
