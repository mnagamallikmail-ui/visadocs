package com.provaluer.dto;

import java.util.Map;

public class DiagnosticsResponse {
    private String status;
    private double cpuUsagePercent;
    private long totalMemoryMb;
    private long freeMemoryMb;
    private long maxMemoryMb;
    private long totalDiskGb;
    private long freeDiskGb;
    private boolean databaseConnected;
    private int activeTemplateProcessingJobs;
    private Map<String, Object> extraInfo;

    public DiagnosticsResponse() {}

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public double getCpuUsagePercent() { return cpuUsagePercent; }
    public void setCpuUsagePercent(double cpuUsagePercent) { this.cpuUsagePercent = cpuUsagePercent; }

    public long getTotalMemoryMb() { return totalMemoryMb; }
    public void setTotalMemoryMb(long totalMemoryMb) { this.totalMemoryMb = totalMemoryMb; }

    public long getFreeMemoryMb() { return freeMemoryMb; }
    public void setFreeMemoryMb(long freeMemoryMb) { this.freeMemoryMb = freeMemoryMb; }

    public long getMaxMemoryMb() { return maxMemoryMb; }
    public void setMaxMemoryMb(long maxMemoryMb) { this.maxMemoryMb = maxMemoryMb; }

    public long getTotalDiskGb() { return totalDiskGb; }
    public void setTotalDiskGb(long totalDiskGb) { this.totalDiskGb = totalDiskGb; }

    public long getFreeDiskGb() { return freeDiskGb; }
    public void setFreeDiskGb(long freeDiskGb) { this.freeDiskGb = freeDiskGb; }

    public boolean isDatabaseConnected() { return databaseConnected; }
    public void setDatabaseConnected(boolean databaseConnected) { this.databaseConnected = databaseConnected; }

    public int getActiveTemplateProcessingJobs() { return activeTemplateProcessingJobs; }
    public void setActiveTemplateProcessingJobs(int activeTemplateProcessingJobs) { this.activeTemplateProcessingJobs = activeTemplateProcessingJobs; }

    public Map<String, Object> getExtraInfo() { return extraInfo; }
    public void setExtraInfo(Map<String, Object> extraInfo) { this.extraInfo = extraInfo; }
}
