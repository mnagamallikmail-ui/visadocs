package com.provaluer.dto;

import java.time.LocalDate;
import java.time.LocalTime;
import com.fasterxml.jackson.annotation.JsonFormat;

public class ScheduleInspectionRequest {

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate inspectionDate;

    @JsonFormat(pattern = "HH:mm")
    private LocalTime inspectionTime;

    private String siteContactName;
    private String siteContactNumber;
    private String altContactName;
    private String altContactNumber;
    private String propertyAccessNotes;

    public ScheduleInspectionRequest() {}

    public LocalDate getInspectionDate() { return inspectionDate; }
    public void setInspectionDate(LocalDate inspectionDate) { this.inspectionDate = inspectionDate; }

    public LocalTime getInspectionTime() { return inspectionTime; }
    public void setInspectionTime(LocalTime inspectionTime) { this.inspectionTime = inspectionTime; }

    public String getSiteContactName() { return siteContactName; }
    public void setSiteContactName(String siteContactName) { this.siteContactName = siteContactName; }

    public String getSiteContactNumber() { return siteContactNumber; }
    public void setSiteContactNumber(String siteContactNumber) { this.siteContactNumber = siteContactNumber; }

    public String getAltContactName() { return altContactName; }
    public void setAltContactName(String altContactName) { this.altContactName = altContactName; }

    public String getAltContactNumber() { return altContactNumber; }
    public void setAltContactNumber(String altContactNumber) { this.altContactNumber = altContactNumber; }

    public String getPropertyAccessNotes() { return propertyAccessNotes; }
    public void setPropertyAccessNotes(String propertyAccessNotes) { this.propertyAccessNotes = propertyAccessNotes; }
}
