package com.provaluer.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.model.Order;
import com.provaluer.model.Template;
import com.provaluer.model.TemplateVersion;
import com.provaluer.service.TemplateProcessingService;
import org.docx4j.jaxb.Context;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.openpackaging.parts.WordprocessingML.MainDocumentPart;
import org.docx4j.wml.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

/**
 * MANDATORY MANUAL FIELD TYPE OVERRIDE GOVERNANCE TEST SUITE
 * 
 * Validates the 10 mandatory regression tests required by the governance authorization:
 * 1. Initial Upload: Parser infers DATE -> Administrator overrides to TEXT -> TEXT everywhere.
 * 2. Publish Metadata Version: Result strictly remains TEXT.
 * 3. Open Template Editor: Field mapping and registry strictly return TEXT.
 * 4. Open Document Studio: Template structure DOM strictly returns TEXT.
 * 5. Create New Order: Bound snapshot and workspace DOM strictly return TEXT.
 * 6. Rebuild Snapshots: Re-parse operations strictly preserve TEXT.
 * 7. Clone Template: Stateless deep-copy inheritance strictly preserves TEXT.
 * 8. IMAGE -> TEXT override survives all operations.
 * 9. TEXT -> DATE override survives all operations.
 * 10. DATE -> IMAGE override survives all operations.
 */
public class ManualOverrideGovernanceTest {

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final DocxStructureParser parser = new DocxStructureParser();
    private final DocxTemplateEngine templateEngine = new DocxTemplateEngine();

    private byte[] sampleDocxBytes;
    private static final String TARGET_KEY = "PHOTOGRAPH_OF_THE_PROPERTY_INCLUDING_GEO_STAMPING_WITH_DATE_F7B9_1";
    private static final String DATE_OF_INSPECTION_KEY = "DATE_OF_INSPECTION";
    private static final String VALUATION_DATE_KEY = "VALUATION_DATE";
    private static final String IMAGE_KEY = "IMG_PROPERTY_FRONT";
    private static final String PLAIN_TEXT_KEY = "INSPECTION_SLOT";

