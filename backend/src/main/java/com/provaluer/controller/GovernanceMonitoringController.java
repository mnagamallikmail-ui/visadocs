package com.provaluer.controller;

import com.provaluer.dto.TelemetryErrorDTO;
import com.provaluer.service.GovernanceMonitoringService;
import com.provaluer.service.OperationalAuditService;
import com.provaluer.service.TelemetryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Enterprise Production Governance & Observability Controller.
 * Provides endpoints for centralized error telemetry, real-time health monitoring,
 * report lineage auditing, and the admin operations dashboard.
 */
@RestController
@RequestMapping("/api/v1")
public class GovernanceMonitoringController {

    @Autowired
    private TelemetryService telemetryService;

    @Autowired
    private GovernanceMonitoringService monitoringService;

    @Autowired
    private OperationalAuditService operationalAuditService;

    /**
     * Phase 1: Ingestion of frontend exceptions and telemetry errors.
     */
    @PostMapping("/telemetry/errors")
    public ResponseEntity<?> ingestTelemetryError(@RequestBody TelemetryErrorDTO errorDto) {
        telemetryService.recordError(errorDto);
        return ResponseEntity.ok(Map.of("status", "RECORDED"));
    }

    /**
     * Phase 3: Operational Health Status Endpoint.
     */
    @GetMapping("/governance/health")
    public ResponseEntity<?> getOperationalHealth() {
        return ResponseEntity.ok(monitoringService.getHealthStatus());
    }

    /**
     * Phase 3: Metrics Summary Endpoint.
     */
    @GetMapping("/governance/metrics")
    public ResponseEntity<?> getMetricsSummary() {
        return ResponseEntity.ok(telemetryService.getMetricsSummary());
    }

    /**
     * Phase 8: Admin Operations Dashboard.
     */
    @GetMapping("/governance/operations-dashboard")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> getOperationsDashboard() {
        return ResponseEntity.ok(monitoringService.getOperationsDashboard());
    }

    /**
     * Phase 7: End-to-End Report Lineage Audit.
     */
    @GetMapping("/governance/audit/report/{reportNumber}/lineage")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> getReportLineage(@PathVariable String reportNumber) {
        return ResponseEntity.ok(operationalAuditService.getReportNumberLineage(reportNumber));
    }
}
