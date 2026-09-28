package com.provaluer.service;

import com.provaluer.model.LeadDocument;
import com.provaluer.model.ValuationLead;
import com.provaluer.repository.LeadDocumentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class DocumentUploadService {

    private static final Logger log = LoggerFactory.getLogger(DocumentUploadService.class);

    // P1-2: Removed "zip" from allowed public intake extensions to eliminate zip bombs,
    // uncompressed recursion exhaustion, and archive-based malware distribution.
    private static final Set<String> ALLOWED_EXTENSIONS = new HashSet<>(Arrays.asList(
        "pdf", "docx", "doc", "xlsx", "xls", "jpg", "jpeg", "png"
    ));

    private static final long MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB

    private final Path rootStorage = Paths.get("storage", "leads");

    @Autowired
    private LeadDocumentRepository leadDocumentRepository;

    public DocumentUploadService() {
        try {
            Files.createDirectories(rootStorage);
        } catch (IOException e) {
            log.error("Could not initialize leads storage directory", e);
        }
    }

    public List<LeadDocument> uploadDocuments(ValuationLead lead, MultipartFile[] files) throws IOException {
        List<LeadDocument> savedDocs = new ArrayList<>();
        if (files == null || files.length == 0) {
            return savedDocs;
        }

        Path leadFolder = rootStorage.resolve(String.valueOf(lead.getId()));
        Files.createDirectories(leadFolder);

        for (MultipartFile file : files) {
            if (file.isEmpty()) continue;

            String rawFilename = file.getOriginalFilename();
            String originalName = (rawFilename != null && !rawFilename.trim().isEmpty()) ? rawFilename : "document";

            if (file.getSize() > MAX_FILE_SIZE) {
                throw new IllegalArgumentException("File " + originalName + " exceeds 50MB limit");
            }

            String ext = "";
            int dotIdx = originalName.lastIndexOf('.');
            if (dotIdx >= 0 && dotIdx < originalName.length() - 1) {
                ext = originalName.substring(dotIdx + 1).toLowerCase();
            }

            if (!ALLOWED_EXTENSIONS.contains(ext)) {
                throw new IllegalArgumentException("Unsupported file type: " + ext);
            }

            // P1-1: Strict binary magic bytes verification
            validateMagicBytes(file, ext);

            String safeName = UUID.randomUUID() + "_" + originalName.replaceAll("[^a-zA-Z0-9.-]", "_");
            Path targetPath = leadFolder.resolve(safeName);
            Files.copy(file.getInputStream(), targetPath);

            LeadDocument doc = new LeadDocument();
            doc.setLead(lead);
            doc.setFileName(originalName);
            doc.setFileType(file.getContentType() != null ? file.getContentType() : ext);
            doc.setFileSizeBytes(file.getSize());
            doc.setStoragePath(targetPath.toString());
            doc.setConfidential(true);

            savedDocs.add(leadDocumentRepository.save(doc));
        }

        return savedDocs;
    }

    /**
     * P1-1: Binary magic byte signature validation.
     * Prevents disguised executables (PE, ELF, scripts, web shells) from being stored.
     */
    public void validateMagicBytes(MultipartFile file, String ext) throws IOException {
        try (java.io.InputStream is = file.getInputStream()) {
            byte[] header = new byte[8];
            int read = is.read(header);
            if (read < 4) {
                throw new IllegalArgumentException("Corrupted or empty file header in: " + file.getOriginalFilename());
            }

            // Explicit rejection of Windows PE Executables (MZ) and Unix/Linux ELF/Scripts
            if (header[0] == 0x4D && header[1] == 0x5A) { // 'M', 'Z'
                throw new IllegalArgumentException("Executable file detected and blocked: " + file.getOriginalFilename());
            }
            if (header[0] == 0x7F && header[1] == 0x45 && header[2] == 0x4C && header[3] == 0x46) { // ELF
                throw new IllegalArgumentException("ELF executable detected and blocked: " + file.getOriginalFilename());
            }
            if (header[0] == 0x23 && header[1] == 0x21) { // '#!' Shebang script
                throw new IllegalArgumentException("Script file detected and blocked: " + file.getOriginalFilename());
            }

            switch (ext) {
                case "pdf":
                    // PDF starts with %PDF (0x25, 0x50, 0x44, 0x46)
                    if (header[0] != 0x25 || header[1] != 0x50 || header[2] != 0x44 || header[3] != 0x46) {
                        throw new IllegalArgumentException("Invalid PDF binary header in: " + file.getOriginalFilename());
                    }
                    break;
                case "docx":
                case "xlsx":
                    // Office OpenXML files are ZIP-based containers starting with PK\x03\x04
                    if (header[0] != 0x50 || header[1] != 0x4B || header[2] != 0x03 || header[3] != 0x04) {
                        throw new IllegalArgumentException("Invalid Office OpenXML binary header in: " + file.getOriginalFilename());
                    }
                    break;
                case "png":
                    // PNG signature: 0x89 0x50 0x4E 0x47
                    if ((header[0] & 0xFF) != 0x89 || header[1] != 0x50 || header[2] != 0x4E || header[3] != 0x47) {
                        throw new IllegalArgumentException("Invalid PNG binary header in: " + file.getOriginalFilename());
                    }
                    break;
                case "jpg":
                case "jpeg":
                    // JPEG starts with FF D8 FF
                    if ((header[0] & 0xFF) != 0xFF || (header[1] & 0xFF) != 0xD8 || (header[2] & 0xFF) != 0xFF) {
                        throw new IllegalArgumentException("Invalid JPEG binary header in: " + file.getOriginalFilename());
                    }
                    break;
                case "doc":
                case "xls":
                    // Microsoft Compound File Binary Format (CFBF / OLE2)
                    // Signature: D0 CF 11 E0 A1 B1 1A E1
                    if ((header[0] & 0xFF) != 0xD0 || (header[1] & 0xFF) != 0xCF ||
                        (header[2] & 0xFF) != 0x11 || (header[3] & 0xFF) != 0xE0) {
                        throw new IllegalArgumentException("Invalid legacy Office document header in: " + file.getOriginalFilename());
                    }
                    break;
                default:
                    throw new IllegalArgumentException("Unsupported file type signature: " + ext);
            }
        }
    }
}
