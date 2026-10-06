package com.provaluer.dto;

import java.time.LocalDateTime;

public class TelemetryErrorDTO {
    private String timestamp;
    private Long userId;
    private Long orderId;
    private String reportNumber;
    private String screen;
    private String action;
    private String stackTrace;
    private String requestId;
    private String severity; // INFO, WARN, ERROR, CRITICAL
    private String errorMessage;
    private Integer statusCode;

    public TelemetryErrorDTO() {
        this.timestamp = LocalDateTime.now().toString();
    }

    public TelemetryErrorDTO(Long userId, Long orderId, String reportNumber, String screen,
                             String action, String errorMessage, String stackTrace,
                             String requestId, String severity, Integer statusCode) {
        this.timestamp = LocalDateTime.now().toString();
        this.userId = userId;
        this.orderId = orderId;
        this.reportNumber = reportNumber;
        this.screen = screen;
        this.action = action;
        this.errorMessage = errorMessage;
        this.stackTrace = stackTrace;
        this.requestId = requestId;
        this.severity = severity != null ? severity : "ERROR";
        this.statusCode = statusCode;
    }

    public String getTimestamp() { return timestamp; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getReportNumber() { return reportNumber; }
    public void setReportNumber(String reportNumber) { this.reportNumber = reportNumber; }

    public String getScreen() { return screen; }
    public void setScreen(String screen) { this.screen = screen; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getStackTrace() { return stackTrace; }
    public void setStackTrace(String stackTrace) { this.stackTrace = stackTrace; }

    public String getRequestId() { return requestId; }
    public void setRequestId(String requestId) { this.requestId = requestId; }

    public String getSeverity() { return severity; }
    public void setSeverity(String severity) { this.severity = severity; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public Integer getStatusCode() { return statusCode; }
    public void setStatusCode(Integer statusCode) { this.statusCode = statusCode; }
}
