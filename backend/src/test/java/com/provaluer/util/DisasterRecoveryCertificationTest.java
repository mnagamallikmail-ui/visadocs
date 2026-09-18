package com.provaluer.util;

import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.nio.file.Files;

import static org.junit.jupiter.api.Assertions.*;

/**
 * DISASTER RECOVERY & BASELINE RECOVERY CERTIFICATION TEST SUITE
 * 
 * Verifies recoverability and governance integrity under worst-case scenarios:
 * 1. Canonical Template existence, structural integrity, and recovery mirror verification.
 * 2. Authoritative Business & Template Governance Rules integrity.
 * 3. Authoritative Rendering, Placeholder & Calculation Governance Rules integrity.
 * 4. Governance and Change Control Documents existence and integrity.
 * 5. ProductionRegressionCertificationTest execution capability.
 * 
 * ANY FAILURE CAUSES IMMEDIATE BUILD FAILURE.
 */
public class DisasterRecoveryCertificationTest {

    @Test
    @DisplayName("[DR-GATE-1] Verification of Canonical Template Existence and Baseline Recoverability")
    void testCanonicalTemplateExistenceAndRecoverability() throws Exception {
        File canonicalTemplate = new File("official_production_valuation_report.docx");
        File baselineTemplate = new File("baseline/official_production_valuation_report.docx");

        assertTrue(canonicalTemplate.exists() || baselineTemplate.exists(),
                "[DR FAILURE]: Neither canonical nor baseline template exists!");

        if (!canonicalTemplate.exists() && baselineTemplate.exists()) {
            Files.copy(baselineTemplate.toPath(), canonicalTemplate.toPath());
            System.out.println("[DR ACTION]: Successfully restored official_production_valuation_report.docx from baseline mirror.");
        }

        assertTrue(canonicalTemplate.exists(), "[DR FAILURE]: Canonical template must exist after recovery check.");
        assertTrue(canonicalTemplate.length() > 50000L, "[DR FAILURE]: Canonical template size must be substantial (> 50,000 bytes)");

        // Verify valid OpenXML DOCX package structure
        assertDoesNotThrow(() -> {
            WordprocessingMLPackage pkg = WordprocessingMLPackage.load(canonicalTemplate);
            assertNotNull(pkg.getMainDocumentPart(), "MainDocumentPart must be valid");
        }, "[DR FAILURE]: Canonical template failed DOCX structural package validation!");
    }

    @Test
    @DisplayName("[DR-GATE-2] Verification of Authoritative Business & Template Governance Rules Integrity")
    void testBusinessAndTemplateGovernanceRulesIntegrity() {
        File bizRules1 = new File("baseline/BusinessGovernanceRules.md");
        File bizRules2 = new File("BusinessGovernanceRules.md");
        assertTrue((bizRules1.exists() && bizRules1.length() > 0) || (bizRules2.exists() && bizRules2.length() > 0),
                "[DR FAILURE]: BusinessGovernanceRules.md must exist as canonical source of truth!");

        File templateRules1 = new File("baseline/TemplateGovernanceRules.md");
        File templateRules2 = new File("TemplateGovernanceRules.md");
        assertTrue((templateRules1.exists() && templateRules1.length() > 0) || (templateRules2.exists() && templateRules2.length() > 0),
                "[DR FAILURE]: TemplateGovernanceRules.md must exist as canonical source of truth!");

        File methodRules1 = new File("baseline/MethodologyGovernanceRules.md");
        File methodRules2 = new File("MethodologyGovernanceRules.md");
        assertTrue((methodRules1.exists() && methodRules1.length() > 0) || (methodRules2.exists() && methodRules2.length() > 0),
                "[DR FAILURE]: MethodologyGovernanceRules.md must exist as canonical source of truth!");
    }

