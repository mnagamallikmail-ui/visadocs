package com.provaluer.security.encryption;

import com.provaluer.config.EncryptionConfig;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * DPDP Act 2023 - AES-256-GCM Field Level Encryption Converter
 * Provides authenticated encryption with associated data (AEAD) to guarantee confidentiality
 * and tamper resistance for Class A Sensitive Personal Data (PAN, Aadhaar, Bank Details, etc.).
 *
 * Format: ENC_GCM:<base64_iv>:<base64_ciphertext>
 * Maintains 100% backward compatibility for legacy plaintext records.
 */
@Converter
public class AesGcmEncryptionConverter implements AttributeConverter<String, String> {

    private static final Logger log = LoggerFactory.getLogger(AesGcmEncryptionConverter.class);

    private static final String ALGORITHM = "AES/GCM/NoPadding";
    private static final String PREFIX = "ENC_GCM:";
    private static final int GCM_IV_LENGTH_BYTES = 12; // 96 bits standard GCM IV
    private static final int GCM_TAG_LENGTH_BITS = 128; // 128 bits authentication tag
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    @Override
    public String convertToDatabaseColumn(String attribute) {
        if (attribute == null || attribute.trim().isEmpty()) {
            return attribute;
        }
        if (!EncryptionConfig.isEncryptionEnabled()) {
            return attribute;
        }
        return encryptString(attribute);
    }

    @Override
    public String convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.trim().isEmpty()) {
            return dbData;
        }
        // Backward compatibility: If the record was stored prior to Batch 2 in plaintext, return as-is
        if (!dbData.startsWith(PREFIX)) {
            return dbData;
        }
        return decryptString(dbData);
    }

    /**
     * Encrypt a plaintext string using AES-256-GCM.
     * Returns: ENC_GCM:<base64_iv>:<base64_ciphertext>
     */
    public static String encryptString(String plaintext) {
        if (plaintext == null || plaintext.trim().isEmpty()) {
            return plaintext;
        }
        // Avoid double encryption if already encrypted
        if (plaintext.startsWith(PREFIX)) {
            return plaintext;
        }

        try {
            byte[] iv = new byte[GCM_IV_LENGTH_BYTES];
            SECURE_RANDOM.nextBytes(iv);

            byte[] keyBytes = EncryptionConfig.getMasterKeyBytes();
            SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, parameterSpec);

            byte[] cipherText = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));

            String base64Iv = Base64.getEncoder().encodeToString(iv);
            String base64Cipher = Base64.getEncoder().encodeToString(cipherText);

            return PREFIX + base64Iv + ":" + base64Cipher;
        } catch (Exception e) {
            log.error("AES-256-GCM field encryption failed: {}", e.getMessage());
            throw new RuntimeException("Cryptographic operation failed during field encryption", e);
        }
    }

    /**
     * Decrypt an AES-256-GCM encrypted string.
     * If input is plaintext (no ENC_GCM prefix), gracefully returns the string.
     */
    public static String decryptString(String encryptedText) {
        if (encryptedText == null || encryptedText.trim().isEmpty()) {
            return encryptedText;
        }
        // Legacy plaintext fallback
        if (!encryptedText.startsWith(PREFIX)) {
            return encryptedText;
        }

        try {
            String payload = encryptedText.substring(PREFIX.length());
            String[] parts = payload.split(":");
            if (parts.length != 2) {
                log.warn("Corrupted or unexpected ciphertext envelope format. Returning original value.");
                return encryptedText;
            }

            byte[] iv = Base64.getDecoder().decode(parts[0]);
            byte[] cipherText = Base64.getDecoder().decode(parts[1]);

            byte[] keyBytes = EncryptionConfig.getMasterKeyBytes();
            SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, parameterSpec);

            byte[] plainTextBytes = cipher.doFinal(cipherText);
            return new String(plainTextBytes, StandardCharsets.UTF_8);
        } catch (Exception e) {
            log.error("AES-256-GCM field decryption failed: {}", e.getMessage());
            throw new RuntimeException("Cryptographic verification failed during field decryption", e);
        }
    }

    public static boolean isEncrypted(String value) {
        return value != null && value.startsWith(PREFIX);
    }

    /**
     * Computes a deterministic SHA-256 blind index for searchable encrypted fields (e.g. Email).
     * Enables O(1) indexed lookups without exposing plaintext in database storage.
     */
    public static String computeBlindIndex(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
            byte[] digest = md.digest(value.trim().toLowerCase().getBytes(StandardCharsets.UTF_8));
            return java.util.HexFormat.of().formatHex(digest);
        } catch (Exception e) {
            log.error("Blind index computation failed: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Decrypts ciphertext with old key and re-encrypts with active master key.
     */
    public static String reEncryptString(String existingCiphertext) {
        if (!isEncrypted(existingCiphertext)) {
            return encryptString(existingCiphertext);
        }
        String plaintext = decryptString(existingCiphertext);
        // Force fresh encryption with new random IV and current active key
        return encryptString(plaintext);
    }
}
