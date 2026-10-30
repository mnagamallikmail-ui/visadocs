package com.provaluer.controller;

import com.provaluer.model.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.AgeVerificationService;
import com.provaluer.service.DataPrincipalRightsService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDate;
import java.util.Map;

/**
 * DPDP Act 2023 - Client Self-Service Privacy & Data Principal Rights Controller
 * Exposes Sections 9 (Child Consent), 11 (Access/Export), 12 (Correction/Erasure), 13 (Grievances), and 14 (Nominees).
 */
@RestController
@RequestMapping("/api/v1/privacy")
@CrossOrigin(origins = "*", maxAge = 3600)
public class DpdpDataPrincipalController {

    @Autowired
    private DataPrincipalRightsService rightsService;

    @Autowired
    private AgeVerificationService ageVerificationService;

    /**
     * Feature 1: Personal Data Summary (Section 11)
     */
    @GetMapping("/profile-summary")
    public ResponseEntity<?> getProfileSummary(
            @AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Authentication required to access personal data summary"));
        }
        return ResponseEntity.ok(rightsService.getProfileSummary(principal.getId(), principal.getEmail()));
    }

    /**
     * Feature 1b: Update Profile (Section 12)
     */
    @PostMapping("/update-profile")
    public ResponseEntity<?> updateProfile(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Authentication required to update profile"));
        }
        return ResponseEntity.ok(rightsService.updateUserProfile(
                principal.getId(),
                body.get("fullName"),
                body.get("mobileNumber")
        ));
    }

    /**
     * Feature 2: Consent History (Section 6)
     */
    @GetMapping("/consent-history")
    public ResponseEntity<?> getConsentHistory(
            @AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Authentication required to access consent history"));
        }
        String actor = principal.getEmail() != null ? principal.getEmail() : principal.getUsername();
        return ResponseEntity.ok(rightsService.getConsentHistory(principal.getId(), actor));
    }

    /**
     * Feature 3: Download My Data (Section 11) - Signed ZIP Export
     */
    @GetMapping("/export")
    public ResponseEntity<?> exportMyData(
            @AuthenticationPrincipal UserDetailsImpl principal,
            HttpServletRequest request) throws IOException {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("error", "Authentication required for data principal export package"));
        }
        String actor = principal.getEmail() != null ? principal.getEmail() : principal.getUsername();
        String ip = extractClientIp(request);
        String ua = request.getHeader(HttpHeaders.USER_AGENT);

        byte[] zipArchive = rightsService.exportMyDataZip(principal.getId(), actor, ip, ua);

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"privacy_export_" + principal.getId() + "_" + System.currentTimeMillis() + ".zip\"")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(zipArchive);
    }

    /**
     * Feature 4: Correction Requests (Section 12)
     */
    @PostMapping("/correction-request")
    public ResponseEntity<?> submitCorrectionRequest(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) return ResponseEntity.status(401).body("Authentication required");

        PrivacyCorrectionRequest req = rightsService.createCorrectionRequest(
                principal.getId(),
                body.get("fieldName"),
                body.get("existingValue"),
                body.get("requestedValue"),
                body.get("reason")
        );
        return ResponseEntity.ok(req);
    }

    @GetMapping("/correction-requests")
    public ResponseEntity<?> listCorrectionRequests(@AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) return ResponseEntity.status(401).body("Authentication required");
        return ResponseEntity.ok(rightsService.getCorrectionRequests(principal.getId()));
    }

    /**
     * Feature 5: Erasure Requests (Section 12)
     */
    @PostMapping("/erasure-request")
    public ResponseEntity<?> submitErasureRequest(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) return ResponseEntity.status(401).body("Authentication required");

        PrivacyErasureRequest req = rightsService.createErasureRequest(
                principal.getId(),
                body.get("reason")
        );
        return ResponseEntity.ok(req);
    }

    @GetMapping("/erasure-requests")
    public ResponseEntity<?> listErasureRequests(@AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) return ResponseEntity.status(401).body("Authentication required");
        return ResponseEntity.ok(rightsService.getErasureRequests(principal.getId()));
    }

    /**
     * Feature 6: Nominee Management (Section 14)
     */
    @PostMapping("/nominees")
    public ResponseEntity<?> registerNominee(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) return ResponseEntity.status(401).body("Authentication required");

        PrivacyNominee nominee = rightsService.createNominee(
                principal.getId(),
                body.get("nomineeName"),
                body.get("relationship"),
                body.get("mobile"),
                body.get("email"),
                body.get("address")
        );
        return ResponseEntity.ok(nominee);
    }

    @GetMapping("/nominees")
    public ResponseEntity<?> listNominees(@AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) return ResponseEntity.status(401).body("Authentication required");
        return ResponseEntity.ok(rightsService.getNominees(principal.getId()));
    }

    @DeleteMapping("/nominees/{id}")
    public ResponseEntity<?> deleteNominee(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) return ResponseEntity.status(401).body("Authentication required");
        boolean removed = rightsService.deleteNominee(id, principal.getId());
        return removed ? ResponseEntity.ok(Map.of("status", "DELETED")) : ResponseEntity.notFound().build();
    }

    /**
     * Feature 7: Grievances (Section 13)
     */
    @PostMapping("/grievances")
    public ResponseEntity<?> submitGrievance(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        Long userId = (principal != null) ? principal.getId() : 0L;
        String email = (principal != null) ? principal.getEmail() : body.get("email");

        GrievanceCase grv = rightsService.createGrievance(
                userId, email, body.get("category"), body.get("description")
        );
        return ResponseEntity.ok(grv);
    }

    @GetMapping("/grievances")
    public ResponseEntity<?> listGrievances(@AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) return ResponseEntity.status(401).body("Authentication required");
        return ResponseEntity.ok(rightsService.getGrievances(principal.getId()));
    }

    @PostMapping("/grievances/{id}/escalate")
    public ResponseEntity<?> escalateGrievance(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {
        if (principal == null) return ResponseEntity.status(401).body("Authentication required");
        String reason = body != null ? body.get("reason") : null;
        return ResponseEntity.ok(rightsService.escalateGrievance(id, principal.getId(), reason));
    }

    /**
     * Phase H: Age Verification & Guardian Consent (Section 9)
     */
    @PostMapping("/age-verification")
    public ResponseEntity<?> verifyAge(@RequestBody Map<String, String> body) {
        LocalDate dob = LocalDate.parse(body.get("dateOfBirth"));
        return ResponseEntity.ok(ageVerificationService.evaluateAge(dob));
    }

    @PostMapping("/guardian-consent")
    public ResponseEntity<?> recordGuardianConsent(
            @RequestBody Map<String, Object> body,
            HttpServletRequest request) {
        LocalDate dob = LocalDate.parse((String) body.get("applicantDob"));
        Long orderId = body.containsKey("orderId") ? ((Number) body.get("orderId")).longValue() : null;
        Long leadId = body.containsKey("leadId") ? ((Number) body.get("leadId")).longValue() : null;
        boolean consent = Boolean.TRUE.equals(body.get("consentGiven"));

        GuardianConsentLedger saved = ageVerificationService.recordGuardianConsent(
                orderId, leadId, dob,
                (String) body.get("guardianName"),
                (String) body.get("relationship"),
                (String) body.get("guardianPhone"),
                (String) body.get("guardianEmail"),
                consent,
                extractClientIp(request),
                request.getHeader(HttpHeaders.USER_AGENT),
                (String) body.getOrDefault("noticeVersion", "v1.0")
        );
        return ResponseEntity.ok(saved);
    }

    private String extractClientIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.isEmpty()) {
            return xf.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
