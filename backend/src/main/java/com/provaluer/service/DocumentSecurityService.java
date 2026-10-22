package com.provaluer.service;

import com.provaluer.config.EncryptionConfig;
import com.provaluer.model.DocumentAccessLog;
import com.provaluer.model.LeadDocument;
import com.provaluer.model.OrderDocument;
import com.provaluer.repository.DocumentAccessLogRepository;
import com.provaluer.repository.LeadDocumentRepository;
import com.provaluer.repository.OrderDocumentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * DPDP Act 2023 - Document Security Service
 * Implements expiring, cryptographically signed download tokens (default 10 minutes TTL),
 * single-use enforcement, and access logging in document_access_logs.
 */
@Service
public class DocumentSecurityService {

    private static final Logger log = LoggerFactory.getLogger(DocumentSecurityService.class);

    private static final String HMAC_ALGO = "HmacSHA256";
    private static final long DEFAULT_EXPIRY_SECONDS = 600; // 10 minutes default TTL
    private static final SecureRandom RANDOM = new SecureRandom();

    // In-memory set for single-use token consumption
    private final Set<String> consumedTokens = Collections.newSetFromMap(new ConcurrentHashMap<>());

    @Autowired
    private DocumentAccessLogRepository accessLogRepository;

    @Autowired
    private LeadDocumentRepository leadDocumentRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private EncryptedFileStorageService encryptedFileStorageService;

    public static class DownloadTokenResult {
        public String token;
        public LocalDateTime expiresAt;
        public long expiresInSeconds;

        public DownloadTokenResult(String token, LocalDateTime expiresAt, long expiresInSeconds) {
            this.token = token;
            this.expiresAt = expiresAt;
            this.expiresInSeconds = expiresInSeconds;
        }
    }

    public static class DecryptedDocumentResult {
        public String filename;
        public String contentType;
        public byte[] data;

        public DecryptedDocumentResult(String filename, String contentType, byte[] data) {
            this.filename = filename;
            this.contentType = contentType;
            this.data = data;
        }
    }

    /**
     * Generate signed expiring download token (default 10 min)
     */
    public DownloadTokenResult generateDownloadToken(
            String documentType,
            String documentId,
            Long userId,
            String username,
            Long expirySeconds,
            boolean singleUse,
            String ipAddress,
            String userAgent) {

        long ttl = (expirySeconds != null && expirySeconds > 0) ? expirySeconds : DEFAULT_EXPIRY_SECONDS;
        long expEpoch = Instant.now().getEpochSecond() + ttl;
        String nonce = Long.toHexString(RANDOM.nextLong());

        // Payload: docType|docId|userId|expEpoch|singleUse|nonce
        String payload = String.format("%s|%s|%s|%d|%b|%s",
                documentType, documentId, (userId != null ? userId : "0"), expEpoch, singleUse, nonce);

        String signature = sign(payload);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString((payload + "." + signature).getBytes(StandardCharsets.UTF_8));

        // Log token generation in document_access_logs
        if (accessLogRepository != null) {
            DocumentAccessLog accessLog = new DocumentAccessLog(
                    userId, username, documentType, documentId,
                    "DOC_" + documentId, "TOKEN_GENERATED", token, ipAddress, userAgent, "SUCCESS"
            );
            accessLogRepository.save(accessLog);
        }

        return new DownloadTokenResult(token, LocalDateTime.now().plusSeconds(ttl), ttl);
    }

