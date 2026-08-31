package com.provaluer.dto;

import com.provaluer.model.TemplateVersion;
import java.time.LocalDateTime;

public class TemplateVersionDTO {
    private Long id;
    private Long templateId;
    private int version;
    private String name;
    private String changeSummary;
    private LocalDateTime createdAt;
    private Long createdBy;

    public TemplateVersionDTO() {}

    public TemplateVersionDTO(TemplateVersion tv) {
        this.id = tv.getId();
        this.templateId = tv.getTemplateId();
        this.version = tv.getVersion();
        this.name = tv.getName();
        this.changeSummary = tv.getChangeSummary();
        this.createdAt = tv.getCreatedAt();
        this.createdBy = tv.getCreatedBy();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getTemplateId() { return templateId; }
    public void setTemplateId(Long templateId) { this.templateId = templateId; }

    public int getVersion() { return version; }
    public void setVersion(int version) { this.version = version; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getChangeSummary() { return changeSummary; }
    public void setChangeSummary(String changeSummary) { this.changeSummary = changeSummary; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public Long getCreatedBy() { return createdBy; }
    public void setCreatedBy(Long createdBy) { this.createdBy = createdBy; }
}
