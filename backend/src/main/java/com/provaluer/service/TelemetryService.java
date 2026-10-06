package com.provaluer.service;

import com.provaluer.dto.TelemetryErrorDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedDeque;
import java.util.concurrent.atomic.LongAdder;

/**
 * Enterprise Production Governance: Telemetry & Failure Monitoring Service.
 * Tracks operational error rates, health metrics, and failure alerts.
 */
@Service
public class TelemetryService {

    private static final Logger log = LoggerFactory.getLogger(TelemetryService.class);

    private static final int MAX_ERROR_HISTORY = 1000;

    // Metrics Counters
    private final LongAdder saveAttempts = new LongAdder();
    private final LongAdder saveSuccesses = new LongAdder();
    private final LongAdder saveFailures = new LongAdder();

    private final LongAdder autosaveAttempts = new LongAdder();
    private final LongAdder autosaveSuccesses = new LongAdder();
    private final LongAdder autosaveFailures = new LongAdder();

    private final LongAdder submitSpaAttempts = new LongAdder();
    private final LongAdder submitSpaSuccesses = new LongAdder();
    private final LongAdder submitSpaFailures = new LongAdder();

    private final LongAdder pdfAttempts = new LongAdder();
    private final LongAdder pdfSuccesses = new LongAdder();
    private final LongAdder pdfFailures = new LongAdder();

    private final LongAdder authFailures = new LongAdder();
    private final LongAdder dbLossCount = new LongAdder();

    // Circular Error Buffer
    private final Deque<TelemetryErrorDTO> recentErrors = new ConcurrentLinkedDeque<>();

    // Alert Debounce Timestamps (per alert type)
    private final Map<String, Long> lastAlertTimestamps = new ConcurrentHashMap<>();
    private static final long ALERT_DEBOUNCE_MS = 60_000; // 1 minute per alert type

    @Autowired
    private TelegramNotificationService telegramNotificationService;

    @Autowired
    private AuditLogService auditLogService;

    // ────────────────────────────────────────────────────────────────────────────
    // Operational Tracking Methods
    // ────────────────────────────────────────────────────────────────────────────

    public void recordSave(boolean success, Long orderId, String reportNumber, String actor) {
        saveAttempts.increment();
        if (success) {
            saveSuccesses.increment();
        } else {
            saveFailures.increment();
            recordError(new TelemetryErrorDTO(null, orderId, reportNumber, "DocumentWorkspace",
                    "SAVE_DRAFT", "Save Draft failed for Order " + orderId, null, null, "ERROR", 500));
            checkThresholds();
        }
    }

    public void recordAutosave(boolean success, Long orderId, String reportNumber, String actor) {
        autosaveAttempts.increment();
        if (success) {
            autosaveSuccesses.increment();
        } else {
            autosaveFailures.increment();
            recordError(new TelemetryErrorDTO(null, orderId, reportNumber, "DocumentWorkspace",
                    "AUTOSAVE", "Autosave failed for Order " + orderId, null, null, "ERROR", 500));
            checkThresholds();
        }
    }

    public void recordSubmitSpa(boolean success, Long orderId, String reportNumber, String actor, String errorDetail) {
        submitSpaAttempts.increment();
        if (success) {
            submitSpaSuccesses.increment();
        } else {
            submitSpaFailures.increment();
            recordError(new TelemetryErrorDTO(null, orderId, reportNumber, "DocumentWorkspace",
                    "SUBMIT_TO_SPA", errorDetail != null ? errorDetail : "Submit to SPA failed", null, null, "CRITICAL", 500));
            // Submit to SPA failure must alert immediately (Threshold: > 0)
            triggerAlert("SUBMIT_TO_SPA_FAILURE", String.format(
                    "Order: %d | Report: %s | Actor: %s | Error: %s",
                    orderId, reportNumber != null ? reportNumber : "N/A", actor, errorDetail
            ));
        }
    }

    public void recordPdfGeneration(boolean success, Long orderId, String reportNumber, String actor, String errorDetail) {
        pdfAttempts.increment();
        if (success) {
            pdfSuccesses.increment();
        } else {
            pdfFailures.increment();
            recordError(new TelemetryErrorDTO(null, orderId, reportNumber, "ReportEngine",
                    "GENERATE_PDF", errorDetail != null ? errorDetail : "PDF generation failed", null, null, "ERROR", 500));
        }
    }

    public void recordAuthFailure(String endpoint, String reason, Integer statusCode) {
        authFailures.increment();
        recordError(new TelemetryErrorDTO(null, null, null, "AuthGateway",
                "AUTHENTICATE", "Auth failure on " + endpoint + ": " + reason, null, null, "WARN", statusCode));
        checkThresholds();
    }

    public void recordDbLoss() {
        dbLossCount.increment();
        triggerAlert("DATABASE_CONNECTIVITY_LOST", "Database connection failed or timed out during health check");
    }

