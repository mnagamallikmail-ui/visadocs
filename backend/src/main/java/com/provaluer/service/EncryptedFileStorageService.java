package com.provaluer.service;

import com.provaluer.config.EncryptionConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.SecureRandom;
import java.util.Arrays;

/**
 * DPDP Act 2023 - Encrypted File Storage Service
 * Provides AES-256-GCM envelope encryption for all sensitive uploaded documents
 * (Deeds, PAN cards, Aadhaar files, Passport copies, Financial Statements, Legal documents).
 *
 * File Envelope:
 * [0..6]   : Magic Bytes "PVENC1\0" (7 bytes)
 * [7]      : Key Version (1 byte, 0x01)
 * [8..19]  : Random 96-bit GCM IV (12 bytes)
 * [20..end]: AES-256-GCM Ciphertext + 128-bit Authentication Tag
 *
 * Fully backward compatible: Files without the PVENC1 magic header are read as legacy plaintext.
 */
@Service
public class EncryptedFileStorageService {

    private static final Logger log = LoggerFactory.getLogger(EncryptedFileStorageService.class);

    public static final byte[] MAGIC_HEADER = new byte[]{'P', 'V', 'E', 'N', 'C', '1', 0};
    private static final byte KEY_VERSION_1 = 0x01;
    private static final int HEADER_LENGTH = 20; // 7 magic + 1 version + 12 IV
    private static final int IV_LENGTH = 12; // 96-bit IV
    private static final int TAG_LENGTH_BITS = 128; // 128-bit authentication tag
    private static final String ALGORITHM = "AES/GCM/NoPadding";
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    /**
     * Encrypts and writes an input stream to the target path.
     */
    public Path storeEncrypted(InputStream inputStream, Path targetPath) throws IOException {
        byte[] plaintext = inputStream.readAllBytes();
        byte[] encryptedEnvelope = encryptBytes(plaintext);

        if (targetPath.getParent() != null) {
            Files.createDirectories(targetPath.getParent());
        }
        Files.write(targetPath, encryptedEnvelope);
        log.info("Encrypted document written securely to: {}", targetPath);
        return targetPath;
    }

    /**
     * Reads a document and decrypts it if encrypted.
     * If legacy plaintext, returns raw bytes without modification.
     */
    public byte[] readDecryptedBytes(Path path) throws IOException {
        if (!Files.exists(path)) {
            throw new FileNotFoundException("Document file not found at: " + path);
        }
        byte[] fileBytes = Files.readAllBytes(path);
        return decryptBytes(fileBytes);
    }

    /**
     * Returns an InputStream for decrypted content.
     */
    public InputStream readDecryptedStream(Path path) throws IOException {
        return new ByteArrayInputStream(readDecryptedBytes(path));
    }

