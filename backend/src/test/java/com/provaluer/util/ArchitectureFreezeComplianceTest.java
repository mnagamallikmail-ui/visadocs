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

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.nio.file.Files;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ARCHITECTURE FREEZE COMPLIANCE & GOVERNANCE INTEGRITY TEST
 * 
 * Verifies that:
 * 1. All Freeze Protected governance documents exist and are non-empty.
 * 2. MASTER_GOVERNANCE_SPECIFICATION.md and ArchitectureFreezeManifest.md exist.
 * 3. All approved production templates exist and are valid OpenXML packages.
 * 4. Methodology definitions remain permanently frozen.
 * 5. Template upload validation rules (Rules 1 - 5) remain active.
 * 
 * ANY FAILURE CAUSES IMMEDIATE BUILD TERMINATION.
 */
@SpringBootTest
@ActiveProfiles("test")
public class ArchitectureFreezeComplianceTest {

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Autowired
    private TemplateProcessingService templateProcessingService;

    private static final List<String> REQUIRED_GOVERNANCE_DOCS = List.of(
            "baseline/MASTER_GOVERNANCE_SPECIFICATION.md",
            "baseline/ArchitectureFreezeManifest.md",
            "baseline/BusinessGovernanceRules.md",
            "baseline/TemplateGovernanceRules.md",
            "baseline/MethodologyGovernanceRules.md",
            "baseline/RenderingCertificationRules.md",
            "baseline/PlaceholderGovernanceRules.md",
            "baseline/CalculationGovernanceRules.md",
            "baseline/FreezeProtectedFiles.md",
            "baseline/GovernanceChangeChecklist.md",
            "baseline/ArchitectureChangeLog.md"
    );

    private static final List<String> APPROVED_TEMPLATES = List.of(
            "official_land_valuation_report.docx",
            "official_production_valuation_report.docx",
            "official_flat_apartment_valuation_report.docx"
    );

    @Test
    @DisplayName("[FREEZE-GATE-1] Verification of All Governance Documents Existence and Non-Emptiness")
    void testProtectedGovernanceDocumentsExistence() {
        for (String docPath : REQUIRED_GOVERNANCE_DOCS) {
            File docFile = new File(docPath);
            if (!docFile.exists()) {
                docFile = new File(docFile.getName());
            }
            assertTrue(docFile.exists(), "[FREEZE VIOLATION]: Required governance document missing: " + docPath);
            assertTrue(docFile.length() > 0, "[FREEZE VIOLATION]: Governance document cannot be empty: " + docPath);
        }
    }

    @Test
    @DisplayName("[FREEZE-GATE-2] Verification of Approved Production Templates and Baseline Mirrors")
    void testApprovedProductionTemplatesExistenceAndIntegrity() throws Exception {
        for (String templateName : APPROVED_TEMPLATES) {
            File canonicalFile = new File(templateName);
            File baselineFile = new File("baseline/" + templateName);

            assertTrue(canonicalFile.exists() || baselineFile.exists(),
                    "[FREEZE VIOLATION]: Neither canonical nor baseline mirror exists for: " + templateName);

            if (!canonicalFile.exists() && baselineFile.exists()) {
                Files.copy(baselineFile.toPath(), canonicalFile.toPath());
            }

            assertTrue(canonicalFile.exists(), "[FREEZE VIOLATION]: Canonical template must exist: " + templateName);
            assertTrue(canonicalFile.length() > 50000L,
                    "[FREEZE VIOLATION]: Canonical template file size must be substantial (> 50,000 bytes): " + templateName);

            // Verify OpenXML package structure
            WordprocessingMLPackage pkg = WordprocessingMLPackage.load(canonicalFile);
            assertNotNull(pkg.getMainDocumentPart(),
                    "[FREEZE VIOLATION]: Template failed OpenXML structural validation: " + templateName);
        }
    }

