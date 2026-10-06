package com.provaluer.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Enterprise Production Governance: PDF Document Integrity Validator.
 * Phase 6: Enforces zero-tolerance rules for placeholder leakage, missing fields,
 * and tabular anomalies in generated valuation reports.
 */
@Service
public class PdfGovernanceValidatorService {

    private static final Logger log = LoggerFactory.getLogger(PdfGovernanceValidatorService.class);

    // Regex detecting placeholder leakage: e.g. <<report_no>>, <<client_name>>
    private static final Pattern PLACEHOLDER_LEAK_PATTERN = Pattern.compile("<<[a-zA-Z0-9_]+>>");

    public static class ValidationResult {
        private final boolean valid;
        private final List<String> violations;
        private final int placeholderLeaksCount;

        public ValidationResult(boolean valid, List<String> violations, int placeholderLeaksCount) {
            this.valid = valid;
            this.violations = violations;
            this.placeholderLeaksCount = placeholderLeaksCount;
        }

        public boolean isValid() { return valid; }
        public List<String> getViolations() { return violations; }
        public int getPlaceholderLeaksCount() { return placeholderLeaksCount; }
    }

    /**
     * Validates report content against strict governance criteria.
     *
     * @param documentText Extracted text from generated document
     * @param reportNumber Expected report number
     * @return ValidationResult detailing compliance
     */
    public ValidationResult validateDocumentContent(String documentText, String reportNumber) {
        List<String> violations = new ArrayList<>();

        if (documentText == null || documentText.isBlank()) {
            violations.add("CRITICAL: Generated document content is empty or null");
            return new ValidationResult(false, violations, 0);
        }

        // 1. Placeholder Leakage Check
        Matcher matcher = PLACEHOLDER_LEAK_PATTERN.matcher(documentText);
        List<String> leakedPlaceholders = new ArrayList<>();
        while (matcher.find()) {
            leakedPlaceholders.add(matcher.group());
        }

        if (!leakedPlaceholders.isEmpty()) {
            violations.add("CRITICAL: Detected " + leakedPlaceholders.size() +
                    " unresolved placeholders: " + String.join(", ", leakedPlaceholders));
        }

        // 2. Expected Report Number Check
        if (reportNumber != null && !reportNumber.isBlank()) {
            if (!documentText.contains(reportNumber)) {
                violations.add("CRITICAL: Report number [" + reportNumber + "] is missing from document body");
            }
        }

        // 3. Calculation & Truncation Anomalies
        if (documentText.contains("NaN") || documentText.contains("undefined") || documentText.contains("Infinity")) {
            violations.add("CRITICAL: Calculation anomaly detected (NaN / undefined / Infinity in text)");
        }

        if (documentText.contains("[TRUNCATED]") || documentText.contains("ERROR_TABLE_RENDER")) {
            violations.add("CRITICAL: Table structure rendered with truncation or failure markers");
        }

        boolean isValid = violations.isEmpty();
        if (!isValid) {
            log.warn("[PDF GOVERNANCE VIOLATION] Report: {} | Violations: {}", reportNumber, violations);
        } else {
            log.info("[PDF GOVERNANCE VERIFIED] Report: {} passed 100% compliance checks", reportNumber);
        }

        return new ValidationResult(isValid, violations, leakedPlaceholders.size());
    }
}
