package com.provaluer.dto;

import java.io.Serializable;
import java.util.Map;

public class DocumentWorkspaceResponse implements Serializable {
    private static final long serialVersionUID = 1L;

    private Long orderId;
    private String status;
    private String reportNumber;
    private VisualPreviewResponse visualPreview;
    private Map<String, String> values;
    private boolean readOnly;

    public DocumentWorkspaceResponse() {}

    public DocumentWorkspaceResponse(Long orderId, String status, String reportNumber,
                                     VisualPreviewResponse visualPreview, Map<String, String> values, boolean readOnly) {
        this.orderId = orderId;
        this.status = status;
        this.reportNumber = reportNumber;
        this.visualPreview = visualPreview;
        this.values = values;
        this.readOnly = readOnly;
    }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getReportNumber() { return reportNumber; }
    public void setReportNumber(String reportNumber) { this.reportNumber = reportNumber; }

    public VisualPreviewResponse getVisualPreview() { return visualPreview; }
    public void setVisualPreview(VisualPreviewResponse visualPreview) { this.visualPreview = visualPreview; }

    public Map<String, String> getValues() { return values; }
    public void setValues(Map<String, String> values) { this.values = values; }

    public boolean isReadOnly() { return readOnly; }
    public void setReadOnly(boolean readOnly) { this.readOnly = readOnly; }
}
