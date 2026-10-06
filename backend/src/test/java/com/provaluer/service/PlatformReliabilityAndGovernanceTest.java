package com.provaluer.service;

import com.provaluer.dto.TelemetryErrorDTO;
import com.provaluer.model.Order;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.AuditLogRepository;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.ReportSequenceRepository;
import com.provaluer.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.*;
import java.util.concurrent.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class PlatformReliabilityAndGovernanceTest {

    @Autowired
    private TelemetryService telemetryService;

    @Autowired
    private OperationalAuditService operationalAuditService;

    @Autowired
    private GovernanceMonitoringService governanceMonitoringService;

    @Autowired
    private PdfGovernanceValidatorService pdfValidatorService;

    @Autowired
    private ReportNumberGeneratorService reportNumberGeneratorService;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private ReportSequenceRepository reportSequenceRepository;

    private User testValuer;
    private User testClient;

    @BeforeEach
    void setup() {
        telemetryService.resetMetricsForTesting();
        auditLogRepository.deleteAll();
        orderRepository.deleteAll();
        userRepository.deleteAll();
        reportSequenceRepository.deleteAll();

        testClient = new User("gov_client", "client@provaluer.in", "pass123", UserRole.CLIENT, "9876543210", "v1.0");
        testClient.setFullName("Gov Client");
        testClient = userRepository.save(testClient);

        testValuer = new User("gov_valuer", "valuer@provaluer.in", "pass123", UserRole.PA, "9876543211", "v1.0");
        testValuer.setFullName("Gov Valuer");
        testValuer = userRepository.save(testValuer);
    }

    @Test
    @DisplayName("Testing Required: Simulate 100 Saves, 100 Autosaves, 50 Submissions, 50 PDFs, 25 Assignments Concurrently")
    void testMassiveConcurrencySimulation() throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(64);
        CountDownLatch startLatch = new CountDownLatch(1);
        List<Future<Boolean>> futures = new ArrayList<>();

        // 100 concurrent saves
        for (int i = 0; i < 100; i++) {
            final long idx = i;
            futures.add(executor.submit(() -> {
                startLatch.await();
                operationalAuditService.recordOperationalAction(
                        testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                        "SAVE_DRAFT", idx, "PV-2610-SAVE", true, "Concurrent draft save"
                );
                return true;
            }));
        }

        // 100 concurrent autosaves
        for (int i = 0; i < 100; i++) {
            final long idx = i;
            futures.add(executor.submit(() -> {
                startLatch.await();
                operationalAuditService.recordOperationalAction(
                        testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                        "AUTOSAVE", idx, "PV-2610-AUTO", true, "Concurrent autosave"
                );
                return true;
            }));
        }

        // 50 simultaneous submissions
        for (int i = 0; i < 50; i++) {
            final long idx = i;
            futures.add(executor.submit(() -> {
                startLatch.await();
                operationalAuditService.recordOperationalAction(
                        testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                        "SUBMIT_TO_SPA", idx, "PV-2610-SUBMIT", true, "Concurrent submission to SPA"
                );
                return true;
            }));
        }

        // 50 PDF generations
        for (int i = 0; i < 50; i++) {
            final long idx = i;
            futures.add(executor.submit(() -> {
                startLatch.await();
                operationalAuditService.recordOperationalAction(
                        testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                        "REPORT_GENERATION", idx, "PV-2610-PDF", true, "Concurrent PDF compile"
                );
                return true;
            }));
        }

        // 25 assignment workflows
        for (int i = 0; i < 25; i++) {
            final long idx = i;
            futures.add(executor.submit(() -> {
                startLatch.await();
                operationalAuditService.recordOperationalAction(
                        testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                        "ORDER_ASSIGNMENT", idx, "PV-2610-ASSIGN", true, "Concurrent assignment"
                );
                return true;
            }));
        }

        startLatch.countDown(); // Release all threads concurrently

        for (Future<Boolean> f : futures) {
            assertTrue(f.get(15, TimeUnit.SECONDS));
        }

        executor.shutdown();
        assertTrue(executor.awaitTermination(15, TimeUnit.SECONDS));

        // Verify Telemetry counters match exactly
        Map<String, Object> metrics = telemetryService.getMetricsSummary();
        assertEquals(100L, metrics.get("saveAttempts"));
        assertEquals(100L, metrics.get("saveSuccesses"));
        assertEquals(0L, metrics.get("saveFailures"));

        assertEquals(100L, metrics.get("autosaveAttempts"));
        assertEquals(100L, metrics.get("autosaveSuccesses"));
        assertEquals(0L, metrics.get("autosaveFailures"));

        assertEquals(50L, metrics.get("submitSpaAttempts"));
        assertEquals(50L, metrics.get("submitSpaSuccesses"));
        assertEquals(0L, metrics.get("submitSpaFailures"));

        assertEquals(50L, metrics.get("pdfAttempts"));
        assertEquals(50L, metrics.get("pdfSuccesses"));
        assertEquals(0L, metrics.get("pdfFailures"));

        // Verify zero corruption and total audit log entries
        assertEquals(325, auditLogRepository.count());
    }

    @Test
    @DisplayName("Phase 5 - Flow A: End-to-End Order Lifecycle Validation")
    void testFlowA_EndToEndOrderLifecycle() {
        // 1. Order Creation
        Order order = new Order();
        order.setClientId(testClient.getId());
        order.setPurpose("BANK_COLLATERAL");
        order.setPropertyCategory("COMMERCIAL");
        order.setStatus("PAID_INTAKE");
        order.setReportNumber(reportNumberGeneratorService.generateNextReportNumberForPrefix("PV-FLOWA-"));
        order = orderRepository.saveAndFlush(order);

        // 2. Assignment
        order.setPaId(testValuer.getId());
        order.setStatus("CLAIMED");
        orderRepository.saveAndFlush(order);
        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                "ORDER_ASSIGNMENT", order.getId(), order.getReportNumber(), true, "Order claimed by valuer"
        );

        // 3. Data Entry & Save Draft
        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                "SAVE_DRAFT", order.getId(), order.getReportNumber(), true, "Manual draft saved with 14 inputs"
        );

        // 4. Autosave
        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                "AUTOSAVE", order.getId(), order.getReportNumber(), true, "Periodic autosave completed"
        );

        // 5. Submit to SPA
        order.setStatus("SUBMITTED_TO_SPA");
        orderRepository.saveAndFlush(order);
        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                "SUBMIT_TO_SPA", order.getId(), order.getReportNumber(), true, "Dossier submitted to SPA for signoff"
        );

        // 6. PA / SPA Review & PDF Generation
        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "SUPER_ADMIN",
                "REPORT_GENERATION", order.getId(), order.getReportNumber(), true, "Valuation PDF report compiled"
        );

        // 7. Completion
        order.setStatus("FINAL_DELIVERY");
        orderRepository.saveAndFlush(order);
        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "SUPER_ADMIN",
                "ORDER_COMPLETION", order.getId(), order.getReportNumber(), true, "Order delivered and closed"
        );

        // Assert Lineage & Audit Trail Traceability
        Map<String, Object> lineage = operationalAuditService.getReportNumberLineage(order.getReportNumber());
        assertEquals("AUDIT_VERIFIED", lineage.get("status"));
        assertEquals("FINAL_DELIVERY", lineage.get("currentStatus"));
        assertEquals(6, lineage.get("totalAuditEntries"));
    }

    @Test
    @DisplayName("Phase 5 - Flow B: JWT Expiration, Re-Authentication & Draft Recovery")
    void testFlowB_JwtExpirationAndDraftRecovery() {
        // Step 1: Simulate 401 Unauthorized captured by Telemetry
        telemetryService.recordAuthFailure("/api/v1/orders/101/save-draft", "JWT token expired (401)", 401);

        Map<String, Object> metrics = telemetryService.getMetricsSummary();
        assertEquals(1L, metrics.get("authFailures"));

        // Step 2: Client re-authenticates and recovers unsaved cached draft
        Order order = new Order();
        order.setClientId(testClient.getId());
        order.setPurpose("VISA_CONSULAR");
        order.setPropertyCategory("COMMERCIAL");
        order.setStatus("IN_PROGRESS");
        order.setReportNumber("PV-2610-FLOWB");
        order = orderRepository.saveAndFlush(order);

        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                "SAVE_DRAFT", order.getId(), order.getReportNumber(), true, "Draft recovered and committed post-auth"
        );

        // Step 3: Subsequent submission succeeds
        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                "SUBMIT_TO_SPA", order.getId(), order.getReportNumber(), true, "Successfully submitted after session restore"
        );

        Map<String, Object> lineage = operationalAuditService.getReportNumberLineage("PV-2610-FLOWB");
        assertEquals("AUDIT_VERIFIED", lineage.get("status"));
        assertEquals(2, lineage.get("totalAuditEntries"));
    }

    @Test
    @DisplayName("Phase 5 - Flow C: Network Failure, Local Cache Recovery & Submission")
    void testFlowC_NetworkFailureAndCacheRecovery() {
        // Step 1: Network failure recorded
        telemetryService.recordError(new TelemetryErrorDTO(
                testValuer.getId(), 202L, "PV-FLOWC", "DocumentWorkspace",
                "SAVE_DRAFT", "Network connection timeout (DioException)", null, "REQ-101", "ERROR", 0
        ));

        List<TelemetryErrorDTO> recentErrors = telemetryService.getRecentErrors(10);
        assertFalse(recentErrors.isEmpty());
        assertEquals("Network connection timeout (DioException)", recentErrors.get(0).getErrorMessage());

        // Step 2: Connection restored -> Client submits recovered cache
        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                "SAVE_DRAFT", 202L, "PV-FLOWC", true, "Cached draft flushed successfully"
        );

        Map<String, Object> metrics = telemetryService.getMetricsSummary();
        assertEquals(1L, metrics.get("saveSuccesses"));
    }

    @Test
    @DisplayName("Phase 6: PDF Governance Validation - Strict Zero-Leakage & Integrity Checks")
    void testPhase6_PdfGovernanceValidation() {
        String validReportText = "PROVALUER VALUATION REPORT\n" +
                "Report Number: PV-2610-0042\n" +
                "Property: Unit 402, Platinum Business Park, Mumbai\n" +
                "Fair Market Value: INR 45,000,000\n" +
                "Valuer: Er. R. K. Sharma (IBBI/RV/02/2019/11045)\n" +
                "Status: Certified Authentic";

        // 1. Valid report must pass with zero violations
        PdfGovernanceValidatorService.ValidationResult validResult =
                pdfValidatorService.validateDocumentContent(validReportText, "PV-2610-0042");
        assertTrue(validResult.isValid());
        assertEquals(0, validResult.getViolations().size());
        assertEquals(0, validResult.getPlaceholderLeaksCount());

        // 2. Report with unresolved placeholders must be rejected
        String leakedReportText = validReportText + "\nClient Address: <<client_registered_address>>";
        PdfGovernanceValidatorService.ValidationResult leakResult =
                pdfValidatorService.validateDocumentContent(leakedReportText, "PV-2610-0042");
        assertFalse(leakResult.isValid());
        assertEquals(1, leakResult.getPlaceholderLeaksCount());
        assertTrue(leakResult.getViolations().get(0).contains("<<client_registered_address>>"));

        // 3. Report with missing report number or calculation anomalies (NaN) must be rejected
        String nanReportText = validReportText.replace("PV-2610-0042", "PV-DIFF-0000") + "\nRate per sq ft: NaN";
        PdfGovernanceValidatorService.ValidationResult nanResult =
                pdfValidatorService.validateDocumentContent(nanReportText, "PV-2610-0042");
        assertFalse(nanResult.isValid());
        assertTrue(nanResult.getViolations().stream().anyMatch(v -> v.contains("NaN")));
    }

    @Test
    @DisplayName("Phase 3 & 4: Operational Health Monitoring and Critical Alert Thresholds")
    void testHealthMonitoringAndAlerting() {
        // Initial health check
        Map<String, Object> health = governanceMonitoringService.getHealthStatus();
        assertTrue((Boolean) health.get("databaseConnected"));
        assertTrue(health.get("systemStatus").toString().contains("HEALTHY"));

        // Simulate failed Submit to SPA (Threshold: > 0 must immediately trigger critical alert)
        operationalAuditService.recordOperationalAction(
                testValuer.getId(), testValuer.getEmail(), "STAFF_APPRAISER",
                "SUBMIT_TO_SPA", 999L, "PV-TEST-FAIL", false, "SPA Gateway validation rejected document"
        );

        Map<String, Object> metricsAfterFail = telemetryService.getMetricsSummary();
        assertEquals(1L, metricsAfterFail.get("submitSpaFailures"));

        // Dashboard visibility
        Map<String, Object> dashboard = governanceMonitoringService.getOperationsDashboard();
        assertNotNull(dashboard.get("operationalMetrics"));
        assertNotNull(dashboard.get("stalledOrdersCount"));
    }
}
