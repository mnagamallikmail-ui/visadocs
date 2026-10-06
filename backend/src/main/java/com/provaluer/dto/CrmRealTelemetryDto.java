package com.provaluer.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

public class CrmRealTelemetryDto {
    private String source = "PostgreSQL (valuation_leads, lead_quotations, orders, transactions)";
    private String verificationStatus = "VERIFIED LIVE";
    private LocalDateTime lastUpdated = LocalDateTime.now();

    // 1. Google Analytics 4 Status
    private boolean ga4Connected = false;
    private String ga4Source = "Google Analytics 4 (GA4)";
    private String ga4Status = "NOT CONNECTED";
    private String ga4LastUpdated = null;
    private String ga4MeasurementId = null;

    // 2. Microsoft Clarity Status
    private boolean clarityConnected = false;
    private String claritySource = "Microsoft Clarity";
    private String clarityStatus = "NOT CONNECTED";
    private String clarityLastUpdated = null;
    private String clarityProjectId = null;

    // 3. Google Search Console Status
    private boolean gscConnected = false;
    private String gscSource = "Google Search Console API";
    private String gscStatus = "NOT CONNECTED";
    private String gscLastUpdated = null;
    private String gscPropertyId = "sc-domain:provaluer.in";
    private int gscTotalQueries = 0;
    private int gscTotalImpressions = 0;
    private int gscTotalClicks = 0;
    private BigDecimal gscAverageCtr = BigDecimal.ZERO;
    private BigDecimal gscAveragePosition = BigDecimal.ZERO;
    private int gscIndexedPages = 0;
    private java.util.List<Map<String, Object>> gscQueries = new java.util.ArrayList<>();
    private java.util.List<Map<String, Object>> gscPages = new java.util.ArrayList<>();

    // 4. PostgreSQL CRM Tables (Verified Live)
    private long totalLeads;
    private long newLeads;
    private long qualifiedLeads;
    private long urgentLeads;
    private Map<String, Long> leadsByService;
    private Map<String, Long> leadsByLocation;
    private Map<String, Long> leadsByStatus;

    // Quotations
    private long totalQuotes;
    private BigDecimal totalQuotedAmount;
    private long acceptedQuotes;

    // Orders & Revenue
    private long totalOrders;
    private long completedOrders;
    private BigDecimal realizedRevenue;