    /**
     * Encrypts arbitrary byte array with AES-256-GCM and prepends PVENC1 envelope.
     */
    public byte[] encryptBytes(byte[] plaintext) {
        if (plaintext == null) return null;
        if (isEncryptedData(plaintext)) {
            return plaintext; // Avoid double encryption
        }

        try {
            byte[] iv = new byte[IV_LENGTH];
            SECURE_RANDOM.nextBytes(iv);

            byte[] keyBytes = EncryptionConfig.getMasterKeyBytes();
            SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            GCMParameterSpec spec = new GCMParameterSpec(TAG_LENGTH_BITS, iv);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, spec);

            byte[] ciphertext = cipher.doFinal(plaintext);

            // Construct envelope: [MAGIC (7)] + [VERSION (1)] + [IV (12)] + [CIPHERTEXT]
            byte[] envelope = new byte[HEADER_LENGTH + ciphertext.length];
            System.arraycopy(MAGIC_HEADER, 0, envelope, 0, MAGIC_HEADER.length);
            envelope[7] = KEY_VERSION_1;
            System.arraycopy(iv, 0, envelope, 8, IV_LENGTH);
            System.arraycopy(ciphertext, 0, envelope, HEADER_LENGTH, ciphertext.length);

            return envelope;
        } catch (Exception e) {
            log.error("Failed to encrypt document bytes: {}", e.getMessage());
            throw new RuntimeException("Document encryption failure", e);
        }
    }

    /**
     * Decrypts byte array if PVENC1 envelope is present; returns original bytes if legacy plaintext.
     */
    public byte[] decryptBytes(byte[] envelope) {
        if (envelope == null || envelope.length == 0) {
            return envelope;
        }

        // Check for PVENC1 magic header
        if (!isEncryptedData(envelope)) {
            // Legacy plaintext fallback
            return envelope;
        }

        try {
            byte[] iv = new byte[IV_LENGTH];
            System.arraycopy(envelope, 8, iv, 0, IV_LENGTH);

            int cipherLength = envelope.length - HEADER_LENGTH;
            byte[] ciphertext = new byte[cipherLength];
            System.arraycopy(envelope, HEADER_LENGTH, ciphertext, 0, cipherLength);

            byte[] keyBytes = EncryptionConfig.getMasterKeyBytes();
            SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            GCMParameterSpec spec = new GCMParameterSpec(TAG_LENGTH_BITS, iv);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec);

            return cipher.doFinal(ciphertext);
        } catch (Exception e) {
            log.error("Failed to decrypt document envelope: {}", e.getMessage());
            throw new RuntimeException("Document decryption failure / tamper check failed", e);
        }
    }

    /**
     * Checks if given byte array has the PVENC1 magic header.
     */
    public boolean isEncryptedData(byte[] data) {
        if (data == null || data.length < HEADER_LENGTH) {
            return false;
        }
        for (int i = 0; i < MAGIC_HEADER.length; i++) {
            if (data[i] != MAGIC_HEADER[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * Static helper for direct byte encryption
     */
    public static byte[] encryptData(byte[] plaintext) {
        if (plaintext == null) return null;
        if (isEncryptedDataStatic(plaintext)) {
            return plaintext;
        }
        try {
            byte[] iv = new byte[IV_LENGTH];
            SECURE_RANDOM.nextBytes(iv);

            byte[] keyBytes = EncryptionConfig.getMasterKeyBytes();
            SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            GCMParameterSpec spec = new GCMParameterSpec(TAG_LENGTH_BITS, iv);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, spec);

            byte[] ciphertext = cipher.doFinal(plaintext);

            byte[] envelope = new byte[HEADER_LENGTH + ciphertext.length];
            System.arraycopy(MAGIC_HEADER, 0, envelope, 0, MAGIC_HEADER.length);
            envelope[7] = KEY_VERSION_1;
            System.arraycopy(iv, 0, envelope, 8, IV_LENGTH);
            System.arraycopy(ciphertext, 0, envelope, HEADER_LENGTH, ciphertext.length);

            return envelope;
        } catch (Exception e) {
            log.error("Static byte encryption failed: {}", e.getMessage());
            throw new RuntimeException("Document byte encryption failure", e);
        }
    }

    /**
     * Static helper for direct byte decryption
     */
    public static byte[] decryptData(byte[] envelope) {
        if (envelope == null || envelope.length == 0) return envelope;
        if (!isEncryptedDataStatic(envelope)) return envelope; // legacy plaintext fallback

        try {
            byte[] iv = new byte[IV_LENGTH];
            System.arraycopy(envelope, 8, iv, 0, IV_LENGTH);

            int cipherLength = envelope.length - HEADER_LENGTH;
            byte[] ciphertext = new byte[cipherLength];
            System.arraycopy(envelope, HEADER_LENGTH, ciphertext, 0, cipherLength);

            byte[] keyBytes = EncryptionConfig.getMasterKeyBytes();
            SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");

            Cipher cipher = Cipher.getInstance(ALGORITHM);
            GCMParameterSpec spec = new GCMParameterSpec(TAG_LENGTH_BITS, iv);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec);

            return cipher.doFinal(ciphertext);
        } catch (Exception e) {
            log.error("Static byte decryption failed: {}", e.getMessage());
            throw new RuntimeException("Document byte decryption failure", e);
        }
    }

    public static boolean isEncryptedDataStatic(byte[] data) {
        if (data == null || data.length < HEADER_LENGTH) {
            return false;
        }
        for (int i = 0; i < MAGIC_HEADER.length; i++) {
            if (data[i] != MAGIC_HEADER[i]) {
                return false;
            }
        }
        return true;
    }

    /**
     * Checks if file on disk is encrypted.
     */
    public boolean isEncryptedFile(Path path) {
        if (!Files.exists(path)) return false;
        try (InputStream is = Files.newInputStream(path)) {
            byte[] header = new byte[MAGIC_HEADER.length];
            int read = is.read(header);
            if (read < MAGIC_HEADER.length) return false;
            return Arrays.equals(header, MAGIC_HEADER);
        } catch (IOException e) {
            return false;
        }
    }
}
