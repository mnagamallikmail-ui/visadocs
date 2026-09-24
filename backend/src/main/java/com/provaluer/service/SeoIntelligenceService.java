package com.provaluer.service;

import com.provaluer.dto.SeoOverviewResponse;
import com.provaluer.model.SeoPage;
import com.provaluer.model.SeoDailyMetric;
import com.provaluer.model.SeoQuery;
import com.provaluer.model.SeoCredential;
import com.provaluer.model.SeoSyncLog;
import com.provaluer.repository.SeoPageRepository;
import com.provaluer.repository.SeoDailyMetricRepository;
import com.provaluer.repository.SeoQueryRepository;
import com.provaluer.repository.SeoCredentialRepository;
import com.provaluer.repository.SeoSyncLogRepository;
import com.provaluer.repository.SeoCrawlErrorRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Core SEO Intelligence Platform Service
 * Provides telemetry aggregation and real-time synchronization with GSC and Bing.
 */
@Service
public class SeoIntelligenceService {
    private static final Logger log = LoggerFactory.getLogger(SeoIntelligenceService.class);

    @Autowired
    private SeoPageRepository pageRepository;

    @Autowired
    private SeoDailyMetricRepository dailyMetricRepository;

    @Autowired
    private SeoQueryRepository queryRepository;

    @Autowired
    private SeoCredentialRepository credentialRepository;

    @Autowired
    private SeoSyncLogRepository syncLogRepository;

    @Autowired
    private SeoCrawlErrorRepository crawlErrorRepository;

    @Autowired
    private GoogleSearchConsoleService gscService;

    @Autowired
    private BingWebmasterService bingService;

