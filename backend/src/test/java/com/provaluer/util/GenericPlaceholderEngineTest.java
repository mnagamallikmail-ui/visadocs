package com.provaluer.util;

import com.fasterxml.jackson.databind.JsonNode;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class GenericPlaceholderEngineTest {

    private DocxTemplateEngine templateEngine;
    private DocxStructureParser parser;
    private ObjectFactory factory;

    @BeforeEach
    public void setUp() {
        templateEngine = new DocxTemplateEngine();
        parser = new DocxStructureParser();
        factory = new ObjectFactory();
    }

    private byte[] packageToBytes(WordprocessingMLPackage wordMLPackage) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wordMLPackage.save(out);
        return out.toByteArray();
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

    @Test
    @DisplayName("1. Two-column table: Question + <<TEXT>> becomes <<QUESTION_KEY_1>>")
    public void testTwoColumnTableGenericPlaceholder() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        // Row 1: Layout Plan (Yes / No) | <<TEXT>>
        Tr row1 = factory.createTr();
        row1.getContent().add(createCell("Layout Plan (Yes / No)"));
        row1.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(row1);

        // Row 2: Building Plan (Yes / No) | <<TEXT>>
        Tr row2 = factory.createTr();
        row2.getContent().add(createCell("Building Plan (Yes / No)"));
        row2.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(row2);

        wordMLPackage.getMainDocumentPart().getContent().add(tbl);
        byte[] rawBytes = packageToBytes(wordMLPackage);

        // Normalization
        GenericPlaceholderNormalizer.TemplateAnalysisReport report = new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, report);

        assertEquals(2, report.getTotalGeneratedFields());

        // Parse structure
        JsonNode dom = parser.parseDocumentStructure(normalizedBytes);
        JsonNode summary = dom.get("placeholdersSummary");
        assertEquals(2, summary.size());

        // Verify keys
        assertEquals("LAYOUT_PLAN_YES_NO_1", summary.get(0).get("key").asText());
        assertEquals("Layout Plan (Yes / No)", summary.get(0).get("questionText").asText());
        assertEquals("Layout Plan (Yes / No)", summary.get(0).get("label").asText());

        assertEquals("BUILDING_PLAN_YES_NO_1", summary.get(1).get("key").asText());
        assertEquals("Building Plan (Yes / No)", summary.get(1).get("questionText").asText());
    }

    @Test
    @DisplayName("2. Three-column table: Serial + Question + <<TEXT>>")
    public void testThreeColumnTableGenericPlaceholder() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        // Header Row
        Tr header = factory.createTr();
        header.getContent().add(createCell("S.No"));
        header.getContent().add(createCell("Item Description"));
        header.getContent().add(createCell("Observed Value"));
        tbl.getContent().add(header);

        // Row 1: 1 | Construction Permission (Yes / No) | <<TEXT>>
        Tr r1 = factory.createTr();
        r1.getContent().add(createCell("1"));
        r1.getContent().add(createCell("Construction Permission (Yes / No)"));
        r1.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(r1);

        wordMLPackage.getMainDocumentPart().getContent().add(tbl);
        byte[] rawBytes = packageToBytes(wordMLPackage);

        GenericPlaceholderNormalizer.TemplateAnalysisReport report = new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, report);

        JsonNode dom = parser.parseDocumentStructure(normalizedBytes);
        JsonNode summary = dom.get("placeholdersSummary");
        assertEquals(1, summary.size());

        JsonNode item = summary.get(0);
        assertEquals("CONSTRUCTION_PERMISSION_YES_NO_1", item.get("key").asText());
        assertEquals("Construction Permission (Yes / No)", item.get("questionText").asText());
        assertEquals("1", item.get("serialNo").asText());
    }

    @Test
    @DisplayName("3. Multi-column table: Interleaved Question/Answer Grid")
    public void testMultiColumnTableGenericPlaceholder() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        // 4-Column Row: Q1 | <<TEXT>> | Q2 | <<TEXT>>
        Tr row = factory.createTr();
        row.getContent().add(createCell("Water Supply Available"));
        row.getContent().add(createCell("<<TEXT>>"));
        row.getContent().add(createCell("Electricity Connected"));
        row.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(row);

        wordMLPackage.getMainDocumentPart().getContent().add(tbl);
        byte[] rawBytes = packageToBytes(wordMLPackage);

        GenericPlaceholderNormalizer.TemplateAnalysisReport report = new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, report);

        JsonNode dom = parser.parseDocumentStructure(normalizedBytes);
        JsonNode summary = dom.get("placeholdersSummary");
        assertEquals(2, summary.size());

        assertEquals("WATER_SUPPLY_AVAILABLE_1", summary.get(0).get("key").asText());
        assertEquals("Water Supply Available", summary.get(0).get("questionText").asText());

        assertEquals("ELECTRICITY_CONNECTED_1", summary.get(1).get("key").asText());
        assertEquals("Electricity Connected", summary.get(1).get("questionText").asText());
    }

    @Test
    @DisplayName("4. Duplicate questions disambiguation: REMARKS_1, REMARKS_2, REMARKS_3")
    public void testDuplicateQuestionsDisambiguation() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        // Row 1: Remarks | <<TEXT>>
        Tr r1 = factory.createTr();
        r1.getContent().add(createCell("Remarks"));
        r1.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(r1);

        // Row 2: Remarks | <<TEXT>>
        Tr r2 = factory.createTr();
        r2.getContent().add(createCell("Remarks"));
        r2.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(r2);

        // Row 3: Remarks | <<TEXT>>
        Tr r3 = factory.createTr();
        r3.getContent().add(createCell("Remarks"));
        r3.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(r3);

        wordMLPackage.getMainDocumentPart().getContent().add(tbl);
        byte[] rawBytes = packageToBytes(wordMLPackage);

        GenericPlaceholderNormalizer.TemplateAnalysisReport report = new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, report);

        assertEquals(3, report.getTotalGeneratedFields());

        JsonNode dom = parser.parseDocumentStructure(normalizedBytes);
        JsonNode summary = dom.get("placeholdersSummary");
        assertEquals(3, summary.size());

        assertEquals("REMARKS_1", summary.get(0).get("key").asText());
        assertEquals("REMARKS_2", summary.get(1).get("key").asText());
        assertEquals("REMARKS_3", summary.get(2).get("key").asText());

        // All retain original question label "Remarks"
        assertEquals("Remarks", summary.get(0).get("questionText").asText());
        assertEquals("Remarks", summary.get(1).get("questionText").asText());
        assertEquals("Remarks", summary.get(2).get("questionText").asText());
    }

    @Test
    @DisplayName("5. Master placeholder exemption: REPORT_DATE and FAIR_VALUE remain untouched")
    public void testMasterPlaceholderExemption() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        // Row 1: Date of Report | <<REPORT_DATE>>
        Tr r1 = factory.createTr();
        r1.getContent().add(createCell("Date of Report"));
        r1.getContent().add(createCell("<<REPORT_DATE>>"));
        tbl.getContent().add(r1);

        // Row 2: Fair Value | <<FAIR_VALUE>>
        Tr r2 = factory.createTr();
        r2.getContent().add(createCell("Fair Market Value"));
        r2.getContent().add(createCell("<<FAIR_VALUE>>"));
        tbl.getContent().add(r2);

        wordMLPackage.getMainDocumentPart().getContent().add(tbl);
        byte[] rawBytes = packageToBytes(wordMLPackage);

        GenericPlaceholderNormalizer.TemplateAnalysisReport report = new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, report);

        // 0 generated fields because both are master placeholders
        assertEquals(0, report.getTotalGeneratedFields());
        assertTrue(report.getMasterPlaceholders().contains("REPORT_DATE"));
        assertTrue(report.getMasterPlaceholders().contains("FAIR_VALUE"));

        JsonNode dom = parser.parseDocumentStructure(normalizedBytes);
        JsonNode summary = dom.get("placeholdersSummary");
        assertEquals(2, summary.size());

        assertEquals("REPORT_DATE", summary.get(0).get("key").asText());
        assertEquals("FAIR_VALUE", summary.get(1).get("key").asText());
    }

    @Test
    @DisplayName("6. Mixed template: Generic <<TEXT>>, Master Placeholders, and explicit custom placeholders")
    public void testMixedTemplate() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        // Generic <<TEXT>>
        Tr r1 = factory.createTr();
        r1.getContent().add(createCell("Municipal Corporation Approval"));
        r1.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(r1);

        // Master placeholder
        Tr r2 = factory.createTr();
        r2.getContent().add(createCell("Valuation Date"));
        r2.getContent().add(createCell("<<REPORT_DATE>>"));
        tbl.getContent().add(r2);

        // Explicit custom placeholder
        Tr r3 = factory.createTr();
        r3.getContent().add(createCell("Borrower Name"));
        r3.getContent().add(createCell("<<CLIENT_NAME>>"));
        tbl.getContent().add(r3);

        wordMLPackage.getMainDocumentPart().getContent().add(tbl);
        byte[] rawBytes = packageToBytes(wordMLPackage);

        GenericPlaceholderNormalizer.TemplateAnalysisReport report = new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, report);

        assertEquals(1, report.getTotalGeneratedFields());
        assertTrue(report.getMasterPlaceholders().contains("REPORT_DATE"));

        JsonNode dom = parser.parseDocumentStructure(normalizedBytes);
        JsonNode summary = dom.get("placeholdersSummary");
        assertEquals(3, summary.size());

        assertEquals("MUNICIPAL_CORPORATION_APPROVAL_1", summary.get(0).get("key").asText());
        assertEquals("REPORT_DATE", summary.get(1).get("key").asText());
        assertEquals("CLIENT_NAME", summary.get(2).get("key").asText());
    }

    @Test
    @DisplayName("7. End-to-end report generation: Independent hydration and zero synchronization")
    public void testEndToEndReportGenerationIndependentHydration() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl tbl = factory.createTbl();

        // Row 1: Layout Plan | <<TEXT>>
        Tr r1 = factory.createTr();
        r1.getContent().add(createCell("Layout Plan (Yes / No)"));
        r1.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(r1);

        // Row 2: Building Plan | <<TEXT>>
        Tr r2 = factory.createTr();
        r2.getContent().add(createCell("Building Plan (Yes / No)"));
        r2.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(r2);

        // Row 3: Remarks | <<TEXT>>
        Tr r3 = factory.createTr();
        r3.getContent().add(createCell("Remarks"));
        r3.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(r3);

        // Row 4: Remarks | <<TEXT>>
        Tr r4 = factory.createTr();
        r4.getContent().add(createCell("Remarks"));
        r4.getContent().add(createCell("<<TEXT>>"));
        tbl.getContent().add(r4);

        wordMLPackage.getMainDocumentPart().getContent().add(tbl);
        byte[] rawBytes = packageToBytes(wordMLPackage);

        // 1. Template Normalization
        GenericPlaceholderNormalizer.TemplateAnalysisReport report = new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, report);

        // 2. Prepare independent input answers
        Map<String, String> inputs = new HashMap<>();
        inputs.put("LAYOUT_PLAN_YES_NO_1", "Yes, Approved Ref #LP-8849");
        inputs.put("BUILDING_PLAN_YES_NO_1", "No, Under Municipal Review");
        inputs.put("REMARKS_1", "First section civil remarks: all pillars verified.");
        inputs.put("REMARKS_2", "Second section legal remarks: clear market title.");

        // 3. Hydrate report
        byte[] compiledDocx = templateEngine.generateReport(normalizedBytes, inputs, new HashMap<>());
        assertNotNull(compiledDocx);
        assertTrue(compiledDocx.length > 0);

        // 4. Verify compiled report content
        WordprocessingMLPackage resultDoc = WordprocessingMLPackage.load(new ByteArrayInputStream(compiledDocx));
        Tbl resultTbl = null;
        for (Object elem : resultDoc.getMainDocumentPart().getContent()) {
            Object unwrapped = unwrap(elem);
            if (unwrapped instanceof Tbl) {
                resultTbl = (Tbl) unwrapped;
                break;
            }
        }
        assertNotNull(resultTbl, "Result table must be present in compiled document");

        java.util.List<Tr> resultRows = new java.util.ArrayList<>();
        for (Object rObj : resultTbl.getContent()) {
            Object unwrappedR = unwrap(rObj);
            if (unwrappedR instanceof Tr) {
                resultRows.add((Tr) unwrappedR);
            }
        }
        assertTrue(resultRows.size() >= 4);

        String textR1 = getCellContentText(getSecondCell(resultRows.get(0)));
        String textR2 = getCellContentText(getSecondCell(resultRows.get(1)));
        String textR3 = getCellContentText(getSecondCell(resultRows.get(2)));
        String textR4 = getCellContentText(getSecondCell(resultRows.get(3)));

        // Each cell has its independent value
        assertEquals("Yes, Approved Ref #LP-8849", textR1.trim());
        assertEquals("No, Under Municipal Review", textR2.trim());
        assertEquals("First section civil remarks: all pillars verified.", textR3.trim());
        assertEquals("Second section legal remarks: clear market title.", textR4.trim());

        // Zero accidental cross-synchronization
        assertNotEquals(textR1, textR2);
        assertNotEquals(textR3, textR4);
    }

    @Test
    @DisplayName("8. Standalone paragraphs with <<TEXT>> receive independent unique keys and values")
    public void testStandaloneParagraphGenericTextUniquification() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();

        // Paragraph A: Introduction section: <<TEXT>>
        wordMLPackage.getMainDocumentPart().getContent().add(createParagraphWithText("Introduction section: <<TEXT>>"));
        // Paragraph B: Observation section: <<TEXT>>
        wordMLPackage.getMainDocumentPart().getContent().add(createParagraphWithText("Observation section: <<TEXT>>"));
        // Paragraph C: Remarks section: <<TEXT>>
        wordMLPackage.getMainDocumentPart().getContent().add(createParagraphWithText("Remarks section: <<TEXT>>"));

        byte[] rawBytes = packageToBytes(wordMLPackage);

        // 1. Template normalization
        GenericPlaceholderNormalizer.TemplateAnalysisReport report = new GenericPlaceholderNormalizer.TemplateAnalysisReport();
        byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes, report);

        assertEquals(3, report.getTotalGeneratedFields());

        // Parse DOM structure to verify workspace summary fields
        JsonNode dom = parser.parseDocumentStructure(normalizedBytes);
        JsonNode summary = dom.get("placeholdersSummary");
        assertEquals(3, summary.size());
        assertEquals("TEXT_001", summary.get(0).get("key").asText());
        assertEquals("TEXT_002", summary.get(1).get("key").asText());
        assertEquals("TEXT_003", summary.get(2).get("key").asText());

        // 2. Hydrate with distinct values
        Map<String, String> inputs = new HashMap<>();
        inputs.put("TEXT_001", "Introduction");
        inputs.put("TEXT_002", "Observation");
        inputs.put("TEXT_003", "Remarks");

        byte[] compiledDocx = templateEngine.generateReport(normalizedBytes, inputs, new HashMap<>());
        assertNotNull(compiledDocx);

        // 3. Verify final hydrated document
        WordprocessingMLPackage resultDoc = WordprocessingMLPackage.load(new ByteArrayInputStream(compiledDocx));
        StringBuilder fullText = new StringBuilder();
        for (Object o : resultDoc.getMainDocumentPart().getContent()) {
            Object unwrapped = unwrap(o);
            if (unwrapped instanceof P) {
                fullText.append(getParagraphContentText((P) unwrapped)).append("\n");
            }
        }

        String docText = fullText.toString();
        assertTrue(docText.contains("Introduction section: Introduction"));
        assertTrue(docText.contains("Observation section: Observation"));
        assertTrue(docText.contains("Remarks section: Remarks"));
        assertFalse(docText.contains("<<TEXT>>"));
    }

    @Test
    @DisplayName("9. Image Governance: only IMG_ and IMAGE_ prefixes qualify as IMAGE; all others are non-image")
    public void testImagePlaceholderGovernance() throws Exception {
        assertTrue(DocxStructureParser.isExplicitImagePlaceholder("IMG_SITE_1"));
        assertTrue(DocxStructureParser.isExplicitImagePlaceholder("IMG_SITE_2"));
        assertTrue(DocxStructureParser.isExplicitImagePlaceholder("IMG_FRONT_PAGE"));
        assertTrue(DocxStructureParser.isExplicitImagePlaceholder("IMG_COVER_PAGE"));
        assertTrue(DocxStructureParser.isExplicitImagePlaceholder("IMG_LOCATION"));
        assertTrue(DocxStructureParser.isExplicitImagePlaceholder("IMG_GOVT_RATE"));
        assertTrue(DocxStructureParser.isExplicitImagePlaceholder("IMAGE_SITE_PHOTO_1"));

        // Non-image placeholders MUST be rejected by image classification
        assertFalse(DocxStructureParser.isExplicitImagePlaceholder("PROPERTY_PHOTO"));
        assertFalse(DocxStructureParser.isExplicitImagePlaceholder("OWNER_NAME"));
        assertFalse(DocxStructureParser.isExplicitImagePlaceholder("SELFIE"));
        assertFalse(DocxStructureParser.isExplicitImagePlaceholder("SIGNATURE"));
        assertFalse(DocxStructureParser.isExplicitImagePlaceholder("SITE_PHOTO"));
        assertFalse(DocxStructureParser.isExplicitImagePlaceholder("FRONT_PAGE_IMAGE"));
        assertFalse(DocxStructureParser.isExplicitImagePlaceholder("LOCATION_IMG"));
    }

    private P createParagraphWithText(String text) {
        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue(text);
        r.getContent().add(t);
        p.getContent().add(r);
        return p;
    }

    private String getParagraphContentText(P p) {
        StringBuilder sb = new StringBuilder();
        for (Object rObj : p.getContent()) {
            Object unwrappedR = unwrap(rObj);
            if (unwrappedR instanceof R) {
                R r = (R) unwrappedR;
                for (Object tObj : r.getContent()) {
                    Object unwrappedT = unwrap(tObj);
                    if (unwrappedT instanceof Text) {
                        sb.append(((Text) unwrappedT).getValue());
                    }
                }
            }
        }
        return sb.toString();
    }

    private Object unwrap(Object obj) {
        if (obj instanceof jakarta.xml.bind.JAXBElement) {
            return ((jakarta.xml.bind.JAXBElement<?>) obj).getValue();
        }
        return obj;
    }

    private Tc getSecondCell(Tr row) {
        java.util.List<Tc> cells = new java.util.ArrayList<>();
        for (Object cObj : row.getContent()) {
            Object unwrapped = unwrap(cObj);
            if (unwrapped instanceof Tc) {
                cells.add((Tc) unwrapped);
            }
        }
        return cells.get(1);
    }

    private String getCellContentText(Tc cell) {
        StringBuilder sb = new StringBuilder();
        for (Object pObj : cell.getContent()) {
            Object unwrappedP = unwrap(pObj);
            if (unwrappedP instanceof P) {
                P p = (P) unwrappedP;
                for (Object rObj : p.getContent()) {
                    Object unwrappedR = unwrap(rObj);
                    if (unwrappedR instanceof R) {
                        R r = (R) unwrappedR;
                        for (Object tObj : r.getContent()) {
                            Object unwrappedT = unwrap(tObj);
                            if (unwrappedT instanceof Text) {
                                sb.append(((Text) unwrappedT).getValue());
                            }
                        }
                    }
                }
            }
        }
        return sb.toString();
    }
}
