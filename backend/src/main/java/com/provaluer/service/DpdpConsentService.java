package com.provaluer.service;

import com.provaluer.model.ConsentLedger;
import com.provaluer.repository.ConsentLedgerRepository;
import com.provaluer.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class DpdpConsentService {

    private static final Logger log = LoggerFactory.getLogger(DpdpConsentService.class);

    public static final String CURRENT_NOTICE_VERSION = "DPDP-NOTICE-V1.0";
    public static final String CURRENT_TERMS_VERSION = "v2.4";

    @Autowired
    private ConsentLedgerRepository consentLedgerRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuditLogService auditLogService;

    @org.springframework.beans.factory.annotation.Value("${app.dpdp.dpo.name:Data Protection Officer}")
    private String dpoName;

    @org.springframework.beans.factory.annotation.Value("${app.dpdp.dpo.title:Designated Data Protection Officer}")
    private String dpoTitle;

    @org.springframework.beans.factory.annotation.Value("${app.dpdp.dpo.email:dpo@provaluer.com}")
    private String dpoEmail;

    @org.springframework.beans.factory.annotation.Value("${app.dpdp.dpo.address:Corporate Compliance Cell, ProValuer Advisory Services Pvt Ltd, India}")
    private String dpoAddress;

    @org.springframework.beans.factory.annotation.Value("${app.dpdp.grievance-officer.email:grievance@provaluer.com}")
    private String grievanceEmail;

    @Transactional
    public ConsentLedger recordConsent(Long userId, Long leadId, String actorIdentifier, 
                                        String consentType, boolean consentGiven, 
                                        String noticeVersion, String termsVersion, 
                                        String ipAddress, String userAgent) {
        String activeNotice = noticeVersion != null && !noticeVersion.isBlank() ? noticeVersion : CURRENT_NOTICE_VERSION;
        String activeTerms = termsVersion != null && !termsVersion.isBlank() ? termsVersion : CURRENT_TERMS_VERSION;

        ConsentLedger entry = new ConsentLedger(
                userId, leadId, actorIdentifier, consentType, consentGiven, 
                activeNotice, activeTerms, ipAddress, userAgent
        );
        ConsentLedger saved = consentLedgerRepository.save(entry);

        if (userId != null) {
            userRepository.findById(userId).ifPresent(user -> {
                if ("TERMS_ACCEPTANCE".equalsIgnoreCase(consentType)) {
                    user.setAcceptedTcVersion(activeTerms);
                }
                if ("VALUATION_PROCESSING".equalsIgnoreCase(consentType)) {
                    user.setDpdpConsentGiven(consentGiven);
                    user.setDpdpConsentVersion(activeNotice);
                    user.setDpdpConsentTimestamp(LocalDateTime.now());
                }
                userRepository.save(user);
            });
        }

        try {
            auditLogService.log(
                    userId != null ? userId : 0L,
                    actorIdentifier != null ? actorIdentifier : "ANONYMOUS",
                    "DATA_PRINCIPAL",
                    "DPDP_CONSENT_RECORDED",
                    "CONSENT_LEDGER",
                    String.valueOf(saved.getId()),
                    null,
                    consentType + ":" + consentGiven,
                    "Statutory DPDP consent recorded for " + consentType + " (Notice: " + activeNotice + ") from IP: " + ipAddress
            );
        } catch (Exception e) {
            log.warn("Could not write immutable audit log for consent: {}", e.getMessage());
        }

        return saved;
    }

    public List<ConsentLedger> getConsentsForUser(Long userId) {
        return consentLedgerRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<ConsentLedger> getConsentsForActor(String actorIdentifier) {
        return consentLedgerRepository.findByActorIdentifierOrderByCreatedAtDesc(actorIdentifier);
    }

    @Transactional
    public boolean withdrawConsent(Long userId, String actorIdentifier, String consentType, String reason) {
        Optional<ConsentLedger> activeConsent;
        if (userId != null) {
            activeConsent = consentLedgerRepository.findFirstByUserIdAndConsentTypeAndWithdrawnFalseOrderByCreatedAtDesc(userId, consentType);
        } else if (actorIdentifier != null) {
            activeConsent = consentLedgerRepository.findFirstByActorIdentifierAndConsentTypeAndWithdrawnFalseOrderByCreatedAtDesc(actorIdentifier, consentType);
        } else {
            return false;
        }

        if (activeConsent.isPresent()) {
            ConsentLedger consent = activeConsent.get();
            consent.setWithdrawn(true);
            consent.setWithdrawnAt(LocalDateTime.now());
            consent.setWithdrawalReason(reason != null ? reason : "Voluntary withdrawal by Data Principal under DPDP Act Sec 6(4)");
            consentLedgerRepository.save(consent);

            if (userId != null) {
                userRepository.findById(userId).ifPresent(user -> {
                    if ("VALUATION_PROCESSING".equalsIgnoreCase(consentType)) {
                        user.setDpdpConsentGiven(false);
                        userRepository.save(user);
                    }
                });
            }

            try {
                auditLogService.log(
                        userId != null ? userId : 0L,
                        actorIdentifier != null ? actorIdentifier : (consent.getActorIdentifier()),
                        "DATA_PRINCIPAL",
                        "DPDP_CONSENT_WITHDRAWN",
                        "CONSENT_LEDGER",
                        String.valueOf(consent.getId()),
                        "ACTIVE",
                        "WITHDRAWN",
                        "Data Principal withdrew statutory consent for " + consentType + ". Reason: " + reason
                );
            } catch (Exception e) {
                log.warn("Could not write audit log for consent withdrawal: {}", e.getMessage());
            }

            return true;
        }

        return false;
    }

    public Map<String, Object> getGovernanceMetadata() {
        Map<String, Object> meta = new HashMap<>();
        meta.put("noticeVersion", CURRENT_NOTICE_VERSION);
        meta.put("termsVersion", CURRENT_TERMS_VERSION);
        meta.put("dpoName", dpoName);
        meta.put("dpoTitle", dpoTitle);
        meta.put("dpoEmail", dpoEmail);
        meta.put("grievanceEmail", grievanceEmail);
        meta.put("dpoAddress", dpoAddress);
        meta.put("grievanceSlaDays", 7);
        meta.put("statutoryAct", "Digital Personal Data Protection Act, 2023 (India)");
        meta.put("dpbiSupervisoryAuthority", "Data Protection Board of India");
        return meta;
    }
}
