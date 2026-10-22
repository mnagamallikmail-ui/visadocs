package com.provaluer.service;

import com.provaluer.model.GuardianConsentLedger;
import com.provaluer.repository.GuardianConsentLedgerRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;

/**
 * DPDP Act 2023 - Section 9 Child / Minor Data Protection & Guardian Consent Service
 * Evaluates applicant date of birth, detects minors (< 18 years), enforces mandatory verifiable
 * guardian consent, and maintains statutory audit logs in guardian_consent_ledger.
 */
@Service
public class AgeVerificationService {

    private static final Logger log = LoggerFactory.getLogger(AgeVerificationService.class);

    @Autowired
    private GuardianConsentLedgerRepository guardianConsentRepository;

    public static class AgeEvaluationResult {
        public boolean isMinor;
        public int calculatedAge;
        public boolean requiresGuardianConsent;
        public String statusMessage;

        public AgeEvaluationResult(boolean isMinor, int calculatedAge, boolean requiresGuardianConsent, String statusMessage) {
            this.isMinor = isMinor;
            this.calculatedAge = calculatedAge;
            this.requiresGuardianConsent = requiresGuardianConsent;
            this.statusMessage = statusMessage;
        }
    }

    /**
     * Evaluates applicant date of birth to detect minority status under DPDP Act Section 9.
     */
    public AgeEvaluationResult evaluateAge(LocalDate dateOfBirth) {
        if (dateOfBirth == null) {
            throw new IllegalArgumentException("Date of Birth is required for DPDP Section 9 age verification");
        }
        if (dateOfBirth.isAfter(LocalDate.now())) {
            throw new IllegalArgumentException("Date of Birth cannot be in the future");
        }

        int age = Period.between(dateOfBirth, LocalDate.now()).getYears();
        boolean isMinor = age < 18;

        String message = isMinor
                ? "Applicant is " + age + " years old (Minor). Under DPDP Act Section 9, processing requires verifiable parental/guardian consent."
                : "Applicant is " + age + " years old (Major). Section 9 minor restrictions do not apply.";

        return new AgeEvaluationResult(isMinor, age, isMinor, message);
    }

    /**
     * Records verified guardian consent for a minor's valuation / intake record.
     */
    @Transactional
    public GuardianConsentLedger recordGuardianConsent(
            Long orderId,
            Long leadId,
            LocalDate applicantDob,
            String guardianName,
            String relationship,
            String guardianPhone,
            String guardianEmail,
            boolean consentGiven,
            String ipAddress,
            String userAgent,
            String noticeVersion) {

        AgeEvaluationResult evaluation = evaluateAge(applicantDob);

        if (evaluation.isMinor && (!consentGiven || guardianName == null || guardianName.isBlank())) {
            throw new IllegalArgumentException("DPDP Section 9 Violation: Parental/Guardian details and explicit consent are mandatory for minors.");
        }

        GuardianConsentLedger ledger = new GuardianConsentLedger();
        ledger.setOrderId(orderId);
        ledger.setLeadId(leadId);
        ledger.setApplicantDob(applicantDob);
        ledger.setMinor(evaluation.isMinor);
        ledger.setGuardianName(guardianName);
        ledger.setGuardianRelationship(relationship);
        ledger.setGuardianPhone(guardianPhone);
        ledger.setGuardianEmail(guardianEmail);
        ledger.setGuardianConsentGiven(consentGiven);
        ledger.setConsentTimestamp(LocalDateTime.now());
        ledger.setIpAddress(ipAddress);
        ledger.setUserAgent(userAgent);
        ledger.setNoticeVersion(noticeVersion != null ? noticeVersion : "v1.0");
        ledger.setWithdrawn(false);

        GuardianConsentLedger saved = guardianConsentRepository.save(ledger);
        log.info("[DPDP SECTION 9] Guardian consent recorded for minor applicant (Ledger ID: {}, Guardian: {})",
                saved.getId(), guardianName);
        return saved;
    }

    /**
     * Withdraws parental/guardian consent under DPDP Act Section 9 & Section 6(4).
     */
    @Transactional
    public boolean withdrawGuardianConsent(Long ledgerId) {
        return guardianConsentRepository.findById(ledgerId).map(ledger -> {
            ledger.setWithdrawn(true);
            ledger.setWithdrawnAt(LocalDateTime.now());
            guardianConsentRepository.save(ledger);
            log.info("[DPDP SECTION 9] Guardian consent withdrawn for Ledger ID: {}", ledgerId);
            return true;
        }).orElse(false);
    }
}
