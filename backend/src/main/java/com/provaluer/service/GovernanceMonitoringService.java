package com.provaluer.service;

import com.provaluer.model.AuditLog;
import com.provaluer.model.Order;
import com.provaluer.repository.AuditLogRepository;
import com.provaluer.repository.OrderRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Enterprise Production Governance: Health Monitoring & Operations Dashboard Service.
 * Evaluates real-time health, database connectivity, failure metrics, and stalled orders.
 */
@Service
public class GovernanceMonitoringService {

    private static final Logger log = LoggerFactory.getLogger(GovernanceMonitoringService.class);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private TelemetryService telemetryService;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    /**
     * Phase 3: Operational Health Monitoring.
     */
    public Map<String, Object> getHealthStatus() {
        Map<String, Object> health = new LinkedHashMap<>();
        health.put("timestamp", LocalDateTime.now().toString());

        // 1. Database Connectivity & Latency Check
        boolean dbConnected = false;
        long dbLatencyMs = -1;
        try {
            long start = System.currentTimeMillis();
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            dbLatencyMs = System.currentTimeMillis() - start;
            dbConnected = true;
        } catch (Exception e) {
            log.error("Database connectivity check failed: {}", e.getMessage());
            telemetryService.recordDbLoss();
        }

        health.put("databaseConnected", dbConnected);
        health.put("databaseLatencyMs", dbLatencyMs);

        // 2. Telemetry Metrics
        Map<String, Object> metrics = telemetryService.getMetricsSummary();
        health.put("metrics", metrics);

        // 3. Determine Overall System Health State
        double saveRate = telemetryService.getSaveFailureRate();
        double autosaveRate = telemetryService.getAutosaveFailureRate();

        String systemStatus;
        if (!dbConnected) {
            systemStatus = "CRITICAL - DATABASE UNREACHABLE";
        } else if (saveRate > 2.0 || autosaveRate > 2.0) {
            systemStatus = "DEGRADED - ELEVATED FAILURE RATES";
        } else {
            systemStatus = "HEALTHY - ALL SYSTEMS OPERATIONAL";
        }
        health.put("systemStatus", systemStatus);

        return health;
    }

    /**
     * Phase 8: Admin Operations Dashboard.
     * Visibility into: Failed Saves, Failed Submissions, Expired Session Recoveries,
     * PDF Errors, Template Errors, Assignment Errors, Stalled Orders.
     */
    public Map<String, Object> getOperationsDashboard() {
        Map<String, Object> dashboard = new LinkedHashMap<>();
        dashboard.put("generatedAt", LocalDateTime.now().toString());

        // Metrics Summary
        dashboard.put("operationalMetrics", telemetryService.getMetricsSummary());

        // Recent Failures from Telemetry Buffer
        dashboard.put("recentErrors", telemetryService.getRecentErrors(50));

        // Stalled Orders Query (Active orders pending without SLA update)
        List<Order> activeOrders = orderRepository.findAllActiveSlaOrders();
        List<Map<String, Object>> stalledList = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();

        for (Order o : activeOrders) {
            if (o.getSlaExpiryTime() != null && o.getSlaExpiryTime().isBefore(now)) {
                stalledList.add(Map.of(
                        "orderId", o.getId(),
                        "referenceCode", o.getReferenceCode() != null ? o.getReferenceCode() : "N/A",
                        "reportNumber", o.getReportNumber() != null ? o.getReportNumber() : "N/A",
                        "status", o.getStatus(),
                        "slaExpiryTime", o.getSlaExpiryTime().toString(),
                        "isBreached", true
                ));
            }
        }
        dashboard.put("stalledOrdersCount", stalledList.size());
        dashboard.put("stalledOrders", stalledList);

        // Recent Audit Actions
        List<AuditLog> recentLogs = auditLogRepository.findTop50ByOrderByTimestampDesc();
        dashboard.put("recentAuditCount", recentLogs.size());

        return dashboard;
    }
}
