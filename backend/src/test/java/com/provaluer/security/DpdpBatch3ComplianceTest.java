package com.provaluer.security;

import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.service.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * DPDP Act 2023 - Batch 3 Comprehensive Compliance Test Suite
 * Validates:
 * 1. Data Principal Rights (Sec 11, 12, 13, 14)
 * 2. Download My Data & Signed ZIP Export (Sec 11)
 * 3. Correction & Erasure Lifecycles (Sec 12)
 * 4. Secure Erasure & Cryptographic Deletion Certificates (Sec 12)
 * 5. Data Retention Engine & Configurable Policy Execution (Sec 8(7))
 * 6. Data Breach Registry & 72-Hour DPBI Notification Pipeline (Sec 8(6))
 * 7. Grievance Redressal with 7-Day SLA Tracking (Sec 13)
 * 8. Child / Minor Compliance & Guardian Consent Ledger (Sec 9)
 */
public class DpdpBatch3ComplianceTest {

    private UserRepository userRepository;
    private ConsentLedgerRepository consentLedgerRepository;
    private PrivacyCorrectionRequestRepository correctionRepository;
    private PrivacyErasureRequestRepository erasureRepository;
    private PrivacyNomineeRepository nomineeRepository;
    private GrievanceCaseRepository grievanceRepository;
    private OrderRepository orderRepository;
    private LeadDocumentRepository leadDocumentRepository;
    private DocumentAccessLogRepository accessLogRepository;
    private RetentionPolicyRepository retentionPolicyRepository;
    private RetentionEventRepository retentionEventRepository;
    private RetentionExecutionLogRepository retentionExecutionLogRepository;
    private DeletionCertificateRepository deletionCertificateRepository;
    private DataBreachIncidentRepository breachRepository;
    private BreachNotificationLogRepository notificationLogRepository;
    private GuardianConsentLedgerRepository guardianConsentRepository;
    private EncryptionStatusService encryptionStatusService;

    private DataPrincipalRightsService principalRightsService;
    private SecureDeletionService secureDeletionService;
    private DataRetentionScheduler retentionScheduler;
    private DpdpBreachNotificationService breachNotificationService;
    private AgeVerificationService ageVerificationService;

    @BeforeEach
    public void setup() {
        userRepository = mock(UserRepository.class);
        consentLedgerRepository = mock(ConsentLedgerRepository.class);
        correctionRepository = mock(PrivacyCorrectionRequestRepository.class);
        erasureRepository = mock(PrivacyErasureRequestRepository.class);
        nomineeRepository = mock(PrivacyNomineeRepository.class);
        grievanceRepository = mock(GrievanceCaseRepository.class);
        orderRepository = mock(OrderRepository.class);
        leadDocumentRepository = mock(LeadDocumentRepository.class);
        accessLogRepository = mock(DocumentAccessLogRepository.class);
        retentionPolicyRepository = mock(RetentionPolicyRepository.class);
        retentionEventRepository = mock(RetentionEventRepository.class);
        retentionExecutionLogRepository = mock(RetentionExecutionLogRepository.class);
        deletionCertificateRepository = mock(DeletionCertificateRepository.class);
        breachRepository = mock(DataBreachIncidentRepository.class);
        notificationLogRepository = mock(BreachNotificationLogRepository.class);
        guardianConsentRepository = mock(GuardianConsentLedgerRepository.class);
        encryptionStatusService = mock(EncryptionStatusService.class);

        // 1. DataPrincipalRightsService
        principalRightsService = new DataPrincipalRightsService();
        inject(principalRightsService, "userRepository", userRepository);
        inject(principalRightsService, "consentLedgerRepository", consentLedgerRepository);
        inject(principalRightsService, "correctionRepository", correctionRepository);
        inject(principalRightsService, "erasureRepository", erasureRepository);
        inject(principalRightsService, "nomineeRepository", nomineeRepository);
        inject(principalRightsService, "grievanceRepository", grievanceRepository);
        inject(principalRightsService, "orderRepository", orderRepository);
        inject(principalRightsService, "accessLogRepository", accessLogRepository);
        inject(principalRightsService, "retentionPolicyRepository", retentionPolicyRepository);
        inject(principalRightsService, "breachRepository", breachRepository);
        inject(principalRightsService, "encryptionStatusService", encryptionStatusService);

        // 2. SecureDeletionService
        secureDeletionService = new SecureDeletionService();
        inject(secureDeletionService, "erasureRequestRepository", erasureRepository);
        inject(secureDeletionService, "certificateRepository", deletionCertificateRepository);
        inject(secureDeletionService, "userRepository", userRepository);
        inject(secureDeletionService, "grievanceCaseRepository", grievanceRepository);

        // 3. DataRetentionScheduler
        retentionScheduler = new DataRetentionScheduler();
        inject(retentionScheduler, "policyRepository", retentionPolicyRepository);
        inject(retentionScheduler, "eventRepository", retentionEventRepository);
        inject(retentionScheduler, "executionLogRepository", retentionExecutionLogRepository);

        // 4. DpdpBreachNotificationService
        breachNotificationService = new DpdpBreachNotificationService();
        inject(breachNotificationService, "breachRepository", breachRepository);
        inject(breachNotificationService, "notificationLogRepository", notificationLogRepository);

        // 5. AgeVerificationService
        ageVerificationService = new AgeVerificationService();
        inject(ageVerificationService, "guardianConsentRepository", guardianConsentRepository);
    }

