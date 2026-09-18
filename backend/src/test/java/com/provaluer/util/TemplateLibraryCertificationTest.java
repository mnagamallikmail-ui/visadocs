package com.provaluer.util;

import com.provaluer.service.TemplateProcessingService;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.P;
import org.docx4j.wml.R;
import org.docx4j.wml.Text;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.nio.file.Files;
import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

/**
 * TEMPLATE LIBRARY REMEDIATION PROGRAM
 * FINAL PRODUCTION TEMPLATE COVERAGE REMEDIATION
 * BUSINESS GOVERNANCE CERTIFICATION TEST
 *
 * Verifies all 6 Authoritative Mandatory Validations (A through F).
 */
@SpringBootTest
@ActiveProfiles("test")
public class TemplateLibraryCertificationTest {

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Autowired
    private TemplateProcessingService templateProcessingService;

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
    // MANDATORY VALIDATION A: FLAT / APARTMENT TEMPLATE CERTIFICATION
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-A] Flat / Apartment Template Certification")
    void testMandatoryValidationA_FlatApartmentTemplateCertification() throws Exception {
        File flatFile = new File("official_flat_apartment_valuation_report.docx");
        assertTrue(flatFile.exists(), "official_flat_apartment_valuation_report.docx must physically exist in production");

        byte[] flatBytes = Files.readAllBytes(flatFile.toPath());
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(flatBytes));
        Set<String> placeholders = templateEngine.scanTemplatePlaceholders(pkg);

        // Required placeholders
        assertTrue(placeholders.contains("COMPOSITEPROPERTYTABLE"), "COMPOSITE_PROPERTY_TABLE must be present");
        assertTrue(placeholders.contains("VALUATIONSUMMARYTABLE"), "VALUATION_SUMMARY_TABLE must be present");

        // Prohibited placeholders
        assertFalse(placeholders.contains("LANDTABLE"), "LAND_TABLE must be ABSENT");
        assertFalse(placeholders.contains("BUILDINGTABLE"), "BUILDING_TABLE must be ABSENT");
        assertFalse(placeholders.contains("VALUEOFPROPERTYTABLE")
                || placeholders.contains("PROPERTYVALUETABLE")
                || placeholders.contains("VALUEOFTHEPROPERTYTABLE"), "VALUE_OF_PROPERTY_TABLE must be ABSENT");

        // Engine methodology detection
        DocxTemplateEngine.TemplateMethodology methodology = templateEngine.detectTemplateMethodology(flatBytes);
        assertEquals(DocxTemplateEngine.TemplateMethodology.COMPOSITE, methodology,
                "Template methodology must detect as COMPOSITE (FLAT_APARTMENT)");
    }

    // ========================================================================
    // MANDATORY VALIDATION B: LAND + BUILDING TEMPLATE CERTIFICATION
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-B] Land + Building Template Certification")
    void testMandatoryValidationB_LandAndBuildingTemplateCertification() throws Exception {
        File lbFile = new File("official_production_valuation_report.docx");
        assertTrue(lbFile.exists(), "official_production_valuation_report.docx must physically exist");

        byte[] lbBytes = Files.readAllBytes(lbFile.toPath());
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(lbBytes));
        Set<String> placeholders = templateEngine.scanTemplatePlaceholders(pkg);

        // Required placeholders
        assertTrue(placeholders.contains("LANDTABLE"), "LAND_TABLE must be present");
        assertTrue(placeholders.contains("BUILDINGTABLE"), "BUILDING_TABLE must be present");
        assertTrue(placeholders.contains("VALUEOFPROPERTYTABLE")
                || placeholders.contains("PROPERTYVALUETABLE")
                || placeholders.contains("VALUEOFTHEPROPERTYTABLE"), "VALUE_OF_PROPERTY_TABLE must be present");
        assertTrue(placeholders.contains("VALUATIONSUMMARYTABLE"), "VALUATION_SUMMARY_TABLE must be present");

        // Prohibited placeholders
        assertFalse(placeholders.contains("COMPOSITEPROPERTYTABLE"), "COMPOSITE_PROPERTY_TABLE must be ABSENT");

        // Engine methodology detection
        DocxTemplateEngine.TemplateMethodology methodology = templateEngine.detectTemplateMethodology(lbBytes);
        assertEquals(DocxTemplateEngine.TemplateMethodology.LAND_AND_BUILDING, methodology,
                "Template methodology must detect as LAND_AND_BUILDING");
    }

    // ========================================================================
    // MANDATORY VALIDATION C: LAND ONLY TEMPLATE CERTIFICATION
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-C] Land Only Template Certification")
    void testMandatoryValidationC_LandOnlyTemplateCertification() throws Exception {
        File landFile = new File("official_land_valuation_report.docx");
        assertTrue(landFile.exists(), "official_land_valuation_report.docx must physically exist in production");

        byte[] landBytes = Files.readAllBytes(landFile.toPath());
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(landBytes));
        Set<String> placeholders = templateEngine.scanTemplatePlaceholders(pkg);

        // Required placeholders
        assertTrue(placeholders.contains("LANDTABLE"), "LAND_TABLE must be present");
        assertTrue(placeholders.contains("VALUATIONSUMMARYTABLE"), "VALUATION_SUMMARY_TABLE must be present");

        // Prohibited placeholders
        assertFalse(placeholders.contains("BUILDINGTABLE"), "BUILDING_TABLE must be ABSENT");
        assertFalse(placeholders.contains("VALUEOFPROPERTYTABLE")
                || placeholders.contains("PROPERTYVALUETABLE")
                || placeholders.contains("VALUEOFTHEPROPERTYTABLE"), "VALUE_OF_PROPERTY_TABLE must be ABSENT");
        assertFalse(placeholders.contains("COMPOSITEPROPERTYTABLE"), "COMPOSITE_PROPERTY_TABLE must be ABSENT");

        // Engine methodology detection
        DocxTemplateEngine.TemplateMethodology methodology = templateEngine.detectTemplateMethodology(landBytes);
        assertEquals(DocxTemplateEngine.TemplateMethodology.LAND_ONLY, methodology,
                "Template methodology must detect as LAND_ONLY");
    }

    // ========================================================================
    // MANDATORY VALIDATION D: TEMPLATE EXCLUSIVITY CERTIFICATION
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-D] Template Exclusivity Certification across All Templates")
    void testMandatoryValidationD_TemplateExclusivityCertification() throws Exception {
        List<String> productionTemplates = List.of(
                "official_production_valuation_report.docx",
                "official_flat_apartment_valuation_report.docx",
                "official_land_valuation_report.docx"
        );

        for (String templateName : productionTemplates) {
            File f = new File(templateName);
            assertTrue(f.exists(), templateName + " must exist");
            byte[] bytes = Files.readAllBytes(f.toPath());
            WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(bytes));
            Set<String> placeholders = templateEngine.scanTemplatePlaceholders(pkg);

            boolean hasComposite = placeholders.contains("COMPOSITEPROPERTYTABLE");
            boolean hasLand = placeholders.contains("LANDTABLE");
            boolean hasBuilding = placeholders.contains("BUILDINGTABLE");
            boolean hasPropertyValue = placeholders.contains("VALUEOFPROPERTYTABLE")
                    || placeholders.contains("PROPERTYVALUETABLE")
                    || placeholders.contains("VALUEOFTHEPROPERTYTABLE");

            if (hasComposite) {
                assertFalse(hasLand, "[" + templateName + "] COMPOSITE_PROPERTY_TABLE cannot coexist with LAND_TABLE");
                assertFalse(hasBuilding, "[" + templateName + "] COMPOSITE_PROPERTY_TABLE cannot coexist with BUILDING_TABLE");
                assertFalse(hasPropertyValue, "[" + templateName + "] COMPOSITE_PROPERTY_TABLE cannot coexist with VALUE_OF_PROPERTY_TABLE");
            }

            if (hasLand || hasBuilding || hasPropertyValue) {
                assertFalse(hasComposite, "[" + templateName + "] Land/Building tables cannot coexist with COMPOSITE_PROPERTY_TABLE");
            }
        }
    }

    // ========================================================================
    // MANDATORY VALIDATION E: BUSINESS SECTION ORDER VERIFICATION
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-E] Business Section Order: LAND -> BUILDING -> VALUE OF PROPERTY -> VALUATION SUMMARY")
    void testMandatoryValidationE_BusinessSectionOrderVerification() throws Exception {
        File lbFile = new File("official_production_valuation_report.docx");
        byte[] lbBytes = Files.readAllBytes(lbFile.toPath());

        // Extract raw XML from docx package
        String docXml;
        try (java.util.zip.ZipInputStream zis = new java.util.zip.ZipInputStream(new ByteArrayInputStream(lbBytes))) {
            java.util.zip.ZipEntry entry;
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            while ((entry = zis.getNextEntry()) != null) {
                if ("word/document.xml".equals(entry.getName())) {
                    byte[] buf = new byte[8192];
                    int len;
                    while ((len = zis.read(buf)) != -1) {
                        baos.write(buf, 0, len);
                    }
                    break;
                }
            }
            docXml = baos.toString(java.nio.charset.StandardCharsets.UTF_8);
        }

        int landPos = docXml.indexOf("LAND_TABLE");
        int bldgPos = docXml.indexOf("BUILDING_TABLE");
        int propValPos = docXml.indexOf("VALUE_OF_PROPERTY_TABLE");
        int summaryPos = docXml.indexOf("VALUATION_SUMMARY_TABLE");

        assertTrue(landPos > 0, "LAND_TABLE must appear in document.xml");
        assertTrue(bldgPos > 0, "BUILDING_TABLE must appear in document.xml");
        assertTrue(propValPos > 0, "VALUE_OF_PROPERTY_TABLE must appear in document.xml");
        assertTrue(summaryPos > 0, "VALUATION_SUMMARY_TABLE must appear in document.xml");

        // Order Verification: LAND TABLE -> BUILDING TABLE -> VALUE OF PROPERTY TABLE -> VALUATION SUMMARY TABLE
        assertTrue(landPos < bldgPos, "LAND_TABLE must appear BEFORE BUILDING_TABLE");
        assertTrue(bldgPos < propValPos, "BUILDING_TABLE must appear BEFORE VALUE_OF_PROPERTY_TABLE");
        assertTrue(propValPos < summaryPos, "VALUE_OF_PROPERTY_TABLE must appear BEFORE VALUATION_SUMMARY_TABLE");
    }

    // ========================================================================
    // MANDATORY VALIDATION F: TEMPLATE UPLOAD GOVERNANCE RULES 1-5
    // ========================================================================
    @Test
    @DisplayName("[VALIDATION-F] Template Upload Governance Certification (Rules 1 - 5)")
    void testMandatoryValidationF_TemplateUploadGovernance() throws Exception {
        // Valid templates must pass upload validation
        templateProcessingService.validateDocxPackage(Files.readAllBytes(new File("official_production_valuation_report.docx").toPath()), "official_production_valuation_report.docx");
        templateProcessingService.validateDocxPackage(Files.readAllBytes(new File("official_flat_apartment_valuation_report.docx").toPath()), "official_flat_apartment_valuation_report.docx");
        templateProcessingService.validateDocxPackage(Files.readAllBytes(new File("official_land_valuation_report.docx").toPath()), "official_land_valuation_report.docx");

        // RULE 1: COMPOSITE_PROPERTY_TABLE cannot coexist with LAND_TABLE, BUILDING_TABLE, VALUE_OF_PROPERTY_TABLE
        byte[] invalidRule1_A = createSyntheticTemplate(List.of("<<COMPOSITE_PROPERTY_TABLE>>", "<<LAND_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        IllegalArgumentException ex1A = assertThrows(IllegalArgumentException.class, () ->
                templateProcessingService.validateDocxPackage(invalidRule1_A, "invalid_comp_land.docx"));
        assertTrue(ex1A.getMessage().contains("Rule 1"), "Must fail on Rule 1 violation: " + ex1A.getMessage());

        byte[] invalidRule1_B = createSyntheticTemplate(List.of("<<COMPOSITE_PROPERTY_TABLE>>", "<<BUILDING_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        IllegalArgumentException ex1B = assertThrows(IllegalArgumentException.class, () ->
                templateProcessingService.validateDocxPackage(invalidRule1_B, "invalid_comp_bldg.docx"));
        assertTrue(ex1B.getMessage().contains("Rule 1"), "Must fail on Rule 1 violation: " + ex1B.getMessage());

        byte[] invalidRule1_C = createSyntheticTemplate(List.of("<<COMPOSITE_PROPERTY_TABLE>>", "<<VALUE_OF_PROPERTY_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        IllegalArgumentException ex1C = assertThrows(IllegalArgumentException.class, () ->
                templateProcessingService.validateDocxPackage(invalidRule1_C, "invalid_comp_val.docx"));
        assertTrue(ex1C.getMessage().contains("Rule 1"), "Must fail on Rule 1 violation: " + ex1C.getMessage());

        // RULE 2: VALUE_OF_PROPERTY_TABLE requires LAND_TABLE and BUILDING_TABLE
        byte[] invalidRule2 = createSyntheticTemplate(List.of("<<VALUE_OF_PROPERTY_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        IllegalArgumentException ex2 = assertThrows(IllegalArgumentException.class, () ->
                templateProcessingService.validateDocxPackage(invalidRule2, "invalid_val_only.docx"));
        assertTrue(ex2.getMessage().contains("Rule 2"), "Must fail on Rule 2 violation: " + ex2.getMessage());

        // RULE 3: Every valuation template must contain VALUATION_SUMMARY_TABLE
        byte[] invalidRule3 = createSyntheticTemplate(List.of("<<LAND_TABLE>>", "<<BUILDING_TABLE>>", "<<VALUE_OF_PROPERTY_TABLE>>"));
        IllegalArgumentException ex3 = assertThrows(IllegalArgumentException.class, () ->
                templateProcessingService.validateDocxPackage(invalidRule3, "invalid_no_summary.docx"));
        assertTrue(ex3.getMessage().contains("Rule 3"), "Must fail on Rule 3 violation: " + ex3.getMessage());

        // RULE 4 & 5: Every template must resolve to exactly one methodology; upload must fail if methodology is ambiguous
        // Ambiguous combination: LAND + BUILDING without VALUE_OF_PROPERTY_TABLE
        byte[] invalidRule4_5 = createSyntheticTemplate(List.of("<<LAND_TABLE>>", "<<BUILDING_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        IllegalArgumentException ex45 = assertThrows(IllegalArgumentException.class, () ->
                templateProcessingService.validateDocxPackage(invalidRule4_5, "invalid_ambiguous.docx"));
        assertTrue(ex45.getMessage().contains("Rule 4 & 5"), "Must fail on Rule 4 & 5 violation: " + ex45.getMessage());
    }
}
