package com.provaluer.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

public class InspectionSummaryDto {

    private Long orderId;
    private String referenceCode;
    private String orderStatus;
    private Long inspectionId;
    private Long paId;
    private String paName;

    // Scheduling
    private LocalDate inspectionDate;
    private LocalTime inspectionTime;
    private String siteContactName;
    private String siteContactNumber;
    private String altContactName;
    private String altContactNumber;
    private String propertyAccessNotes;
    private LocalDateTime scheduledAt;
    private String scheduleHistory;

    // Execution
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private BigDecimal gpsLatStart;
    private BigDecimal gpsLngStart;
    private Float gpsAccuracyStart;
    private BigDecimal gpsLatEnd;
    private BigDecimal gpsLngEnd;
    private Float gpsAccuracyEnd;

    // Outcome
    private String visitStatus;
    private String inspectionRemarks;
    private Boolean accessConfirmed;
    private String accessNotes;

    // Photos
    private int totalPhotos;
    private boolean readyForCompletion;
    private List<PhotoCategoryStatusDto> categoryStatuses = new ArrayList<>();
    private List<InspectionPhotoDto> photos = new ArrayList<>();

    public InspectionSummaryDto() {}

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getReferenceCode() { return referenceCode; }
    public void setReferenceCode(String referenceCode) { this.referenceCode = referenceCode; }

    public String getOrderStatus() { return orderStatus; }
    public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; }

    public Long getInspectionId() { return inspectionId; }
    public void setInspectionId(Long inspectionId) { this.inspectionId = inspectionId; }

    public Long getPaId() { return paId; }
    public void setPaId(Long paId) { this.paId = paId; }

    public String getPaName() { return paName; }
    public void setPaName(String paName) { this.paName = paName; }

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

    public LocalDateTime getScheduledAt() { return scheduledAt; }
    public void setScheduledAt(LocalDateTime scheduledAt) { this.scheduledAt = scheduledAt; }

    public String getScheduleHistory() { return scheduleHistory; }
    public void setScheduleHistory(String scheduleHistory) { this.scheduleHistory = scheduleHistory; }

    public LocalDateTime getStartedAt() { return startedAt; }
    public void setStartedAt(LocalDateTime startedAt) { this.startedAt = startedAt; }

    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }

    public BigDecimal getGpsLatStart() { return gpsLatStart; }
    public void setGpsLatStart(BigDecimal gpsLatStart) { this.gpsLatStart = gpsLatStart; }

    public BigDecimal getGpsLngStart() { return gpsLngStart; }
    public void setGpsLngStart(BigDecimal gpsLngStart) { this.gpsLngStart = gpsLngStart; }

    public Float getGpsAccuracyStart() { return gpsAccuracyStart; }
    public void setGpsAccuracyStart(Float gpsAccuracyStart) { this.gpsAccuracyStart = gpsAccuracyStart; }

    public BigDecimal getGpsLatEnd() { return gpsLatEnd; }
    public void setGpsLatEnd(BigDecimal gpsLatEnd) { this.gpsLatEnd = gpsLatEnd; }

    public BigDecimal getGpsLngEnd() { return gpsLngEnd; }
    public void setGpsLngEnd(BigDecimal gpsLngEnd) { this.gpsLngEnd = gpsLngEnd; }

    public Float getGpsAccuracyEnd() { return gpsAccuracyEnd; }
    public void setGpsAccuracyEnd(Float gpsAccuracyEnd) { this.gpsAccuracyEnd = gpsAccuracyEnd; }

    public String getVisitStatus() { return visitStatus; }
    public void setVisitStatus(String visitStatus) { this.visitStatus = visitStatus; }

    public String getInspectionRemarks() { return inspectionRemarks; }
    public void setInspectionRemarks(String inspectionRemarks) { this.inspectionRemarks = inspectionRemarks; }

    public Boolean getAccessConfirmed() { return accessConfirmed; }
    public void setAccessConfirmed(Boolean accessConfirmed) { this.accessConfirmed = accessConfirmed; }

    public String getAccessNotes() { return accessNotes; }
    public void setAccessNotes(String accessNotes) { this.accessNotes = accessNotes; }

    public int getTotalPhotos() { return totalPhotos; }
    public void setTotalPhotos(int totalPhotos) { this.totalPhotos = totalPhotos; }

    public boolean isReadyForCompletion() { return readyForCompletion; }
    public void setReadyForCompletion(boolean readyForCompletion) { this.readyForCompletion = readyForCompletion; }

    public List<PhotoCategoryStatusDto> getCategoryStatuses() { return categoryStatuses; }
    public void setCategoryStatuses(List<PhotoCategoryStatusDto> categoryStatuses) { this.categoryStatuses = categoryStatuses; }

    public List<InspectionPhotoDto> getPhotos() { return photos; }
    public void setPhotos(List<InspectionPhotoDto> photos) { this.photos = photos; }
}
