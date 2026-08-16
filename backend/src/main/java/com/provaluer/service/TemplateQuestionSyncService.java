package com.provaluer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.provaluer.model.DocumentStudioConfig;
import com.provaluer.model.Template;
import com.provaluer.model.TemplateQuestion;
import com.provaluer.repository.DocumentStudioConfigRepository;
import com.provaluer.repository.TemplateQuestionRepository;
import com.provaluer.repository.TemplateRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.Serializable;
import java.util.*;

/**
 * Service responsible for synchronizing Document Studio customized placeholder questions
 * into the central template questions dictionary and updating the template field mapping schema.
 */
@Service
public class TemplateQuestionSyncService {

    private static final Logger log = LoggerFactory.getLogger(TemplateQuestionSyncService.class);

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private DocumentStudioConfigRepository studioConfigRepository;

    @Autowired
    private TemplateQuestionRepository templateQuestionRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Synchronizes Document Studio configuration into template_questions_dictionary and Template.fieldMapping.
     *
     * @param templateId The unique ID of the template.
     * @param updatedBy  The user ID initiating the synchronization.
     * @return SyncResult containing summary counts.
     */
    @Transactional
    public SyncResult syncTemplateQuestions(Long templateId, Long updatedBy) {
        if (templateId == null) {
            throw new IllegalArgumentException("Template ID must not be null");
        }

        // 1. Load Template
        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new NoSuchElementException("Template not found with ID: " + templateId));

        // 2. Load DocumentStudioConfig
        DocumentStudioConfig studioConfig = studioConfigRepository.findByTemplateId(templateId)
                .orElseThrow(() -> new IllegalStateException("No Document Studio configuration found for template ID: " + templateId));

        String customLabelsJson = studioConfig.getCustomLabels();
        if (customLabelsJson == null || customLabelsJson.trim().isEmpty() || "{}".equals(customLabelsJson.trim())) {
            log.info("No custom labels to sync for template ID {}", templateId);
            return new SyncResult(templateId, 0, 0, "NO_CUSTOM_LABELS_FOUND");
        }

        // 3. Parse customLabels JSON payload
        Map<String, QuestionDefinition> questionDefs = parseCustomLabels(customLabelsJson);
        if (questionDefs.isEmpty()) {
            return new SyncResult(templateId, 0, 0, "EMPTY_QUESTION_DEFINITIONS");
        }

        // 4. Upsert into template_questions_dictionary
        int dictionaryUpsertCount = 0;
        for (Map.Entry<String, QuestionDefinition> entry : questionDefs.entrySet()) {
            String key = entry.getKey().toUpperCase().trim();
            QuestionDefinition def = entry.getValue();

            if (def.label != null && !def.label.trim().isEmpty()) {
                TemplateQuestion question = templateQuestionRepository.findById(key)
                        .orElse(new TemplateQuestion(key, def.label.trim()));

                question.setQuestionText(def.label.trim());
                templateQuestionRepository.save(question);
                dictionaryUpsertCount++;
            }
        }

        // 5. Update Template.fieldMapping JSON
        int fieldMappingUpdatedCount = updateTemplateFieldMapping(template, questionDefs);

        log.info("Template #{} synced: {} dictionary questions updated, {} field mappings refreshed by user #{}",
                templateId, dictionaryUpsertCount, fieldMappingUpdatedCount, updatedBy);

