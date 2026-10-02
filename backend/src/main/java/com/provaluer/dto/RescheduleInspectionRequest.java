package com.provaluer.dto;

import java.time.LocalDate;
import java.time.LocalTime;
import com.fasterxml.jackson.annotation.JsonFormat;

public class RescheduleInspectionRequest {

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate newInspectionDate;

    @JsonFormat(pattern = "HH:mm")
    private LocalTime newInspectionTime;

    private String rescheduleReason;
    private String siteContactName;
    private String siteContactNumber;

    public RescheduleInspectionRequest() {}

    public LocalDate getNewInspectionDate() { return newInspectionDate; }
    public void setNewInspectionDate(LocalDate newInspectionDate) { this.newInspectionDate = newInspectionDate; }

    public LocalTime getNewInspectionTime() { return newInspectionTime; }
    public void setNewInspectionTime(LocalTime newInspectionTime) { this.newInspectionTime = newInspectionTime; }

    public String getRescheduleReason() { return rescheduleReason; }
    public void setRescheduleReason(String rescheduleReason) { this.rescheduleReason = rescheduleReason; }

    public String getSiteContactName() { return siteContactName; }
    public void setSiteContactName(String siteContactName) { this.siteContactName = siteContactName; }

    public String getSiteContactNumber() { return siteContactNumber; }
    public void setSiteContactNumber(String siteContactNumber) { this.siteContactNumber = siteContactNumber; }
}
