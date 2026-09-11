package com.provaluer.dto;

import com.provaluer.model.Template;
import java.time.LocalDateTime;

public class TemplateListDTO {
    private Long id;
    private String code;
    private String name;
    private String status;
    private int version;
    private String isActive;
    private String processingError;
    private long totalReportsCount;
    private long draftReportsCount;
    private long submittedReportsCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime deletedAt;

    public TemplateListDTO() {}

    public TemplateListDTO(Template template) {
        this(template, 0, 0, 0);
    }

    public TemplateListDTO(Template template, long totalReportsCount, long draftReportsCount, long submittedReportsCount) {
        this.id = template.getId();
        this.code = template.getCode();
        this.name = template.getName();
        this.status = template.getStatus();
        this.version = template.getVersion();
        this.isActive = template.getIsActive();
        this.processingError = template.getProcessingError();
        this.totalReportsCount = totalReportsCount;
        this.draftReportsCount = draftReportsCount;
        this.submittedReportsCount = submittedReportsCount;
        this.createdAt = template.getCreatedAt();
        this.updatedAt = template.getUpdatedAt();
        this.deletedAt = template.getDeletedAt();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public int getVersion() { return version; }
    public void setVersion(int version) { this.version = version; }

    public String getIsActive() { return isActive; }
    public void setIsActive(String isActive) { this.isActive = isActive; }

    public String getProcessingError() { return processingError; }
    public void setProcessingError(String processingError) { this.processingError = processingError; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public long getTotalReportsCount() { return totalReportsCount; }
    public void setTotalReportsCount(long totalReportsCount) { this.totalReportsCount = totalReportsCount; }

    public long getDraftReportsCount() { return draftReportsCount; }
    public void setDraftReportsCount(long draftReportsCount) { this.draftReportsCount = draftReportsCount; }

    public long getSubmittedReportsCount() { return submittedReportsCount; }
    public void setSubmittedReportsCount(long submittedReportsCount) { this.submittedReportsCount = submittedReportsCount; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
