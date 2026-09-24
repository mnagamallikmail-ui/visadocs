package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "seo_crawl_errors")
public class SeoCrawlError {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 500)
    private String url;

    @Column(nullable = false, length = 50)
    private String source; // 'BING', 'GSC'

    @Column(name = "error_type", nullable = false, length = 100)
    private String errorType;

    @Column(name = "http_status")
    private Integer httpStatus;

    @Column(name = "detected_at", nullable = false)
    private LocalDateTime detectedAt = LocalDateTime.now();

    @Column(nullable = false)
    private Boolean resolved = false;

    @Column(name = "resolution_notes", columnDefinition = "TEXT")
    private String resolutionNotes;

    public SeoCrawlError() {}

    public SeoCrawlError(String url, String source, String errorType, Integer httpStatus) {
        this.url = url;
        this.source = source;
        this.errorType = errorType;
        this.httpStatus = httpStatus;
        this.detectedAt = LocalDateTime.now();
        this.resolved = false;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }

    public String getErrorType() { return errorType; }
    public void setErrorType(String errorType) { this.errorType = errorType; }

    public Integer getHttpStatus() { return httpStatus; }
    public void setHttpStatus(Integer httpStatus) { this.httpStatus = httpStatus; }

    public LocalDateTime getDetectedAt() { return detectedAt; }
    public void setDetectedAt(LocalDateTime detectedAt) { this.detectedAt = detectedAt; }

    public Boolean getResolved() { return resolved; }
    public void setResolved(Boolean resolved) { this.resolved = resolved; }

    public String getResolutionNotes() { return resolutionNotes; }
    public void setResolutionNotes(String resolutionNotes) { this.resolutionNotes = resolutionNotes; }
}
