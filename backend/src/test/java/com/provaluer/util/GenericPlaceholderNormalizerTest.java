package com.provaluer.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

public class GenericPlaceholderNormalizerTest {

    @Test
    @DisplayName("1. Basic question slugification with consistent _1 suffix")
    public void testBasicQuestionSlugification() {
        String key1 = GenericPlaceholderNormalizer.normalizeQuestionToKey("Layout Plan (Yes / No)", 1);
        assertEquals("LAYOUT_PLAN_YES_NO_1", key1);

        String keyLong = GenericPlaceholderNormalizer.normalizeQuestionToKey("Layout Plan (Yes / No), if yes mention approval number", 1);
        assertEquals("LAYOUT_PLAN_YES_NO_IF_YES_MENTION_APPROVAL_NUMBER_1", keyLong);

        String key2 = GenericPlaceholderNormalizer.normalizeQuestionToKey("Building Plan (Yes / No)", 1);
        assertEquals("BUILDING_PLAN_YES_NO_1", key2);

        String key3 = GenericPlaceholderNormalizer.normalizeQuestionToKey("Construction Permission (Yes / No)", 1);
        assertEquals("CONSTRUCTION_PERMISSION_YES_NO_1", key3);
    }

    @Test
    @DisplayName("2. Duplicate question numbering: REMARKS_1, REMARKS_2, REMARKS_3")
    public void testDuplicateQuestionsNumbering() {
        String r1 = GenericPlaceholderNormalizer.normalizeQuestionToKey("Remarks", 1);
        String r2 = GenericPlaceholderNormalizer.normalizeQuestionToKey("Remarks", 2);
        String r3 = GenericPlaceholderNormalizer.normalizeQuestionToKey("Remarks", 3);

        assertEquals("REMARKS_1", r1);
        assertEquals("REMARKS_2", r2);
        assertEquals("REMARKS_3", r3);
    }

    @Test
    @DisplayName("3. Stripping leading serial numbers and bullets")
    public void testStrippingLeadingBullets() {
        assertEquals("LAYOUT_PLAN_YES_NO_1", GenericPlaceholderNormalizer.normalizeQuestionToKey("14.b) Layout Plan (Yes / No)", 1));
        assertEquals("BUILDING_PLAN_STATUS_1", GenericPlaceholderNormalizer.normalizeQuestionToKey("1. Building Plan Status", 1));
        assertEquals("LEGAL_CLEARANCE_1", GenericPlaceholderNormalizer.normalizeQuestionToKey("a) Legal Clearance", 1));
        assertEquals("PROPERTY_ACCESS_1", GenericPlaceholderNormalizer.normalizeQuestionToKey("- Property Access", 1));
    }

    @Test
    @DisplayName("4. Master placeholder exemption identification")
    public void testMasterPlaceholderExemption() {
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("REPORT_DATE"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("<<REPORT_DATE>>"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("REPORT_NO"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("PROPERTY_DESCRIPTION"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("PROPERTY_ADDRESS"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("NAME_OF_THE_OWNER"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("FAIR_VALUE"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("REALIZABLE_VALUE"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("DISTRESS_SALE_VALUE"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("LAND_AREA"));
        assertTrue(GenericPlaceholderNormalizer.isMasterPlaceholder("PLINTH_AREA"));

        assertFalse(GenericPlaceholderNormalizer.isMasterPlaceholder("TEXT"));
        assertFalse(GenericPlaceholderNormalizer.isMasterPlaceholder("LAYOUT_PLAN_YES_NO_1"));
    }

    @Test
    @DisplayName("5. Extensible generic tokens support")
    public void testGenericTokensSupport() {
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("TEXT"));
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("<<TEXT>>"));
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("NUMBER"));
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("<<NUMBER>>"));
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("DATE"));
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("<<DATE>>"));
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("IMAGE"));
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("<<IMAGE>>"));
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("CHECKBOX"));
        assertTrue(GenericPlaceholderNormalizer.isGenericPlaceholder("<<CHECKBOX>>"));

        assertFalse(GenericPlaceholderNormalizer.isGenericPlaceholder("CLIENT_NAME"));
        assertFalse(GenericPlaceholderNormalizer.isGenericPlaceholder("REPORT_DATE"));
    }

    @Test
    @DisplayName("6. Template Analysis Report generation")
    public void testTemplateAnalysisReport() {
        GenericPlaceholderNormalizer.TemplateAnalysisReport report = new GenericPlaceholderNormalizer.TemplateAnalysisReport();

        report.recordGeneratedField(new GenericPlaceholderNormalizer.NormalizedField(
                "LAYOUT_PLAN_YES_NO_1", "Layout Plan (Yes / No)", "TEXT", 1, "tbl_0_r1_c1"), "LAYOUT_PLAN_YES_NO");
        report.recordGeneratedField(new GenericPlaceholderNormalizer.NormalizedField(
                "REMARKS_1", "Remarks", "TEXT", 1, "tbl_0_r2_c1"), "REMARKS");
        report.recordGeneratedField(new GenericPlaceholderNormalizer.NormalizedField(
                "REMARKS_2", "Remarks", "TEXT", 2, "tbl_0_r3_c1"), "REMARKS");
        report.recordGeneratedField(new GenericPlaceholderNormalizer.NormalizedField(
                "REMARKS_3", "Remarks", "TEXT", 3, "tbl_0_r4_c1"), "REMARKS");

        report.recordMasterPlaceholder("REPORT_DATE");
        report.recordMasterPlaceholder("FAIR_VALUE");

        assertEquals(4, report.getTotalGeneratedFields());
        assertEquals(4, report.getFieldsByType().get("TEXT"));
        assertTrue(report.getMasterPlaceholders().contains("REPORT_DATE"));
        assertTrue(report.getMasterPlaceholders().contains("FAIR_VALUE"));

        String formatted = report.toFormattedReport();
        assertTrue(formatted.contains("Generated Fields: 4"));
        assertTrue(formatted.contains("TEXT Fields: 4"));
        assertTrue(formatted.contains("REMARKS (3 occurrences)"));
        assertTrue(formatted.contains("→ REMARKS_1"));
        assertTrue(formatted.contains("→ REMARKS_2"));
        assertTrue(formatted.contains("→ REMARKS_3"));
        assertTrue(formatted.contains("REPORT_DATE"));
    }
}
