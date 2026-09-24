package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "seo_sync_logs")
public class SeoSyncLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String provider; // 'GSC', 'BING', 'COMPOSITE'

    @Column(nullable = false, length = 50)
    private String status; // 'SUCCESS', 'FAILED', 'IN_PROGRESS'

    @Column(columnDefinition = "TEXT")
    private String message;

    @Column(name = "items_synced", nullable = false)
    private Integer itemsSynced = 0;

    @Column(name = "duration_ms", nullable = false)
    private Long durationMs = 0L;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public SeoSyncLog() {}

    public SeoSyncLog(String provider, String status, String message, Integer itemsSynced, Long durationMs) {
        this.provider = provider;
        this.status = status;
        this.message = message;
        this.itemsSynced = itemsSynced != null ? itemsSynced : 0;
        this.durationMs = durationMs != null ? durationMs : 0L;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public Integer getItemsSynced() { return itemsSynced; }
    public void setItemsSynced(Integer itemsSynced) { this.itemsSynced = itemsSynced; }

    public Long getDurationMs() { return durationMs; }
    public void setDurationMs(Long durationMs) { this.durationMs = durationMs; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
