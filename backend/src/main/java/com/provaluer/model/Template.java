package com.provaluer.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "templates")
public class Template {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @JsonIgnore
    @Column(name = "template_content", columnDefinition = "BYTEA", nullable = false)
    private byte[] templateContent;

    public static final String STATUS_DRAFT = "DRAFT";
    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_ARCHIVED = "ARCHIVED";
    public static final String STATUS_DELETED = "DELETED";

    @Column(name = "code", length = 50)
    private String code = "COMM_VAL_STD";

    @Column(name = "field_mapping", nullable = false, columnDefinition = "TEXT")
    private String fieldMapping;

    @Column(name = "is_active", nullable = false, length = 1)
    private String isActive = "Y";

    @Column(name = "status", nullable = false)
    private String status = STATUS_DRAFT;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "document_dom", columnDefinition = "JSONB")
    private String documentDom;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "placeholder_registry", columnDefinition = "JSONB")
    private String placeholderRegistry;

    @Column(name = "version", nullable = false)
    private int version = 1;

    @Column(name = "processing_error", columnDefinition = "TEXT")
    private String processingError;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public Template() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public byte[] getTemplateContent() { return templateContent; }
    public void setTemplateContent(byte[] templateContent) { this.templateContent = templateContent; }

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

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
