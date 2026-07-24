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
}
