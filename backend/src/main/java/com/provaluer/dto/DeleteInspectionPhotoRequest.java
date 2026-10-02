package com.provaluer.dto;

public class DeleteInspectionPhotoRequest {

    private String reason;

    public DeleteInspectionPhotoRequest() {}

    public DeleteInspectionPhotoRequest(String reason) {
        this.reason = reason;
    }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}
