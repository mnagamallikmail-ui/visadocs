package com.provaluer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.provaluer.model.DocumentStudioConfig;
import com.provaluer.model.Template;
import com.provaluer.repository.DocumentStudioConfigRepository;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.util.DocxStructureParser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.NoSuchElementException;
import java.util.Optional;

@Service
public class DocumentStudioService {

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private DocumentStudioConfigRepository studioConfigRepository;

    @Autowired
    private DocxStructureParser docxStructureParser;

    /**
     * Loads a template's raw binary DOCX from PostgreSQL and parses its structure into a JsonNode DOM.
     *
     * @param templateId The unique ID of the template to inspect.
     * @return JsonNode containing sections, paragraphs, tables, runs, and placeholder summary.
     */
    @Transactional(readOnly = true)
    public JsonNode getTemplateStructure(Long templateId) {
        if (templateId == null) {
            throw new IllegalArgumentException("Template ID must not be null");
        }

        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new NoSuchElementException("Template not found with ID: " + templateId));

        byte[] content = template.getTemplateContent();
        if (content == null || content.length == 0) {
            throw new IllegalStateException("Template binary content is empty for template ID: " + templateId);
        }

        try {
            return docxStructureParser.parseDocumentStructure(content);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to parse OpenXML document structure for template ID " + templateId + ": " + e.getMessage(), e);
        }
    }

    /**
     * Retrieves existing visual designer configuration and custom label overrides for a template.
     *
     * @param templateId The unique ID of the template.
     * @return DocumentStudioConfig entity if found, or null if no configuration exists.
     */
    @Transactional(readOnly = true)
    public DocumentStudioConfig getStudioConfig(Long templateId) {
        if (templateId == null) {
            return null;
        }
        return studioConfigRepository.findByTemplateId(templateId).orElse(null);
    }

    /**
     * Creates or updates the DocumentStudioConfig record for a template.
     *
     * @param templateId   The template ID.
     * @param customLabels JSON string containing customized placeholder questions/labels.
     * @param tableConfigs JSON string containing calculation table column and row metadata.
     * @param updatedBy    User ID of the administrator making the modification.
     * @return The persisted DocumentStudioConfig entity.
     */
    @Transactional
    public DocumentStudioConfig saveStudioConfig(Long templateId, String customLabels, String tableConfigs, Long updatedBy) {
        if (templateId == null) {
            throw new IllegalArgumentException("Template ID must not be null");
        }

        // Validate template exists before persisting studio configuration
        if (!templateRepository.existsById(templateId)) {
            throw new NoSuchElementException("Cannot save configuration: Template not found with ID: " + templateId);
        }

        Optional<DocumentStudioConfig> existingOpt = studioConfigRepository.findByTemplateId(templateId);

        DocumentStudioConfig config;
        if (existingOpt.isPresent()) {
            config = existingOpt.get();
            if (customLabels != null) {
                config.setCustomLabels(customLabels);
            }
            if (tableConfigs != null) {
                config.setTableConfigs(tableConfigs);
            }
            config.setUpdatedBy(updatedBy);
            config.setUpdatedAt(LocalDateTime.now());
        } else {
            config = new DocumentStudioConfig(
                    templateId,
                    customLabels != null ? customLabels : "{}",
                    tableConfigs != null ? tableConfigs : "[]",
                    updatedBy
            );
        }

        return studioConfigRepository.save(config);
    }
}
