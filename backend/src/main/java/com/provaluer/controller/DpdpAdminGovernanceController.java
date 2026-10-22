package com.provaluer.controller;

import com.provaluer.model.BreachNotificationLog;
import com.provaluer.model.DataBreachIncident;
import com.provaluer.model.DeletionCertificate;
import com.provaluer.model.GrievanceCase;
import com.provaluer.model.RetentionExecutionLog;
import com.provaluer.repository.GrievanceCaseRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.DataPrincipalRightsService;
import com.provaluer.service.DataRetentionScheduler;
import com.provaluer.service.DpdpBreachNotificationService;
import com.provaluer.service.SecureDeletionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * DPDP Act 2023 - Privacy Governance Command Center Controller
 * Dedicated to Super Admin and Legal Compliance Officers.
 */
@RestController
@RequestMapping("/api/v1/admin/privacy")
@PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
@CrossOrigin(origins = "*", maxAge = 3600)
public class DpdpAdminGovernanceController {

    @Autowired private DataPrincipalRightsService rightsService;
    @Autowired private DataRetentionScheduler retentionScheduler;
    @Autowired private SecureDeletionService secureDeletionService;
    @Autowired private DpdpBreachNotificationService breachService;
    @Autowired private GrievanceCaseRepository grievanceRepository;

    /**
     * Phase G: Governance Command Center KPI Summary
     */
    @GetMapping("/governance-summary")
    public ResponseEntity<Map<String, Object>> getGovernanceSummary() {
        return ResponseEntity.ok(rightsService.getGovernanceSummary());
    }

    /**
     * Phase B: Trigger on-demand retention execution
     */
    @PostMapping("/retention/execute")
    public ResponseEntity<RetentionExecutionLog> executeRetentionRun(
            @AuthenticationPrincipal UserDetailsImpl principal) {
        String officer = (principal != null) ? principal.getUsername() : "SUPER_ADMIN";
        return ResponseEntity.ok(retentionScheduler.executeRetentionRun(officer));
    }

    /**
     * Phase C: Approve erasure request and execute secure deletion
     */
    @PostMapping("/erasure/{requestId}/approve-and-execute")
    public ResponseEntity<DeletionCertificate> approveAndExecuteErasure(
            @PathVariable Long requestId,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        String officer = (principal != null) ? principal.getUsername() : "Data Protection Officer";
        DeletionCertificate cert = secureDeletionService.executeErasure(requestId, officer);
        return ResponseEntity.ok(cert);
    }

    /**
     * Phase C: Download official Deletion Certificate
     */
    @GetMapping("/deletion-certificates/{id}/download")
    public ResponseEntity<byte[]> downloadCertificate(@PathVariable Long id) {
        byte[] certBytes = secureDeletionService.generateCertificateDownload(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"deletion_certificate_" + id + ".txt\"")
                .contentType(MediaType.TEXT_PLAIN)
                .body(certBytes);
    }

    /**
     * Phase D: Register Data Breach Incident
     */
    @PostMapping("/breaches")
    public ResponseEntity<DataBreachIncident> registerBreach(
            @RequestBody Map<String, Object> body) {
        String severity = (String) body.get("severity");
        String rootCause = (String) body.get("rootCause");
        String impact = (String) body.get("impactAssessment");
        int affected = body.containsKey("numberAffected") ? ((Number) body.get("numberAffected")).intValue() : 0;
        String dataImpacted = (String) body.get("dataImpacted");
        String systemsImpacted = (String) body.get("systemsImpacted");

        DataBreachIncident incident = breachService.registerIncident(
                severity, rootCause, impact, affected, dataImpacted, systemsImpacted
        );
        return ResponseEntity.ok(incident);
    }

    @GetMapping("/breaches")
    public ResponseEntity<List<DataBreachIncident>> listBreaches() {
        return ResponseEntity.ok(breachService.listAllIncidents());
    }

    /**
     * Phase E: Dispatch statutory notice to DPBI under Section 8(6)
     */
    @PostMapping("/breaches/{incidentId}/notify-dpbi")
    public ResponseEntity<BreachNotificationLog> notifyDpbi(
            @PathVariable String incidentId,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        String officer = (principal != null) ? principal.getUsername() : "Data Protection Officer";
        return ResponseEntity.ok(breachService.notifyDpbi(incidentId, officer));
    }

    /**
     * Phase F: Grievances Management
     */
    @GetMapping("/grievances")
    public ResponseEntity<List<GrievanceCase>> listAllGrievances() {
        return ResponseEntity.ok(grievanceRepository.findAllByOrderByCreatedAtDesc());
    }

    @PostMapping("/grievances/{id}/resolve")
    public ResponseEntity<GrievanceCase> resolveGrievance(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        GrievanceCase grv = grievanceRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Grievance ticket not found: " + id));

        grv.setStatus("RESOLVED");
        grv.setResolutionNotes(body.get("resolutionNotes"));
        grv.setAssignedOfficer((principal != null) ? principal.getUsername() : "DPO Officer");
        grv.setUpdatedAt(LocalDateTime.now());

        return ResponseEntity.ok(grievanceRepository.save(grv));
    }
}
