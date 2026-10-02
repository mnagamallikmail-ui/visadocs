package com.provaluer.dto;

import java.math.BigDecimal;

public class CompleteInspectionRequest {

    private String inspectionRemarks;
    private String visitStatus; // COMPLETED | PARTIAL | ABORTED
    private BigDecimal gpsLat;
    private BigDecimal gpsLng;
    private Float gpsAccuracy;

    public CompleteInspectionRequest() {}

    public String getInspectionRemarks() { return inspectionRemarks; }
    public void setInspectionRemarks(String inspectionRemarks) { this.inspectionRemarks = inspectionRemarks; }

    public String getVisitStatus() { return visitStatus; }
    public void setVisitStatus(String visitStatus) { this.visitStatus = visitStatus; }

    public BigDecimal getGpsLat() { return gpsLat; }
    public void setGpsLat(BigDecimal gpsLat) { this.gpsLat = gpsLat; }

    public BigDecimal getGpsLng() { return gpsLng; }
    public void setGpsLng(BigDecimal gpsLng) { this.gpsLng = gpsLng; }

    public Float getGpsAccuracy() { return gpsAccuracy; }
    public void setGpsAccuracy(Float gpsAccuracy) { this.gpsAccuracy = gpsAccuracy; }
}
