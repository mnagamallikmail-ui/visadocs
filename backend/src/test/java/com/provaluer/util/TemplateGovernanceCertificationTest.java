package com.provaluer.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.docx4j.XmlUtils;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.P;
import org.docx4j.wml.R;
import org.docx4j.wml.Text;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.nio.file.Files;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ARCHITECTURAL GOVERNANCE CERTIFICATION TEST
 *
 * Verifies that:
 * 1. The Template is the SINGLE SOURCE OF TRUTH for Valuation Methodology.
 * 2. Methodology is determined exclusively by physical placeholders present in the template.
 * 3. Runtime metadata, inputs, and category flags NEVER hijack or override template directives.
 * 4. Land Only, Land + Building, and Composite methodologies route strictly to their corresponding tables & summaries.
 */
@SpringBootTest
@ActiveProfiles("test")
public class TemplateGovernanceCertificationTest {

    @Autowired
    private DocxTemplateEngine templateEngine;

    private byte[] officialTemplateBytes;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() throws Exception {
        File officialFile = new File("official_production_valuation_report.docx");
        assertTrue(officialFile.exists(), "official_production_valuation_report.docx must exist");
        officialTemplateBytes = Files.readAllBytes(officialFile.toPath());
    }

    private byte[] createSyntheticTemplate(List<String> placeholders) throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        org.docx4j.wml.ObjectFactory f = new org.docx4j.wml.ObjectFactory();