    @Test
    @DisplayName("[DR-GATE-3] Verification of Rendering, Placeholder & Calculation Governance Rules Integrity")
    void testRenderingPlaceholderAndCalculationRulesIntegrity() {
        File renderingRules1 = new File("baseline/RenderingCertificationRules.md");
        File renderingRules2 = new File("RenderingCertificationRules.md");
        assertTrue((renderingRules1.exists() && renderingRules1.length() > 0) || (renderingRules2.exists() && renderingRules2.length() > 0),
                "[DR FAILURE]: RenderingCertificationRules.md must exist as canonical source of truth!");

        File placeholderRules1 = new File("baseline/PlaceholderGovernanceRules.md");
        File placeholderRules2 = new File("PlaceholderGovernanceRules.md");
        assertTrue((placeholderRules1.exists() && placeholderRules1.length() > 0) || (placeholderRules2.exists() && placeholderRules2.length() > 0),
                "[DR FAILURE]: PlaceholderGovernanceRules.md must exist as canonical source of truth!");

        File calculationRules1 = new File("baseline/CalculationGovernanceRules.md");
        File calculationRules2 = new File("CalculationGovernanceRules.md");
        assertTrue((calculationRules1.exists() && calculationRules1.length() > 0) || (calculationRules2.exists() && calculationRules2.length() > 0),
                "[DR FAILURE]: CalculationGovernanceRules.md must exist as canonical source of truth!");
    }

    @Test
    @DisplayName("[DR-GATE-4] Verification of Governance and Change Control Documents")
    void testGovernanceAndChangeControlDocuments() {
        File govDoc1 = new File("REPORT_ENGINE_GOVERNANCE_V1.md");
        File govDoc2 = new File("../REPORT_ENGINE_GOVERNANCE_V1.md");
        File govDoc3 = new File("baseline/REPORT_ENGINE_GOVERNANCE_V1.md");
        assertTrue(govDoc1.exists() || govDoc2.exists() || govDoc3.exists(),
                "[DR FAILURE]: REPORT_ENGINE_GOVERNANCE_V1.md missing across all locations!");

        File policyDoc1 = new File("CHANGE_CONTROL_POLICY_V1.md");
        File policyDoc2 = new File("../CHANGE_CONTROL_POLICY_V1.md");
        File policyDoc3 = new File("baseline/CHANGE_CONTROL_POLICY_V1.md");
        assertTrue(policyDoc1.exists() || policyDoc2.exists() || policyDoc3.exists(),
                "[DR FAILURE]: CHANGE_CONTROL_POLICY_V1.md missing across all locations!");

        File drDoc1 = new File("DISASTER_RECOVERY_V1.md");
        File drDoc2 = new File("../DISASTER_RECOVERY_V1.md");
        File drDoc3 = new File("baseline/DISASTER_RECOVERY_V1.md");
        assertTrue(drDoc1.exists() || drDoc2.exists() || drDoc3.exists(),
                "[DR FAILURE]: DISASTER_RECOVERY_V1.md missing across all locations!");
    }

    @Test
    @DisplayName("[DR-GATE-5] Regression Gate & Rule-Based Report Certification Execution Certification")
    void testRegressionGateAndRuleBasedReportCertificationExecutability() {
        ProductionRegressionCertificationTest regressionTest = new ProductionRegressionCertificationTest();
        assertNotNull(regressionTest, "[DR FAILURE]: ProductionRegressionCertificationTest must be instantiable");

        // Execute core regression verification directly to ensure runtime stability
        assertDoesNotThrow(regressionTest::testRegressionDomain1TextGovernance,
                "[DR FAILURE]: Domain 1 Text Governance threw an exception during DR certification!");
        assertDoesNotThrow(regressionTest::testRegressionDomain5FormulaEngine,
                "[DR FAILURE]: Domain 5 Formula Engine threw an exception during DR certification!");
        assertDoesNotThrow(regressionTest::testRegressionDomain8CurrencyFormatting,
                "[DR FAILURE]: Domain 8 Currency Formatting threw an exception during DR certification!");
        assertDoesNotThrow(regressionTest::testRuleBasedReportCertification,
                "[DR FAILURE]: Rule-Based Report Certification threw an exception during DR certification!");
    }
}
