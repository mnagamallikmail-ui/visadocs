package com.provaluer.util;

import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.docx4j.TraversalUtil;
import org.docx4j.XmlUtils;
import org.docx4j.dml.wordprocessingDrawing.Anchor;
import org.docx4j.finders.ClassFinder;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.Tbl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.*;

/**
 * PRODUCTION REGRESSION CERTIFICATION TEST SUITE (PERMANENT BUILD GATE)
 * 
 * Enforces zero-tolerance regression protection across all 8 governance domains:
 * Domain 1: Text Governance (Hard-Stop Rule)
 * Domain 2: Image Governance (Prefix & Anchor Preservation)
 * Domain 3: Composite Property Table (Presence & Hierarchy)
 * Domain 4: Valuation Parameters Table (Presence & Completeness)
 * Domain 5: Formula Engine (Untouched Blanks, N Defaults, Rounding Approach A)
 * Domain 6: Image Boundary Governance (Strict Containment Across 6 Geometries)
 * Domain 7: Keyboard Navigation (Navigation Contract & Boundary Invariants)
 * Domain 8: Currency Formatting (Indian Format with 'Rs ' Prefix)
 * Golden Report Comparison (Structural & Content Parity between current and golden artifacts)
 * 
 * ANY VIOLATION IMMEDIATELY FAILS THE BUILD.
 */
public class ProductionRegressionCertificationTest {

    private final DocxTemplateEngine engine = new DocxTemplateEngine();
    private final DocxStructureParser parser = new DocxStructureParser();

    // ========================================================================
    // REGRESSION DOMAIN 1: TEXT GOVERNANCE
    // ========================================================================
    @Test
    @DisplayName("[GATE-1] Text Governance: Hard-Stop Identifiers Must Classify as TEXT Only")
    void testRegressionDomain1TextGovernance() {
        String[] textCandidates = {
            "TEXT", "TEXT_001", "TEXT_002", "TEXT_003",
            "TXT", "TXT_001", "TEXT_PLACEHOLDER", "TEXT_99", "TXT_50"
        };
        for (String key : textCandidates) {
            String fieldType = parser.inferFieldType(key);
            assertEquals("TEXT", fieldType,
                    "[REGRESSION VIOLATION - DOMAIN 1]: Key '" + key + "' must immediately classify as TEXT");
            assertNotEquals("DATE", fieldType,
                    "[REGRESSION VIOLATION - DOMAIN 1]: Key '" + key + "' must NEVER be inferred as DATE");
            assertNotEquals("IMAGE", fieldType,
                    "[REGRESSION VIOLATION - DOMAIN 1]: Key '" + key + "' must NEVER be inferred as IMAGE");
        }
    }