        for (String ph : placeholders) {
            P p = f.createP();
            R r = f.createR();
            Text t = f.createText();
            t.setValue(ph);
            r.getContent().add(t);
            p.getContent().add(r);
            pkg.getMainDocumentPart().getContent().add(p);
        }

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        pkg.save(baos);
        return baos.toByteArray();
    }

    // ========================================================================
    // MANDATORY VALIDATION A: TEMPLATE GOVERNANCE & METHODOLOGY DETECTION
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-A] Template Governance: Methodology determined ONLY from physical template placeholders")
    void testValidationA_TemplateMethodologyDetection() throws Exception {
        System.out.println("=== MANDATORY VALIDATION A: TEMPLATE METHODOLOGY DETECTION ===");

        // 1. Official Canonical Template (Physical: <<LAND_TABLE>>, <<BUILDING_TABLE>>, <<VALUATION_SUMMARY_TABLE>>)
        Set<String> officialPlaceholders = templateEngine.scanTemplatePlaceholders(WordprocessingMLPackage.load(new ByteArrayInputStream(officialTemplateBytes)));
        assertTrue(officialPlaceholders.contains("LANDTABLE"), "Official template must contain LAND_TABLE");
        assertTrue(officialPlaceholders.contains("BUILDINGTABLE"), "Official template must contain BUILDING_TABLE");
        assertFalse(officialPlaceholders.contains("COMPOSITEPROPERTYTABLE"), "Official template must NOT contain COMPOSITE_PROPERTY_TABLE");

        DocxTemplateEngine.TemplateMethodology officialMethodology = templateEngine.detectTemplateMethodology(officialTemplateBytes);
        assertEquals(DocxTemplateEngine.TemplateMethodology.LAND_AND_BUILDING, officialMethodology,
                "Official production template must be detected as LAND_AND_BUILDING");

        // 2. Synthetic Land-Only Template
        byte[] landOnlyBytes = createSyntheticTemplate(List.of("<<LAND_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        DocxTemplateEngine.TemplateMethodology landOnlyMethodology = templateEngine.detectTemplateMethodology(landOnlyBytes);
        assertEquals(DocxTemplateEngine.TemplateMethodology.LAND_ONLY, landOnlyMethodology,
                "Template with LAND_TABLE and without BUILDING_TABLE must be detected as LAND_ONLY");

        // 3. Synthetic Composite Template
        byte[] compositeBytes = createSyntheticTemplate(List.of("<<COMPOSITE_PROPERTY_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        DocxTemplateEngine.TemplateMethodology compMethodology = templateEngine.detectTemplateMethodology(compositeBytes);
        assertEquals(DocxTemplateEngine.TemplateMethodology.COMPOSITE, compMethodology,
                "Template with COMPOSITE_PROPERTY_TABLE must be detected as COMPOSITE");

        System.out.println("-> Official Template Methodology: " + officialMethodology);
        System.out.println("-> Land Only Template Methodology: " + landOnlyMethodology);
        System.out.println("-> Composite Template Methodology: " + compMethodology);
        System.out.println("-> VALIDATION A PASSED: Methodology determined solely by physical placeholders.");
    }

    // ========================================================================
    // MANDATORY VALIDATION B: LAND ONLY TEMPLATE RENDERING
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-B] Land Only Template: Renders LAND_TABLE and Land Summary, never invokes Composite renderer")
    void testValidationB_LandOnlyTemplateRendering() throws Exception {
        System.out.println("=== MANDATORY VALIDATION B: LAND ONLY TEMPLATE RENDERING ===");

        byte[] landOnlyTemplate = createSyntheticTemplate(List.of("<<LAND_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));

        Map<String, String> inputs = new HashMap<>();
        // Inject confusing composite metadata into runtime inputs to test resilience
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE");
        inputs.put("PROPERTY_CATEGORY", "Flat");
        inputs.put("RAW_COMPOSITE_ITEMS_JSON", "[{\"description\":\"Unit\"}]");
        inputs.put("LAND_FAIR_VALUE", "5000000");
        inputs.put("SAY_LAND_VALUE", "5000000");
        inputs.put("LAND_REALIZABLE_VALUE", "4500000");
        inputs.put("LAND_DISTRESS_VALUE", "3750000");
        inputs.put("LAND_GOVERNMENT_VALUE", "2500000");

        byte[] docx = templateEngine.generateReport(landOnlyTemplate, inputs, Collections.emptyMap());
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docx));
        String xml = XmlUtils.marshaltoString(pkg.getMainDocumentPart().getJaxbElement());

        // Must render Land Table
        assertTrue(xml.contains("Value Of Land"), "Must render Value Of Land table");
        // Must render Land Valuation Summary
        assertTrue(xml.contains("Land Valuation Summary"), "Must render Land Valuation Summary");
        assertTrue(xml.contains("Land Fair Value"), "Must contain Land Fair Value in summary");
        assertTrue(xml.contains("50,00,000"), "Must contain Land Fair Value amount");
        assertTrue(xml.contains("Land Realizable Value"), "Must contain Land Realizable Value in summary");
        assertTrue(xml.contains("45,00,000"), "Must contain Land Realizable Value amount");

        // Must NEVER invoke Composite Table or Composite Summary
        assertFalse(xml.contains("Valuation of Property (Composite Rate Method)"),
                "Must NOT invoke Composite Property table in Land Only template");
        assertFalse(xml.contains("Valuation Parameters Summary"),
                "Must NOT invoke Composite Summary table in Land Only template");

        System.out.println("-> VALIDATION B PASSED: Land Only template renders LAND_TABLE and Land Summary.");
    }

    // ========================================================================
    // MANDATORY VALIDATION C: LAND + BUILDING TEMPLATE (NO HIJACKING)
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-C] Land + Building Template: Renders LAND_TABLE, BUILDING_TABLE, Land+Building Summary, NO hijacking")
    void testValidationC_LandBuildingTemplateRendering() throws Exception {
        System.out.println("=== MANDATORY VALIDATION C: LAND + BUILDING TEMPLATE RENDERING ===");

        Map<String, String> inputs = new HashMap<>();
        // Inject COMPOSITE metadata to verify that runtime metadata CANNOT hijack LAND_TABLE
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE_RATE");
        inputs.put("PROPERTY_CATEGORY", "Apartment");
        inputs.put("PROPERTY_TYPE", "Flat");
        inputs.put("RAW_COMPOSITE_ITEMS_JSON", "[{\"description\":\"Apartment 101\"}]");

        inputs.put("SAY_LAND_VALUE", "5000000");
        inputs.put("SAY_BUILDING_VALUE", "3000000");
        inputs.put("FAIR_VALUE", "8000000");
        inputs.put("SAY_VALUE", "8000000");
        inputs.put("LAND_REALIZABLE_VALUE", "4500000");
        inputs.put("BUILDING_REALIZABLE_VALUE", "2100000");
        inputs.put("REALIZABLE_VALUE", "6600000");
        inputs.put("LAND_DISTRESS_VALUE", "3750000");
        inputs.put("BUILDING_DISTRESS_VALUE", "1500000");
        inputs.put("DISTRESS_SALE_VALUE", "5250000");
        inputs.put("LAND_GOVERNMENT_VALUE", "2000000");
        inputs.put("BUILDING_GOVERNMENT_VALUE", "1000000");
        inputs.put("GOVERNMENT_VALUE", "3000000");

        byte[] docx = templateEngine.generateReport(officialTemplateBytes, inputs, Collections.emptyMap());
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docx));
        String xml = XmlUtils.marshaltoString(pkg.getMainDocumentPart().getJaxbElement());

        // Template Governance Verification:
        // 1. LAND_TABLE must NOT be replaced by Composite Table
        assertFalse(xml.contains("Valuation of Property (Composite Rate Method)"),
                "LAND_TABLE must NEVER be hijacked into Composite Property table");
        // 2. LAND_TABLE must be rendered
        assertTrue(xml.contains("Value Of Land"), "Must render Value Of Land");
        // 3. BUILDING_TABLE must NOT be suppressed
        assertTrue(xml.contains("Value Of Buildings"), "Must render Value Of Buildings (not suppressed)");
        // 4. Land + Building Valuation Summary Table must be rendered
        assertTrue(xml.contains("Valuation Parameter"), "Must render Valuation Summary headers");
        assertTrue(xml.contains("Land (₹)"), "Summary must contain Land column");
        assertTrue(xml.contains("Building (₹)"), "Summary must contain Building column");
        assertTrue(xml.contains("Total (₹)"), "Summary must contain Total column");

        System.out.println("-> VALIDATION C PASSED: Land + Building template honors template directives with zero hijacking.");
    }

    // ========================================================================
    // MANDATORY VALIDATION D: COMPOSITE TEMPLATE RENDERING
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-D] Composite Template: Renders COMPOSITE_PROPERTY_TABLE and COMPOSITE SUMMARY")
    void testValidationD_CompositeTemplateRendering() throws Exception {
        System.out.println("=== MANDATORY VALIDATION D: COMPOSITE TEMPLATE RENDERING ===");

        byte[] compositeTemplate = createSyntheticTemplate(List.of("<<COMPOSITE_PROPERTY_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));

        Map<String, String> inputs = new HashMap<>();
        inputs.put("COMPOSITE_RATE", "5500");
        inputs.put("FAIR_VALUE", "6600000");
        inputs.put("SAY_FAIR_VALUE", "6600000");
        inputs.put("REALIZABLE_VALUE", "5940000");
        inputs.put("DISTRESS_SALE_VALUE", "4950000");
        inputs.put("GOVERNMENT_VALUE", "3850000");

        List<Map<String, Object>> compItems = List.of(Map.of(
                "description", "Commercial Suite 501",
                "enteredUnit", "Sq.Ft",
                "quantity", "1200",
                "rate", "5500",
                "amount", "6600000",
                "depreciationAmount", "0",
                "fairValue", "6600000"
        ));
        inputs.put("RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(compItems));

        byte[] docx = templateEngine.generateReport(compositeTemplate, inputs, Collections.emptyMap());
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docx));
        String xml = XmlUtils.marshaltoString(pkg.getMainDocumentPart().getJaxbElement());

        // Must render Composite Table
        assertTrue(xml.contains("Valuation of Property (Composite Rate Method)"), "Must render Composite Table");
        assertTrue(xml.contains("Commercial Suite 501"), "Must render Composite Item");
        // Must render Composite Summary Table
        assertTrue(xml.contains("Valuation Parameters Summary"), "Must render Composite Parameters Summary");
        assertTrue(xml.contains("66,00,000"), "Must contain Fair Value");
        assertTrue(xml.contains("59,40,000"), "Must contain Realizable Value");
        assertTrue(xml.contains("49,50,000"), "Must contain Distress Sale Value");
        assertTrue(xml.contains("38,50,000"), "Must contain Government Value");

        // Must NOT render Land Table or Building Table
        assertFalse(xml.contains("Value Of Land"), "Must NOT render Value Of Land in Composite Template");
        assertFalse(xml.contains("Value Of Buildings"), "Must NOT render Value Of Buildings in Composite Template");

        System.out.println("-> VALIDATION D PASSED: Composite Template strictly renders Composite Table and Composite Summary.");
    }

    // ========================================================================
    // MANDATORY VALIDATION E: RUNTIME CODEBASE INSPECTION FOR METHODOLOGY HIJACKING
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-E] Runtime Inspection: Verify DocxTemplateEngine does not use isCompositeProperty for methodology selection")
    void testValidationE_RuntimeCodeInspection() throws Exception {
        System.out.println("=== MANDATORY VALIDATION E: RUNTIME INSPECTION ===");

        // Read DocxTemplateEngine source code
        File engineFile = new File("src/main/java/com/provaluer/util/DocxTemplateEngine.java");
        assertTrue(engineFile.exists(), "DocxTemplateEngine.java must exist");
        String source = Files.readString(engineFile.toPath());

        // 1. Verify "if (isComposite && isExplicitTableDirective)" is completely removed
        assertFalse(source.contains("if (isComposite && isExplicitTableDirective)"),
                "VIOLATION: 'if (isComposite && isExplicitTableDirective)' must be completely removed");

        // 2. Verify isCompositeProperty is not called in generateElements
        assertFalse(source.contains("boolean isComposite = isCompositeProperty(inputs);"),
                "VIOLATION: 'boolean isComposite = isCompositeProperty(inputs);' must not exist in generateElements");

        // 3. Verify summary routing uses templateMethodology
        assertTrue(source.contains("templateMethodology == TemplateMethodology.COMPOSITE"),
                "Summary routing must inspect templateMethodology == COMPOSITE");
        assertTrue(source.contains("templateMethodology == TemplateMethodology.LAND_ONLY"),
                "Summary routing must inspect templateMethodology == LAND_ONLY");
        assertTrue(source.contains("buildLandSummary(inputs)"),
                "Summary routing must call buildLandSummary(inputs) for LAND_ONLY");

        System.out.println("-> VALIDATION E PASSED: Zero runtime metadata used for methodology detection or renderer routing.");
    }
}