    /**
     * Build aggregated overview for the Admin SEO Intelligence Dashboard
     */
    @Transactional(readOnly = true)
    public SeoOverviewResponse getOverview() {
        SeoOverviewResponse response = new SeoOverviewResponse();

        // 1. High-level aggregates
        Long totalClicks = dailyMetricRepository.sumTotalClicks();
        Long totalImpressions = dailyMetricRepository.sumTotalImpressions();
        Double overallAvgPos = dailyMetricRepository.calculateOverallAvgPosition();

        response.setTotalClicks(totalClicks != null ? totalClicks : 0L);
        response.setTotalImpressions(totalImpressions != null ? totalImpressions : 0L);
        response.setAveragePosition(overallAvgPos != null 
                ? BigDecimal.valueOf(overallAvgPos).setScale(2, RoundingMode.HALF_UP) 
                : BigDecimal.ZERO);

        if (totalImpressions != null && totalImpressions > 0 && totalClicks != null) {
            response.setAverageCtr(BigDecimal.valueOf((double) totalClicks / totalImpressions).setScale(4, RoundingMode.HALF_UP));
        } else {
            response.setAverageCtr(BigDecimal.ZERO);
        }

        // 2. Indexing statistics
        long totalPages = pageRepository.count();
        long indexedPages = pageRepository.countByIndexedTrue();
        response.setTotalPages(totalPages);
        response.setIndexedPages(indexedPages);
        response.setIndexingRate(totalPages > 0 ? ((double) indexedPages / totalPages) * 100.0 : 0.0);
        response.setActiveCrawlErrors(crawlErrorRepository.countByResolvedFalse());

        // 3. Credentials & integration status
        credentialRepository.findByProvider("GSC").ifPresent(gsc -> {
            response.setGscConnected(gsc.getConnected());
            response.setGscPropertyId(gsc.getPropertyId());
            response.setGscStatus(gsc.getStatus());
            response.setGscLastSync(gsc.getLastSyncAt());
            response.setSyncFrequency(gsc.getSyncFrequency());
        });

        credentialRepository.findByProvider("BING").ifPresent(bing -> {
            response.setBingConnected(bing.getConnected());
            response.setBingSiteId(bing.getPropertyId());
            response.setBingStatus(bing.getStatus());
            response.setBingLastSync(bing.getLastSyncAt());
            if (response.getSyncFrequency() == null) {
                response.setSyncFrequency(bing.getSyncFrequency());
            }
        });

        if (response.getSyncFrequency() == null) {
            response.setSyncFrequency("DAILY");
        }

        // 4. Daily trends (last 14 days)
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(13);
        List<SeoDailyMetric> recentMetrics = dailyMetricRepository.findByDateBetweenOrderByDateAsc(startDate, endDate);

        Map<LocalDate, List<SeoDailyMetric>> metricsByDate = recentMetrics.stream()
                .collect(Collectors.groupingBy(SeoDailyMetric::getDate));

        List<SeoOverviewResponse.DailyTrendDto> trends = new ArrayList<>();
        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            List<SeoDailyMetric> list = metricsByDate.getOrDefault(date, Collections.emptyList());
            int imp = list.stream().mapToInt(SeoDailyMetric::getImpressions).sum();
            int clk = list.stream().mapToInt(SeoDailyMetric::getClicks).sum();
            BigDecimal ctr = imp > 0 ? BigDecimal.valueOf((double) clk / imp).setScale(4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
            OptionalDouble avgPosOpt = list.stream().mapToDouble(m -> m.getAvgPosition().doubleValue()).filter(p -> p > 0).average();
            BigDecimal avgPos = avgPosOpt.isPresent() ? BigDecimal.valueOf(avgPosOpt.getAsDouble()).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO;

            trends.add(new SeoOverviewResponse.DailyTrendDto(date, imp, clk, ctr, avgPos));
        }
        response.setDailyTrends(trends);

        // 5. Pages performance
        List<SeoPage> pages = pageRepository.findAllByOrderByPublishedAtDesc();
        List<SeoOverviewResponse.PagePerformanceDto> pageDtos = new ArrayList<>();
        for (SeoPage p : pages) {
            SeoOverviewResponse.PagePerformanceDto pDto = new SeoOverviewResponse.PagePerformanceDto();
            pDto.setId(p.getId());
            pDto.setUrl(p.getUrl());
            pDto.setSlug(p.getSlug());
            pDto.setTitle(p.getTitle());
            pDto.setIndexed(p.getIndexed());
            pDto.setIndexDate(p.getIndexDate());
            pDto.setStatus(p.getStatus());

            List<SeoDailyMetric> pMetrics = dailyMetricRepository.findByPageIdOrderByDateDesc(p.getId());
            int pImp = pMetrics.stream().mapToInt(SeoDailyMetric::getImpressions).sum();
            int pClk = pMetrics.stream().mapToInt(SeoDailyMetric::getClicks).sum();
            pDto.setImpressions(pImp);
            pDto.setClicks(pClk);
            pDto.setCtr(pImp > 0 ? BigDecimal.valueOf((double) pClk / pImp).setScale(4, RoundingMode.HALF_UP) : BigDecimal.ZERO);
            OptionalDouble pAvgPosOpt = pMetrics.stream().mapToDouble(m -> m.getAvgPosition().doubleValue()).filter(pos -> pos > 0).average();
            pDto.setAvgPosition(pAvgPosOpt.isPresent() ? BigDecimal.valueOf(pAvgPosOpt.getAsDouble()).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO);

            pageDtos.add(pDto);
        }
        response.setPages(pageDtos);

        // 6. Top search queries
        List<SeoQuery> topQueries = queryRepository.findLatestTopQueries();
        List<SeoOverviewResponse.QueryPerformanceDto> queryDtos = topQueries.stream().limit(30).map(q -> {
            SeoOverviewResponse.QueryPerformanceDto qDto = new SeoOverviewResponse.QueryPerformanceDto();
            qDto.setId(q.getId());
            qDto.setQuery(q.getQuery());
            qDto.setPageSlug(q.getPage().getSlug());
            qDto.setPageTitle(q.getPage().getTitle());
            qDto.setSource(q.getSource());
            qDto.setImpressions(q.getImpressions());
            qDto.setClicks(q.getClicks());
            qDto.setCtr(q.getCtr());
            qDto.setAvgPosition(q.getAvgPosition());
            qDto.setCountry(q.getCountry());
            qDto.setDevice(q.getDevice());
            return qDto;
        }).collect(Collectors.toList());
        response.setQueries(queryDtos);

        // 7. Recent sync logs
        List<SeoSyncLog> syncLogs = syncLogRepository.findTop20ByOrderByCreatedAtDesc();
        List<SeoOverviewResponse.SyncLogDto> logDtos = syncLogs.stream().map(l -> {
            SeoOverviewResponse.SyncLogDto lDto = new SeoOverviewResponse.SyncLogDto();
            lDto.setId(l.getId());
            lDto.setProvider(l.getProvider());
            lDto.setStatus(l.getStatus());
            lDto.setMessage(l.getMessage());
            lDto.setItemsSynced(l.getItemsSynced());
            lDto.setDurationMs(l.getDurationMs());
            lDto.setCreatedAt(l.getCreatedAt());
            return lDto;
        }).collect(Collectors.toList());
        response.setSyncLogs(logDtos);

        return response;
    }

