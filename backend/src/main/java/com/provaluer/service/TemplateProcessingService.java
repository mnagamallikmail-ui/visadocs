package com.provaluer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
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
import com.provaluer.dto.TemplateDiffDTO;
import com.provaluer.dto.TemplateUsageDTO;
import java.time.LocalDateTime;
import java.util.*;
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
    private com.provaluer.repository.OrderRepository orderRepository;

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

                // Step 1: Normalize run fragments, standardize placeholders & resolve generic <<TEXT>> placeholders
                com.provaluer.util.GenericPlaceholderNormalizer.TemplateAnalysisReport analysisReport =
                        new com.provaluer.util.GenericPlaceholderNormalizer.TemplateAnalysisReport();
                byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, analysisReport);
                log.info("Template ID: {} parser analysis report:{}", templateId, analysisReport.toFormattedReport());

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
        // Find existing versions for this template to prevent duplicate key violations on (template_id, version)
        java.util.List<TemplateVersion> existingVersions = templateVersionRepository.findAllByTemplateIdOrderByVersionDesc(template.getId());
        int targetVersion = template.getVersion();

        if (!existingVersions.isEmpty()) {
            int maxVersion = existingVersions.get(0).getVersion();
            final int currentVer = targetVersion;
            boolean versionAlreadyExists = existingVersions.stream().anyMatch(v -> v.getVersion() == currentVer);
            if (versionAlreadyExists || targetVersion <= maxVersion) {
                targetVersion = maxVersion + 1;
                template.setVersion(targetVersion);
                templateRepository.save(template);
            }
        } else {
            if (targetVersion <= 0) {
                targetVersion = 1;
                template.setVersion(1);
                templateRepository.save(template);
            }
        }

        TemplateVersion version = new TemplateVersion(template, changeSummary, actorId);
        version.setVersion(targetVersion);
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

    /**
     * Retrieves usage impact metrics for a given template.
     */
    public TemplateUsageDTO getTemplateUsage(Long templateId) {
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found: " + templateId));

        long total = orderRepository.countByTemplateId(templateId);
        long drafts = orderRepository.countByTemplateIdAndStatus(templateId, "DRAFT");
        long submitted = total - drafts;

        List<TemplateVersion> versions = templateVersionRepository.findAllByTemplateIdOrderByVersionDesc(templateId);
        List<Map<String, Object>> versionList = new ArrayList<>();
        for (TemplateVersion v : versions) {
            long verReports = orderRepository.countByTemplateVersionId(v.getId());
            versionList.add(Map.of(
                    "versionId", v.getId(),
                    "version", v.getVersion(),
                    "name", v.getName(),
                    "status", v.getStatus() != null ? v.getStatus() : "ACTIVE",
                    "reportCount", verReports,
                    "createdAt", v.getCreatedAt() != null ? v.getCreatedAt().toString() : ""
            ));
        }

        return new TemplateUsageDTO(
                template.getId(),
                template.getName(),
                template.getCode(),
                template.getVersion(),
                template.getStatus(),
                total,
                drafts,
                submitted,
                total == 0,
                versionList
        );
    }

    /**
     * Computes placeholder compatibility diff between old template version and revised DOCX package.
     */
    public TemplateDiffDTO computeTemplateDiff(Long templateId, byte[] newDocxBytes) throws Exception {
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found: " + templateId));

        TemplateDiffDTO diff = new TemplateDiffDTO();
        diff.setOldVersion(template.getVersion());
        diff.setProposedVersion(template.getVersion() + 1);

        // 1. Extract existing placeholder keys
        Set<String> oldKeys = new LinkedHashSet<>();
        if (template.getPlaceholderRegistry() != null && !template.getPlaceholderRegistry().trim().isEmpty()) {
            JsonNode regNode = objectMapper.readTree(template.getPlaceholderRegistry());
            if (regNode.isArray()) {
                for (JsonNode item : regNode) {
                    if (item.has("key")) oldKeys.add(item.get("key").asText().toUpperCase().trim());
                }
            }
        }

        // 2. Parse new DOCX
        byte[] normalizedNew = templateEngine.normalizeTemplate(newDocxBytes);
        JsonNode newDom = docxStructureParser.parseDocumentStructure(normalizedNew);
        String newRegistryJson = docxStructureParser.generatePlaceholderRegistry(newDom);
        Set<String> newKeys = new LinkedHashSet<>();
        JsonNode newRegNode = objectMapper.readTree(newRegistryJson);
        if (newRegNode.isArray()) {
            for (JsonNode item : newRegNode) {
                if (item.has("key")) newKeys.add(item.get("key").asText().toUpperCase().trim());
            }
        }

        // 3. Diff analysis
        for (String k : oldKeys) {
            if (newKeys.contains(k)) {
                diff.getRetainedTokens().add(k);
            } else {
                diff.getRemovedTokens().add(k);
            }
        }
        for (String k : newKeys) {
            if (!oldKeys.contains(k)) {
                diff.getAddedTokens().add(k);
            }
        }

        // 4. Detect alias renames (e.g. SUPER_BUILT_UP_AREA -> SALEABLE_AREA)
        if (diff.getRemovedTokens().contains("SUPER_BUILT_UP_AREA") && diff.getAddedTokens().contains("SALEABLE_AREA")) {
            diff.getRenamedTokens().put("SUPER_BUILT_UP_AREA", "SALEABLE_AREA");
        }
        if (diff.getRemovedTokens().contains("COMPOSITE_RATE") && diff.getAddedTokens().contains("MARKET_RATE_FLAT")) {
            diff.getRenamedTokens().put("COMPOSITE_RATE", "MARKET_RATE_FLAT");
        }

        // 5. Detect breaking changes (removal of core valuation drivers)
        Set<String> criticalDrivers = Set.of("SALEABLE_AREA", "MARKET_RATE_FLAT", "FAIR_VALUE", "REALIZABLE_VALUE", "REPORT_NO");
        for (String removed : diff.getRemovedTokens()) {
            if (criticalDrivers.contains(removed) && !diff.getRenamedTokens().containsKey(removed)) {
                diff.setHasBreakingChanges(true);
                diff.getBreakingChangeReasons().add("Authoritative valuation driver <<" + removed + ">> has been removed without an alias.");
            }
        }

        if (diff.isHasBreakingChanges()) {
            diff.setCompatibilityStatus("BREAKING_CHANGE");
        } else if (!diff.getRemovedTokens().isEmpty() || !diff.getRenamedTokens().isEmpty()) {
            diff.setCompatibilityStatus("SAFE_WITH_NOTICE");
        } else {
            diff.setCompatibilityStatus("SAFE");
        }

        return diff;
    }

    /**
     * Publishes a new version (V_next) of an existing template under Single Active Version Governance.
     * The previous active version is archived. Existing reports remain strictly untouched.
     */
    @Transactional
    public Template publishNewVersion(Long templateId, byte[] docxBytes, String changeSummary, Long actorId) throws Exception {
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found: " + templateId));

        validateDocxPackage(docxBytes, "revised_template.docx");

        byte[] normalized = templateEngine.normalizeTemplate(docxBytes);
        JsonNode domNode = docxStructureParser.parseDocumentStructure(normalized);
        String documentDomJson = domNode.toString();
        String placeholderRegistryJson = docxStructureParser.generatePlaceholderRegistry(domNode);
        String fieldMappingJson = templateEngine.parseTemplate(normalized);

        // Pre-commit diff calculation
        TemplateDiffDTO diff = computeTemplateDiff(templateId, docxBytes);
        String diffJson = objectMapper.writeValueAsString(diff);

        // Archive previous version record in template_versions
        List<TemplateVersion> prevVersions = templateVersionRepository.findAllByTemplateIdOrderByVersionDesc(templateId);
        for (TemplateVersion pv : prevVersions) {
            if ("ACTIVE".equalsIgnoreCase(pv.getStatus())) {
                pv.setStatus("ARCHIVED");
                templateVersionRepository.save(pv);
            }
        }

        // Determine new sequential version number
        int nextVersion = template.getVersion() + 1;
        if (!prevVersions.isEmpty()) {
            int maxV = prevVersions.get(0).getVersion();
            if (nextVersion <= maxV) {
                nextVersion = maxV + 1;
            }
        }

        // Create new Version record
        TemplateVersion newVer = new TemplateVersion();
        newVer.setTemplateId(template.getId());
        newVer.setVersion(nextVersion);
        newVer.setName(template.getName());
        newVer.setTemplateContent(normalized);
        newVer.setFieldMapping(fieldMappingJson);
        newVer.setDocumentDom(documentDomJson);
        newVer.setPlaceholderRegistry(placeholderRegistryJson);
        newVer.setChangeSummary(changeSummary != null ? changeSummary : "Published version " + nextVersion);
        newVer.setStatus("ACTIVE");
        newVer.setPlaceholderDiff(diffJson);
        newVer.setCreatedBy(actorId);
        newVer.setCreatedAt(LocalDateTime.now());
        templateVersionRepository.save(newVer);

        // Update parent Template record to new version and mark ACTIVE
        template.setVersion(nextVersion);
        template.setTemplateContent(normalized);
        template.setDocumentDom(documentDomJson);
        template.setPlaceholderRegistry(placeholderRegistryJson);
        template.setFieldMapping(fieldMappingJson);
        template.setStatus(Template.STATUS_ACTIVE);
        template.setIsActive("Y");
        template.setProcessingError(null);
        Template saved = templateRepository.save(template);

        // Single Active Version Governance: Archive other templates with identical code
        if (template.getCode() != null) {
            List<Template> siblings = templateRepository.findAllByCode(template.getCode());
            for (Template s : siblings) {
                if (!s.getId().equals(template.getId()) && Template.STATUS_ACTIVE.equals(s.getStatus())) {
                    s.setStatus(Template.STATUS_ARCHIVED);
                    s.setIsActive("N");
                    templateRepository.save(s);
                }
            }
        }

        log.info("Template #{} published new version v{} successfully.", templateId, nextVersion);
        return saved;
    }

    /**
     * Publishes a new version of template metadata (renames, additions, deletions, type changes, aliases)
     * without modifying the uploaded DOCX binary.
     * Option A Guarantee: Preserves original binary byte-for-byte; creates new TemplateVersion (v_next);
     * archives previous active version; historical reports remain completely untouched.
     */
    @Transactional
    public Template publishMetadataVersion(Long templateId, Map<String, Object> metadataUpdates, String changeSummary, Long actorId) throws Exception {
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found: " + templateId));

        byte[] existingContent = template.getTemplateContent();
        if (existingContent == null) {
            throw new IllegalStateException("Template has no content binary to base metadata version on.");
        }

        // 1. Read existing DOM and Placeholder Registry
        JsonNode domRoot = template.getDocumentDom() != null
                ? objectMapper.readTree(template.getDocumentDom())
                : docxStructureParser.parseDocumentStructure(existingContent);

        ObjectNode registryNode = template.getPlaceholderRegistry() != null
                ? (ObjectNode) objectMapper.readTree(template.getPlaceholderRegistry())
                : (ObjectNode) objectMapper.readTree(docxStructureParser.generatePlaceholderRegistry(domRoot));

        // 2. Apply metadata modifications
        if (metadataUpdates.containsKey("renames")) {
            @SuppressWarnings("unchecked")
            Map<String, String> renames = (Map<String, String>) metadataUpdates.get("renames");
            for (Map.Entry<String, String> entry : renames.entrySet()) {
                String oldKey = entry.getKey().toUpperCase();
                String newKey = entry.getValue().toUpperCase();
                if (registryNode.has(oldKey)) {
                    JsonNode oldItem = registryNode.remove(oldKey);
                    registryNode.set(newKey, oldItem);
                }
            }
        }

        if (metadataUpdates.containsKey("typeChanges")) {
            @SuppressWarnings("unchecked")
            Map<String, String> typeChanges = (Map<String, String>) metadataUpdates.get("typeChanges");
            for (Map.Entry<String, String> entry : typeChanges.entrySet()) {
                String key = entry.getKey().toUpperCase();
                String newType = entry.getValue().toUpperCase();
                if (registryNode.has(key)) {
                    ((ObjectNode) registryNode.get(key)).put("type", newType);
                }
            }
        }

        if (metadataUpdates.containsKey("additions")) {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> additions = (List<Map<String, Object>>) metadataUpdates.get("additions");
            for (Map<String, Object> add : additions) {
                String key = add.get("key").toString().toUpperCase();
                String type = add.getOrDefault("type", "TEXT").toString().toUpperCase();
                String questionText = add.getOrDefault("questionText", key).toString();
                ObjectNode item = registryNode.putObject(key);
                item.put("type", type);
                item.put("source", "USER_METADATA");
                item.put("isCalculated", false);
                item.put("questionText", questionText);
            }
        }

        if (metadataUpdates.containsKey("deletions")) {
            @SuppressWarnings("unchecked")
            List<String> deletions = (List<String>) metadataUpdates.get("deletions");
            for (String delKey : deletions) {
                registryNode.remove(delKey.toUpperCase());
            }
        }

        if (metadataUpdates.containsKey("placeholders")) {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> placeholdersList = (List<Map<String, Object>>) metadataUpdates.get("placeholders");
            for (Map<String, Object> ph : placeholdersList) {
                String key = ph.get("key").toString().toUpperCase();
                boolean isDeleted = Boolean.TRUE.equals(ph.get("isDeleted"));
                if (isDeleted) {
                    registryNode.remove(key);
                    continue;
                }
                String type = ph.getOrDefault("type", "TEXT").toString().toUpperCase();
                String questionText = ph.getOrDefault("questionText", key).toString();
                ObjectNode item = registryNode.has(key) ? (ObjectNode) registryNode.get(key) : registryNode.putObject(key);
                item.put("type", type);
                item.put("questionText", questionText);
                if (ph.containsKey("aliases")) {
                    item.set("aliases", objectMapper.valueToTree(ph.get("aliases")));
                }
            }
        }

        String updatedPlaceholderRegistryJson = registryNode.toString();
        String updatedDocumentDomJson = domRoot.toString();
        String updatedFieldMappingJson = templateEngine.parseTemplate(existingContent);

        // Archive previous versions
        List<TemplateVersion> prevVersions = templateVersionRepository.findAllByTemplateIdOrderByVersionDesc(templateId);
        for (TemplateVersion pv : prevVersions) {
            if ("ACTIVE".equalsIgnoreCase(pv.getStatus())) {
                pv.setStatus("ARCHIVED");
                templateVersionRepository.save(pv);
            }
        }

        int nextVersion = template.getVersion() + 1;
        if (!prevVersions.isEmpty()) {
            int maxV = prevVersions.get(0).getVersion();
            if (nextVersion <= maxV) {
                nextVersion = maxV + 1;
            }
        }

        // Create new Version record preserving existing binary!
        TemplateVersion newVer = new TemplateVersion();
        newVer.setTemplateId(template.getId());
        newVer.setVersion(nextVersion);
        newVer.setName(template.getName());
        newVer.setTemplateContent(existingContent); // Option A: Exactly identical binary
        newVer.setFieldMapping(updatedFieldMappingJson);
        newVer.setDocumentDom(updatedDocumentDomJson);
        newVer.setPlaceholderRegistry(updatedPlaceholderRegistryJson);
        newVer.setChangeSummary(changeSummary != null && !changeSummary.trim().isEmpty()
                ? changeSummary.trim()
                : "Metadata update version " + nextVersion);
        newVer.setStatus("ACTIVE");
        newVer.setCreatedBy(actorId);
        newVer.setCreatedAt(LocalDateTime.now());
        templateVersionRepository.save(newVer);

        // Update parent template
        template.setVersion(nextVersion);
        template.setDocumentDom(updatedDocumentDomJson);
        template.setPlaceholderRegistry(updatedPlaceholderRegistryJson);
        template.setStatus(Template.STATUS_ACTIVE);
        template.setIsActive("Y");
        template.setProcessingError(null);
        Template saved = templateRepository.save(template);

        log.info("Template #{} published new metadata version v{} successfully without modifying binary.", templateId, nextVersion);
        return saved;
    }

    /**
     * Validates proposed metadata changes before publish.
     */
    public Map<String, Object> validateMetadataUpdates(Long templateId, Map<String, Object> metadataUpdates) throws Exception {
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found: " + templateId));

        Map<String, Object> result = new HashMap<>();
        List<String> added = new ArrayList<>();
        List<String> removed = new ArrayList<>();
        List<String> renamed = new ArrayList<>();
        List<String> typeChanged = new ArrayList<>();

        if (metadataUpdates.containsKey("renames")) {
            @SuppressWarnings("unchecked")
            Map<String, String> renames = (Map<String, String>) metadataUpdates.get("renames");
            renames.forEach((k, v) -> renamed.add(k + " -> " + v));
        }
        if (metadataUpdates.containsKey("deletions")) {
            @SuppressWarnings("unchecked")
            List<String> deletions = (List<String>) metadataUpdates.get("deletions");
            removed.addAll(deletions);
        }
        if (metadataUpdates.containsKey("additions")) {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> additions = (List<Map<String, Object>>) metadataUpdates.get("additions");
            for (Map<String, Object> add : additions) {
                added.add(add.get("key").toString());
            }
        }
        if (metadataUpdates.containsKey("typeChanges")) {
            @SuppressWarnings("unchecked")
            Map<String, String> tc = (Map<String, String>) metadataUpdates.get("typeChanges");
            tc.forEach((k, v) -> typeChanged.add(k + " (" + v + ")"));
        }

        result.put("safeToPublish", true);
        result.put("addedPlaceholders", added);
        result.put("removedPlaceholders", removed);
        result.put("renamedPlaceholders", renamed);
        result.put("typeChangedPlaceholders", typeChanged);
        result.put("templateVersion", template.getVersion());
        return result;
    }

    /**
     * Soft-deletes a template (Option A).
     * NEVER unlinks historical reports or deletes template_versions.
     */
    @Transactional
    public void softDeleteTemplate(Long templateId) {
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found: " + templateId));

        template.setStatus(Template.STATUS_DELETED);
        template.setIsActive("N");
        template.setDeletedAt(LocalDateTime.now());
        templateRepository.save(template);
        log.info("Template #{} soft-deleted under Option A. Historical reports and version snapshots preserved.", templateId);
    }

    /**
     * Hard-deletes template metadata ONLY if usage is strictly 0.
     */
    @Transactional
    public void hardDeleteTemplate(Long templateId) {
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found: " + templateId));

        long count = orderRepository.countByTemplateId(templateId);
        if (count > 0) {
            throw new IllegalStateException("Cannot permanently delete template #" + templateId +
                    ": " + count + " historical reports depend on it. Use soft-delete / archive instead.");
        }

        templateVersionRepository.deleteAllByTemplateId(templateId);
        templateRepository.delete(template);
        log.info("Template #{} permanently purged (zero dependent reports).", templateId);
    }

    /**
     * Sandbox environment: Test-hydrates template against sample order input map without persisting.
     */
    public byte[] testSandboxHydration(Long templateId, Map<String, String> sampleInputs) throws Exception {
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found: " + templateId));

        byte[] raw = template.getTemplateContent();
        return templateEngine.generateReport(raw, sampleInputs, Collections.emptyMap());
    }
}