    private void inject(Object target, String fieldName, Object val) {
        try {
            java.lang.reflect.Field field = target.getClass().getDeclaredField(fieldName);
            field.setAccessible(true);
            field.set(target, val);
        } catch (Exception e) {
            throw new RuntimeException("Injection failed for field " + fieldName, e);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. DATA PRINCIPAL PROFILE SUMMARY & EXPORT (Sec 11)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Phase A: Profile Summary delivers full DPDP Section 11 transparency")
    public void testGetProfileSummary() {
        User user = new User("aditi", "aditi@example.com", "secret", UserRole.CLIENT, "+91 98765 43210", "v2.4");
        user.setId(101L);
        user.setFullName("Aditi Sharma");
        user.setDpdpConsentGiven(true);
        user.setDpdpConsentVersion("DPDP-NOTICE-V1.0");

        when(userRepository.findById(101L)).thenReturn(Optional.of(user));
        when(orderRepository.findAllByClientId(101L)).thenReturn(Collections.emptyList());
        when(consentLedgerRepository.findByUserIdOrderByCreatedAtDesc(101L)).thenReturn(Collections.emptyList());

        Map<String, Object> summary = principalRightsService.getProfileSummary(101L, "aditi@example.com");

        assertNotNull(summary);
        assertEquals("Aditi Sharma", summary.get("name"));
        assertEquals("aditi@example.com", summary.get("email"));
        assertEquals("+91 98765 43210", summary.get("mobile"));
        assertEquals("CLIENT", summary.get("role"));
        assertNotNull(summary.get("dataCollected"));
        assertNotNull(summary.get("purposesOfProcessing"));
        assertNotNull(summary.get("thirdPartiesWithAccess"));
    }

    @Test
    @DisplayName("Phase A: Export My Data produces valid ZIP package with privacy_export.json")
    public void testExportMyDataZip() throws IOException {
        User user = new User("rahul", "rahul@example.com", "secret", UserRole.CLIENT, "+91 91234 56789", "v2.4");
        user.setId(102L);
        user.setFullName("Rahul Verma");

        when(userRepository.findById(102L)).thenReturn(Optional.of(user));
        when(orderRepository.findAllByClientId(102L)).thenReturn(Collections.emptyList());
        when(consentLedgerRepository.findByUserIdOrderByCreatedAtDesc(102L)).thenReturn(Collections.emptyList());
        when(correctionRepository.findByUserIdOrderByCreatedAtDesc(102L)).thenReturn(Collections.emptyList());
        when(erasureRepository.findByUserIdOrderByCreatedAtDesc(102L)).thenReturn(Collections.emptyList());
        when(nomineeRepository.findByUserIdOrderByCreatedAtDesc(102L)).thenReturn(Collections.emptyList());
        when(grievanceRepository.findByUserIdOrderByCreatedAtDesc(102L)).thenReturn(Collections.emptyList());

        byte[] zipBytes = principalRightsService.exportMyDataZip(102L, "rahul@example.com", "127.0.0.1", "JUnit-Test");

        assertNotNull(zipBytes);
        assertTrue(zipBytes.length > 0);

        Set<String> entries = new HashSet<>();
        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(zipBytes))) {
            ZipEntry e;
            while ((e = zis.getNextEntry()) != null) {
                entries.add(e.getName());
                zis.closeEntry();
            }
        }

        assertTrue(entries.contains("privacy_export.json"), "Must contain privacy_export.json");
        assertTrue(entries.contains("README.txt"), "Must contain README.txt verification statement");
        verify(accessLogRepository, times(1)).save(any(DocumentAccessLog.class));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. CORRECTION REQUESTS (Sec 12)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Phase A: Correction request creates persistent SUBMITTED record")
    public void testCreateCorrectionRequest() {
        when(correctionRepository.save(any(PrivacyCorrectionRequest.class))).thenAnswer(i -> {
            PrivacyCorrectionRequest r = i.getArgument(0);
            r.setId(501L);
            return r;
        });

        PrivacyCorrectionRequest req = principalRightsService.createCorrectionRequest(
                201L, "mobileNumber", "+91 99999 11111", "+91 98888 22222", "Updated contact mobile"
        );

        assertNotNull(req);
        assertEquals(501L, req.getId());
        assertEquals("SUBMITTED", req.getStatus());
        assertEquals("mobileNumber", req.getFieldName());
        assertEquals("+91 98888 22222", req.getRequestedValue());
        assertTrue(req.getRequestId().startsWith("CORR-"));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. ERASURE REQUESTS & SECURE ERASURE CERTIFICATE (Sec 12)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Phase C: Erasure request is created and SecureDeletionService executes irreversible purge")
    public void testErasureAndSecureDeletionCertificate() {
        // Step 1: Create Erasure Request
        when(erasureRepository.save(any(PrivacyErasureRequest.class))).thenAnswer(i -> {
            PrivacyErasureRequest r = i.getArgument(0);
            r.setId(777L);
            return r;
        });

        PrivacyErasureRequest erasureReq = principalRightsService.createErasureRequest(301L, "Account termination");
        assertNotNull(erasureReq);
        assertEquals("SUBMITTED", erasureReq.getStatus());
        assertFalse(erasureReq.isLegalHoldFlag());

        // Step 2: Execute Secure Erasure
        User targetUser = new User("priya", "priya@example.com", "pass", UserRole.CLIENT, "+91 90000 12345", "v2.4");
        targetUser.setId(301L);

        when(erasureRepository.findById(777L)).thenReturn(Optional.of(erasureReq));
        when(userRepository.findById(301L)).thenReturn(Optional.of(targetUser));
        when(grievanceRepository.findByUserIdOrderByCreatedAtDesc(301L)).thenReturn(Collections.emptyList());
        when(deletionCertificateRepository.save(any(DeletionCertificate.class))).thenAnswer(i -> {
            DeletionCertificate c = i.getArgument(0);
            c.setId(888L);
            return c;
        });

        DeletionCertificate cert = secureDeletionService.executeErasure(777L, "DPO-INSPECTOR");

        assertNotNull(cert);
        assertEquals(888L, cert.getId());
        assertEquals(301L, cert.getUserId());
        assertTrue(cert.getCertificateNumber().startsWith("DEL-CERT-"));
        assertNotNull(cert.getHashSignature());
        assertEquals("COMPLETED", erasureReq.getStatus());

        // Verify user profile is unlinked and pseudonymized
        assertEquals("DPDP Purged Subject", targetUser.getFullName());
        assertEquals("0000000000", targetUser.getMobileNumber());
        assertTrue(targetUser.isLocked());

        // Step 3: Certificate Download Generation
        when(deletionCertificateRepository.findById(888L)).thenReturn(Optional.of(cert));
        byte[] certDownload = secureDeletionService.generateCertificateDownload(888L);
        assertNotNull(certDownload);
        assertTrue(certDownload.length > 50);
        String text = new String(certDownload);
        assertTrue(text.contains("PROVALUER COMMERCIAL - DATA ERASURE CERTIFICATE"));
        assertTrue(text.contains(cert.getCertificateNumber()));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. NOMINEE MANAGEMENT (Sec 14)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Phase A: Nominee registration and deletion under DPDP Section 14")
    public void testNomineeLifecycle() {
        when(nomineeRepository.save(any(PrivacyNominee.class))).thenAnswer(i -> {
            PrivacyNominee n = i.getArgument(0);
            n.setId(901L);
            return n;
        });

        PrivacyNominee nominee = principalRightsService.createNominee(
                401L, "Vikram Malhotra", "Spouse", "+91 98765 00000", "vikram@example.com", "Hyderabad, India"
        );

        assertNotNull(nominee);
        assertEquals(901L, nominee.getId());
        assertEquals("Vikram Malhotra", nominee.getNomineeName());
        assertEquals("REGISTERED", nominee.getVerificationStatus());

        // Test deletion
        when(nomineeRepository.findById(901L)).thenReturn(Optional.of(nominee));
        boolean deleted = principalRightsService.deleteNominee(901L, 401L);
        assertTrue(deleted);
        verify(nomineeRepository, times(1)).delete(nominee);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. RETENTION POLICY EXECUTION (Sec 8(7))
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Phase B: DataRetentionScheduler runs automated scan across active retention policies")
    public void testDataRetentionSchedulerExecution() {
        RetentionPolicy policy1 = new RetentionPolicy("LEADS", 180, "Pre-engagement enquiry", "ENCRYPTED_COLD_STORAGE", "HARD_PURGE");
        RetentionPolicy policy2 = new RetentionPolicy("DRAFT_WORKSPACES", 30, "Unsubmitted drafts", "LOCAL_EPHEMERAL", "PURGE");

        when(retentionPolicyRepository.findAll()).thenReturn(List.of(policy1, policy2));
        when(retentionExecutionLogRepository.save(any(RetentionExecutionLog.class))).thenAnswer(i -> {
            RetentionExecutionLog l = i.getArgument(0);
            l.setId(1001L);
            return l;
        });

        RetentionExecutionLog execLog = retentionScheduler.executeRetentionRun("ADMIN_CONSOLE");

        assertNotNull(execLog);
        assertEquals("SUCCESS", execLog.getStatus());
        assertNotNull(execLog.getExecutionTimestamp());
        assertNotNull(execLog.getSummary());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 6. DATA BREACH REGISTRY & DPBI NOTIFICATION (Sec 8(6))
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Phase D & E: Data Breach Registry and Statutory DPBI Notice Pipeline")
    public void testDataBreachAndDpbiNotification() {
        DataBreachIncident incident = new DataBreachIncident();
        incident.setId(555L);
        incident.setIncidentId("BREACH-2026-TEST01");
        incident.setDiscoveryTime(LocalDateTime.now().minusHours(2));
        incident.setSeverity("HIGH");
        incident.setStatus("OPEN");
        incident.setRootCause("Misconfigured public bucket");
        incident.setImpactAssessment("10 Valuation draft summaries read");
        incident.setNumberAffected(10);
        incident.setDataImpacted("Property addresses");
        incident.setSystemsImpacted("Cloud Storage Bucket");

        when(breachRepository.save(any(DataBreachIncident.class))).thenAnswer(i -> {
            DataBreachIncident b = i.getArgument(0);
            if (b.getId() == null) b.setId(555L);
            return b;
        });
        when(breachRepository.findByIncidentId("BREACH-2026-TEST01")).thenReturn(Optional.of(incident));
        when(notificationLogRepository.save(any(BreachNotificationLog.class))).thenAnswer(i -> {
            BreachNotificationLog l = i.getArgument(0);
            l.setId(999L);
            return l;
        });

        // 1. Register
        DataBreachIncident savedIncident = breachNotificationService.registerIncident(
                "HIGH", "Misconfigured public bucket", "10 Valuation draft summaries read", 10, "Property addresses", "Cloud Storage Bucket"
        );
        assertNotNull(savedIncident);
        assertEquals("HIGH", savedIncident.getSeverity());
        assertEquals("OPEN", savedIncident.getStatus());

        // 2. Dispatch Statutory DPBI Notice
        BreachNotificationLog dpbiNotice = breachNotificationService.notifyDpbi("BREACH-2026-TEST01", "DPO-LEAD");
        assertNotNull(dpbiNotice);
        assertEquals(999L, dpbiNotice.getId());
        assertEquals("DPBI_BOARD_NOTICE", dpbiNotice.getNotificationType());
        assertEquals("DISPATCHED", dpbiNotice.getDeliveryStatus());
        assertEquals("NOTIFIED", incident.getStatus());
        assertTrue(dpbiNotice.getContentPayload().contains("FORM DPBI-1: STATUTORY NOTICE OF PERSONAL DATA BREACH"));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 7. GRIEVANCE REDRESSAL SYSTEM (Sec 13)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Phase F: Grievance case registration, 7-day SLA assignment, and escalation")
    public void testGrievanceWorkflow() {
        when(grievanceRepository.save(any(GrievanceCase.class))).thenAnswer(i -> {
            GrievanceCase g = i.getArgument(0);
            if (g.getId() == null) g.setId(701L);
            return g;
        });

        // Step 1: Submit Complaint
        GrievanceCase grv = principalRightsService.createGrievance(
                601L, "user@example.com", "CONSENT_VIOLATION", "Marketing call received despite consent withdrawal"
        );

        assertNotNull(grv);
        assertEquals(701L, grv.getId());
        assertEquals("SUBMITTED", grv.getStatus());
        assertEquals(1, grv.getEscalationLevel());
        assertNotNull(grv.getSlaDueDate());
        assertTrue(grv.getSlaDueDate().isAfter(LocalDateTime.now().plusDays(6)), "Must enforce 7-day SLA standard");

        // Step 2: Escalate
        when(grievanceRepository.findById(701L)).thenReturn(Optional.of(grv));
        GrievanceCase escalated = principalRightsService.escalateGrievance(701L, 601L, "No response after 48 hours");

        assertNotNull(escalated);
        assertEquals("UNDER_REVIEW", escalated.getStatus());
        assertEquals(2, escalated.getEscalationLevel());
        assertEquals("Chief Legal Officer & Supervisory DPO", escalated.getAssignedOfficer());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 8. CHILD / MINOR COMPLIANCE & GUARDIAN CONSENT (Sec 9)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Phase H: Date of Birth evaluation accurately detects minors and records Guardian Consent")
    public void testMinorDetectionAndGuardianConsent() {
        // Adult test (28 years old)
        LocalDate adultDob = LocalDate.now().minusYears(28);
        AgeVerificationService.AgeEvaluationResult adultEval = ageVerificationService.evaluateAge(adultDob);
        assertFalse(adultEval.isMinor);
        assertEquals(28, adultEval.calculatedAge);
        assertFalse(adultEval.requiresGuardianConsent);

        // Minor test (15 years old)
        LocalDate minorDob = LocalDate.now().minusYears(15);
        AgeVerificationService.AgeEvaluationResult minorEval = ageVerificationService.evaluateAge(minorDob);
        assertTrue(minorEval.isMinor);
        assertEquals(15, minorEval.calculatedAge);
        assertTrue(minorEval.requiresGuardianConsent);
        assertTrue(minorEval.statusMessage.contains("requires verifiable parental/guardian consent"));

        // Guardian consent capture
        when(guardianConsentRepository.save(any(GuardianConsentLedger.class))).thenAnswer(i -> {
            GuardianConsentLedger g = i.getArgument(0);
            g.setId(801L);
            return g;
        });

        GuardianConsentLedger consent = ageVerificationService.recordGuardianConsent(
                101L, 201L, minorDob, "Ramesh Nambiar", "Father", "+91 94444 55555", "ramesh.nambiar@example.com",
                true, "10.0.0.1", "Mozilla/5.0", "DPDP-CHILD-NOTICE-V1.0"
        );

        assertNotNull(consent);
        assertEquals(801L, consent.getId());
        assertEquals("Ramesh Nambiar", consent.getGuardianName());
        assertEquals("Father", consent.getGuardianRelationship());
        assertFalse(consent.isWithdrawn());

        // Guardian consent withdrawal
        when(guardianConsentRepository.findById(801L)).thenReturn(Optional.of(consent));
        boolean withdrawn = ageVerificationService.withdrawGuardianConsent(801L);
        assertTrue(withdrawn);
        assertTrue(consent.isWithdrawn());
        assertNotNull(consent.getWithdrawnAt());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 9. GOVERNANCE COMMAND CENTER TELEMETRY (Phase G)
    // ─────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Phase G: Governance Command Center KPI Telemetry and 98% Health Score")
    public void testGovernanceSummaryAggregation() {
        when(consentLedgerRepository.count()).thenReturn(150L);
        when(correctionRepository.findAll()).thenReturn(Collections.emptyList());
        when(erasureRepository.findAll()).thenReturn(Collections.emptyList());
        when(nomineeRepository.count()).thenReturn(12L);
        when(grievanceRepository.countByStatus("SUBMITTED")).thenReturn(2L);
        when(grievanceRepository.countByStatus("UNDER_REVIEW")).thenReturn(1L);
        when(breachRepository.count()).thenReturn(0L);
        when(retentionPolicyRepository.count()).thenReturn(8L);
        when(encryptionStatusService.getSecurityDashboardSummary()).thenReturn(Map.of("coverage", "100%"));

        Map<String, Object> summary = principalRightsService.getGovernanceSummary();

        assertNotNull(summary);
        assertEquals(150L, summary.get("totalConsents"));
        assertEquals(12L, summary.get("registeredNominees"));
        assertEquals(3L, summary.get("openGrievances"));
        assertEquals(98, summary.get("complianceHealthScore"));
        assertEquals("HEALTHY", summary.get("status"));
    }
}
