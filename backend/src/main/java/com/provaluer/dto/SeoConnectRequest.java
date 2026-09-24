package com.provaluer.dto;

public class SeoConnectRequest {
    private String provider; // 'GSC', 'BING'
    private String propertyId;
    private String siteUrl;
    private String apiKey;
    private String ownerPermissions;
    private String authCode;

    public SeoConnectRequest() {}

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getPropertyId() { return propertyId; }
    public void setPropertyId(String propertyId) { this.propertyId = propertyId; }

    public String getSiteUrl() { return siteUrl; }
    public void setSiteUrl(String siteUrl) { this.siteUrl = siteUrl; }

    public String getApiKey() { return apiKey; }
    public void setApiKey(String apiKey) { this.apiKey = apiKey; }

    public String getOwnerPermissions() { return ownerPermissions; }
    public void setOwnerPermissions(String ownerPermissions) { this.ownerPermissions = ownerPermissions; }

    public String getAuthCode() { return authCode; }
    public void setAuthCode(String authCode) { this.authCode = authCode; }
}