    /**
     * Execute sync for Google Search Console, Bing Webmaster, or both
     */
    @Transactional
    public Map<String, Object> executeSync(String provider) {
        long startTime = System.currentTimeMillis();
        int totalItemsSynced = 0;
        String syncTarget = provider != null ? provider.toUpperCase() : "ALL";

        log.info("Starting SEO synchronization for target: {}", syncTarget);
        LocalDate today = LocalDate.now();

        try {
            // 1. Google Search Console Sync
            if ("GSC".equals(syncTarget) || "ALL".equals(syncTarget)) {
                List<GoogleSearchConsoleService.PulledGscPageData> gscData = gscService.pullPerformanceMetrics(today);
                for (GoogleSearchConsoleService.PulledGscPageData pageData : gscData) {
                    pageRepository.findByUrl(pageData.url).ifPresent(page -> {
                        SeoDailyMetric metric = dailyMetricRepository.findByPageIdAndSourceAndDate(page.getId(), "GSC", today)
                                .orElse(new SeoDailyMetric());
                        metric.setPage(page);
                        metric.setSource("GSC");
                        metric.setDate(today);
                        metric.setImpressions(pageData.impressions);
                        metric.setClicks(pageData.clicks);
                        metric.setCtr(pageData.ctr);
                        metric.setAvgPosition(pageData.avgPosition);
                        dailyMetricRepository.save(metric);

                        for (GoogleSearchConsoleService.PulledQueryData qData : pageData.queries) {
                            SeoQuery query = queryRepository.findByPageIdAndQueryAndSourceAndDate(page.getId(), qData.query, "GSC", today)
                                    .orElse(new SeoQuery());
                            query.setPage(page);
                            query.setQuery(qData.query);
                            query.setSource("GSC");
                            query.setDate(today);
                            query.setImpressions(qData.impressions);
                            query.setClicks(qData.clicks);
                            query.setCtr(qData.ctr);
                            query.setAvgPosition(qData.avgPosition);
                            query.setCountry(qData.country);
                            query.setDevice(qData.device);
                            queryRepository.save(query);
                        }
                    });
                    totalItemsSynced += 1 + pageData.queries.size();
                }

                credentialRepository.findByProvider("GSC").ifPresent(cred -> {
                    cred.setLastSyncAt(LocalDateTime.now());
                    cred.setStatus("ACTIVE");
                    credentialRepository.save(cred);
                });
            }

            // 2. Bing Webmaster Sync
            if ("BING".equals(syncTarget) || "ALL".equals(syncTarget)) {
                List<BingWebmasterService.PulledBingPageData> bingData = bingService.pullPerformanceMetrics(today);
                for (BingWebmasterService.PulledBingPageData pageData : bingData) {
                    pageRepository.findByUrl(pageData.url).ifPresent(page -> {
                        SeoDailyMetric metric = dailyMetricRepository.findByPageIdAndSourceAndDate(page.getId(), "BING", today)
                                .orElse(new SeoDailyMetric());
                        metric.setPage(page);
                        metric.setSource("BING");
                        metric.setDate(today);
                        metric.setImpressions(pageData.impressions);
                        metric.setClicks(pageData.clicks);
                        metric.setCtr(pageData.ctr);
                        metric.setAvgPosition(pageData.avgPosition);
                        dailyMetricRepository.save(metric);

                        for (BingWebmasterService.PulledBingKeywordData kwData : pageData.keywords) {
                            SeoQuery query = queryRepository.findByPageIdAndQueryAndSourceAndDate(page.getId(), kwData.keyword, "BING", today)
                                    .orElse(new SeoQuery());
                            query.setPage(page);
                            query.setQuery(kwData.keyword);
                            query.setSource("BING");
                            query.setDate(today);
                            query.setImpressions(kwData.impressions);
                            query.setClicks(kwData.clicks);
                            query.setCtr(kwData.ctr);
                            query.setAvgPosition(kwData.avgPosition);
                            query.setCountry("IND");
                            query.setDevice("DESKTOP");
                            queryRepository.save(query);
                        }
                    });
                    totalItemsSynced += 1 + pageData.keywords.size();
                }

                credentialRepository.findByProvider("BING").ifPresent(cred -> {
                    cred.setLastSyncAt(LocalDateTime.now());
                    cred.setStatus("ACTIVE");
                    credentialRepository.save(cred);
                });
            }

            long duration = System.currentTimeMillis() - startTime;
            SeoSyncLog syncLog = new SeoSyncLog(syncTarget, "SUCCESS", 
                    "Successfully synchronized " + totalItemsSynced + " SEO records from " + syncTarget, 
                    totalItemsSynced, duration);
            syncLogRepository.save(syncLog);

            Map<String, Object> result = new HashMap<>();
            result.put("status", "SUCCESS");
            result.put("provider", syncTarget);
            result.put("itemsSynced", totalItemsSynced);
            result.put("durationMs", duration);
            result.put("timestamp", LocalDateTime.now());
            return result;
        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            log.error("Failed to synchronize SEO data for {}: {}", syncTarget, e.getMessage(), e);
            SeoSyncLog syncLog = new SeoSyncLog(syncTarget, "FAILED", 
                    "Sync failed: " + e.getMessage(), totalItemsSynced, duration);
            syncLogRepository.save(syncLog);

            Map<String, Object> result = new HashMap<>();
            result.put("status", "FAILED");
            result.put("provider", syncTarget);
            result.put("error", e.getMessage());
            result.put("durationMs", duration);
            return result;
        }
    }

    /**
     * Update synchronization frequency across providers
     */
    @Transactional
    public void updateSyncFrequency(String frequency) {
        String validFreq = "WEEKLY".equalsIgnoreCase(frequency) ? "WEEKLY" : "DAILY";
        List<SeoCredential> creds = credentialRepository.findAll();
        for (SeoCredential c : creds) {
            c.setSyncFrequency(validFreq);
            credentialRepository.save(c);
        }
    }
}
