package com.provaluer.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "template_versions")
public class TemplateVersion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "template_id", nullable = false)
    private Long templateId;

    @Column(nullable = false)
    private int version;

    @Column(nullable = false)
    private String name;

    @JsonIgnore
    @Column(name = "template_content", columnDefinition = "BYTEA", nullable = false)
    private byte[] templateContent;

    @Column(name = "field_mapping", nullable = false, columnDefinition = "TEXT")
    private String fieldMapping;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "document_dom", columnDefinition = "JSONB")
    private String documentDom;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "placeholder_registry", columnDefinition = "JSONB")
    private String placeholderRegistry;

    @Column(name = "change_summary", length = 500)
    private String changeSummary;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "created_by")
    private Long createdBy;

    public TemplateVersion() {}

    public TemplateVersion(Template template, String changeSummary, Long createdBy) {
        this.templateId = template.getId();
        this.version = template.getVersion();
        this.name = template.getName();
        this.templateContent = template.getTemplateContent();
        this.fieldMapping = template.getFieldMapping();
        this.documentDom = template.getDocumentDom();
        this.placeholderRegistry = template.getPlaceholderRegistry();
        this.changeSummary = changeSummary;
        this.createdAt = LocalDateTime.now();
        this.createdBy = createdBy;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getTemplateId() { return templateId; }
    public void setTemplateId(Long templateId) { this.templateId = templateId; }

    public int getVersion() { return version; }
    public void setVersion(int version) { this.version = version; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public byte[] getTemplateContent() { return templateContent; }
    public void setTemplateContent(byte[] templateContent) { this.templateContent = templateContent; }

    public String getFieldMapping() { return fieldMapping; }
    public void setFieldMapping(String fieldMapping) { this.fieldMapping = fieldMapping; }

    public String getDocumentDom() { return documentDom; }
    public void setDocumentDom(String documentDom) { this.documentDom = documentDom; }

    public String getPlaceholderRegistry() { return placeholderRegistry; }
    public void setPlaceholderRegistry(String placeholderRegistry) { this.placeholderRegistry = placeholderRegistry; }

    public String getChangeSummary() { return changeSummary; }
    public void setChangeSummary(String changeSummary) { this.changeSummary = changeSummary; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public Long getCreatedBy() { return createdBy; }
    public void setCreatedBy(Long createdBy) { this.createdBy = createdBy; }
}
