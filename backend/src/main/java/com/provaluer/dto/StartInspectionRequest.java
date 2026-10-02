package com.provaluer.dto;

import java.math.BigDecimal;

public class StartInspectionRequest {

    private BigDecimal gpsLat;
    private BigDecimal gpsLng;
    private Float gpsAccuracy;
    private Boolean accessConfirmed;
    private String accessNotes;

    public StartInspectionRequest() {}

    public BigDecimal getGpsLat() { return gpsLat; }
    public void setGpsLat(BigDecimal gpsLat) { this.gpsLat = gpsLat; }

    public BigDecimal getGpsLng() { return gpsLng; }
    public void setGpsLng(BigDecimal gpsLng) { this.gpsLng = gpsLng; }

    public Float getGpsAccuracy() { return gpsAccuracy; }
    public void setGpsAccuracy(Float gpsAccuracy) { this.gpsAccuracy = gpsAccuracy; }

    public Boolean getAccessConfirmed() { return accessConfirmed; }
    public void setAccessConfirmed(Boolean accessConfirmed) { this.accessConfirmed = accessConfirmed; }

    public String getAccessNotes() { return accessNotes; }
    public void setAccessNotes(String accessNotes) { this.accessNotes = accessNotes; }
}