    @Test
    @DisplayName("[FREEZE-GATE-3] Verification of Methodology Definitions Frozen and Unchanged")
    void testMethodologyDefinitionsFrozenAndUnchanged() throws Exception {
        // 1. Land Only Template must detect as LAND_ONLY
        byte[] landBytes = Files.readAllBytes(new File("official_land_valuation_report.docx").toPath());
        assertEquals(DocxTemplateEngine.TemplateMethodology.LAND_ONLY,
                templateEngine.detectTemplateMethodology(landBytes),
                "[FREEZE VIOLATION]: Land Only template methodology definition altered!");

        // 2. Land and Building Template must detect as LAND_AND_BUILDING
        byte[] lbBytes = Files.readAllBytes(new File("official_production_valuation_report.docx").toPath());
        assertEquals(DocxTemplateEngine.TemplateMethodology.LAND_AND_BUILDING,
                templateEngine.detectTemplateMethodology(lbBytes),
                "[FREEZE VIOLATION]: Land + Building template methodology definition altered!");

        // 3. Flat / Apartment Template must detect as COMPOSITE
        byte[] flatBytes = Files.readAllBytes(new File("official_flat_apartment_valuation_report.docx").toPath());
        assertEquals(DocxTemplateEngine.TemplateMethodology.COMPOSITE,
                templateEngine.detectTemplateMethodology(flatBytes),
                "[FREEZE VIOLATION]: Flat / Apartment template methodology definition altered!");
    }

    @Test
    @DisplayName("[FREEZE-GATE-4] Verification of Template Upload Validation Rules (Rules 1 - 5) Active")
    void testTemplateUploadRulesRemainActive() throws Exception {
        // Approved templates must pass upload validation
        for (String templateName : APPROVED_TEMPLATES) {
            byte[] bytes = Files.readAllBytes(new File(templateName).toPath());
            assertDoesNotThrow(() -> templateProcessingService.validateDocxPackage(bytes, templateName),
                    "[FREEZE VIOLATION]: Approved template failed upload validation: " + templateName);
        }

        // Upload Rule 1: Exclusivity (Composite cannot coexist with Land)
        byte[] invalidRule1 = createSyntheticTemplate(List.of("<<COMPOSITE_PROPERTY_TABLE>>", "<<LAND_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        IllegalArgumentException ex1 = assertThrows(IllegalArgumentException.class,
                () -> templateProcessingService.validateDocxPackage(invalidRule1, "invalid_exclusivity.docx"),
                "[FREEZE VIOLATION]: Upload Rule 1 (Exclusivity) is not being enforced!");
        assertTrue(ex1.getMessage().contains("Rule 1"), "Must reference Rule 1 in exception message");

        // Upload Rule 2: Dependency (Value of Property requires Land + Building)
        byte[] invalidRule2 = createSyntheticTemplate(List.of("<<VALUE_OF_PROPERTY_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        IllegalArgumentException ex2 = assertThrows(IllegalArgumentException.class,
                () -> templateProcessingService.validateDocxPackage(invalidRule2, "invalid_dependency.docx"),
                "[FREEZE VIOLATION]: Upload Rule 2 (Dependency) is not being enforced!");
        assertTrue(ex2.getMessage().contains("Rule 2"), "Must reference Rule 2 in exception message");

        // Upload Rule 3: Summary Table Mandate
        byte[] invalidRule3 = createSyntheticTemplate(List.of("<<LAND_TABLE>>", "<<BUILDING_TABLE>>", "<<VALUE_OF_PROPERTY_TABLE>>"));
        IllegalArgumentException ex3 = assertThrows(IllegalArgumentException.class,
                () -> templateProcessingService.validateDocxPackage(invalidRule3, "invalid_no_summary.docx"),
                "[FREEZE VIOLATION]: Upload Rule 3 (Summary Mandate) is not being enforced!");
        assertTrue(ex3.getMessage().contains("Rule 3"), "Must reference Rule 3 in exception message");

        // Upload Rules 4 & 5: Methodology Singularity & Ambiguity Prohibition
        byte[] invalidRule4_5 = createSyntheticTemplate(List.of("<<LAND_TABLE>>", "<<BUILDING_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        IllegalArgumentException ex45 = assertThrows(IllegalArgumentException.class,
                () -> templateProcessingService.validateDocxPackage(invalidRule4_5, "invalid_ambiguous.docx"),
                "[FREEZE VIOLATION]: Upload Rules 4 & 5 (Ambiguity Prohibition) are not being enforced!");
        assertTrue(ex45.getMessage().contains("Rule 4 & 5"), "Must reference Rule 4 & 5 in exception message");
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
}
