package com.provaluer.dto;

public class SeoConfigUpdateRequest {
    private String syncFrequency; // 'DAILY', 'WEEKLY'

    public SeoConfigUpdateRequest() {}

    public SeoConfigUpdateRequest(String syncFrequency) {
        this.syncFrequency = syncFrequency;
    }

    public String getSyncFrequency() { return syncFrequency; }
    public void setSyncFrequency(String syncFrequency) { this.syncFrequency = syncFrequency; }
}