    public void recordError(TelemetryErrorDTO errorDto) {
        if (errorDto == null) return;
        if (errorDto.getTimestamp() == null) {
            errorDto.setTimestamp(LocalDateTime.now().toString());
        }

        recentErrors.addFirst(errorDto);
        while (recentErrors.size() > MAX_ERROR_HISTORY) {
            recentErrors.pollLast();
        }

        if ("CRITICAL".equalsIgnoreCase(errorDto.getSeverity())) {
            auditLogService.log(
                    errorDto.getUserId() != null ? errorDto.getUserId() : 0L,
                    "system@provaluer.in",
                    "SYSTEM",
                    "CRITICAL_ERROR",
                    "ORDER",
                    errorDto.getOrderId() != null ? errorDto.getOrderId().toString() : "N/A",
                    null,
                    errorDto.getErrorMessage(),
                    "Screen: " + errorDto.getScreen() + " | Action: " + errorDto.getAction()
            );
        }
    }

    // ────────────────────────────────────────────────────────────────────────────
    // Alerting Thresholds (Phase 4)
    // ────────────────────────────────────────────────────────────────────────────

    private void checkThresholds() {
        double saveRate = getSaveFailureRate();
        if (saveAttempts.sum() >= 10 && saveRate > 2.0) {
            triggerAlert("HIGH_SAVE_FAILURE_RATE", String.format(
                    "Save Draft failure rate reached %.2f%% (Failures: %d / %d)",
                    saveRate, saveFailures.sum(), saveAttempts.sum()
            ));
        }

        double autosaveRate = getAutosaveFailureRate();
        if (autosaveAttempts.sum() >= 10 && autosaveRate > 2.0) {
            triggerAlert("HIGH_AUTOSAVE_FAILURE_RATE", String.format(
                    "Autosave failure rate reached %.2f%% (Failures: %d / %d)",
                    autosaveRate, autosaveFailures.sum(), autosaveAttempts.sum()
            ));
        }

        if (authFailures.sum() > 20) {
            triggerAlert("JWT_AUTH_FAILURES_SPIKE", String.format(
                    "Authentication failures elevated: %d cumulative failures recorded",
                    authFailures.sum()
            ));
        }
    }

    private void triggerAlert(String alertType, String details) {
        long now = System.currentTimeMillis();
        Long lastTime = lastAlertTimestamps.get(alertType);
        if (lastTime != null && (now - lastTime) < ALERT_DEBOUNCE_MS) {
            return; // Debounced
        }
        lastAlertTimestamps.put(alertType, now);

        log.error("[ALERT DISPATCH] {} - {}", alertType, details);
        telegramNotificationService.sendOperationalGovernanceAlert(alertType, details);
    }

    // ────────────────────────────────────────────────────────────────────────────
    // Metrics & Health Status
    // ────────────────────────────────────────────────────────────────────────────

    public double getSaveFailureRate() {
        long att = saveAttempts.sum();
        return att == 0 ? 0.0 : (double) saveFailures.sum() / att * 100.0;
    }

    public double getAutosaveFailureRate() {
        long att = autosaveAttempts.sum();
        return att == 0 ? 0.0 : (double) autosaveFailures.sum() / att * 100.0;
    }

    public List<TelemetryErrorDTO> getRecentErrors(int limit) {
        return recentErrors.stream().limit(limit).toList();
    }

    public Map<String, Object> getMetricsSummary() {
        Map<String, Object> metrics = new LinkedHashMap<>();
        metrics.put("saveAttempts", saveAttempts.sum());
        metrics.put("saveSuccesses", saveSuccesses.sum());
        metrics.put("saveFailures", saveFailures.sum());
        metrics.put("saveFailureRate", String.format("%.2f%%", getSaveFailureRate()));

        metrics.put("autosaveAttempts", autosaveAttempts.sum());
        metrics.put("autosaveSuccesses", autosaveSuccesses.sum());
        metrics.put("autosaveFailures", autosaveFailures.sum());
        metrics.put("autosaveFailureRate", String.format("%.2f%%", getAutosaveFailureRate()));

        metrics.put("submitSpaAttempts", submitSpaAttempts.sum());
        metrics.put("submitSpaSuccesses", submitSpaSuccesses.sum());
        metrics.put("submitSpaFailures", submitSpaFailures.sum());

        metrics.put("pdfAttempts", pdfAttempts.sum());
        metrics.put("pdfSuccesses", pdfSuccesses.sum());
        metrics.put("pdfFailures", pdfFailures.sum());

        metrics.put("authFailures", authFailures.sum());
        metrics.put("dbLossCount", dbLossCount.sum());
        metrics.put("totalRecordedErrors", recentErrors.size());
        return metrics;
    }

    public void resetMetricsForTesting() {
        saveAttempts.reset();
        saveSuccesses.reset();
        saveFailures.reset();
        autosaveAttempts.reset();
        autosaveSuccesses.reset();
        autosaveFailures.reset();
        submitSpaAttempts.reset();
        submitSpaSuccesses.reset();
        submitSpaFailures.reset();
        pdfAttempts.reset();
        pdfSuccesses.reset();
        pdfFailures.reset();
        authFailures.reset();
        dbLossCount.reset();
        recentErrors.clear();
        lastAlertTimestamps.clear();
    }
}