        return new SyncResult(templateId, dictionaryUpsertCount, fieldMappingUpdatedCount, "SUCCESS");
    }

    /**
     * Parses customLabels JSON which may contain structured objects or simple key-value string pairs.
     */
    private Map<String, QuestionDefinition> parseCustomLabels(String customLabelsJson) {
        Map<String, QuestionDefinition> result = new HashMap<>();
        try {
            JsonNode root = objectMapper.readTree(customLabelsJson);
            if (!root.isObject()) {
                return result;
            }

            Iterator<Map.Entry<String, JsonNode>> fields = root.fields();
            while (fields.hasNext()) {
                Map.Entry<String, JsonNode> field = fields.next();
                String key = field.getKey();
                JsonNode val = field.getValue();

                if (val.isObject()) {
                    String label = val.has("label") ? val.get("label").asText() : "";
                    String helpText = val.has("helpText") ? val.get("helpText").asText() : null;
                    String fieldType = val.has("fieldType") ? val.get("fieldType").asText() : "TEXT";
                    boolean isRequired = val.has("isRequired") && val.get("isRequired").asBoolean();
                    String sectionGroup = val.has("sectionGroup") ? val.get("sectionGroup").asText() : null;

                    result.put(key, new QuestionDefinition(label, helpText, fieldType, isRequired, sectionGroup));
                } else if (val.isTextual()) {
                    result.put(key, new QuestionDefinition(val.asText(), null, "TEXT", false, null));
                }
            }
        } catch (Exception e) {
            log.error("Failed to parse customLabels JSON: {}", e.getMessage(), e);
        }
        return result;
    }

    /**
     * Updates Template.fieldMapping JSON with customized labels, types, and groupings.
     */
    private int updateTemplateFieldMapping(Template template, Map<String, QuestionDefinition> questionDefs) {
        String existingMapping = template.getFieldMapping();
        if (existingMapping == null || existingMapping.trim().isEmpty()) {
            return 0;
        }

        try {
            JsonNode root = objectMapper.readTree(existingMapping);
            if (!root.isObject() || !root.has("fields") || !root.get("fields").isArray()) {
                return 0;
            }

            ArrayNode fieldsArray = (ArrayNode) root.get("fields");
            int updatedCount = 0;

            for (int i = 0; i < fieldsArray.size(); i++) {
                JsonNode fieldNode = fieldsArray.get(i);
                if (fieldNode.isObject() && fieldNode.has("key")) {
                    String key = fieldNode.get("key").asText().toUpperCase().trim();
                    QuestionDefinition def = questionDefs.get(key);

                    if (def != null && def.label != null && !def.label.trim().isEmpty()) {
                        ObjectNode objNode = (ObjectNode) fieldNode;
                        objNode.put("question", def.label.trim());

                        if (def.fieldType != null) {
                            objNode.put("type", def.fieldType.toUpperCase());
                        }
                        if (def.helpText != null && !def.helpText.trim().isEmpty()) {
                            objNode.put("helpText", def.helpText.trim());
                        }
                        if (def.sectionGroup != null && !def.sectionGroup.trim().isEmpty()) {
                            objNode.put("section", def.sectionGroup.trim());
                        }
                        objNode.put("required", def.isRequired);

                        updatedCount++;
                    }
                }
            }

            template.setFieldMapping(objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(root));
            templateRepository.save(template);
            return updatedCount;
        } catch (Exception e) {
            log.error("Failed to update template field mapping for template #{}: {}", template.getId(), e.getMessage(), e);
            return 0;
        }
    }

    /**
     * Helper holder for question configuration attributes.
     */
    private static class QuestionDefinition {
        final String label;
        final String helpText;
        final String fieldType;
        final boolean isRequired;
        final String sectionGroup;

        QuestionDefinition(String label, String helpText, String fieldType, boolean isRequired, String sectionGroup) {
            this.label = label;
            this.helpText = helpText;
            this.fieldType = fieldType;
            this.isRequired = isRequired;
            this.sectionGroup = sectionGroup;
        }
    }

    /**
     * Value object representing the outcome of a synchronization operation.
     */
    public static class SyncResult implements Serializable {
        private static final long serialVersionUID = 1L;

        private final Long templateId;
        private final int dictionaryUpdatedCount;
        private final int fieldMappingUpdatedCount;
        private final String status;

        public SyncResult(Long templateId, int dictionaryUpdatedCount, int fieldMappingUpdatedCount, String status) {
            this.templateId = templateId;
            this.dictionaryUpdatedCount = dictionaryUpdatedCount;
            this.fieldMappingUpdatedCount = fieldMappingUpdatedCount;
            this.status = status;
        }

        public Long getTemplateId() {
            return templateId;
        }

        public int getDictionaryUpdatedCount() {
            return dictionaryUpdatedCount;
        }

        public int getFieldMappingUpdatedCount() {
            return fieldMappingUpdatedCount;
        }

        public String getStatus() {
            return status;
        }
    }
}
