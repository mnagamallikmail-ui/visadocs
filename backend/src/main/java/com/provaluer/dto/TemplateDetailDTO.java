package com.provaluer.dto;

import com.provaluer.model.Template;
import java.time.LocalDateTime;

public class TemplateDetailDTO {
    private Long id;
    private String name;
    private String fieldMapping;
    private String isActive;
    private String status;
    private String documentDom;
    private String placeholderRegistry;
    private int version;
    private String processingError;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public TemplateDetailDTO() {}

    public TemplateDetailDTO(Template template) {
        this.id = template.getId();
        this.name = template.getName();
        this.fieldMapping = template.getFieldMapping();
        this.isActive = template.getIsActive();
        this.status = template.getStatus();
        this.documentDom = template.getDocumentDom();
        this.placeholderRegistry = template.getPlaceholderRegistry();
        this.version = template.getVersion();
        this.processingError = template.getProcessingError();
        this.createdAt = template.getCreatedAt();
        this.updatedAt = template.getUpdatedAt();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getFieldMapping() { return fieldMapping; }
    public void setFieldMapping(String fieldMapping) { this.fieldMapping = fieldMapping; }

    public String getIsActive() { return isActive; }
    public void setIsActive(String isActive) { this.isActive = isActive; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getDocumentDom() { return documentDom; }
    public void setDocumentDom(String documentDom) { this.documentDom = documentDom; }

    public String getPlaceholderRegistry() { return placeholderRegistry; }
    public void setPlaceholderRegistry(String placeholderRegistry) { this.placeholderRegistry = placeholderRegistry; }

    public int getVersion() { return version; }
    public void setVersion(int version) { this.version = version; }

    public String getProcessingError() { return processingError; }
    public void setProcessingError(String processingError) { this.processingError = processingError; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
