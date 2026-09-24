package com.provaluer.dto;

public class SeoSyncRequest {
    private String provider; // 'GSC', 'BING', 'ALL'

    public SeoSyncRequest() {}

    public SeoSyncRequest(String provider) {
        this.provider = provider;
    }

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }
}
