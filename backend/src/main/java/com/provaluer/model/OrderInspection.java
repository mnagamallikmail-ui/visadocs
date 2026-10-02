package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(name = "order_inspections")
public class OrderInspection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false, unique = true)
    private Long orderId;

    @Column(name = "pa_id", nullable = false)
    private Long paId;

    // Scheduling
    @Column(name = "inspection_date")
    private LocalDate inspectionDate;

    @Column(name = "inspection_time")
    private LocalTime inspectionTime;

    @Column(name = "site_contact_name", length = 200)
    private String siteContactName;

    @Column(name = "site_contact_number", length = 20)
    private String siteContactNumber;

    @Column(name = "alt_contact_name", length = 200)
    private String altContactName;

    @Column(name = "alt_contact_number", length = 20)
    private String altContactNumber;

    @Column(name = "property_access_notes", columnDefinition = "TEXT")
    private String propertyAccessNotes;

    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "schedule_history", columnDefinition = "JSONB")
    private String scheduleHistory = "[]";

    // Visit Execution
    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    // GPS at start
    @Column(name = "gps_lat_start", precision = 10, scale = 7)
    private BigDecimal gpsLatStart;

    @Column(name = "gps_lng_start", precision = 10, scale = 7)
    private BigDecimal gpsLngStart;

    @Column(name = "gps_accuracy_start")
    private Float gpsAccuracyStart;

    // GPS at completion
    @Column(name = "gps_lat_end", precision = 10, scale = 7)
    private BigDecimal gpsLatEnd;

    @Column(name = "gps_lng_end", precision = 10, scale = 7)
    private BigDecimal gpsLngEnd;

    @Column(name = "gps_accuracy_end")
    private Float gpsAccuracyEnd;

    // Visit Outcome
    @Column(name = "visit_status", length = 32)
    private String visitStatus; // COMPLETED, PARTIAL, ABORTED

    @Column(name = "inspection_remarks", columnDefinition = "TEXT")
    private String inspectionRemarks;

    @Column(name = "access_confirmed")
    private Boolean accessConfirmed = true;

    @Column(name = "access_notes", columnDefinition = "TEXT")
    private String accessNotes;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public OrderInspection() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public Long getPaId() { return paId; }
    public void setPaId(Long paId) { this.paId = paId; }

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

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
