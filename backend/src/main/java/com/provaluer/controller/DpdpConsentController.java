package com.provaluer.controller;

import com.provaluer.model.ConsentLedger;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.DpdpConsentService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/privacy")
@CrossOrigin(origins = "*", maxAge = 3600)
public class DpdpConsentController {

    @Autowired
    private DpdpConsentService dpdpConsentService;

    @GetMapping("/governance")
    public ResponseEntity<Map<String, Object>> getGovernanceMetadata() {
        return ResponseEntity.ok(dpdpConsentService.getGovernanceMetadata());
    }

    @PostMapping("/consent")
    public ResponseEntity<?> recordConsent(@RequestBody ConsentRequest request, HttpServletRequest httpRequest) {
        String ip = extractClientIp(httpRequest);
        String userAgent = httpRequest.getHeader("User-Agent");

        Long userId = null;
        String actor = request.getActorIdentifier();

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetailsImpl) {
            UserDetailsImpl principal = (UserDetailsImpl) auth.getPrincipal();
            userId = principal.getId();
            if (actor == null || actor.isBlank()) {
                actor = principal.getEmail() != null ? principal.getEmail() : principal.getUsername();
            }
        }

        if (actor == null || actor.isBlank()) {
            actor = "ANONYMOUS_" + ip;
        }

        ConsentLedger saved = dpdpConsentService.recordConsent(
                userId,
                request.getLeadId(),
                actor,
                request.getConsentType() != null ? request.getConsentType() : "VALUATION_PROCESSING",
                request.isConsentGiven(),
                request.getNoticeVersion(),
                request.getTermsVersion(),
                ip,
                userAgent
        );

        return ResponseEntity.ok(Map.of(
                "status", "RECORDED",
                "id", saved.getId(),
                "consentType", saved.getConsentType(),
                "consentGiven", saved.isConsentGiven(),
                "noticeVersion", saved.getNoticeVersion(),
                "timestamp", saved.getCreatedAt()
        ));
    }

    @PostMapping("/consent/withdraw")
    public ResponseEntity<?> withdrawConsent(@RequestBody WithdrawConsentRequest request) {
        Long userId = null;
        String actor = request.getActorIdentifier();

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetailsImpl) {
            UserDetailsImpl principal = (UserDetailsImpl) auth.getPrincipal();
            userId = principal.getId();
            if (actor == null || actor.isBlank()) {
                actor = principal.getEmail() != null ? principal.getEmail() : principal.getUsername();
            }
        }

        boolean success = dpdpConsentService.withdrawConsent(
                userId, actor, 
                request.getConsentType() != null ? request.getConsentType() : "VALUATION_PROCESSING", 
                request.getReason()
        );

        if (success) {
            return ResponseEntity.ok(Map.of(
                    "status", "WITHDRAWN",
                    "consentType", request.getConsentType(),
                    "message", "Statutory consent has been successfully withdrawn under DPDP Act Section 6(4). Active valuation processing for non-mandatory stages has been paused."
            ));
        } else {
            return ResponseEntity.badRequest().body(Map.of("error", "No active consent found to withdraw for the specified category."));
        }
    }

    @GetMapping("/consent/my-consents")
    public ResponseEntity<?> getMyConsents() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetailsImpl) {
            UserDetailsImpl principal = (UserDetailsImpl) auth.getPrincipal();
            List<ConsentLedger> consents = dpdpConsentService.getConsentsForUser(principal.getId());
            return ResponseEntity.ok(consents);
        }
        return ResponseEntity.status(401).body("Authentication required to view consent history.");
    }

    private String extractClientIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.isBlank() && !"unknown".equalsIgnoreCase(xf)) {
            return xf.split(",")[0].trim();
        }
        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.isBlank() && !"unknown".equalsIgnoreCase(realIp)) {
            return realIp.trim();
        }
        return request.getRemoteAddr();
    }

    public static class ConsentRequest {
        private Long leadId;
        private String actorIdentifier;
        private String consentType;
        private boolean consentGiven;
        private String noticeVersion;
        private String termsVersion;

        public Long getLeadId() { return leadId; }
        public void setLeadId(Long leadId) { this.leadId = leadId; }
        public String getActorIdentifier() { return actorIdentifier; }
        public void setActorIdentifier(String actorIdentifier) { this.actorIdentifier = actorIdentifier; }
        public String getConsentType() { return consentType; }
        public void setConsentType(String consentType) { this.consentType = consentType; }
        public boolean isConsentGiven() { return consentGiven; }
        public void setConsentGiven(boolean consentGiven) { this.consentGiven = consentGiven; }
        public String getNoticeVersion() { return noticeVersion; }
        public void setNoticeVersion(String noticeVersion) { this.noticeVersion = noticeVersion; }
        public String getTermsVersion() { return termsVersion; }
        public void setTermsVersion(String termsVersion) { this.termsVersion = termsVersion; }
    }

    public static class WithdrawConsentRequest {
        private String actorIdentifier;
        private String consentType;
        private String reason;

        public String getActorIdentifier() { return actorIdentifier; }
        public void setActorIdentifier(String actorIdentifier) { this.actorIdentifier = actorIdentifier; }
        public String getConsentType() { return consentType; }
        public void setConsentType(String consentType) { this.consentType = consentType; }
        public String getReason() { return reason; }
        public void setReason(String reason) { this.reason = reason; }
    }
}
