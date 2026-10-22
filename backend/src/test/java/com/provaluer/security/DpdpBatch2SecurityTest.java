package com.provaluer.security;

import com.provaluer.config.EncryptionConfig;
import com.provaluer.model.OrderInput;
import com.provaluer.security.encryption.AesGcmEncryptionConverter;
import com.provaluer.service.DocumentSecurityService;
import com.provaluer.service.EncryptedFileStorageService;
import com.provaluer.service.EncryptionStatusService;
import com.provaluer.util.DataMaskingUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * DPDP Act 2023 - Batch 2 Security & Compliance Tests
 * Verifies AES-256-GCM field encryption, document storage hardening,
 * expiring signed tokens, data masking, and legacy backward compatibility.
 */
public class DpdpBatch2SecurityTest {

    private EncryptedFileStorageService storageService;
    private EncryptionStatusService statusService;

    @BeforeEach
    public void setup() {
        // Ensure dev master key is active
        EncryptionConfig config = new EncryptionConfig();
        config.init();
        storageService = new EncryptedFileStorageService();
        statusService = new EncryptionStatusService();
    }

    @Test
    @DisplayName("Phase B: AES-256-GCM Field Level Encryption & Decryption")
    public void testAesGcmFieldEncryptionAndDecryption() {
        String originalPan = "ABCDE1234F";
        String cipherText = AesGcmEncryptionConverter.encryptString(originalPan);

        assertNotNull(cipherText);
        assertTrue(cipherText.startsWith("ENC_GCM:"), "Ciphertext must follow ENC_GCM: prefix format");
        assertNotEquals(originalPan, cipherText, "Ciphertext must not match plaintext");

        // Verify decryption recovers original plaintext
        String decrypted = AesGcmEncryptionConverter.decryptString(cipherText);
        assertEquals(originalPan, decrypted, "Decryption must recover exact plaintext value");

        // Verify idempotency (no double encryption)
        String reEncrypted = AesGcmEncryptionConverter.encryptString(cipherText);
        assertEquals(cipherText, reEncrypted, "Re-encrypting ciphertext should be idempotent");
    }

    @Test
    @DisplayName("Phase B: Backward Compatibility - Legacy Plaintext Read Fallback")
    public void testLegacyPlaintextReadFallback() {
        AesGcmEncryptionConverter converter = new AesGcmEncryptionConverter();

        String legacyPan = "ABCDE9999Z";
        // Legacy record in database without ENC_GCM prefix
        String converted = converter.convertToEntityAttribute(legacyPan);

        assertEquals(legacyPan, converted, "Legacy plaintext records must be returned untouched without errors");
    }

    @Test
    @DisplayName("Phase B: OrderInput Sensitive Key Detection & Lifecycle Hook Hardening")
    public void testOrderInputSensitiveFieldHooks() {
        // Verify sensitive keys
        assertTrue(OrderInput.isSensitiveKey("CLIENT_PAN"));
        assertTrue(OrderInput.isSensitiveKey("PAN"));
        assertTrue(OrderInput.isSensitiveKey("AADHAAR_NUMBER"));
        assertTrue(OrderInput.isSensitiveKey("PASSPORT_NO"));
        assertTrue(OrderInput.isSensitiveKey("BANK_ACCOUNT_NUM"));
        assertTrue(OrderInput.isSensitiveKey("NET_WORTH_INR"));
        assertTrue(OrderInput.isSensitiveKey("FINANCIAL_STATEMENTS"));
        assertTrue(OrderInput.isSensitiveKey("LOAN_ACCOUNT_NO"));

        // Verify non-sensitive operational keys
        assertFalse(OrderInput.isSensitiveKey("PROPERTY_TYPE"));
        assertFalse(OrderInput.isSensitiveKey("VALUATION_DATE"));
        assertFalse(OrderInput.isSensitiveKey("TOTAL_AREA_SQFT"));

        // Simulate OrderInput persistence lifecycle
        OrderInput panInput = new OrderInput(101L, "CLIENT_PAN", "XYZAB5678C");
        panInput.prePersistOrUpdate();

        assertTrue(panInput.getFieldValue().startsWith("ENC_GCM:"), "Sensitive field must be encrypted before database write");

        // Simulate PostPersist / PostLoad in-memory restoration
        panInput.postLoadOrPersist();
        assertEquals("XYZAB5678C", panInput.getFieldValue(), "Field value must be decrypted in memory for business logic");
    }

    @Test
    @DisplayName("Phase C: Encrypted File Storage - Envelope Writing & Secure Decryption")
    public void testEncryptedFileStorageEnvelope() throws IOException {
        Path tempFile = Files.createTempFile("dpdp_test_lead_deed_", ".pdf");
        try {
            byte[] rawDocumentBytes = "%PDF-1.4 Mock Legal Sale Deed for Commercial Property".getBytes(StandardCharsets.UTF_8);

            // Store encrypted file
            storageService.storeEncrypted(new ByteArrayInputStream(rawDocumentBytes), tempFile);

            // Read raw bytes on disk
            byte[] diskBytes = Files.readAllBytes(tempFile);
            assertTrue(storageService.isEncryptedData(diskBytes), "Stored file must contain PVENC1 magic envelope");
            assertNotEquals(new String(rawDocumentBytes), new String(diskBytes), "On-disk file content must not be plaintext");

            // Decrypt via secure retrieval service
            byte[] decrypted = storageService.readDecryptedBytes(tempFile);
            assertArrayEquals(rawDocumentBytes, decrypted, "Decrypted file bytes must match original content");
        } finally {
            Files.deleteIfExists(tempFile);
        }
    }

