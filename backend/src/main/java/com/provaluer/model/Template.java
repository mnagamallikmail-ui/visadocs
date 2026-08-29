package com.provaluer.model;

import jakarta.persistence.*;

@Entity
@Table(name = "templates")
public class Template {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(name = "template_content", columnDefinition = "BYTEA", nullable = false)
    private byte[] templateContent;

    @Column(name = "field_mapping", nullable = false, columnDefinition = "TEXT")
    private String fieldMapping;

    @Column(name = "is_active", nullable = false, length = 1)
    private String isActive = "Y";

    @Column(name = "status", nullable = false)
    private String status = "PENDING";

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "document_dom", columnDefinition = "JSONB")
    private String documentDom;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "placeholder_registry", columnDefinition = "JSONB")
    private String placeholderRegistry;

    @Column(name = "version", nullable = false)
    private int version = 1;

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
}
