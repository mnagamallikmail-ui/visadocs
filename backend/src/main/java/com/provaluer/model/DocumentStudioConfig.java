package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "document_studio_configs")
public class DocumentStudioConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "template_id", nullable = false, unique = true)
    private Long templateId;

    @Column(name = "custom_labels", nullable = false, columnDefinition = "TEXT")
    private String customLabels = "{}";

    @Column(name = "table_configs", nullable = false, columnDefinition = "TEXT")
    private String tableConfigs = "[]";

    @Column(name = "updated_by")
    private Long updatedBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public DocumentStudioConfig() {}

    public DocumentStudioConfig(Long templateId, String customLabels, String tableConfigs, Long updatedBy) {
        this.templateId = templateId;
        this.customLabels = (customLabels != null) ? customLabels : "{}";
        this.tableConfigs = (tableConfigs != null) ? tableConfigs : "[]";
        this.updatedBy = updatedBy;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void onPreUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getTemplateId() {
        return templateId;
    }

    public void setTemplateId(Long templateId) {
        this.templateId = templateId;
    }

    public String getCustomLabels() {
        return customLabels;
    }

    public void setCustomLabels(String customLabels) {
        this.customLabels = customLabels;
    }

    public String getTableConfigs() {
        return tableConfigs;
    }

    public void setTableConfigs(String tableConfigs) {
        this.tableConfigs = tableConfigs;
    }

    public Long getUpdatedBy() {
        return updatedBy;
    }

    public void setUpdatedBy(Long updatedBy) {
        this.updatedBy = updatedBy;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