    @Test
    @DisplayName("Phase C: Encrypted File Storage - Legacy Plaintext File Fallback")
    public void testEncryptedFileStorageLegacyFallback() throws IOException {
        Path tempLegacyFile = Files.createTempFile("dpdp_legacy_lead_doc_", ".pdf");
        try {
            byte[] legacyBytes = "%PDF-1.4 Unencrypted legacy document from previous sprint".getBytes(StandardCharsets.UTF_8);
            Files.write(tempLegacyFile, legacyBytes);

            assertFalse(storageService.isEncryptedFile(tempLegacyFile), "Legacy file should not report encrypted");

            // Read via storage service
            byte[] retrieved = storageService.readDecryptedBytes(tempLegacyFile);
            assertArrayEquals(legacyBytes, retrieved, "Storage service must transparently read legacy plaintext files");
        } finally {
            Files.deleteIfExists(tempLegacyFile);
        }
    }

    @Test
    @DisplayName("Phase D: Expiring Download Tokens - Expiry & Cryptographic Signature Verification")
    public void testDownloadTokenSignatureAndExpiry() {
        DocumentSecurityService docSec = new DocumentSecurityService();

        DocumentSecurityService.DownloadTokenResult tokenResult = docSec.generateDownloadToken(
                "LEAD_DOCUMENT", "45", 1L, "admin@provaluer.com", 600L, false, "127.0.0.1", "JUnit-Agent"
        );

        assertNotNull(tokenResult.token);
        assertTrue(tokenResult.expiresInSeconds <= 600);
        assertTrue(tokenResult.expiresAt.isAfter(LocalDateTime.now()));

        // Tampered token test: Alter token payload and verify exception
        byte[] decodedBytes = Base64.getUrlDecoder().decode(tokenResult.token);
        String decodedStr = new String(decodedBytes, StandardCharsets.UTF_8);
        String tampered = Base64.getUrlEncoder().withoutPadding().encodeToString(
                decodedStr.replace("45", "99").getBytes(StandardCharsets.UTF_8)
        );

        assertThrows(SecurityException.class, () -> {
            docSec.downloadDocumentWithToken(tampered, "127.0.0.1", "JUnit-Agent");
        }, "Tampered download token must be rejected with SecurityException");
    }

    @Test
    @DisplayName("Phase F: Data Masking Utility - PAN, Aadhaar, Passport, Phone, Email & Freeform Logs")
    public void testDataMaskingUtility() {
        assertEquals("XXXXX1234F", DataMaskingUtil.maskPan("ABCDE1234F"));
        assertEquals("XXXXXXXX9012", DataMaskingUtil.maskAadhaar("123456789012"));
        assertEquals("XXXXXXXX9012", DataMaskingUtil.maskAadhaar("1234 5678 9012"));
        assertEquals("XXXXX567", DataMaskingUtil.maskPassport("A1234567"));
        assertEquals("j***e@example.com", DataMaskingUtil.maskEmail("john.doe@example.com"));
        assertEquals("XXXXXX3210", DataMaskingUtil.maskPhone("9876543210"));
        assertEquals("XXXXXXXXXX2345", DataMaskingUtil.maskBankAccount("50200088912345"));

        // Freeform text log sanitization test
        String rawLog = "Customer submitted PAN ABCDE1234F and Aadhaar 2345 6789 0123 with email user@provaluer.com and phone 9876543210";
        String sanitized = DataMaskingUtil.sanitizeLog(rawLog);

        assertFalse(sanitized.contains("ABCDE1234F"), "Sanitized log must not contain raw PAN");
        assertFalse(sanitized.contains("2345 6789 0123"), "Sanitized log must not contain raw Aadhaar");
        assertFalse(sanitized.contains("user@provaluer.com"), "Sanitized log must not contain raw Email");
        assertFalse(sanitized.contains("9876543210"), "Sanitized log must not contain raw Phone");

        assertTrue(sanitized.contains("XXXXX1234F"));
        assertTrue(sanitized.contains("XXXXXXXX0123"));
    }

    @Test
    @DisplayName("Phase G: Encryption Health Status & Dashboard Telemetry")
    public void testEncryptionStatusService() {
        assertTrue(statusService.isEncryptionEnabled());
        assertEquals("v1-aes256-gcm", statusService.getKeyVersion());
        assertEquals("HEALTHY", statusService.getHealthStatus());

        Map<String, Object> summary = statusService.getSecurityDashboardSummary();
        assertNotNull(summary);
        assertEquals(true, summary.get("encryptionEnabled"));
        assertEquals("AES-256-GCM (AEAD)", summary.get("algorithm"));
        assertEquals("HEALTHY", summary.get("healthStatus"));
    }
}