    public CrmRealTelemetryDto() {}

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }

    public String getVerificationStatus() { return verificationStatus; }
    public void setVerificationStatus(String verificationStatus) { this.verificationStatus = verificationStatus; }

    public LocalDateTime getLastUpdated() { return lastUpdated; }
    public void setLastUpdated(LocalDateTime lastUpdated) { this.lastUpdated = lastUpdated; }

    public boolean isGa4Connected() { return ga4Connected; }
    public void setGa4Connected(boolean ga4Connected) { this.ga4Connected = ga4Connected; }

    public String getGa4Source() { return ga4Source; }
    public void setGa4Source(String ga4Source) { this.ga4Source = ga4Source; }

    public String getGa4Status() { return ga4Status; }
    public void setGa4Status(String ga4Status) { this.ga4Status = ga4Status; }

    public String getGa4LastUpdated() { return ga4LastUpdated; }
    public void setGa4LastUpdated(String ga4LastUpdated) { this.ga4LastUpdated = ga4LastUpdated; }

    public String getGa4MeasurementId() { return ga4MeasurementId; }
    public void setGa4MeasurementId(String ga4MeasurementId) { this.ga4MeasurementId = ga4MeasurementId; }

    public boolean isClarityConnected() { return clarityConnected; }
    public void setClarityConnected(boolean clarityConnected) { this.clarityConnected = clarityConnected; }

    public String getClaritySource() { return claritySource; }
    public void setClaritySource(String claritySource) { this.claritySource = claritySource; }

    public String getClarityStatus() { return clarityStatus; }
    public void setClarityStatus(String clarityStatus) { this.clarityStatus = clarityStatus; }

    public String getClarityLastUpdated() { return clarityLastUpdated; }
    public void setClarityLastUpdated(String clarityLastUpdated) { this.clarityLastUpdated = clarityLastUpdated; }

    public String getClarityProjectId() { return clarityProjectId; }
    public void setClarityProjectId(String clarityProjectId) { this.clarityProjectId = clarityProjectId; }

    public boolean isGscConnected() { return gscConnected; }
    public void setGscConnected(boolean gscConnected) { this.gscConnected = gscConnected; }

    public String getGscSource() { return gscSource; }
    public void setGscSource(String gscSource) { this.gscSource = gscSource; }

    public String getGscStatus() { return gscStatus; }
    public void setGscStatus(String gscStatus) { this.gscStatus = gscStatus; }

    public String getGscLastUpdated() { return gscLastUpdated; }
    public void setGscLastUpdated(String gscLastUpdated) { this.gscLastUpdated = gscLastUpdated; }

    public String getGscPropertyId() { return gscPropertyId; }
    public void setGscPropertyId(String gscPropertyId) { this.gscPropertyId = gscPropertyId; }

    public int getGscTotalQueries() { return gscTotalQueries; }
    public void setGscTotalQueries(int gscTotalQueries) { this.gscTotalQueries = gscTotalQueries; }

    public int getGscTotalImpressions() { return gscTotalImpressions; }
    public void setGscTotalImpressions(int gscTotalImpressions) { this.gscTotalImpressions = gscTotalImpressions; }

    public int getGscTotalClicks() { return gscTotalClicks; }
    public void setGscTotalClicks(int gscTotalClicks) { this.gscTotalClicks = gscTotalClicks; }

    public BigDecimal getGscAverageCtr() { return gscAverageCtr; }
    public void setGscAverageCtr(BigDecimal gscAverageCtr) { this.gscAverageCtr = gscAverageCtr; }

    public BigDecimal getGscAveragePosition() { return gscAveragePosition; }
    public void setGscAveragePosition(BigDecimal gscAveragePosition) { this.gscAveragePosition = gscAveragePosition; }

    public int getGscIndexedPages() { return gscIndexedPages; }
    public void setGscIndexedPages(int gscIndexedPages) { this.gscIndexedPages = gscIndexedPages; }

    public java.util.List<Map<String, Object>> getGscQueries() { return gscQueries; }
    public void setGscQueries(java.util.List<Map<String, Object>> gscQueries) { this.gscQueries = gscQueries; }

    public java.util.List<Map<String, Object>> getGscPages() { return gscPages; }
    public void setGscPages(java.util.List<Map<String, Object>> gscPages) { this.gscPages = gscPages; }

    public long getTotalLeads() { return totalLeads; }
    public void setTotalLeads(long totalLeads) { this.totalLeads = totalLeads; }

    public long getNewLeads() { return newLeads; }
    public void setNewLeads(long newLeads) { this.newLeads = newLeads; }

    public long getQualifiedLeads() { return qualifiedLeads; }
    public void setQualifiedLeads(long qualifiedLeads) { this.qualifiedLeads = qualifiedLeads; }

    public long getUrgentLeads() { return urgentLeads; }
    public void setUrgentLeads(long urgentLeads) { this.urgentLeads = urgentLeads; }

    public Map<String, Long> getLeadsByService() { return leadsByService; }
    public void setLeadsByService(Map<String, Long> leadsByService) { this.leadsByService = leadsByService; }

    public Map<String, Long> getLeadsByLocation() { return leadsByLocation; }
    public void setLeadsByLocation(Map<String, Long> leadsByLocation) { this.leadsByLocation = leadsByLocation; }

    public Map<String, Long> getLeadsByStatus() { return leadsByStatus; }
    public void setLeadsByStatus(Map<String, Long> leadsByStatus) { this.leadsByStatus = leadsByStatus; }

    public long getTotalQuotes() { return totalQuotes; }
    public void setTotalQuotes(long totalQuotes) { this.totalQuotes = totalQuotes; }

    public BigDecimal getTotalQuotedAmount() { return totalQuotedAmount; }
    public void setTotalQuotedAmount(BigDecimal totalQuotedAmount) { this.totalQuotedAmount = totalQuotedAmount; }

    public long getAcceptedQuotes() { return acceptedQuotes; }
    public void setAcceptedQuotes(long acceptedQuotes) { this.acceptedQuotes = acceptedQuotes; }

    public long getTotalOrders() { return totalOrders; }
    public void setTotalOrders(long totalOrders) { this.totalOrders = totalOrders; }

    public long getCompletedOrders() { return completedOrders; }
    public void setCompletedOrders(long completedOrders) { this.completedOrders = completedOrders; }

    public BigDecimal getRealizedRevenue() { return realizedRevenue; }
    public void setRealizedRevenue(BigDecimal realizedRevenue) { this.realizedRevenue = realizedRevenue; }
}
