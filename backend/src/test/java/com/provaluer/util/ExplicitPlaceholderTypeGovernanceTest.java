package com.provaluer.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * MANDATORY CERTIFICATION TEST SUITE
 * Explicit Placeholder Type Governance: Upload-Time Classification Verification
 * Priority 0 Rule: Original Placeholder Type strictly wins; NO inference allowed.
 */
public class ExplicitPlaceholderTypeGovernanceTest {

    private DocxTemplateEngine templateEngine;
    private DocxStructureParser parser;
    private ObjectFactory factory;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        templateEngine = new DocxTemplateEngine();
        parser = new DocxStructureParser();
        factory = new ObjectFactory();
        objectMapper = new ObjectMapper();
    }

    private byte[] packageToBytes(WordprocessingMLPackage pkg) throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        pkg.save(baos);
        return baos.toByteArray();
    }

    private Tc createCell(String text) {
        Tc cell = factory.createTc();
        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue(text);
        r.getContent().add(t);
        p.getContent().add(r);
        cell.getContent().add(p);
        return cell;
    }

    private String getSummaryFieldType(JsonNode dom, String key) {
        if (dom != null && dom.has("placeholdersSummary")) {
            for (JsonNode item : dom.get("placeholdersSummary")) {
                if (item.has("key") && item.get("key").asText().equalsIgnoreCase(key)) {
                    return item.get("fieldType").asText();
                }
            }
        }
        return null;
    }

    private String getRegistryFieldType(String registryJson, String key) throws Exception {
        JsonNode node = objectMapper.readTree(registryJson);
        for (java.util.Iterator<String> it = node.fieldNames(); it.hasNext(); ) {
            String fieldName = it.next();
            if (fieldName.equalsIgnoreCase(key)) {
                return node.get(fieldName).get("type").asText();
            }
        }
        return null;
    }

    private String getFieldMappingType(String fieldMappingJson, String key) throws Exception {
        JsonNode node = objectMapper.readTree(fieldMappingJson);
        if (node.has("fields")) {
            for (JsonNode field : node.get("fields")) {
                String k = field.has("key") ? field.get("key").asText() : (field.has("placeholder") ? field.get("placeholder").asText() : "");
                if (k.equalsIgnoreCase(key)) {
                    return field.has("fieldType") ? field.get("fieldType").asText() : (field.has("type") ? field.get("type").asText() : null);
                }
            }
        }
        return null;
    }

    @Test
    @DisplayName("Test 1: <<TEXT>> with label 'Photograph of property including geo stamping with date' -> TEXT (NOT DATE)")
    void test1_photographWithDate_explicitText() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        Tr row = factory.createTr();
        row.getContent().add(createCell("(d) Photograph of property including geo stamping with date"));
        row.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(row);
        pkg.getMainDocumentPart().getContent().add(tbl);

        byte[] rawBytes = packageToBytes(pkg);

        // Upload Pipeline Step 1: Normalize & Record
        GenericPlaceholderNormalizer.TemplateAnalysisReport analysisReport =
                new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, analysisReport);

        assertEquals(1, analysisReport.getTotalGeneratedFields());
        GenericPlaceholderNormalizer.NormalizedField normalizedField = analysisReport.getGeneratedFields().get(0);
        String generatedKey = normalizedField.getKey();
        assertEquals("TEXT", normalizedField.getGenericType());
        assertTrue(generatedKey.contains("DATE"), "Generated slug must contain DATE to verify guard");

        // Priority 0: Extract authoritative explicit type overrides
        Map<String, String> explicitOverrides = analysisReport.toExplicitTypeOverrides();
        assertEquals("TEXT", explicitOverrides.get(generatedKey));

        // Upload Pipeline Step 2: DOM & Registry
        JsonNode dom = parser.parseDocumentStructure(normalizedBytes, explicitOverrides);
        parser.applyTypeOverridesToDom(dom, explicitOverrides);
        String registry = parser.generatePlaceholderRegistry(dom, explicitOverrides);

        // Upload Pipeline Step 3: Field Mapping
        String fieldMapping = templateEngine.parseTemplate(normalizedBytes, explicitOverrides);

        // Assertions: Final type strictly remains TEXT everywhere
        assertEquals("TEXT", getSummaryFieldType(dom, generatedKey), "DOM placeholdersSummary must be TEXT");
        assertEquals("TEXT", getRegistryFieldType(registry, generatedKey), "Placeholder Registry must be TEXT");
        assertEquals("TEXT", getFieldMappingType(fieldMapping, generatedKey), "Field Mapping must be TEXT");
    }

    @Test
    @DisplayName("Test 2: <<TEXT>> with label 'Date of Inspection' -> TEXT (NOT DATE)")
    void test2_dateOfInspection_explicitText() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        Tr row = factory.createTr();
        row.getContent().add(createCell("Date of Inspection"));
        row.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(row);
        pkg.getMainDocumentPart().getContent().add(tbl);

        byte[] rawBytes = packageToBytes(pkg);

        GenericPlaceholderNormalizer.TemplateAnalysisReport analysisReport =
                new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, analysisReport);

        assertEquals(1, analysisReport.getTotalGeneratedFields());
        GenericPlaceholderNormalizer.NormalizedField normalizedField = analysisReport.getGeneratedFields().get(0);
        String generatedKey = normalizedField.getKey();
        assertEquals("TEXT", normalizedField.getGenericType());
        assertEquals("DATE_OF_INSPECTION_1", generatedKey);

        Map<String, String> explicitOverrides = analysisReport.toExplicitTypeOverrides();
        assertEquals("TEXT", explicitOverrides.get(generatedKey));

        JsonNode dom = parser.parseDocumentStructure(normalizedBytes, explicitOverrides);
        parser.applyTypeOverridesToDom(dom, explicitOverrides);
        String registry = parser.generatePlaceholderRegistry(dom, explicitOverrides);
        String fieldMapping = templateEngine.parseTemplate(normalizedBytes, explicitOverrides);

        assertEquals("TEXT", getSummaryFieldType(dom, generatedKey), "DOM must be TEXT");
        assertEquals("TEXT", getRegistryFieldType(registry, generatedKey), "Registry must be TEXT");
        assertEquals("TEXT", getFieldMappingType(fieldMapping, generatedKey), "Field mapping must be TEXT");
    }

    @Test
    @DisplayName("Test 3: <<IMAGE>> with label 'Photograph with date' -> IMAGE (NOT DATE)")
    void test3_photographWithDate_explicitImage() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        Tr row = factory.createTr();
        row.getContent().add(createCell("Photograph with date"));
        row.getContent().add(createCell("<<IMAGE>>"));
        tbl.getContent().add(row);
        pkg.getMainDocumentPart().getContent().add(tbl);

        byte[] rawBytes = packageToBytes(pkg);

        GenericPlaceholderNormalizer.TemplateAnalysisReport analysisReport =
                new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, analysisReport);

        assertEquals(1, analysisReport.getTotalGeneratedFields());
        GenericPlaceholderNormalizer.NormalizedField normalizedField = analysisReport.getGeneratedFields().get(0);
        String generatedKey = normalizedField.getKey();
        assertEquals("IMAGE", normalizedField.getGenericType());
        assertTrue(generatedKey.contains("DATE"), "Generated slug contains DATE");

        Map<String, String> explicitOverrides = analysisReport.toExplicitTypeOverrides();
        assertEquals("IMAGE", explicitOverrides.get(generatedKey));

        JsonNode dom = parser.parseDocumentStructure(normalizedBytes, explicitOverrides);
        parser.applyTypeOverridesToDom(dom, explicitOverrides);
        String registry = parser.generatePlaceholderRegistry(dom, explicitOverrides);
        String fieldMapping = templateEngine.parseTemplate(normalizedBytes, explicitOverrides);

        assertEquals("IMAGE", getSummaryFieldType(dom, generatedKey), "DOM must be IMAGE");
        assertEquals("IMAGE", getRegistryFieldType(registry, generatedKey), "Registry must be IMAGE");
        assertEquals("IMAGE", getFieldMappingType(fieldMapping, generatedKey), "Field mapping must be IMAGE");
    }

    @Test
    @DisplayName("Test 4: Standalone or table <<DATE>> -> DATE")
    void test4_explicitDate() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        Tr row = factory.createTr();
        row.getContent().add(createCell("Report Issuance"));
        row.getContent().add(createCell("<<DATE>>"));
        tbl.getContent().add(row);
        pkg.getMainDocumentPart().getContent().add(tbl);

        byte[] rawBytes = packageToBytes(pkg);

        GenericPlaceholderNormalizer.TemplateAnalysisReport analysisReport =
                new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, analysisReport);

        GenericPlaceholderNormalizer.NormalizedField normalizedField = analysisReport.getGeneratedFields().get(0);
        String generatedKey = normalizedField.getKey();
        assertEquals("DATE", normalizedField.getGenericType());

        Map<String, String> explicitOverrides = analysisReport.toExplicitTypeOverrides();
        JsonNode dom = parser.parseDocumentStructure(normalizedBytes, explicitOverrides);
        parser.applyTypeOverridesToDom(dom, explicitOverrides);
        String registry = parser.generatePlaceholderRegistry(dom, explicitOverrides);
        String fieldMapping = templateEngine.parseTemplate(normalizedBytes, explicitOverrides);

        assertEquals("DATE", getSummaryFieldType(dom, generatedKey), "DOM must be DATE");
        assertEquals("DATE", getRegistryFieldType(registry, generatedKey), "Registry must be DATE");
        assertEquals("DATE", getFieldMappingType(fieldMapping, generatedKey), "Field mapping must be DATE");
    }

    @Test
    @DisplayName("Test 5: <<MULTILINE>> -> MULTILINE")
    void test5_explicitMultiline() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        Tr row = factory.createTr();
        row.getContent().add(createCell("Property Boundaries Description"));
        row.getContent().add(createCell("<<MULTILINE>>"));
        tbl.getContent().add(row);
        pkg.getMainDocumentPart().getContent().add(tbl);

        byte[] rawBytes = packageToBytes(pkg);

        GenericPlaceholderNormalizer.TemplateAnalysisReport analysisReport =
                new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, analysisReport);

        assertEquals(1, analysisReport.getTotalGeneratedFields());
        GenericPlaceholderNormalizer.NormalizedField normalizedField = analysisReport.getGeneratedFields().get(0);
        String generatedKey = normalizedField.getKey();
        assertEquals("MULTILINE", normalizedField.getGenericType());

        Map<String, String> explicitOverrides = analysisReport.toExplicitTypeOverrides();
        assertEquals("MULTILINE", explicitOverrides.get(generatedKey));

        JsonNode dom = parser.parseDocumentStructure(normalizedBytes, explicitOverrides);
        parser.applyTypeOverridesToDom(dom, explicitOverrides);
        String registry = parser.generatePlaceholderRegistry(dom, explicitOverrides);
        String fieldMapping = templateEngine.parseTemplate(normalizedBytes, explicitOverrides);

        assertEquals("MULTILINE", getSummaryFieldType(dom, generatedKey), "DOM must be MULTILINE");
        assertEquals("MULTILINE", getRegistryFieldType(registry, generatedKey), "Registry must be MULTILINE");
        assertEquals("MULTILINE", getFieldMappingType(fieldMapping, generatedKey), "Field mapping must be MULTILINE");
    }

    @Test
    @DisplayName("Test 6: <<NUMBER>> -> NUMBER")
    void test6_explicitNumber() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        Tr row = factory.createTr();
        row.getContent().add(createCell("Sanctioned Floor Units"));
        row.getContent().add(createCell("<<NUMBER>>"));
        tbl.getContent().add(row);
        pkg.getMainDocumentPart().getContent().add(tbl);

        byte[] rawBytes = packageToBytes(pkg);

        GenericPlaceholderNormalizer.TemplateAnalysisReport analysisReport =
                new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, analysisReport);

        assertEquals(1, analysisReport.getTotalGeneratedFields());
        GenericPlaceholderNormalizer.NormalizedField normalizedField = analysisReport.getGeneratedFields().get(0);
        String generatedKey = normalizedField.getKey();
        assertEquals("NUMBER", normalizedField.getGenericType());

        Map<String, String> explicitOverrides = analysisReport.toExplicitTypeOverrides();
        assertEquals("NUMBER", explicitOverrides.get(generatedKey));

        JsonNode dom = parser.parseDocumentStructure(normalizedBytes, explicitOverrides);
        parser.applyTypeOverridesToDom(dom, explicitOverrides);
        String registry = parser.generatePlaceholderRegistry(dom, explicitOverrides);
        String fieldMapping = templateEngine.parseTemplate(normalizedBytes, explicitOverrides);

        assertEquals("NUMBER", getSummaryFieldType(dom, generatedKey), "DOM must be NUMBER");
        assertEquals("NUMBER", getRegistryFieldType(registry, generatedKey), "Registry must be NUMBER");
        assertEquals("NUMBER", getFieldMappingType(fieldMapping, generatedKey), "Field mapping must be NUMBER");
    }
}
