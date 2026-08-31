package com.provaluer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.model.Template;
import com.provaluer.model.TemplateVersion;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.repository.TemplateVersionRepository;
import com.provaluer.util.DocxStructureParser;
import com.provaluer.util.DocxTemplateEngine;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

@Service
public class TemplateProcessingService {

    private static final Logger log = LoggerFactory.getLogger(TemplateProcessingService.class);

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private TemplateVersionRepository templateVersionRepository;

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Autowired
    private DocxStructureParser docxStructureParser;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final AtomicInteger activeProcessingJobs = new AtomicInteger(0);
    private final Set<Long> currentlyProcessingTemplates = ConcurrentHashMap.newKeySet();

    /**
     * Pre-upload validation: Validates that the byte array represents a valid, uncorrupted DOCX package.
     */
    public void validateDocxPackage(byte[] rawBytes, String originalFilename) throws IllegalArgumentException {
        if (rawBytes == null || rawBytes.length == 0) {
            throw new IllegalArgumentException("Uploaded file is empty or missing.");
        }

        // 1. Check minimum ZIP header signature (PK\x03\x04)
        if (rawBytes.length < 4 || rawBytes[0] != 0x50 || rawBytes[1] != 0x4B || rawBytes[2] != 0x03 || rawBytes[3] != 0x04) {
            throw new IllegalArgumentException("Uploaded file is not a valid DOCX document (invalid ZIP header).");
        }

        // 2. Scan ZIP archive entries for required WordprocessingML parts
        boolean hasContentTypes = false;
        boolean hasDocumentXml = false;

        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(rawBytes))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                String name = entry.getName();
                if ("[Content_Types].xml".equalsIgnoreCase(name)) {
                    hasContentTypes = true;
                } else if ("word/document.xml".equalsIgnoreCase(name)) {
                    hasDocumentXml = true;
                }
                zis.closeEntry();
            }
        } catch (IOException e) {
            throw new IllegalArgumentException("Failed to read DOCX package structure: " + e.getMessage(), e);
        }

        if (!hasContentTypes || !hasDocumentXml) {
            throw new IllegalArgumentException("Corrupted DOCX: Missing critical parts ([Content_Types].xml or word/document.xml).");
        }
    }

    /**
     * Triggers asynchronous parsing of an already saved PENDING template.
     */
    public CompletableFuture<Void> processTemplateAsync(Long templateId, byte[] rawBytes, Long actorId) {
        activeProcessingJobs.incrementAndGet();
        currentlyProcessingTemplates.add(templateId);

        return CompletableFuture.runAsync(() -> {
            log.info("Starting background processing for template ID: {}", templateId);
            try {
                // Update status to PARSING
                updateStatus(templateId, "PARSING", null);

                // Step 1: Normalize run fragments & standardize placeholders
                byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes);

                // Step 2: Extract canonical DOM and Placeholder Registry
                JsonNode domNode = docxStructureParser.parseDocumentStructure(normalizedBytes);
                String documentDomJson = domNode.toString();
                String placeholderRegistryJson = docxStructureParser.generatePlaceholderRegistry(domNode);

                // Step 3: Backward compatible field mapping
                String fieldMappingJson = templateEngine.parseTemplate(normalizedBytes);

                // Step 4: Persist finalized results
                templateRepository.findById(templateId).ifPresent(t -> {
                    t.setTemplateContent(normalizedBytes);
                    t.setDocumentDom(documentDomJson);
                    t.setPlaceholderRegistry(placeholderRegistryJson);
                    t.setFieldMapping(fieldMappingJson);
                    t.setStatus("PARSED");
                    t.setProcessingError(null);
                    Template saved = templateRepository.save(t);

                    // Create initial version snapshot
                    saveVersionSnapshot(saved, "Initial template upload and parse", actorId);
                    log.info("Template ID: {} successfully parsed and version 1 snapshot saved.", templateId);
                });

            } catch (Throwable t) {
                String errorMessage = "DOCX Parsing Failure: " + (t.getMessage() != null ? t.getMessage() : t.getClass().getSimpleName());
                log.error("Error processing template ID: " + templateId, t);
                updateStatus(templateId, "FAILED", errorMessage);
            } finally {
                activeProcessingJobs.decrementAndGet();
                currentlyProcessingTemplates.remove(templateId);
            }
        });
    }

    @Transactional
    public void updateStatus(Long templateId, String status, String errorMessage) {
        templateRepository.findById(templateId).ifPresent(t -> {
            t.setStatus(status);
            t.setProcessingError(errorMessage);
            templateRepository.save(t);
        });
    }

    @Transactional
    public TemplateVersion saveVersionSnapshot(Template template, String changeSummary, Long actorId) {
        TemplateVersion version = new TemplateVersion(template, changeSummary, actorId);
        return templateVersionRepository.save(version);
    }

    @Transactional
    public Template rollbackTemplateVersion(Long templateId, int targetVersion, Long actorId) {
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found: " + templateId));

        TemplateVersion versionSnapshot = templateVersionRepository.findByTemplateIdAndVersion(templateId, targetVersion)
                .orElseThrow(() -> new IllegalArgumentException("Template version not found: v" + targetVersion));

        template.setTemplateContent(versionSnapshot.getTemplateContent());
        template.setFieldMapping(versionSnapshot.getFieldMapping());
        template.setDocumentDom(versionSnapshot.getDocumentDom());
        template.setPlaceholderRegistry(versionSnapshot.getPlaceholderRegistry());
        template.setVersion(versionSnapshot.getVersion());
        template.setStatus("CONFIRMED");
        template.setIsActive("Y");
        template.setProcessingError(null);

        Template saved = templateRepository.save(template);
        saveVersionSnapshot(saved, "Rolled back to version " + targetVersion, actorId);
        return saved;
    }

    public int getActiveJobCount() {
        return activeProcessingJobs.get();
    }
}
