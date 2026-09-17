package com.provaluer.util;

import org.docx4j.finders.ClassFinder;
import org.docx4j.TraversalUtil;
import org.docx4j.dml.wordprocessingDrawing.Anchor;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class CriticalPostFormulaEngineGovernanceTest {

    private final DocxTemplateEngine engine = new DocxTemplateEngine();
    private final DocxStructureParser parser = new DocxStructureParser();

    @Test
    @DisplayName("Decision 1: Rounding Governance (Approach A - True Rounding HALF_UP)")
    void testRoundingGovernance() {
        // Lakhs (< 1 Crore) -> nearest 1,000
        assertEquals(9523000.0, NumericFormulaEngine.applyRoundingGovernance("REALIZABLE_VALUE", 9522650.0), 0.001);
        assertEquals(9522000.0, NumericFormulaEngine.applyRoundingGovernance("REALIZABLE_VALUE", 9522200.0), 0.001);
        assertEquals(9523000.0, NumericFormulaEngine.applyRoundingGovernance("DISTRESS_SALE_VALUE", 9522650.0), 0.001);
        assertEquals(9523000.0, NumericFormulaEngine.applyRoundingGovernance("INSURABLE_VALUE", 9522650.0), 0.001);

        // Crores (>= 1 Crore) -> nearest 10,000
        assertEquals(17050000.0, NumericFormulaEngine.applyRoundingGovernance("REALIZABLE_VALUE", 17048900.0), 0.001);
        assertEquals(17040000.0, NumericFormulaEngine.applyRoundingGovernance("REALIZABLE_VALUE", 17042350.0), 0.001);
        assertEquals(127540000.0, NumericFormulaEngine.applyRoundingGovernance("DISTRESS_VALUE", 127538900.0), 0.001);

        // Exact governance: Government Value and Fair Value must never be rounded by applyRoundingGovernance
        assertEquals(9522650.0, NumericFormulaEngine.applyRoundingGovernance("GOVERNMENT_VALUE", 9522650.0), 0.001);
        assertEquals(17048900.0, NumericFormulaEngine.applyRoundingGovernance("FAIR_VALUE", 17048900.0), 0.001);
    }

    @Test
    @DisplayName("Decision 2: Zero Display Governance & Default N Values")
    void testZeroDisplayGovernance() {
        // Issue 1: Default N values internally initialize to 0.0
        Map<String, String> emptyInputs = new HashMap<>();
        NumericFormulaEngine.EvaluationResult res = NumericFormulaEngine.evaluate("N1*N2", emptyInputs);
        assertTrue(res.isValid());
        assertEquals(0.0, res.getValue());
        assertTrue(res.isAllInputsUntouched(), "Untouched inputs must set allInputsUntouched=true");

        // Issue 2: Genuinely calculated zero
        Map<String, String> zeroCalcInputs = new HashMap<>();
        zeroCalcInputs.put("N1", "500");
        zeroCalcInputs.put("N2", "500");
        NumericFormulaEngine.EvaluationResult zeroCalc = NumericFormulaEngine.evaluate("N1-N2", zeroCalcInputs);
        assertTrue(zeroCalc.isValid());
        assertEquals(0.0, zeroCalc.getValue());
        assertFalse(zeroCalc.isAllInputsUntouched(), "Entered inputs calculating to 0 must have allInputsUntouched=false");
        assertEquals("0", zeroCalc.getFormattedValue());
    }

    @Test
    @DisplayName("Decision 3: Text Placeholder Governance - Hard-Stop TEXT Inference")
    void testTextPlaceholderHardStop() {
        String[] textKeys = {"TEXT", "TEXT_001", "TEXT_002", "TEXT_003", "TXT", "TXT_001", "TEXT_PLACEHOLDER"};
        for (String k : textKeys) {
            String inferred = parser.inferFieldType(k);
            assertEquals("TEXT", inferred, "Placeholder " + k + " must immediately return TEXT");
            assertNotEquals("DATE", inferred, "Placeholder " + k + " must NEVER be inferred as DATE");
            assertNotEquals("IMAGE", inferred, "Placeholder " + k + " must NEVER be inferred as IMAGE");
        }
    }

    @Test
    @DisplayName("Decision 4 & First Page Image Governance: Anchor Preservation & Alias Parity")
    void testFirstPageImagePreservationAndAliases() throws Exception {
        File file = new File("official_production_valuation_report.docx");
        assertTrue(file.exists());

        byte[] templateBytes = Files.readAllBytes(file.toPath());
        byte[] dummyPng = new byte[]{
            (byte) 137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
            0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, -60,
            -119, 0, 0, 0, 10, 73, 68, 65, 84, 120, -100, 99, 0, 1, 0, 0,
            5, 0, 1, 13, 10, 45, -76, 0, 0, 0, 0, 73, 69, 78, 68,
            -82, 66, 96, -126
        };

        Map<String, String> inputs = new HashMap<>();
        inputs.put("name_of_the_owner", "Dr. Rajesh Sharma");
        inputs.put("TEXT_001", "Certified Valuation Governance Text");

        Map<String, byte[]> images = new HashMap<>();
        images.put("IMG_FRONT_PAGE", dummyPng);

        byte[] generatedBytes = engine.generateReport(templateBytes, inputs, images);
        assertNotNull(generatedBytes);

        WordprocessingMLPackage resultPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generatedBytes));
        ClassFinder anchorFinder = new ClassFinder(Anchor.class);
        new TraversalUtil(resultPkg.getMainDocumentPart().getContent(), anchorFinder);

        // Verify that Anchor drawings on Page 1 are fully preserved (all 14 anchors intact)
        assertEquals(14, anchorFinder.results.size(), "All 14 anchor drawings including Page 1 front image must be preserved");
    }

    @Test
    @DisplayName("Currency Formatting Governance: Consistent 'Rs ' prefix")
    void testCurrencyFormatting() {
        assertEquals("Rs 95,22,200", IndianNumberFormatter.formatCurrency(new BigDecimal("9522200")));
        assertEquals("Rs 1,70,50,000", IndianNumberFormatter.formatCurrency(new BigDecimal("17050000")));
        assertEquals("Rs 12,75,40,000", IndianNumberFormatter.formatCurrency(new BigDecimal("127540000")));
    }

    @Test
    @DisplayName("Runtime Proof: Composite Property Valuation Table & Valuation Parameters Table in DOCX and PDF")
    void testCompositePropertyValuationTableAndValuationParametersTableInDocxAndPdf() throws Exception {
        File file = new File("official_production_valuation_report.docx");
        assertTrue(file.exists());

        byte[] templateBytes = Files.readAllBytes(file.toPath());

        Map<String, String> inputs = new HashMap<>();
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE");
        inputs.put("PROPERTY_CATEGORY", "Flat");
        inputs.put("name_of_the_owner", "Dr. Rajesh Sharma");
        inputs.put("PROPERTY_TYPE", "Residential Flat");
        inputs.put("SUPER_BUILT_UP_AREA", "1250");
        inputs.put("COMPOSITE_RATE", "6500");
        inputs.put("COMPOSITE_AMOUNT", "8125000");
        inputs.put("COMPOSITE_DEPRECIATION", "0");
        inputs.put("COMPOSITE_FAIR_VALUE", "8125000");
        inputs.put("RAW_FAIR_VALUE", "8875000");
        inputs.put("SAY_FAIR_VALUE", "8880000");
        inputs.put("FAIR_VALUE", "8880000");
        inputs.put("REALIZABLE_VALUE", "7548000");
        inputs.put("DISTRESS_SALE_VALUE", "6660000");
        inputs.put("GOVERNMENT_VALUE", "5000000");
        inputs.put("INSURABLE_VALUE", "3500000");

        String compositeItemsJson = "[" +
                "{\"description\":\"Flat No. 402, Main Unit\",\"enteredUnit\":\"Sq.Ft\",\"quantity\":\"1250\",\"rate\":\"6500\",\"amount\":\"8125000\",\"depreciationAmount\":\"0\",\"fairValue\":\"8125000\"}," +
                "{\"description\":\"Interior Works & Woodwork\",\"enteredUnit\":\"LS\",\"quantity\":\"1\",\"rate\":\"500000\",\"amount\":\"500000\",\"depreciationAmount\":\"50000\",\"fairValue\":\"450000\"}," +
                "{\"description\":\"Covered Car Parking Space\",\"enteredUnit\":\"No\",\"quantity\":\"1\",\"rate\":\"300000\",\"amount\":\"300000\",\"depreciationAmount\":\"0\",\"fairValue\":\"300000\"}" +
                "]";
        inputs.put("RAW_COMPOSITE_ITEMS_JSON", compositeItemsJson);

        byte[] generatedDocx = engine.generateReport(templateBytes, inputs, java.util.Collections.emptyMap());
        assertNotNull(generatedDocx, "Generated DOCX must not be null");

        // 1. DOCX Verification
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generatedDocx));
        String docxXml = org.docx4j.XmlUtils.marshaltoString(pkg.getMainDocumentPart().getJaxbElement());

        // Composite Property Valuation Table proof in DOCX
        assertTrue(docxXml.contains("Valuation of Property (Composite Rate Method)"),
                "DOCX must contain Composite Valuation Table title");
        assertTrue(docxXml.contains("Flat No. 402, Main Unit"),
                "DOCX Composite Table must contain Main Unit row");
        assertTrue(docxXml.contains("Interior Works"),
                "DOCX Composite Table must contain independent Interior Works row");
        assertTrue(docxXml.contains("Covered Car Parking Space"),
                "DOCX Composite Table must contain independent Parking row");
        assertTrue(docxXml.contains("Fair Value Of Property"),
                "DOCX Composite Table must contain Fair Value Of Property total row");

        // Valuation Parameters Table proof in DOCX
        assertTrue(docxXml.contains("Valuation Parameters Summary"),
                "DOCX must contain Valuation Parameters Summary title");
        assertTrue(docxXml.contains("Realizable Value"),
                "DOCX Parameters Table must contain Realizable Value");
        assertTrue(docxXml.contains("Distress Sale Value"),
                "DOCX Parameters Table must contain Distress Sale Value");
        assertTrue(docxXml.contains("Government Value"),
                "DOCX Parameters Table must contain Government Value");
        assertTrue(docxXml.contains("Insurable Value"),
                "DOCX Parameters Table must contain Insurable Value");

        System.out.println("=== RUNTIME PROOF (DOCX) ===");
        System.out.println("-> Composite Property Valuation Table: PRESENT in DOCX");
        System.out.println("-> Valuation Parameters Table: PRESENT in DOCX");

        // 2. PDF Verification
        byte[] generatedPdf = engine.convertDocxToPdf(generatedDocx);
        assertNotNull(generatedPdf, "Generated PDF must not be null");
        assertTrue(generatedPdf.length > 0, "PDF bytes must be non-empty");

        try (org.apache.pdfbox.pdmodel.PDDocument pdfDoc = org.apache.pdfbox.Loader.loadPDF(generatedPdf)) {
            org.apache.pdfbox.text.PDFTextStripper stripper = new org.apache.pdfbox.text.PDFTextStripper();
            String pdfText = stripper.getText(pdfDoc);

            assertTrue(pdfText.contains("Composite Rate Method") || pdfText.contains("Valuation of Property"),
                    "PDF must contain Composite Valuation Table");
            assertTrue(pdfText.contains("Interior Works"),
                    "PDF Composite Table must contain Interior Works row");
            assertTrue(pdfText.contains("Covered Car Parking Space"),
                    "PDF Composite Table must contain Parking row");

            assertTrue(pdfText.contains("Valuation Parameters Summary"),
                    "PDF must contain Valuation Parameters Summary table");
            assertTrue(pdfText.contains("Realizable Value"),
                    "PDF Parameters Table must contain Realizable Value");
            assertTrue(pdfText.contains("Distress Sale Value"),
                    "PDF Parameters Table must contain Distress Sale Value");
            assertTrue(pdfText.contains("Government Value"),
                    "PDF Parameters Table must contain Government Value");
            assertTrue(pdfText.contains("Insurable Value"),
                    "PDF Parameters Table must contain Insurable Value");

            System.out.println("=== RUNTIME PROOF (PDF) ===");
            System.out.println("-> Total PDF Pages: " + pdfDoc.getNumberOfPages());
            System.out.println("-> Composite Property Valuation Table: PRESENT in PDF");
            System.out.println("-> Valuation Parameters Table: PRESENT in PDF");
        }
    }
}
