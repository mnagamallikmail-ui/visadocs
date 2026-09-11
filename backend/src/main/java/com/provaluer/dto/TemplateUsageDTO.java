package com.provaluer.dto;

import java.util.List;
import java.util.Map;

public class TemplateUsageDTO {
    private Long templateId;
    private String templateName;
    private String templateCode;
    private int currentVersion;
    private String status;
    private long totalReportsCount;
    private long draftReportsCount;
    private long submittedReportsCount;
    private boolean canPermanentlyDelete;
    private List<Map<String, Object>> versionBreakdown;

    public TemplateUsageDTO() {}

    public TemplateUsageDTO(Long templateId, String templateName, String templateCode, int currentVersion, String status,
                            long totalReportsCount, long draftReportsCount, long submittedReportsCount,
                            boolean canPermanentlyDelete, List<Map<String, Object>> versionBreakdown) {
        this.templateId = templateId;
        this.templateName = templateName;
        this.templateCode = templateCode;
        this.currentVersion = currentVersion;
        this.status = status;
        this.totalReportsCount = totalReportsCount;
        this.draftReportsCount = draftReportsCount;
        this.submittedReportsCount = submittedReportsCount;
        this.canPermanentlyDelete = canPermanentlyDelete;
        this.versionBreakdown = versionBreakdown;
    }

    public Long getTemplateId() { return templateId; }
    public void setTemplateId(Long templateId) { this.templateId = templateId; }

    public String getTemplateName() { return templateName; }
    public void setTemplateName(String templateName) { this.templateName = templateName; }

    public String getTemplateCode() { return templateCode; }
    public void setTemplateCode(String templateCode) { this.templateCode = templateCode; }

    public int getCurrentVersion() { return currentVersion; }
    public void setCurrentVersion(int currentVersion) { this.currentVersion = currentVersion; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public long getTotalReportsCount() { return totalReportsCount; }
    public void setTotalReportsCount(long totalReportsCount) { this.totalReportsCount = totalReportsCount; }

    public long getDraftReportsCount() { return draftReportsCount; }
    public void setDraftReportsCount(long draftReportsCount) { this.draftReportsCount = draftReportsCount; }

    public long getSubmittedReportsCount() { return submittedReportsCount; }
    public void setSubmittedReportsCount(long submittedReportsCount) { this.submittedReportsCount = submittedReportsCount; }

    public boolean isCanPermanentlyDelete() { return canPermanentlyDelete; }
    public void setCanPermanentlyDelete(boolean canPermanentlyDelete) { this.canPermanentlyDelete = canPermanentlyDelete; }

    public List<Map<String, Object>> getVersionBreakdown() { return versionBreakdown; }
    public void setVersionBreakdown(List<Map<String, Object>> versionBreakdown) { this.versionBreakdown = versionBreakdown; }
}
