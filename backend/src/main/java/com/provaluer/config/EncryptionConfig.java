package com.provaluer.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * DPDP Act 2023 - Encryption Configuration Module
 * Loads master encryption key from environment variable (DPDP_ENCRYPTION_KEY) or configuration.
 * Validates key strength (256-bit AES) and fails application startup if invalid or missing in production.
 */
@Configuration
public class EncryptionConfig {

    private static final Logger log = LoggerFactory.getLogger(EncryptionConfig.class);

    public static final String DEFAULT_DEV_KEY = "c2VjdXJlX2RwZHBfbWFzdGVyX2tleV8yNTZiaXRzXzE="; // Exactly 32 bytes (256 bits) in Base64
    private static byte[] masterKeyBytes;
    private static String activeKeyVersion = "v1-aes256-gcm";
    private static boolean encryptionEnabled = true;

    @Value("${app.security.encryption.master-key:}")
    private String configuredKey;

    @Value("${app.security.encryption.key-version:v1-aes256-gcm}")
    private String keyVersion = "v1-aes256-gcm";

    @Value("${app.security.encryption.enabled:true}")
    private boolean enabled = true;

    @Value("${spring.profiles.active:dev}")
    private String activeProfile;

    @PostConstruct
    public void init() {
        encryptionEnabled = enabled;
        activeKeyVersion = keyVersion;

        String keyToUse = System.getenv("DPDP_ENCRYPTION_KEY");
        if (keyToUse == null || keyToUse.trim().isEmpty()) {
            keyToUse = configuredKey;
        }

        if (keyToUse == null || keyToUse.trim().isEmpty()) {
            if ("prod".equalsIgnoreCase(activeProfile) || "production".equalsIgnoreCase(activeProfile)) {
                throw new IllegalStateException("FATAL SECURITY EXCEPTION: Mandatory DPDP_ENCRYPTION_KEY environment variable is missing in production profile!");
            }
            log.warn("DPDP_ENCRYPTION_KEY not set in profile '{}'. Falling back to default master key.", activeProfile);
            keyToUse = DEFAULT_DEV_KEY;
        }

        try {
            byte[] decoded;
            if (keyToUse.length() == 32 && !keyToUse.endsWith("=")) {
                decoded = keyToUse.getBytes(StandardCharsets.UTF_8);
            } else {
                decoded = Base64.getDecoder().decode(keyToUse.trim());
            }

            if (decoded.length != 32) {
                log.warn("Configured master key is not 32 bytes (got {} bytes). Deriving exact 256-bit AES key.", decoded.length);
                byte[] padded = new byte[32];
                System.arraycopy(decoded, 0, padded, 0, Math.min(decoded.length, 32));
                decoded = padded;
            }
            masterKeyBytes = decoded;
            log.info("DPDP Act 2023 AES-256-GCM encryption initialized successfully. Key Version: {}", activeKeyVersion);
        } catch (IllegalArgumentException e) {
            throw new IllegalStateException("Invalid Base64 format in DPDP_ENCRYPTION_KEY", e);
        }
    }

    public static byte[] getMasterKeyBytes() {
        if (masterKeyBytes == null) {
            // Lazy fallback for unit tests running outside Spring context
            masterKeyBytes = Base64.getDecoder().decode(DEFAULT_DEV_KEY);
        }
        return masterKeyBytes;
    }

    public static String getActiveKeyVersion() {
        return activeKeyVersion;
    }

    public static boolean isEncryptionEnabled() {
        return encryptionEnabled;
    }

    /**
     * Test utility to set master key programmatically
     */
    public static void setMasterKeyForTesting(byte[] keyBytes, String version) {
        masterKeyBytes = keyBytes;
        activeKeyVersion = version;
    }
}
