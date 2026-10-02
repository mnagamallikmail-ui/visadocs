package com.provaluer.dto;

public class BindTemplateRequest {
    private Long templateId;
    private Boolean forceSnapshotRebuild = false;

    public BindTemplateRequest() {}

    public BindTemplateRequest(Long templateId, Boolean forceSnapshotRebuild) {
        this.templateId = templateId;
        this.forceSnapshotRebuild = forceSnapshotRebuild;
    }

    public Long getTemplateId() {
        return templateId;
    }

    public void setTemplateId(Long templateId) {
        this.templateId = templateId;
    }

    public Boolean getForceSnapshotRebuild() {
        return forceSnapshotRebuild;
    }

    public void setForceSnapshotRebuild(Boolean forceSnapshotRebuild) {
        this.forceSnapshotRebuild = forceSnapshotRebuild;
    }
}
