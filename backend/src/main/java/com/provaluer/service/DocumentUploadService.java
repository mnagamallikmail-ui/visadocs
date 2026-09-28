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

    private static final Set<String> ALLOWED_EXTENSIONS = new HashSet<>(Arrays.asList(
        "pdf", "docx", "doc", "xlsx", "xls", "zip", "jpg", "jpeg", "png"
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
}
