package com.provaluer.dto;

import com.provaluer.model.Template;
import java.time.LocalDateTime;

public class TemplateListDTO {
    private Long id;
    private String name;
    private String status;
    private int version;
    private String isActive;
    private String processingError;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public TemplateListDTO() {}

    public TemplateListDTO(Template template) {
        this.id = template.getId();
        this.name = template.getName();
        this.status = template.getStatus();
        this.version = template.getVersion();
        this.isActive = template.getIsActive();
        this.processingError = template.getProcessingError();
        this.createdAt = template.getCreatedAt();
        this.updatedAt = template.getUpdatedAt();
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

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
