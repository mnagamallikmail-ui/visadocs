package com.provaluer.dto;

import java.io.Serializable;
import java.util.Map;

public class SaveDocumentValuesRequest implements Serializable {
    private static final long serialVersionUID = 1L;

    private Map<String, String> values;
    private Integer workspaceRevision;

    public SaveDocumentValuesRequest() {}

    public SaveDocumentValuesRequest(Map<String, String> values) {
        this.values = values;
    }

    public SaveDocumentValuesRequest(Map<String, String> values, Integer workspaceRevision) {
        this.values = values;
        this.workspaceRevision = workspaceRevision;
    }

    public Map<String, String> getValues() { return values; }
    public void setValues(Map<String, String> values) { this.values = values; }

    public Integer getWorkspaceRevision() { return workspaceRevision; }
    public void setWorkspaceRevision(Integer workspaceRevision) { this.workspaceRevision = workspaceRevision; }
}
