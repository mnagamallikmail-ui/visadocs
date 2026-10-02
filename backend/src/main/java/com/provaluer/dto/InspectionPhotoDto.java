package com.provaluer.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class InspectionPhotoDto {

    private Long id;
    private Long inspectionId;
    private Long orderId;
    private Long paId;
    private String category;
    private String filename;
    private Long fileSizeBytes;
    private String mimeType;
    private BigDecimal gpsLat;
    private BigDecimal gpsLng;
    private Float gpsAccuracy;
    private LocalDateTime deviceTimestamp;
    private Integer captureSequence;
    private LocalDateTime uploadedAt;
    private Long uploadedBy;
    private String downloadUrl;

    public InspectionPhotoDto() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getInspectionId() { return inspectionId; }
    public void setInspectionId(Long inspectionId) { this.inspectionId = inspectionId; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public Long getPaId() { return paId; }
    public void setPaId(Long paId) { this.paId = paId; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getFilename() { return filename; }
    public void setFilename(String filename) { this.filename = filename; }

    public Long getFileSizeBytes() { return fileSizeBytes; }
    public void setFileSizeBytes(Long fileSizeBytes) { this.fileSizeBytes = fileSizeBytes; }

    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }

    public BigDecimal getGpsLat() { return gpsLat; }
    public void setGpsLat(BigDecimal gpsLat) { this.gpsLat = gpsLat; }

    public BigDecimal getGpsLng() { return gpsLng; }
    public void setGpsLng(BigDecimal gpsLng) { this.gpsLng = gpsLng; }

    public Float getGpsAccuracy() { return gpsAccuracy; }
    public void setGpsAccuracy(Float gpsAccuracy) { this.gpsAccuracy = gpsAccuracy; }

    public LocalDateTime getDeviceTimestamp() { return deviceTimestamp; }
    public void setDeviceTimestamp(LocalDateTime deviceTimestamp) { this.deviceTimestamp = deviceTimestamp; }

    public Integer getCaptureSequence() { return captureSequence; }
    public void setCaptureSequence(Integer captureSequence) { this.captureSequence = captureSequence; }

    public LocalDateTime getUploadedAt() { return uploadedAt; }
    public void setUploadedAt(LocalDateTime uploadedAt) { this.uploadedAt = uploadedAt; }

    public Long getUploadedBy() { return uploadedBy; }
    public void setUploadedBy(Long uploadedBy) { this.uploadedBy = uploadedBy; }

    public String getDownloadUrl() { return downloadUrl; }
    public void setDownloadUrl(String downloadUrl) { this.downloadUrl = downloadUrl; }
}
