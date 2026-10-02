package com.provaluer.dto;

public class ReleaseOrderRequest {
    private boolean includeDocx = false;
    private String releaseNotes;
    private String clientStateCode; // Default "27" if null

    public ReleaseOrderRequest() {}

    public ReleaseOrderRequest(boolean includeDocx, String releaseNotes, String clientStateCode) {
        this.includeDocx = includeDocx;
        this.releaseNotes = releaseNotes;
        this.clientStateCode = clientStateCode;
    }

    public boolean isIncludeDocx() { return includeDocx; }
    public void setIncludeDocx(boolean includeDocx) { this.includeDocx = includeDocx; }

    public String getReleaseNotes() { return releaseNotes; }
    public void setReleaseNotes(String releaseNotes) { this.releaseNotes = releaseNotes; }

    public String getClientStateCode() { return clientStateCode; }
    public void setClientStateCode(String clientStateCode) { this.clientStateCode = clientStateCode; }
}
