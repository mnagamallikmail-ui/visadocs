package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "inspection_photos")
public class InspectionPhoto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "inspection_id", nullable = false)
    private Long inspectionId;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "pa_id", nullable = false)
    private Long paId;

    @Column(nullable = false, length = 32)
    private String category;

    @Column(nullable = false, length = 500)
    private String filename;

    @Column(name = "file_size_bytes")
    private Long fileSizeBytes;

    @Column(name = "mime_type", length = 32)
    private String mimeType;

    @Column(name = "file_content", columnDefinition = "bytea")
    private byte[] fileContent;

    @Column(name = "md5_hash", length = 64)
    private String md5Hash;

    // GPS at photo capture
    @Column(name = "gps_lat", precision = 10, scale = 7)
    private BigDecimal gpsLat;

    @Column(name = "gps_lng", precision = 10, scale = 7)
    private BigDecimal gpsLng;

    @Column(name = "gps_accuracy")
    private Float gpsAccuracy;

    // Device metadata
    @Column(name = "device_timestamp")
    private LocalDateTime deviceTimestamp;

    @Column(name = "capture_sequence")
    private Integer captureSequence;

    // Audit
    @Column(name = "uploaded_at", nullable = false)
    private LocalDateTime uploadedAt = LocalDateTime.now();

    @Column(name = "uploaded_by", nullable = false)
    private Long uploadedBy;

    @Column(name = "is_deleted", nullable = false)
    private boolean isDeleted = false;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @Column(name = "deleted_by")
    private Long deletedBy;

    @Column(name = "delete_reason", length = 1000)
    private String deleteReason;

    @Column(name = "storage_key", length = 1000)
    private String storageKey;

    public InspectionPhoto() {}

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

    public byte[] getFileContent() { return fileContent; }
    public void setFileContent(byte[] fileContent) { this.fileContent = fileContent; }

    public String getMd5Hash() { return md5Hash; }
    public void setMd5Hash(String md5Hash) { this.md5Hash = md5Hash; }

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

    public boolean isDeleted() { return isDeleted; }
    public void setDeleted(boolean deleted) { isDeleted = deleted; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public Long getDeletedBy() { return deletedBy; }
    public void setDeletedBy(Long deletedBy) { this.deletedBy = deletedBy; }

    public String getDeleteReason() { return deleteReason; }
    public void setDeleteReason(String deleteReason) { this.deleteReason = deleteReason; }

    public String getStorageKey() { return storageKey; }
    public void setStorageKey(String storageKey) { this.storageKey = storageKey; }
}
