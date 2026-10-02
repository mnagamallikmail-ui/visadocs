package com.provaluer.dto;

public class EvaluateGateRequest {
    private boolean adminOverride = false;
    private String overrideReason;
    private Boolean corporateCreditActive;

    public EvaluateGateRequest() {}

    public EvaluateGateRequest(boolean adminOverride, String overrideReason, Boolean corporateCreditActive) {
        this.adminOverride = adminOverride;
        this.overrideReason = overrideReason;
        this.corporateCreditActive = corporateCreditActive;
    }

    public boolean isAdminOverride() { return adminOverride; }
    public void setAdminOverride(boolean adminOverride) { this.adminOverride = adminOverride; }

    public String getOverrideReason() { return overrideReason; }
    public void setOverrideReason(String overrideReason) { this.overrideReason = overrideReason; }

    public Boolean getCorporateCreditActive() { return corporateCreditActive; }
    public void setCorporateCreditActive(Boolean corporateCreditActive) { this.corporateCreditActive = corporateCreditActive; }
}
