package com.provaluer.util;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * DPDP Act 2023 - Data Masking Utility
 * Prevents plain-text exposure of sensitive personal data (PAN, Aadhaar, Passport,
 * Bank Accounts, Phone Numbers, Emails, Financials) in logs, audit records, and UI displays.
 */
public final class DataMaskingUtil {

    private DataMaskingUtil() {}

    // Regex patterns for sensitive data discovery
    private static final Pattern PAN_PATTERN = Pattern.compile("(?i)\\b[A-Z]{5}[0-9]{4}[A-Z]\\b");
    private static final Pattern AADHAAR_PATTERN = Pattern.compile("\\b[2-9][0-9]{3}\\s?[0-9]{4}\\s?[0-9]{4}\\b");
    private static final Pattern EMAIL_PATTERN = Pattern.compile("(?i)\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b");
    private static final Pattern PHONE_PATTERN = Pattern.compile("\\b(?:\\+91[-.\\s]?)?[6-9]\\d{9}\\b");

    /**
     * Mask PAN (Format: 5 letters, 4 digits, 1 letter)
     * e.g. ABCDE1234F -> XXXXX1234F or XXXXXX1234
     */
    public static String maskPan(String pan) {
        if (pan == null || pan.trim().isEmpty()) return pan;
        String trimmed = pan.trim();
        if (trimmed.length() < 6) return "XXXXXX";
        int len = trimmed.length();
        // Mask first 5 characters and retain last 4 (e.g. XXXXX1234F -> XXXXXXX234F or XXXXX1234F)
        return "XXXXX" + trimmed.substring(5);
    }

    /**
     * Mask Aadhaar (12 digits)
     * e.g. 1234 5678 9012 or 123456789012 -> XXXXXXXX9012
     */
    public static String maskAadhaar(String aadhaar) {
        if (aadhaar == null || aadhaar.trim().isEmpty()) return aadhaar;
        String clean = aadhaar.replaceAll("\\s+", "");
        if (clean.length() <= 4) return "XXXXXXXX";
        return "XXXXXXXX" + clean.substring(clean.length() - 4);
    }

    /**
     * Mask Passport (Typically 1 letter + 7 digits)
     * e.g. A1234567 -> XXXXX567
     */
    public static String maskPassport(String passport) {
        if (passport == null || passport.trim().isEmpty()) return passport;
        String trimmed = passport.trim();
        if (trimmed.length() <= 3) return "XXXX";
        return "XXXXX" + trimmed.substring(trimmed.length() - 3);
    }

    /**
     * Mask Bank Account Number
     * e.g. 50200088912345 -> XXXXXXXXXX2345
     */
    public static String maskBankAccount(String account) {
        if (account == null || account.trim().isEmpty()) return account;
        String trimmed = account.trim();
        if (trimmed.length() <= 4) return "XXXX";
        return "X".repeat(Math.max(4, trimmed.length() - 4)) + trimmed.substring(trimmed.length() - 4);
    }

    /**
     * Mask Email address
     * e.g. john.doe@example.com -> j***e@example.com
     */
    public static String maskEmail(String email) {
        if (email == null || email.trim().isEmpty()) return email;
        int atIndex = email.indexOf('@');
        if (atIndex <= 1) return "***" + (atIndex >= 0 ? email.substring(atIndex) : "");
        String username = email.substring(0, atIndex);
        String domain = email.substring(atIndex);
        String maskedUser = username.charAt(0) + "***" + username.charAt(username.length() - 1);
        return maskedUser + domain;
    }

    /**
     * Mask Phone Number (10 digits)
     * e.g. +91 9876543210 -> XXXXXX3210
     */
    public static String maskPhone(String phone) {
        if (phone == null || phone.trim().isEmpty()) return phone;
        String clean = phone.replaceAll("[^0-9]", "");
        if (clean.length() <= 4) return "XXXX";
        return "XXXXXX" + clean.substring(clean.length() - 4);
    }

    /**
     * Mask Net Worth / Financial statement values
     */
    public static String maskFinancial(String financialValue) {
        if (financialValue == null || financialValue.trim().isEmpty()) return financialValue;
        return "[CONFIDENTIAL FINANCIAL DATA]";
    }

    /**
     * Universal log sanitizer: masks any detected PAN, Aadhaar, Email, or Phone in freeform text.
     */
    public static String sanitizeLog(String message) {
        if (message == null || message.isEmpty()) return message;

        // Mask PANs
        Matcher panMatcher = PAN_PATTERN.matcher(message);
        StringBuffer sb = new StringBuffer();
        while (panMatcher.find()) {
            panMatcher.appendReplacement(sb, maskPan(panMatcher.group()));
        }
        panMatcher.appendTail(sb);
        String result = sb.toString();

        // Mask Aadhaar
        Matcher aadhaarMatcher = AADHAAR_PATTERN.matcher(result);
        sb = new StringBuffer();
        while (aadhaarMatcher.find()) {
            aadhaarMatcher.appendReplacement(sb, maskAadhaar(aadhaarMatcher.group()));
        }
        aadhaarMatcher.appendTail(sb);
        result = sb.toString();

        // Mask Emails
        Matcher emailMatcher = EMAIL_PATTERN.matcher(result);
        sb = new StringBuffer();
        while (emailMatcher.find()) {
            emailMatcher.appendReplacement(sb, maskEmail(emailMatcher.group()));
        }
        emailMatcher.appendTail(sb);
        result = sb.toString();

        // Mask Phones
        Matcher phoneMatcher = PHONE_PATTERN.matcher(result);
        sb = new StringBuffer();
        while (phoneMatcher.find()) {
            phoneMatcher.appendReplacement(sb, maskPhone(phoneMatcher.group()));
        }
        phoneMatcher.appendTail(sb);

        return sb.toString();
    }
}