    /**
     * Validate token, log access, and stream decrypted document.
     */
    public DecryptedDocumentResult downloadDocumentWithToken(String rawToken, String ipAddress, String userAgent) throws IOException {
        if (rawToken == null || rawToken.trim().isEmpty()) {
            throw new IllegalArgumentException("Missing download token");
        }

        String decoded;
        try {
            decoded = new String(Base64.getUrlDecoder().decode(rawToken.trim()), StandardCharsets.UTF_8);
        } catch (Exception e) {
            logAccess(null, null, "UNKNOWN", "0", "UNKNOWN", "TOKEN_MALFORMED", rawToken, ipAddress, userAgent, "DENIED");
            throw new SecurityException("Malformed download token");
        }

        int dotIdx = decoded.lastIndexOf('.');
        if (dotIdx <= 0) {
            logAccess(null, null, "UNKNOWN", "0", "UNKNOWN", "TOKEN_MALFORMED", rawToken, ipAddress, userAgent, "DENIED");
            throw new SecurityException("Invalid download token structure");
        }

        String payload = decoded.substring(0, dotIdx);
        String signature = decoded.substring(dotIdx + 1);

        // Verify cryptographic signature
        if (!sign(payload).equals(signature)) {
            logAccess(null, null, "UNKNOWN", "0", "UNKNOWN", "SIGNATURE_INVALID", rawToken, ipAddress, userAgent, "DENIED");
            throw new SecurityException("Tampered or invalid download token signature");
        }

        String[] parts = payload.split("\\|");
        if (parts.length != 6) {
            throw new SecurityException("Corrupted download token payload");
        }

        String docType = parts[0];
        String docId = parts[1];
        Long userId = "0".equals(parts[2]) ? null : Long.parseLong(parts[2]);
        long expEpoch = Long.parseLong(parts[3]);
        boolean singleUse = Boolean.parseBoolean(parts[4]);

        // Check expiration
        if (Instant.now().getEpochSecond() > expEpoch) {
            logAccess(userId, null, docType, docId, "DOC_" + docId, "TOKEN_EXPIRED", rawToken, ipAddress, userAgent, "EXPIRED");
            throw new SecurityException("Download token has expired. Please request a new link.");
        }

        // Check single-use consumption
        if (singleUse) {
            if (consumedTokens.contains(rawToken)) {
                logAccess(userId, null, docType, docId, "DOC_" + docId, "TOKEN_ALREADY_CONSUMED", rawToken, ipAddress, userAgent, "DENIED");
                throw new SecurityException("Single-use download token has already been consumed");
            }
            consumedTokens.add(rawToken);
        }

        // Retrieve and decrypt document
        DecryptedDocumentResult result;
        if ("LEAD_DOCUMENT".equalsIgnoreCase(docType)) {
            Long id = Long.parseLong(docId);
            LeadDocument doc = leadDocumentRepository.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Lead document not found with id: " + id));

            byte[] decrypted = encryptedFileStorageService.readDecryptedBytes(Paths.get(doc.getStoragePath()));
            result = new DecryptedDocumentResult(doc.getFileName(), doc.getFileType(), decrypted);
        } else if ("ORDER_DOCUMENT".equalsIgnoreCase(docType)) {
            Long id = Long.parseLong(docId);
            OrderDocument doc = orderDocumentRepository.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Order document not found with id: " + id));

            result = new DecryptedDocumentResult(doc.getFilename(), "application/octet-stream", doc.getFileContent());
        } else {
            throw new UnsupportedOperationException("Unsupported document type: " + docType);
        }

        // Log successful download in audit trail
        logAccess(userId, null, docType, docId, result.filename, "DOWNLOAD_SUCCESS", rawToken, ipAddress, userAgent, "SUCCESS");
        return result;
    }

    private void logAccess(Long userId, String username, String docType, String docId,
                           String docName, String action, String token, String ip, String ua, String status) {
        if (accessLogRepository == null) return;
        try {
            DocumentAccessLog log = new DocumentAccessLog(
                    userId, username, docType, docId, docName, action, token, ip, ua, status
            );
            accessLogRepository.save(log);
        } catch (Exception e) {
            log.error("Failed to write document access log: {}", e.getMessage());
        }
    }

    private String sign(String data) {
        try {
            byte[] keyBytes = EncryptionConfig.getMasterKeyBytes();
            Mac mac = Mac.getInstance(HMAC_ALGO);
            mac.init(new SecretKeySpec(keyBytes, HMAC_ALGO));
            byte[] rawHmac = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(rawHmac);
        } catch (Exception e) {
            throw new RuntimeException("HMAC signing error", e);
        }
    }
}