    @BeforeEach
    void setUp() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        MainDocumentPart mainPart = wordMLPackage.getMainDocumentPart();
        ObjectFactory factory = Context.getWmlObjectFactory();

        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue("Photo: <<" + TARGET_KEY + ">> Inspection: <<" + DATE_OF_INSPECTION_KEY + ">> Date: <<" + VALUATION_DATE_KEY + ">> Image: <<" + IMAGE_KEY + ">> Text: <<" + PLAIN_TEXT_KEY + ">>");
        r.getContent().add(t);
        p.getContent().add(r);
        mainPart.getContent().add(p);

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        wordMLPackage.save(baos);
        sampleDocxBytes = baos.toByteArray();
    }

    private String getSummaryFieldType(JsonNode dom, String key) {
        if (dom != null && dom.has("placeholdersSummary")) {
            for (JsonNode ph : dom.get("placeholdersSummary")) {
                if (key.equalsIgnoreCase(ph.path("key").asText())) {
                    if (ph.has("type") && !ph.path("type").asText().isEmpty()) {
                        return ph.path("type").asText();
                    }
                    if (ph.has("fieldType") && !ph.path("fieldType").asText().isEmpty()) {
                        return ph.path("fieldType").asText();
                    }
                }
            }
        }
        return null;
    }

    private String getRegistryFieldType(String registryJson, String key) throws Exception {
        JsonNode reg = objectMapper.readTree(registryJson);
        if (reg.has(key)) {
            return reg.get(key).path("type").asText();
        }
        return null;
    }

    private String getFieldMappingType(String fieldMappingJson, String key) throws Exception {
        JsonNode fm = objectMapper.readTree(fieldMappingJson);
        if (fm.has("fields")) {
            for (JsonNode f : fm.get("fields")) {
                if (key.equalsIgnoreCase(f.path("key").asText())) {
                    return f.path("type").asText();
                }
            }
        }
        return null;
    }

    @Test
    @DisplayName("Test 1: Initial Upload: Parser infers DATE, Admin overrides to TEXT -> TEXT everywhere")
    void test1_initialUploadAndOverrideToText() throws Exception {
        // Step 1: Initial upload without overrides -> infers DATE due to _DATE_ in key
        JsonNode initialDom = parser.parseDocumentStructure(sampleDocxBytes);
        String initialType = getSummaryFieldType(initialDom, TARGET_KEY);
        assertEquals("DATE", initialType, "Initial parse should infer DATE from key containing _DATE_");

        String initialFieldMapping = templateEngine.parseTemplate(sampleDocxBytes);
        assertEquals("DATE", getFieldMappingType(initialFieldMapping, TARGET_KEY));

        // Step 2: Administrator overrides DATE -> TEXT
        Map<String, String> adminOverrides = Map.of(TARGET_KEY, "TEXT");

        // Parse with override
        JsonNode overriddenDom = parser.parseDocumentStructure(sampleDocxBytes, adminOverrides);
        parser.applyTypeOverridesToDom(overriddenDom, adminOverrides);
        String overriddenRegistry = parser.generatePlaceholderRegistry(overriddenDom, adminOverrides);
        String overriddenFieldMapping = templateEngine.parseTemplate(sampleDocxBytes, adminOverrides);

        // Verification: TEXT in all layers
        assertEquals("TEXT", getSummaryFieldType(overriddenDom, TARGET_KEY), "DOM placeholdersSummary must be TEXT");
        assertEquals("TEXT", getRegistryFieldType(overriddenRegistry, TARGET_KEY), "Placeholder registry must be TEXT");
        assertEquals("TEXT", getFieldMappingType(overriddenFieldMapping, TARGET_KEY), "Field mapping must be TEXT");
    }

    @Test
    @DisplayName("Test 2: Publish Metadata Version: Result strictly remains TEXT")
    void test2_publishMetadataVersionPreservesText() throws Exception {
        // Initialize template with TEXT override
        Map<String, String> adminOverrides = Map.of(TARGET_KEY, "TEXT");
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, adminOverrides);
        parser.applyTypeOverridesToDom(dom, adminOverrides);
        String registryJson = parser.generatePlaceholderRegistry(dom, adminOverrides);
        String fieldMappingJson = templateEngine.parseTemplate(sampleDocxBytes, adminOverrides);

        Template template = new Template();
        template.setId(101L);
        template.setName("Test Commercial Report");
        template.setVersion(1);
        template.setTemplateContent(sampleDocxBytes);
        template.setDocumentDom(dom.toString());
        template.setPlaceholderRegistry(registryJson);
        template.setFieldMapping(fieldMappingJson);

        // Extract authoritative overrides from template
        Map<String, String> extractedOverrides = TemplateProcessingService.extractTypeOverrides(template);
        assertEquals("TEXT", extractedOverrides.get(TARGET_KEY));

        // Simulate publishMetadataVersion re-parsing DOCX
        String updatedFieldMapping = templateEngine.parseTemplate(sampleDocxBytes, extractedOverrides);
        JsonNode updatedDom = objectMapper.readTree(template.getDocumentDom());
        parser.applyTypeOverridesToDom(updatedDom, extractedOverrides);

        assertEquals("TEXT", getFieldMappingType(updatedFieldMapping, TARGET_KEY), "Field mapping must remain TEXT");
        assertEquals("TEXT", getSummaryFieldType(updatedDom, TARGET_KEY), "Document DOM must remain TEXT");
    }

    @Test
    @DisplayName("Test 3: Open Template Editor: Result strictly remains TEXT")
    void test3_openTemplateEditorRemainsText() throws Exception {
        Map<String, String> adminOverrides = Map.of(TARGET_KEY, "TEXT");
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, adminOverrides);
        parser.applyTypeOverridesToDom(dom, adminOverrides);
        String registryJson = parser.generatePlaceholderRegistry(dom, adminOverrides);
        String fieldMappingJson = templateEngine.parseTemplate(sampleDocxBytes, adminOverrides);

        Template template = new Template();
        template.setFieldMapping(fieldMappingJson);
        template.setPlaceholderRegistry(registryJson);
        template.setDocumentDom(dom.toString());

        // Template editor reads fieldMapping and placeholderRegistry
        Map<String, String> effective = TemplateProcessingService.extractTypeOverrides(template);
        assertEquals("TEXT", effective.get(TARGET_KEY), "Template editor must see authoritative TEXT");
        assertEquals("TEXT", getFieldMappingType(template.getFieldMapping(), TARGET_KEY));
        assertEquals("TEXT", getRegistryFieldType(template.getPlaceholderRegistry(), TARGET_KEY));
    }

    @Test
    @DisplayName("Test 4: Open Document Studio: Result strictly remains TEXT")
    void test4_openDocumentStudioRemainsText() throws Exception {
        Map<String, String> adminOverrides = Map.of(TARGET_KEY, "TEXT");
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, adminOverrides);
        parser.applyTypeOverridesToDom(dom, adminOverrides);
        String registryJson = parser.generatePlaceholderRegistry(dom, adminOverrides);

        Template template = new Template();
        template.setTemplateContent(sampleDocxBytes);
        template.setDocumentDom(dom.toString());
        template.setPlaceholderRegistry(registryJson);

        // DocumentStudioService.getTemplateStructure extracts type overrides and applies to DOM
        Map<String, String> overrides = TemplateProcessingService.extractTypeOverrides(template);
        JsonNode studioDom = objectMapper.readTree(template.getDocumentDom());
        parser.applyTypeOverridesToDom(studioDom, overrides);

        assertEquals("TEXT", getSummaryFieldType(studioDom, TARGET_KEY), "Document Studio DOM must be TEXT");
    }

    @Test
    @DisplayName("Test 5: Create New Order: Result strictly remains TEXT")
    void test5_createNewOrderRemainsText() throws Exception {
        Map<String, String> adminOverrides = Map.of(TARGET_KEY, "TEXT");
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, adminOverrides);
        parser.applyTypeOverridesToDom(dom, adminOverrides);
        String registryJson = parser.generatePlaceholderRegistry(dom, adminOverrides);
        String fieldMappingJson = templateEngine.parseTemplate(sampleDocxBytes, adminOverrides);

        Template template = new Template();
        template.setId(105L);
        template.setVersion(1);
        template.setDocumentDom(dom.toString());
        template.setFieldMapping(fieldMappingJson);
        template.setPlaceholderRegistry(registryJson);

        // Create new order associated with template
        Order order = new Order();
        order.setTemplateId(template.getId());
        order.setFieldMappingSnapshot(template.getFieldMapping());
        order.setDocumentDomSnapshot(template.getDocumentDom());
        order.setTemplateVersion(template.getVersion());

        // Verify order snapshot
        assertEquals("TEXT", getFieldMappingType(order.getFieldMappingSnapshot(), TARGET_KEY));
        JsonNode orderDom = objectMapper.readTree(order.getDocumentDomSnapshot());
        assertEquals("TEXT", getSummaryFieldType(orderDom, TARGET_KEY));
    }

    @Test
    @DisplayName("Test 6: Rebuild Snapshots: Result strictly remains TEXT")
    void test6_rebuildSnapshotsRemainsText() throws Exception {
        Map<String, String> adminOverrides = Map.of(TARGET_KEY, "TEXT");
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, adminOverrides);
        parser.applyTypeOverridesToDom(dom, adminOverrides);
        String registryJson = parser.generatePlaceholderRegistry(dom, adminOverrides);

        Template template = new Template();
        template.setTemplateContent(sampleDocxBytes);
        template.setDocumentDom(dom.toString());
        template.setPlaceholderRegistry(registryJson);

        // Rebuild execution logic:
        Map<String, String> typeOverrides = TemplateProcessingService.extractTypeOverrides(template);
        JsonNode rebuiltDom = parser.parseDocumentStructure(template.getTemplateContent(), typeOverrides);
        parser.applyTypeOverridesToDom(rebuiltDom, typeOverrides);
        String rebuiltRegistry = parser.generatePlaceholderRegistry(rebuiltDom, typeOverrides);

        assertEquals("TEXT", getSummaryFieldType(rebuiltDom, TARGET_KEY), "Rebuilt DOM must remain TEXT");
        assertEquals("TEXT", getRegistryFieldType(rebuiltRegistry, TARGET_KEY), "Rebuilt registry must remain TEXT");
    }

    @Test
    @DisplayName("Test 7: Clone Template: Result strictly remains TEXT")
    void test7_cloneTemplateRemainsText() throws Exception {
        Map<String, String> adminOverrides = Map.of(TARGET_KEY, "TEXT");
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, adminOverrides);
        parser.applyTypeOverridesToDom(dom, adminOverrides);
        String registryJson = parser.generatePlaceholderRegistry(dom, adminOverrides);
        String fieldMappingJson = templateEngine.parseTemplate(sampleDocxBytes, adminOverrides);

        Template oldTemplate = new Template();
        oldTemplate.setId(201L);
        oldTemplate.setVersion(1);
        oldTemplate.setTemplateContent(sampleDocxBytes);
        oldTemplate.setDocumentDom(dom.toString());
        oldTemplate.setPlaceholderRegistry(registryJson);
        oldTemplate.setFieldMapping(fieldMappingJson);

        // Clone / archiveAndInherit logic:
        Map<String, String> typeOverrides = TemplateProcessingService.extractTypeOverrides(oldTemplate);
        String newFieldMapping = templateEngine.parseTemplate(sampleDocxBytes, typeOverrides);
        JsonNode newDom = parser.parseDocumentStructure(sampleDocxBytes, typeOverrides);
        parser.applyTypeOverridesToDom(newDom, typeOverrides);
        String newRegistry = parser.generatePlaceholderRegistry(newDom, typeOverrides);

        assertEquals("TEXT", getFieldMappingType(newFieldMapping, TARGET_KEY), "Cloned field mapping must remain TEXT");
        assertEquals("TEXT", getSummaryFieldType(newDom, TARGET_KEY), "Cloned DOM must remain TEXT");
        assertEquals("TEXT", getRegistryFieldType(newRegistry, TARGET_KEY), "Cloned registry must remain TEXT");
    }

    @Test
    @DisplayName("Test 8: IMAGE -> TEXT override survives all operations")
    void test8_imageToTextOverrideSurvives() throws Exception {
        // IMAGE_KEY initially infers IMAGE
        String initialType = parser.inferFieldType(IMAGE_KEY);
        assertEquals("IMAGE", initialType);

        // Administrator overrides IMAGE -> TEXT
        Map<String, String> overrides = Map.of(IMAGE_KEY, "TEXT");
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, overrides);
        parser.applyTypeOverridesToDom(dom, overrides);
        String registry = parser.generatePlaceholderRegistry(dom, overrides);
        String fieldMapping = templateEngine.parseTemplate(sampleDocxBytes, overrides);

        assertEquals("TEXT", getSummaryFieldType(dom, IMAGE_KEY));
        assertEquals("TEXT", getRegistryFieldType(registry, IMAGE_KEY));
        assertEquals("TEXT", getFieldMappingType(fieldMapping, IMAGE_KEY));

        // Re-parse with extracted overrides (simulating publish / rebuild)
        Map<String, String> extracted = TemplateProcessingService.extractTypeOverrides(registry, dom.toString(), fieldMapping);
        assertEquals("TEXT", extracted.get(IMAGE_KEY));

        JsonNode reparsedDom = parser.parseDocumentStructure(sampleDocxBytes, extracted);
        assertEquals("TEXT", getSummaryFieldType(reparsedDom, IMAGE_KEY));
    }

    @Test
    @DisplayName("Test 9: TEXT -> DATE override survives all operations")
    void test9_textToDateOverrideSurvives() throws Exception {
        // PLAIN_TEXT_KEY initially infers TEXT
        String initialType = parser.inferFieldType(PLAIN_TEXT_KEY);
        assertEquals("TEXT", initialType);

        // Administrator overrides TEXT -> DATE
        Map<String, String> overrides = Map.of(PLAIN_TEXT_KEY, "DATE");
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, overrides);
        parser.applyTypeOverridesToDom(dom, overrides);
        String registry = parser.generatePlaceholderRegistry(dom, overrides);
        String fieldMapping = templateEngine.parseTemplate(sampleDocxBytes, overrides);

        assertEquals("DATE", getSummaryFieldType(dom, PLAIN_TEXT_KEY));
        assertEquals("DATE", getRegistryFieldType(registry, PLAIN_TEXT_KEY));
        assertEquals("DATE", getFieldMappingType(fieldMapping, PLAIN_TEXT_KEY));

        // Re-parse with extracted overrides
        Map<String, String> extracted = TemplateProcessingService.extractTypeOverrides(registry, dom.toString(), fieldMapping);
        assertEquals("DATE", extracted.get(PLAIN_TEXT_KEY));

        JsonNode reparsedDom = parser.parseDocumentStructure(sampleDocxBytes, extracted);
        assertEquals("DATE", getSummaryFieldType(reparsedDom, PLAIN_TEXT_KEY));
    }

    @Test
    @DisplayName("Test 10: DATE -> IMAGE override survives all operations")
    void test10_dateToImageOverrideSurvives() throws Exception {
        // VALUATION_DATE_KEY initially infers DATE
        String initialType = parser.inferFieldType(VALUATION_DATE_KEY);
        assertEquals("DATE", initialType);

        // Administrator overrides DATE -> IMAGE
        Map<String, String> overrides = Map.of(VALUATION_DATE_KEY, "IMAGE");
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, overrides);
        parser.applyTypeOverridesToDom(dom, overrides);
        String registry = parser.generatePlaceholderRegistry(dom, overrides);
        String fieldMapping = templateEngine.parseTemplate(sampleDocxBytes, overrides);

        assertEquals("IMAGE", getSummaryFieldType(dom, VALUATION_DATE_KEY));
        assertEquals("IMAGE", getRegistryFieldType(registry, VALUATION_DATE_KEY));
        assertEquals("IMAGE", getFieldMappingType(fieldMapping, VALUATION_DATE_KEY));

        // Re-parse with extracted overrides
        Map<String, String> extracted = TemplateProcessingService.extractTypeOverrides(registry, dom.toString(), fieldMapping);
        assertEquals("IMAGE", extracted.get(VALUATION_DATE_KEY));

        JsonNode reparsedDom = parser.parseDocumentStructure(sampleDocxBytes, extracted);
        assertEquals("IMAGE", getSummaryFieldType(reparsedDom, VALUATION_DATE_KEY));
    }

    @Test
    @DisplayName("Test Multi-Layer Synchronization: All 5 layers contain exactly identical type")
    void testMultiLayerSynchronization() throws Exception {
        Map<String, String> adminOverrides = Map.of(
                TARGET_KEY, "TEXT",
                DATE_OF_INSPECTION_KEY, "TEXT",
                VALUATION_DATE_KEY, "TEXT"
        );

        // 1. templates.document_dom
        JsonNode dom = parser.parseDocumentStructure(sampleDocxBytes, adminOverrides);
        parser.applyTypeOverridesToDom(dom, adminOverrides);

        // 2. templates.placeholder_registry
        String registryJson = parser.generatePlaceholderRegistry(dom, adminOverrides);

        // 3. templates.field_mapping
        String fieldMappingJson = templateEngine.parseTemplate(sampleDocxBytes, adminOverrides);

        // 4. template_versions copy
        Template template = new Template();
        template.setId(501L);
        template.setVersion(1);
        template.setDocumentDom(dom.toString());
        template.setPlaceholderRegistry(registryJson);
        template.setFieldMapping(fieldMappingJson);

        TemplateVersion version = new TemplateVersion(template, "Confirmed", 1L);

        // 5. orders snapshots
        Order order = new Order();
        order.setTemplateId(template.getId());
        order.setDocumentDomSnapshot(template.getDocumentDom());
        order.setFieldMappingSnapshot(template.getFieldMapping());

        // Verify across all layers
        assertEquals("TEXT", getSummaryFieldType(dom, TARGET_KEY));
        assertEquals("TEXT", getRegistryFieldType(registryJson, TARGET_KEY));
        assertEquals("TEXT", getFieldMappingType(fieldMappingJson, TARGET_KEY));

        assertEquals("TEXT", getSummaryFieldType(objectMapper.readTree(version.getDocumentDom()), TARGET_KEY));
        assertEquals("TEXT", getRegistryFieldType(version.getPlaceholderRegistry(), TARGET_KEY));
        assertEquals("TEXT", getFieldMappingType(version.getFieldMapping(), TARGET_KEY));

        assertEquals("TEXT", getSummaryFieldType(objectMapper.readTree(order.getDocumentDomSnapshot()), TARGET_KEY));
        assertEquals("TEXT", getFieldMappingType(order.getFieldMappingSnapshot(), TARGET_KEY));
    }
}