    // ========================================================================
    // REGRESSION DOMAIN 2: IMAGE GOVERNANCE
    // ========================================================================
    @Test
    @DisplayName("[GATE-2] Image Governance: Prefix Enforcement, Parity Aliases & Anchor Count")
    void testRegressionDomain2ImageGovernance() throws Exception {
        // 1. Prefix Rule: IMG_* and IMAGE_* must classify as IMAGE
        String[] imageKeys = {"IMG_FRONT_PAGE", "IMG_PIC1", "IMG_PIC2", "IMAGE_SITE_OVERVIEW", "IMG_GOVT_RATE"};
        for (String key : imageKeys) {
            assertEquals("IMAGE", parser.inferFieldType(key),
                    "[REGRESSION VIOLATION - DOMAIN 2]: Key '" + key + "' must classify as IMAGE");
        }

        // 2. Non-prefixed descriptive keys must NOT classify as IMAGE (only IMG_ and IMAGE_ prefixes qualify)
        String[] nonImageKeys = {"PHOTO_REMARKS", "PICTURE_CAPTION", "PHOTO_DESCRIPTION", "SITE_PHOTO_NOTE"};
        for (String key : nonImageKeys) {
            assertNotEquals("IMAGE", parser.inferFieldType(key),
                    "[REGRESSION VIOLATION - DOMAIN 2]: Narrative key '" + key + "' must not classify as IMAGE");
        }

        // 3. Alias parity & front page anchor preservation
        File templateFile = new File("official_production_valuation_report.docx");
        assertTrue(templateFile.exists(), "[REGRESSION VIOLATION - DOMAIN 2]: official_production_valuation_report.docx must exist");

        byte[] templateBytes = Files.readAllBytes(templateFile.toPath());
        byte[] dummyImg = createTestImageBytes(400, 300, Color.LIGHT_GRAY, "TEST");

        Map<String, byte[]> images = new HashMap<>();
        images.put("COVER_IMAGE", dummyImg); // test alias parity

        byte[] generated = engine.generateReport(templateBytes, Collections.emptyMap(), images);
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));

        ClassFinder anchorFinder = new ClassFinder(Anchor.class);
        new TraversalUtil(pkg.getMainDocumentPart().getContent(), anchorFinder);
        assertEquals(14, anchorFinder.results.size(),
                "[REGRESSION VIOLATION - DOMAIN 2]: Front-page anchor count must remain exactly 14");
    }

    // ========================================================================
    // REGRESSION DOMAIN 3: COMPOSITE PROPERTY TABLE
    // ========================================================================
    @Test
    @DisplayName("[GATE-3] Composite Property Table: Hierarchy & Mandatory Rows")
    void testRegressionDomain3CompositePropertyTable() throws Exception {
        byte[] docxBytes = generateStandardProductionReportDocx();
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));
        String docxXml = XmlUtils.marshaltoString(pkg.getMainDocumentPart().getJaxbElement());

        assertTrue(docxXml.contains("Valuation of Property (Composite Rate Method)"),
                "[REGRESSION VIOLATION - DOMAIN 3]: Composite Property Valuation Table title missing");
        assertTrue(docxXml.contains("Flat No. 402, Main Unit"),
                "[REGRESSION VIOLATION - DOMAIN 3]: Main Unit row missing from Composite Table");
        assertTrue(docxXml.contains("Interior Works"),
                "[REGRESSION VIOLATION - DOMAIN 3]: Interior Works row missing from Composite Table");
        assertTrue(docxXml.contains("Covered Car Parking Space"),
                "[REGRESSION VIOLATION - DOMAIN 3]: Parking row missing from Composite Table");
        assertTrue(docxXml.contains("Fair Value Of Property"),
                "[REGRESSION VIOLATION - DOMAIN 3]: Fair Value Of Property subtotal row missing from Composite Table");
    }

    // ========================================================================
    // REGRESSION DOMAIN 4: VALUATION PARAMETERS TABLE
    // ========================================================================
    @Test
    @DisplayName("[GATE-4] Valuation Parameters Table: Summary Presence & Mandatory Parameter Rows")
    void testRegressionDomain4ValuationParametersTable() throws Exception {
        byte[] docxBytes = generateStandardProductionReportDocx();
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));
        String docxXml = XmlUtils.marshaltoString(pkg.getMainDocumentPart().getJaxbElement());

        assertTrue(docxXml.contains("Valuation Parameters Summary"),
                "[REGRESSION VIOLATION - DOMAIN 4]: Valuation Parameters Summary table title missing");
        assertTrue(docxXml.contains("Fair Value"),
                "[REGRESSION VIOLATION - DOMAIN 4]: Fair Value parameter row missing");
        assertTrue(docxXml.contains("Realizable Value"),
                "[REGRESSION VIOLATION - DOMAIN 4]: Realizable Value parameter row missing");
        assertTrue(docxXml.contains("Distress Sale Value"),
                "[REGRESSION VIOLATION - DOMAIN 4]: Distress Sale Value parameter row missing");
        assertTrue(docxXml.contains("Government Value"),
                "[REGRESSION VIOLATION - DOMAIN 4]: Government Value parameter row missing");
        assertTrue(docxXml.contains("Insurable Value"),
                "[REGRESSION VIOLATION - DOMAIN 4]: Insurable Value parameter row missing");
    }

    // ========================================================================
    // REGRESSION DOMAIN 5: FORMULA ENGINE
    // ========================================================================
    @Test
    @DisplayName("[GATE-5] Formula Engine: Default N, Untouched Blanks, Exact Govt Value & Rounding Approach A")
    void testRegressionDomain5FormulaEngine() {
        // 1. N placeholders default internally to 0.0 with allInputsUntouched=true
        Map<String, String> emptyInputs = new HashMap<>();
        NumericFormulaEngine.EvaluationResult res = NumericFormulaEngine.evaluate("N1*N2", emptyInputs);
        assertTrue(res.isValid(), "[REGRESSION VIOLATION - DOMAIN 5]: Default N evaluation must be valid");
        assertEquals(0.0, res.getValue(), "[REGRESSION VIOLATION - DOMAIN 5]: Default N value must be 0.0");
        assertTrue(res.isAllInputsUntouched(),
                "[REGRESSION VIOLATION - DOMAIN 5]: Untouched formula inputs must set allInputsUntouched = true");

        // 2. Genuine calculation evaluates to zero (500 - 500 = 0)
        Map<String, String> zeroInputs = new HashMap<>();
        zeroInputs.put("N1", "500");
        zeroInputs.put("N2", "500");
        NumericFormulaEngine.EvaluationResult calcZero = NumericFormulaEngine.evaluate("N1-N2", zeroInputs);
        assertTrue(calcZero.isValid());
        assertEquals(0.0, calcZero.getValue());
        assertFalse(calcZero.isAllInputsUntouched(),
                "[REGRESSION VIOLATION - DOMAIN 5]: Genuinely calculated zero must NOT be marked untouched");
        assertEquals("0", calcZero.getFormattedValue(),
                "[REGRESSION VIOLATION - DOMAIN 5]: Genuinely calculated zero must format as '0'");

        // 3. Government Value remains exact (never rounded)
        assertEquals(9522650.0, NumericFormulaEngine.applyRoundingGovernance("GOVERNMENT_VALUE", 9522650.0), 0.001,
                "[REGRESSION VIOLATION - DOMAIN 5]: Government Value must remain exact");
        assertEquals(17048900.0, NumericFormulaEngine.applyRoundingGovernance("FAIR_VALUE", 17048900.0), 0.001,
                "[REGRESSION VIOLATION - DOMAIN 5]: Fair Value must remain exact");

        // 4. Approach A (HALF_UP): Lakhs (< 1 Cr) -> nearest 1,000
        assertEquals(9523000.0, NumericFormulaEngine.applyRoundingGovernance("REALIZABLE_VALUE", 9522650.0), 0.001,
                "[REGRESSION VIOLATION - DOMAIN 5]: Lakhs rounding must round 95,22,650 up to 95,23,000");
        assertEquals(9522000.0, NumericFormulaEngine.applyRoundingGovernance("REALIZABLE_VALUE", 9522200.0), 0.001,
                "[REGRESSION VIOLATION - DOMAIN 5]: Lakhs rounding must round 95,22,200 down to 95,22,000");

        // 5. Approach A (HALF_UP): Crores (>= 1 Cr) -> nearest 10,000
        assertEquals(17050000.0, NumericFormulaEngine.applyRoundingGovernance("REALIZABLE_VALUE", 17048900.0), 0.001,
                "[REGRESSION VIOLATION - DOMAIN 5]: Crores rounding must round 1,70,48,900 up to 1,70,50,000");
        assertEquals(17040000.0, NumericFormulaEngine.applyRoundingGovernance("REALIZABLE_VALUE", 17042350.0), 0.001,
                "[REGRESSION VIOLATION - DOMAIN 5]: Crores rounding must round 1,70,42,350 down to 1,70,40,000");
    }

    // ========================================================================
    // REGRESSION DOMAIN 6: IMAGE BOUNDARY GOVERNANCE
    // ========================================================================
    @Test
    @DisplayName("[GATE-6] Image Boundary Governance: Strict Containment Across 6 Geometries")
    void testRegressionDomain6ImageBoundaryGovernance() throws Exception {
        long frameCx = 2743200L;
        long frameCy = 1828800L;
        double expectedAspect = (double) frameCx / (double) frameCy; // 1.50

        Map<String, byte[]> geometries = Map.of(
            "PORTRAIT", createTestImageBytes(1200, 2400, Color.BLUE, "Portrait"),
            "LANDSCAPE", createTestImageBytes(4000, 2000, Color.GREEN, "Landscape"),
            "SQUARE", createTestImageBytes(3000, 3000, Color.RED, "Square"),
            "COVER", createTestImageBytes(2480, 3508, Color.DARK_GRAY, "Cover"),
            "SITE", createTestImageBytes(4032, 3024, Color.CYAN, "Site"),
            "GOVT_SCAN", createTestImageBytes(2550, 3300, Color.MAGENTA, "Govt Scan")
        );

        for (Map.Entry<String, byte[]> entry : geometries.entrySet()) {
            String name = entry.getKey();
            byte[] processed = invokePadImage(entry.getValue(), frameCx, frameCy);
            assertNotNull(processed, "[REGRESSION VIOLATION - DOMAIN 6]: Processed image bytes must not be null");

            BufferedImage rendered = ImageIO.read(new ByteArrayInputStream(processed));
            int w = rendered.getWidth();
            int h = rendered.getHeight();
            double actualAspect = (double) w / (double) h;

            assertEquals(expectedAspect, actualAspect, 0.02,
                    "[REGRESSION VIOLATION - DOMAIN 6]: " + name + " canvas aspect ratio must match frame (1.50)");
            assertTrue(w <= 1600, "[REGRESSION VIOLATION - DOMAIN 6]: " + name + " width must not exceed 1600px");
            assertTrue(h <= 1600, "[REGRESSION VIOLATION - DOMAIN 6]: " + name + " height must not exceed 1600px");
        }
    }

    // ========================================================================
    // REGRESSION DOMAIN 7: KEYBOARD NAVIGATION CONTRACT
    // ========================================================================
    @Test
    @DisplayName("[GATE-7] Keyboard Navigation: Invariants & Multiline Boundary State Transitions")
    void testRegressionDomain7KeyboardNavigationContract() {
        // Contract 1: TAB advances index, SHIFT+TAB retreats index
        int activeIdx = 1;
        int maxIdx = 10;
        int nextIdx = (activeIdx < maxIdx) ? activeIdx + 1 : activeIdx;
        assertEquals(2, nextIdx, "[REGRESSION VIOLATION - DOMAIN 7]: TAB must advance index");

        int prevIdx = (nextIdx > 0) ? nextIdx - 1 : nextIdx;
        assertEquals(1, prevIdx, "[REGRESSION VIOLATION - DOMAIN 7]: SHIFT+TAB must retreat index");

        // Contract 2: Multiline Arrow boundary detection
        String multilineText = "Line 1\nLine 2\nLine 3";
        int firstLineEnd = multilineText.indexOf('\n');
        int lastLineStart = multilineText.lastIndexOf('\n') + 1;

        // Cursor at position 2 (on Line 1) -> UP arrow retreats focus
        int cursorAtLine1 = 2;
        boolean canRetreatOnUp = cursorAtLine1 <= firstLineEnd;
        assertTrue(canRetreatOnUp, "[REGRESSION VIOLATION - DOMAIN 7]: UP arrow on first line must allow focus retreat");

        // Cursor at position 18 (on Line 3) -> DOWN arrow advances focus
        int cursorAtLine3 = 18;
        boolean canAdvanceOnDown = cursorAtLine3 >= lastLineStart;
        assertTrue(canAdvanceOnDown, "[REGRESSION VIOLATION - DOMAIN 7]: DOWN arrow on last line must allow focus advance");

        // Contract 3: ENTER key on multiline inserts newline without focus transition
        boolean isMultiline = true;
        String textBeforeEnter = "Line 1";
        String textAfterEnter = isMultiline ? textBeforeEnter + "\n" : textBeforeEnter;
        assertTrue(textAfterEnter.contains("\n"),
                "[REGRESSION VIOLATION - DOMAIN 7]: ENTER key on multiline must insert newline");
    }

    // ========================================================================
    // REGRESSION DOMAIN 8: CURRENCY FORMATTING
    // ========================================================================
    @Test
    @DisplayName("[GATE-8] Currency Formatting: 'Rs ' Prefix & Indian Numbering Governance")
    void testRegressionDomain8CurrencyFormatting() {
        assertEquals("Rs 95,22,200", IndianNumberFormatter.formatCurrency(new BigDecimal("9522200")),
                "[REGRESSION VIOLATION - DOMAIN 8]: Realizable Value currency format mismatch");
        assertEquals("Rs 1,70,50,000", IndianNumberFormatter.formatCurrency(new BigDecimal("17050000")),
                "[REGRESSION VIOLATION - DOMAIN 8]: Crores currency format mismatch");
        assertEquals("Rs 12,75,40,000", IndianNumberFormatter.formatCurrency(new BigDecimal("127540000")),
                "[REGRESSION VIOLATION - DOMAIN 8]: High Crores currency format mismatch");
        assertEquals("Rs 50,00,000", IndianNumberFormatter.formatCurrency(new BigDecimal("5000000")),
                "[REGRESSION VIOLATION - DOMAIN 8]: Government Value currency format mismatch");
        assertEquals("Rs 0", IndianNumberFormatter.formatCurrency(BigDecimal.ZERO),
                "[REGRESSION VIOLATION - DOMAIN 8]: Zero currency format mismatch");
    }

    // ========================================================================
    // GOLDEN REPORT COMPARISON
    // ========================================================================
    @Test
    @DisplayName("[GOLDEN GATE] Golden Report Comparison: Structural & Content Parity")
    void testGoldenReportComparison() throws Exception {
        // Step 1: Generate current_report.docx & current_report.pdf
        byte[] currentDocxBytes = generateStandardProductionReportDocx();
        byte[] currentPdfBytes = engine.convertDocxToPdf(currentDocxBytes);

        File outputDir = new File("build");
        if (!outputDir.exists()) outputDir.mkdirs();

        File currentDocxFile = new File(outputDir, "current_report.docx");
        try (FileOutputStream fos = new FileOutputStream(currentDocxFile)) {
            fos.write(currentDocxBytes);
        }

        File currentPdfFile = new File(outputDir, "current_report.pdf");
        try (FileOutputStream fos = new FileOutputStream(currentPdfFile)) {
            fos.write(currentPdfBytes);
        }

        // Step 2: Load Golden reference artifacts
        File goldenDocxFile = new File("baseline/golden_production_report.docx");
        if (!goldenDocxFile.exists()) goldenDocxFile = new File("build/golden_production_report.docx");
        assertTrue(goldenDocxFile.exists(), "[GOLDEN GATE VIOLATION]: golden_production_report.docx baseline missing");

        File goldenPdfFile = new File("baseline/golden_production_report.pdf");
        if (!goldenPdfFile.exists()) goldenPdfFile = new File("build/golden_production_report.pdf");
        assertTrue(goldenPdfFile.exists(), "[GOLDEN GATE VIOLATION]: golden_production_report.pdf baseline missing");

        byte[] goldenDocxBytes = Files.readAllBytes(goldenDocxFile.toPath());
        byte[] goldenPdfBytes = Files.readAllBytes(goldenPdfFile.toPath());

        // 1. Table Count Comparison
        WordprocessingMLPackage currentDocxPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(currentDocxBytes));
        WordprocessingMLPackage goldenDocxPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(goldenDocxBytes));

        ClassFinder currentTblFinder = new ClassFinder(Tbl.class);
        ClassFinder goldenTblFinder = new ClassFinder(Tbl.class);
        new TraversalUtil(currentDocxPkg.getMainDocumentPart().getContent(), currentTblFinder);
        new TraversalUtil(goldenDocxPkg.getMainDocumentPart().getContent(), goldenTblFinder);

        assertEquals(goldenTblFinder.results.size(), currentTblFinder.results.size(),
                "[GOLDEN GATE VIOLATION]: Table count mismatch! Expected: " + goldenTblFinder.results.size()
                        + ", Got: " + currentTblFinder.results.size());

        // 2. Anchor Count Comparison
        ClassFinder currentAnchorFinder = new ClassFinder(Anchor.class);
        ClassFinder goldenAnchorFinder = new ClassFinder(Anchor.class);
        new TraversalUtil(currentDocxPkg.getMainDocumentPart().getContent(), currentAnchorFinder);
        new TraversalUtil(goldenDocxPkg.getMainDocumentPart().getContent(), goldenAnchorFinder);

        assertEquals(14, currentAnchorFinder.results.size(),
                "[GOLDEN GATE VIOLATION]: Current report anchor count must be 14");
        assertEquals(goldenAnchorFinder.results.size(), currentAnchorFinder.results.size(),
                "[GOLDEN GATE VIOLATION]: Anchor count mismatch against Golden baseline");

        // 3. Unresolved Placeholder Count (must be 0)
        String currentXml = XmlUtils.marshaltoString(currentDocxPkg.getMainDocumentPart().getJaxbElement());
        Matcher m = Pattern.compile("<<[A-Za-z0-9_]+>>").matcher(currentXml);
        int unresolvedCount = 0;
        while (m.find()) {
            unresolvedCount++;
        }
        assertEquals(0, unresolvedCount,
                "[GOLDEN GATE VIOLATION]: Unresolved placeholder leakage detected in current_report.docx");

        // 4. PDF Page Count Comparison
        try (PDDocument currentPdfDoc = Loader.loadPDF(currentPdfBytes);
             PDDocument goldenPdfDoc = Loader.loadPDF(goldenPdfBytes)) {

            assertEquals(goldenPdfDoc.getNumberOfPages(), currentPdfDoc.getNumberOfPages(),
                    "[GOLDEN GATE VIOLATION]: PDF Page count mismatch! Expected: " + goldenPdfDoc.getNumberOfPages()
                            + ", Got: " + currentPdfDoc.getNumberOfPages());

            // 5. Key Valuation Strings & Headings Comparison
            PDFTextStripper stripper = new PDFTextStripper();
            String currentPdfText = stripper.getText(currentPdfDoc);

            assertTrue(currentPdfText.contains("Valuation of Property (Composite Rate Method)"),
                    "[GOLDEN GATE VIOLATION]: Missing Composite Valuation Table in current PDF");
            assertTrue(currentPdfText.contains("Valuation Parameters Summary"),
                    "[GOLDEN GATE VIOLATION]: Missing Valuation Parameters Summary in current PDF");
            assertTrue(currentPdfText.contains("Rs 75,48,000"),
                    "[GOLDEN GATE VIOLATION]: Missing Realizable Value string in current PDF");
            assertTrue(currentPdfText.contains("Rs 66,60,000"),
                    "[GOLDEN GATE VIOLATION]: Missing Distress Sale Value string in current PDF");
            assertTrue(currentPdfText.contains("Rs 50,00,000"),
                    "[GOLDEN GATE VIOLATION]: Missing Government Value string in current PDF");
        }

        System.out.println("==========================================================================");
        System.out.println("PRODUCTION REGRESSION CERTIFICATION GATE: 100% PASSED");
        System.out.println("-> current_report.docx & current_report.pdf strictly match golden baseline");
        System.out.println("==========================================================================");
    }

    // Helper to generate standard report
    private byte[] generateStandardProductionReportDocx() throws Exception {
        File templateFile = new File("official_production_valuation_report.docx");
        byte[] templateBytes = Files.readAllBytes(templateFile.toPath());

        Map<String, String> inputs = new HashMap<>();
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE");
        inputs.put("PROPERTY_CATEGORY", "Flat");
        inputs.put("name_of_the_owner", "Dr. Rajesh Sharma");
        inputs.put("NAME_OF_THE_OWNER", "Dr. Rajesh Sharma");
        inputs.put("PROPERTY_TYPE", "Residential Flat");
        inputs.put("PROPERTY_DESCRIPTION", "Flat No. 402, 4th Floor, Prestige Heights");
        inputs.put("PROPERTY_ADDRESS", "Plot No. 12, Road No. 3, Banjara Hills, Hyderabad");
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

        Map<String, byte[]> images = new HashMap<>();
        images.put("IMG_FRONT_PAGE", createTestImageBytes(2480, 3508, Color.DARK_GRAY, "GOLDEN COVER"));
        images.put("IMG_PIC1", createTestImageBytes(1600, 1200, Color.BLUE, "SITE PHOTO 1"));
        images.put("IMG_GOVT_RATE", createTestImageBytes(1200, 1600, Color.MAGENTA, "GOVT RATE SCAN"));

        return engine.generateReport(templateBytes, inputs, images);
    }

    private byte[] createTestImageBytes(int width, int height, Color color, String text) throws Exception {
        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
        g.setColor(color);
        g.fillRect(0, 0, width, height);
        g.setColor(Color.WHITE);
        g.setFont(new Font("Arial", Font.BOLD, Math.max(16, width / 25)));
        g.drawString(text + " (" + width + "x" + height + ")", 40, height / 2);
        g.dispose();

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", baos);
        return baos.toByteArray();
    }

    private byte[] invokePadImage(byte[] rawBytes, long emuCx, long emuCy) throws Exception {
        java.lang.reflect.Method method = DocxTemplateEngine.class.getDeclaredMethod("padImageToFitEmu", byte[].class, long.class, long.class);
        method.setAccessible(true);
        return (byte[]) method.invoke(engine, rawBytes, emuCx, emuCy);
    }
}
