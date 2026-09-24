package com.provaluer.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public class SeoOverviewResponse {
    private Long totalClicks;
    private Long totalImpressions;
    private BigDecimal averageCtr;
    private BigDecimal averagePosition;
    private Long totalPages;
    private Long indexedPages;
    private Double indexingRate;
    private Long activeCrawlErrors;

    private Boolean gscConnected;
    private String gscPropertyId;
    private String gscStatus;
    private LocalDateTime gscLastSync;

    private Boolean bingConnected;
    private String bingSiteId;
    private String bingStatus;
    private LocalDateTime bingLastSync;

    private String syncFrequency;

    private List<DailyTrendDto> dailyTrends;
    private List<PagePerformanceDto> pages;
    private List<QueryPerformanceDto> queries;
    private List<SyncLogDto> syncLogs;

    public SeoOverviewResponse() {}

    public static class DailyTrendDto {
        private LocalDate date;
        private Integer impressions;
        private Integer clicks;
        private BigDecimal ctr;
        private BigDecimal avgPosition;

        public DailyTrendDto() {}
        public DailyTrendDto(LocalDate date, Integer impressions, Integer clicks, BigDecimal ctr, BigDecimal avgPosition) {
            this.date = date;
            this.impressions = impressions;
            this.clicks = clicks;
            this.ctr = ctr;
            this.avgPosition = avgPosition;
        }

        public LocalDate getDate() { return date; }
        public void setDate(LocalDate date) { this.date = date; }
        public Integer getImpressions() { return impressions; }
        public void setImpressions(Integer impressions) { this.impressions = impressions; }
        public Integer getClicks() { return clicks; }
        public void setClicks(Integer clicks) { this.clicks = clicks; }
        public BigDecimal getCtr() { return ctr; }
        public void setCtr(BigDecimal ctr) { this.ctr = ctr; }
        public BigDecimal getAvgPosition() { return avgPosition; }
        public void setAvgPosition(BigDecimal avgPosition) { this.avgPosition = avgPosition; }
    }

    public static class PagePerformanceDto {
        private Long id;
        private String url;
        private String slug;
        private String title;
        private Boolean indexed;
        private LocalDateTime indexDate;
        private String status;
        private Integer impressions;
        private Integer clicks;
        private BigDecimal ctr;
        private BigDecimal avgPosition;

        public PagePerformanceDto() {}

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getUrl() { return url; }
        public void setUrl(String url) { this.url = url; }
        public String getSlug() { return slug; }
        public void setSlug(String slug) { this.slug = slug; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public Boolean getIndexed() { return indexed; }
        public void setIndexed(Boolean indexed) { this.indexed = indexed; }
        public LocalDateTime getIndexDate() { return indexDate; }
        public void setIndexDate(LocalDateTime indexDate) { this.indexDate = indexDate; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public Integer getImpressions() { return impressions; }
        public void setImpressions(Integer impressions) { this.impressions = impressions; }
        public Integer getClicks() { return clicks; }
        public void setClicks(Integer clicks) { this.clicks = clicks; }
        public BigDecimal getCtr() { return ctr; }
        public void setCtr(BigDecimal ctr) { this.ctr = ctr; }
        public BigDecimal getAvgPosition() { return avgPosition; }
        public void setAvgPosition(BigDecimal avgPosition) { this.avgPosition = avgPosition; }
    }

    public static class QueryPerformanceDto {
        private Long id;
        private String query;
        private String pageSlug;
        private String pageTitle;
        private String source;
        private Integer impressions;
        private Integer clicks;
        private BigDecimal ctr;
        private BigDecimal avgPosition;
        private String country;
        private String device;

        public QueryPerformanceDto() {}

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getQuery() { return query; }
        public void setQuery(String query) { this.query = query; }
        public String getPageSlug() { return pageSlug; }
        public void setPageSlug(String pageSlug) { this.pageSlug = pageSlug; }
        public String getPageTitle() { return pageTitle; }
        public void setPageTitle(String pageTitle) { this.pageTitle = pageTitle; }
        public String getSource() { return source; }
        public void setSource(String source) { this.source = source; }
        public Integer getImpressions() { return impressions; }
        public void setImpressions(Integer impressions) { this.impressions = impressions; }
        public Integer getClicks() { return clicks; }
        public void setClicks(Integer clicks) { this.clicks = clicks; }
        public BigDecimal getCtr() { return ctr; }
        public void setCtr(BigDecimal ctr) { this.ctr = ctr; }
        public BigDecimal getAvgPosition() { return avgPosition; }
        public void setAvgPosition(BigDecimal avgPosition) { this.avgPosition = avgPosition; }
        public String getCountry() { return country; }
        public void setCountry(String country) { this.country = country; }
        public String getDevice() { return device; }
        public void setDevice(String device) { this.device = device; }
    }

    public static class SyncLogDto {
        private Long id;
        private String provider;
        private String status;
        private String message;
        private Integer itemsSynced;
        private Long durationMs;
        private LocalDateTime createdAt;

        public SyncLogDto() {}

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public String getProvider() { return provider; }
        public void setProvider(String provider) { this.provider = provider; }
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        public Integer getItemsSynced() { return itemsSynced; }
        public void setItemsSynced(Integer itemsSynced) { this.itemsSynced = itemsSynced; }
        public Long getDurationMs() { return durationMs; }
        public void setDurationMs(Long durationMs) { this.durationMs = durationMs; }
        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    }

    // Getters and Setters
    public Long getTotalClicks() { return totalClicks; }
    public void setTotalClicks(Long totalClicks) { this.totalClicks = totalClicks; }
    public Long getTotalImpressions() { return totalImpressions; }
    public void setTotalImpressions(Long totalImpressions) { this.totalImpressions = totalImpressions; }
    public BigDecimal getAverageCtr() { return averageCtr; }
    public void setAverageCtr(BigDecimal averageCtr) { this.averageCtr = averageCtr; }
    public BigDecimal getAveragePosition() { return averagePosition; }
    public void setAveragePosition(BigDecimal averagePosition) { this.averagePosition = averagePosition; }
    public Long getTotalPages() { return totalPages; }
    public void setTotalPages(Long totalPages) { this.totalPages = totalPages; }
    public Long getIndexedPages() { return indexedPages; }
    public void setIndexedPages(Long indexedPages) { this.indexedPages = indexedPages; }
    public Double getIndexingRate() { return indexingRate; }
    public void setIndexingRate(Double indexingRate) { this.indexingRate = indexingRate; }
    public Long getActiveCrawlErrors() { return activeCrawlErrors; }
    public void setActiveCrawlErrors(Long activeCrawlErrors) { this.activeCrawlErrors = activeCrawlErrors; }

    public Boolean getGscConnected() { return gscConnected; }
    public void setGscConnected(Boolean gscConnected) { this.gscConnected = gscConnected; }
    public String getGscPropertyId() { return gscPropertyId; }
    public void setGscPropertyId(String gscPropertyId) { this.gscPropertyId = gscPropertyId; }
    public String getGscStatus() { return gscStatus; }
    public void setGscStatus(String gscStatus) { this.gscStatus = gscStatus; }
    public LocalDateTime getGscLastSync() { return gscLastSync; }
    public void setGscLastSync(LocalDateTime gscLastSync) { this.gscLastSync = gscLastSync; }

    public Boolean getBingConnected() { return bingConnected; }
    public void setBingConnected(Boolean bingConnected) { this.bingConnected = bingConnected; }
    public String getBingSiteId() { return bingSiteId; }
    public void setBingSiteId(String bingSiteId) { this.bingSiteId = bingSiteId; }
    public String getBingStatus() { return bingStatus; }
    public void setBingStatus(String bingStatus) { this.bingStatus = bingStatus; }
    public LocalDateTime getBingLastSync() { return bingLastSync; }
    public void setBingLastSync(LocalDateTime bingLastSync) { this.bingLastSync = bingLastSync; }

    public String getSyncFrequency() { return syncFrequency; }
    public void setSyncFrequency(String syncFrequency) { this.syncFrequency = syncFrequency; }

    public List<DailyTrendDto> getDailyTrends() { return dailyTrends; }
    public void setDailyTrends(List<DailyTrendDto> dailyTrends) { this.dailyTrends = dailyTrends; }
    public List<PagePerformanceDto> getPages() { return pages; }
    public void setPages(List<PagePerformanceDto> pages) { this.pages = pages; }
    public List<QueryPerformanceDto> getQueries() { return queries; }
    public void setQueries(List<QueryPerformanceDto> queries) { this.queries = queries; }
    public List<SyncLogDto> getSyncLogs() { return syncLogs; }
    public void setSyncLogs(List<SyncLogDto> syncLogs) { this.syncLogs = syncLogs; }
}
