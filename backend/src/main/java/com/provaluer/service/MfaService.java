package com.provaluer.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URLEncoder;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.*;

/**
 * DPDP Act 2023 & CERT-In Compliant Multi-Factor Authentication (MFA) Service
 * Implements RFC 6238 Time-Based One-Time Password (TOTP) and Single-Use Cryptographic Recovery Codes.
 * Mandatory for privileged administrative, appraiser, and reviewer roles.
 */
@Service
public class MfaService {

    private static final Logger log = LoggerFactory.getLogger(MfaService.class);
    private static final String BASE32_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    private static final int TIME_STEP_SECONDS = 30;
    private static final int CODE_DIGITS = 6;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    public static class MfaSetupPackage {
        private final String secretKey;
        private final String otpAuthUri;
        private final List<String> recoveryCodes;

        public MfaSetupPackage(String secretKey, String otpAuthUri, List<String> recoveryCodes) {
            this.secretKey = secretKey;
            this.otpAuthUri = otpAuthUri;
            this.recoveryCodes = recoveryCodes;
        }

        public String getSecretKey() { return secretKey; }
        public String getOtpAuthUri() { return otpAuthUri; }
        public List<String> getRecoveryCodes() { return recoveryCodes; }
    }

    /**
     * Generates a new 160-bit (20 byte / 32 base32 chars) secret key, QR URI, and 5 recovery codes.
     */
    public MfaSetupPackage generateMfaSetup(String username, String email) {
        byte[] buffer = new byte[20];
        SECURE_RANDOM.nextBytes(buffer);
        String secret = encodeBase32(buffer);

        String accountIdentifier = (email != null && !email.isBlank()) ? email.trim() : username.trim();
        String issuer = "ProValuer";
        String encodedAccount = URLEncoder.encode(accountIdentifier, StandardCharsets.UTF_8);
        String encodedIssuer = URLEncoder.encode(issuer, StandardCharsets.UTF_8);

        String otpAuthUri = String.format("otpauth://totp/%s:%s?secret=%s&issuer=%s&algorithm=SHA1&digits=%d&period=%d",
                encodedIssuer, encodedAccount, secret, encodedIssuer, CODE_DIGITS, TIME_STEP_SECONDS);

        List<String> recoveryCodes = generateRecoveryCodes(5);

        return new MfaSetupPackage(secret, otpAuthUri, recoveryCodes);
    }

    /**
     * Validates a 6-digit TOTP code against the base32 secret with +/- 1 time step tolerance (90s window).
     */
    public boolean verifyTotp(String base32Secret, String candidateCode) {
        if (base32Secret == null || candidateCode == null) return false;
        String cleanCode = candidateCode.trim().replaceAll("\\s+", "");
        if (cleanCode.length() != CODE_DIGITS) return false;

        long currentInterval = System.currentTimeMillis() / 1000L / TIME_STEP_SECONDS;
        byte[] keyBytes = decodeBase32(base32Secret);

        for (int i = -1; i <= 1; i++) {
            long hash = generateCodeForInterval(keyBytes, currentInterval + i);
            String expected = String.format("%0" + CODE_DIGITS + "d", hash);
            if (expected.equals(cleanCode)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Generates cryptographic single-use alphanumeric recovery codes (8 chars each).
     */
    public List<String> generateRecoveryCodes(int count) {
        List<String> codes = new ArrayList<>();
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
        for (int i = 0; i < count; i++) {
            StringBuilder sb = new StringBuilder();
            for (int j = 0; j < 8; j++) {
                sb.append(chars.charAt(SECURE_RANDOM.nextInt(chars.length())));
            }
            codes.add(sb.substring(0, 4) + "-" + sb.substring(4));
        }
        return codes;
    }

    /**
     * Verifies and consumes a single-use recovery code.
     * Returns true if valid and updates the remaining codes string.
     */
    public boolean verifyAndConsumeRecoveryCode(String candidateCode, StringBuilder storedCodesHolder) {
        if (candidateCode == null || storedCodesHolder == null) return false;
        String normalized = candidateCode.trim().toUpperCase();
        String stored = storedCodesHolder.toString();
        if (stored.isBlank()) return false;

        List<String> codes = new ArrayList<>(Arrays.asList(stored.split(",")));
        boolean match = false;
        Iterator<String> it = codes.iterator();
        while (it.hasNext()) {
            String code = it.next().trim();
            if (code.equalsIgnoreCase(normalized)) {
                it.remove();
                match = true;
                break;
            }
        }

        if (match) {
            storedCodesHolder.setLength(0);
            storedCodesHolder.append(String.join(",", codes));
            return true;
        }
        return false;
    }

    private static long generateCodeForInterval(byte[] key, long interval) {
        try {
            byte[] data = ByteBuffer.allocate(8).putLong(interval).array();
            Mac mac = Mac.getInstance("HmacSHA1");
            mac.init(new SecretKeySpec(key, "RAW"));
            byte[] hash = mac.doFinal(data);

            int offset = hash[hash.length - 1] & 0x0F;
            long truncatedHash = 0;
            for (int i = 0; i < 4; ++i) {
                truncatedHash <<= 8;
                truncatedHash |= (hash[offset + i] & 0xFF);
            }
            truncatedHash &= 0x7FFFFFFF;
            truncatedHash %= (long) Math.pow(10, CODE_DIGITS);
            return truncatedHash;
        } catch (Exception e) {
            log.error("Error generating TOTP code: {}", e.getMessage());
            return -1;
        }
    }

    private static String encodeBase32(byte[] data) {
        StringBuilder sb = new StringBuilder((data.length * 8 + 4) / 5);
        int val = 0, count = 0;
        for (byte b : data) {
            val = (val << 8) | (b & 0xFF);
            count += 8;
            while (count >= 5) {
                count -= 5;
                sb.append(BASE32_ALPHABET.charAt((val >> count) & 0x1F));
            }
        }
        if (count > 0) {
            sb.append(BASE32_ALPHABET.charAt((val << (5 - count)) & 0x1F));
        }
        return sb.toString();
    }

    private static byte[] decodeBase32(String base32) {
        String clean = base32.toUpperCase().replaceAll("[^A-Z2-7]", "");
        int numBytes = clean.length() * 5 / 8;
        byte[] bytes = new byte[numBytes];
        int val = 0, count = 0, index = 0;
        for (char c : clean.toCharArray()) {
            int charVal = BASE32_ALPHABET.indexOf(c);
            if (charVal == -1) continue;
            val = (val << 5) | charVal;
            count += 5;
            if (count >= 8) {
                count -= 8;
                bytes[index++] = (byte) ((val >> count) & 0xFF);
            }
        }
        return bytes;
    }
}
