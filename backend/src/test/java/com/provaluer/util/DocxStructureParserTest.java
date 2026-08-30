package com.provaluer.util;

import com.fasterxml.jackson.databind.JsonNode;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.math.BigInteger;

import static org.junit.jupiter.api.Assertions.*;

public class DocxStructureParserTest {

    private DocxStructureParser parser;
    private ObjectFactory factory;

    @BeforeEach
    public void setUp() {
        parser = new DocxStructureParser();
        factory = new ObjectFactory();
    }

    private byte[] packageToBytes(WordprocessingMLPackage wordMLPackage) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        wordMLPackage.save(out);
        return out.toByteArray();
    }

    @Test
    @DisplayName("1. Placeholder inside a single Word run")
    public void testSingleRunPlaceholder() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue("Valuation for <<CLIENT_NAME>> details.");
        r.getContent().add(t);
        p.getContent().add(r);
        wordMLPackage.getMainDocumentPart().getContent().add(p);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        assertNotNull(root);
        assertTrue(root.has("sections"));
        assertTrue(root.has("placeholdersSummary"));

        JsonNode summary = root.get("placeholdersSummary");
        assertEquals(1, summary.size());
        assertEquals("CLIENT_NAME", summary.get(0).get("key").asText());
        assertEquals("Client Name", summary.get(0).get("label").asText());
        assertEquals(1, summary.get(0).get("occurrences").asInt());
        assertEquals("TEXT", summary.get(0).get("type").asText());

        // Inspect runs in section
        JsonNode runs = root.get("sections").get(0).get("elements").get(0).get("runs");
        assertTrue(runs.size() >= 2);
        boolean foundPlaceholderRun = false;
        for (JsonNode run : runs) {
            if (run.get("isPlaceholder").asBoolean() && "CLIENT_NAME".equals(run.get("placeholderKey").asText())) {
                foundPlaceholderRun = true;
                break;
            }
        }
        assertTrue(foundPlaceholderRun, "Placeholder run must be isolated in paragraph runs");
    }

    @Test
    @DisplayName("2. Placeholder split across multiple Word runs (e.g. <<CLI and ENT_NAME>>)")
    public void testSplitRunPlaceholder() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        P p = factory.createP();

        // Run 1: "<<CLI"
        R r1 = factory.createR();
        Text t1 = factory.createText();
        t1.setValue("<<CLI");
        r1.getContent().add(t1);
        p.getContent().add(r1);

        // Run 2: "ENT_NAME>>"
        R r2 = factory.createR();
        Text t2 = factory.createText();
        t2.setValue("ENT_NAME>>");
        r2.getContent().add(t2);
        p.getContent().add(r2);

        wordMLPackage.getMainDocumentPart().getContent().add(p);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode summary = root.get("placeholdersSummary");
        assertEquals(1, summary.size(), "Fragmented placeholder runs must stitch into 1 token");
        assertEquals("CLIENT_NAME", summary.get(0).get("key").asText());
        assertEquals(1, summary.get(0).get("occurrences").asInt());
    }

    @Test
    @DisplayName("3. Multiple placeholders in one paragraph")
    public void testMultiplePlaceholdersInOneParagraph() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue("Client: <<CLIENT_NAME>>, Property: <<PROPERTY_ADDRESS>>, Date: <<INSPECTION_DATE>>.");
        r.getContent().add(t);
        p.getContent().add(r);
        wordMLPackage.getMainDocumentPart().getContent().add(p);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode summary = root.get("placeholdersSummary");
        assertEquals(3, summary.size());

        assertEquals("CLIENT_NAME", summary.get(0).get("key").asText());
        assertEquals("TEXT", summary.get(0).get("type").asText());

        assertEquals("PROPERTY_ADDRESS", summary.get(1).get("key").asText());
        assertEquals("TEXT", summary.get(1).get("type").asText());

        assertEquals("INSPECTION_DATE", summary.get(2).get("key").asText());
        assertEquals("DATE", summary.get(2).get("type").asText());
    }

    @Test
    @DisplayName("4. Placeholder occurrence counting across multiple paragraphs")
    public void testPlaceholderOccurrenceCounting() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();

        // Paragraph 1
        P p1 = factory.createP();
        R r1 = factory.createR();
        Text t1 = factory.createText();
        t1.setValue("First mention of <<CLIENT_NAME>>.");
        r1.getContent().add(t1);
        p1.getContent().add(r1);
        wordMLPackage.getMainDocumentPart().getContent().add(p1);

        // Paragraph 2
        P p2 = factory.createP();
        R r2 = factory.createR();
        Text t2 = factory.createText();
        t2.setValue("Second confirmation for <<CLIENT_NAME>>.");
        r2.getContent().add(t2);
        p2.getContent().add(r2);
        wordMLPackage.getMainDocumentPart().getContent().add(p2);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode summary = root.get("placeholdersSummary");
        assertEquals(1, summary.size());
        assertEquals("CLIENT_NAME", summary.get(0).get("key").asText());
        assertEquals(2, summary.get(0).get("occurrences").asInt());
    }

    @Test
    @DisplayName("5. Placeholder detection inside table cells")
    public void testPlaceholderInsideTableCell() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl table = factory.createTbl();
        Tr row = factory.createTr();
        Tc cell = factory.createTc();

        P p = factory.createP();
        R r = factory.createR();
        Text t = factory.createText();
        t.setValue("Rate: <<LAND_RATE>>");
        r.getContent().add(t);
        p.getContent().add(r);
        cell.getContent().add(p);

        row.getContent().add(cell);
        table.getContent().add(row);
        wordMLPackage.getMainDocumentPart().getContent().add(table);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode summary = root.get("placeholdersSummary");
        assertEquals(1, summary.size());
        assertEquals("LAND_RATE", summary.get(0).get("key").asText());
        assertEquals("NUMBER", summary.get(0).get("type").asText());

        JsonNode element = root.get("sections").get(0).get("elements").get(0);
        assertEquals("TABLE", element.get("type").asText());
        assertEquals(1, element.get("rowCount").asInt());
        assertEquals(1, element.get("columnCount").asInt());
    }

    @Test
    @DisplayName("6. Merged cell parsing (colSpan and vMerge)")
    public void testMergedCellParsing() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl table = factory.createTbl();
        Tr row = factory.createTr();

        // Cell with colSpan = 2 and vMerge = "restart"
        Tc cell = factory.createTc();
        TcPr tcPr = factory.createTcPr();

        TcPrInner.GridSpan gridSpan = factory.createTcPrInnerGridSpan();
        gridSpan.setVal(BigInteger.valueOf(2));
        tcPr.setGridSpan(gridSpan);

        TcPrInner.VMerge vMerge = factory.createTcPrInnerVMerge();
        vMerge.setVal("restart");
        tcPr.setVMerge(vMerge);

        cell.setTcPr(tcPr);
        row.getContent().add(cell);
        table.getContent().add(row);
        wordMLPackage.getMainDocumentPart().getContent().add(table);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode cellNode = root.get("sections").get(0).get("elements").get(0).get("rows").get(0).get("cells").get(0);
        assertEquals(2, cellNode.get("colSpan").asInt());
        assertEquals("restart", cellNode.get("vMerge").asText());
    }

    @Test
    @DisplayName("7. Image representation in runs")
    public void testImageRepresentation() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        P p = factory.createP();
        R r = factory.createR();

        Drawing drawing = factory.createDrawing();
        r.getContent().add(drawing);
        p.getContent().add(r);
        wordMLPackage.getMainDocumentPart().getContent().add(p);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode runs = root.get("sections").get(0).get("elements").get(0).get("runs");
        assertEquals(1, runs.size());
        assertEquals("IMAGE", runs.get(0).get("type").asText());
        assertTrue(runs.get(0).get("present").asBoolean());
    }

    @Test
    @DisplayName("8. Empty document handling")
    public void testEmptyDocumentHandling() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        // Clear default body contents
        wordMLPackage.getMainDocumentPart().getContent().clear();

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        assertNotNull(root);
        assertTrue(root.has("sections"));
        assertTrue(root.has("placeholdersSummary"));
        assertEquals(0, root.get("placeholdersSummary").size());
    }

    @Test
    @DisplayName("9. Invalid DOCX byte stream handling")
    public void testInvalidDocxHandling() {
        byte[] invalidBytes = "This is not a valid zip or docx archive".getBytes();
        assertThrows(Exception.class, () -> parser.parseDocumentStructure(invalidBytes));
    }

    @Test
    @DisplayName("10. Null or zero-byte input handling")
    public void testNullOrEmptyInputHandling() {
        assertThrows(IllegalArgumentException.class, () -> parser.parseDocumentStructure((byte[]) null));
        assertThrows(IllegalArgumentException.class, () -> parser.parseDocumentStructure(new byte[0]));
    }

    @Test
    @DisplayName("11. Semantic Analysis: 3-Column Table Row Classification")
    public void testThreeColumnTableSemanticClassification() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl table = factory.createTbl();

        // Row 0: Table Header
        Tr headerRow = factory.createTr();
        headerRow.getContent().add(createCellWithText("S.No"));
        headerRow.getContent().add(createCellWithText("Particulars"));
        headerRow.getContent().add(createCellWithText("Observed Details"));
        table.getContent().add(headerRow);

        // Row 1: 3-column Q&A row
        Tr qaRow = factory.createTr();
        qaRow.getContent().add(createCellWithText("1"));
        qaRow.getContent().add(createCellWithText("Name of owner(s) and address"));
        qaRow.getContent().add(createCellWithText("<<CLIENT_NAME>>"));
        table.getContent().add(qaRow);

        wordMLPackage.getMainDocumentPart().getContent().add(table);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode tableNode = root.get("sections").get(0).get("elements").get(0);
        assertEquals("TABLE", tableNode.get("type").asText());

        // Verify Row 0 (Header)
        JsonNode row0 = tableNode.get("rows").get(0);
        assertEquals("TABLE_HEADER", row0.get("rowType").asText());
        assertEquals("HEADER", row0.get("cells").get(0).get("cellRole").asText());
        assertEquals("HEADER", row0.get("cells").get(1).get("cellRole").asText());
        assertEquals("HEADER", row0.get("cells").get(2).get("cellRole").asText());

        // Verify Row 1 (Q&A)
        JsonNode row1 = tableNode.get("rows").get(1);
        assertEquals("QUESTION_ANSWER", row1.get("rowType").asText());

        JsonNode cell0 = row1.get("cells").get(0);
        assertEquals("INDEX", cell0.get("cellRole").asText());
        assertEquals("1", cell0.get("plainText").asText());

        JsonNode cell1 = row1.get("cells").get(1);
        assertEquals("QUESTION", cell1.get("cellRole").asText());
        assertEquals("Name of owner(s) and address", cell1.get("plainText").asText());
        assertTrue(cell1.has("targetAnswerCellId"));

        JsonNode cell2 = row1.get("cells").get(2);
        assertEquals("ANSWER", cell2.get("cellRole").asText());
        assertEquals(cell1.get("cellId").asText(), cell2.get("sourceQuestionCellId").asText());

        JsonNode bindings = cell2.get("placeholderBindings");
        assertNotNull(bindings);
        assertEquals(1, bindings.size());
        assertEquals("CLIENT_NAME", bindings.get(0).get("key").asText());
        assertEquals("1", bindings.get(0).get("serialNo").asText());
        assertEquals("Name of owner(s) and address", bindings.get(0).get("questionText").asText());

        // Verify placeholdersSummary enrichment
        JsonNode summary = root.get("placeholdersSummary");
        assertEquals(1, summary.size());
        assertEquals("CLIENT_NAME", summary.get(0).get("key").asText());
        assertEquals("Name of owner(s) and address", summary.get(0).get("questionText").asText());
        assertEquals("1", summary.get(0).get("serialNo").asText());
        assertEquals("TABLE_ROW", summary.get(0).get("source").asText());
        assertTrue(summary.get(0).has("tableContext"));
    }

    @Test
    @DisplayName("12. Semantic Analysis: 2-Column Table Row Classification")
    public void testTwoColumnTableSemanticClassification() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl table = factory.createTbl();

        // Row 0: 2-column Q&A row
        Tr qaRow = factory.createTr();
        qaRow.getContent().add(createCellWithText("Purpose of Valuation"));
        qaRow.getContent().add(createCellWithText("<<VALUATION_PURPOSE>>"));
        table.getContent().add(qaRow);

        wordMLPackage.getMainDocumentPart().getContent().add(table);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode tableNode = root.get("sections").get(0).get("elements").get(0);
        JsonNode row0 = tableNode.get("rows").get(0);
        assertEquals("QUESTION_ANSWER", row0.get("rowType").asText());

        JsonNode cell0 = row0.get("cells").get(0);
        assertEquals("QUESTION", cell0.get("cellRole").asText());
        assertEquals("Purpose of Valuation", cell0.get("plainText").asText());

        JsonNode cell1 = row0.get("cells").get(1);
        assertEquals("ANSWER", cell1.get("cellRole").asText());

        JsonNode summary = root.get("placeholdersSummary");
        assertEquals(1, summary.size());
        assertEquals("VALUATION_PURPOSE", summary.get(0).get("key").asText());
        assertEquals("Purpose of Valuation", summary.get(0).get("questionText").asText());
    }

    @Test
    @DisplayName("13. Semantic Analysis: Merged Section Sub-header Row")
    public void testMergedSubheaderClassification() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl table = factory.createTbl();

        // Merged Subheader Row (colSpan = 3)
        Tr subheaderRow = factory.createTr();
        Tc cell = createCellWithText("SECTION A: BOUNDARIES AND EXTENT");
        TcPr tcPr = factory.createTcPr();
        TcPrInner.GridSpan gridSpan = factory.createTcPrInnerGridSpan();
        gridSpan.setVal(BigInteger.valueOf(3));
        tcPr.setGridSpan(gridSpan);
        cell.setTcPr(tcPr);
        subheaderRow.getContent().add(cell);
        table.getContent().add(subheaderRow);

        wordMLPackage.getMainDocumentPart().getContent().add(table);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode tableNode = root.get("sections").get(0).get("elements").get(0);
        JsonNode row0 = tableNode.get("rows").get(0);
        assertEquals("SECTION_SUBHEADER", row0.get("rowType").asText());
        assertEquals("HEADER", row0.get("cells").get(0).get("cellRole").asText());
        assertTrue(row0.get("cells").get(0).get("isSubHeader").asBoolean());
    }

    @Test
    @DisplayName("14. Semantic Analysis: Multi-Placeholder Answer Cell")
    public void testMultiPlaceholderAnswerCell() throws Exception {
        WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
        Tbl table = factory.createTbl();

        Tr row = factory.createTr();
        row.getContent().add(createCellWithText("Plot Dimensions (Length x Width)"));
        row.getContent().add(createCellWithText("<<PLOT_LENGTH>> ft x <<PLOT_WIDTH>> ft"));
        table.getContent().add(row);

        wordMLPackage.getMainDocumentPart().getContent().add(table);

        byte[] bytes = packageToBytes(wordMLPackage);
        JsonNode root = parser.parseDocumentStructure(bytes);

        JsonNode summary = root.get("placeholdersSummary");
        assertEquals(2, summary.size());

        assertEquals("PLOT_LENGTH", summary.get(0).get("key").asText());
        assertEquals("Plot Dimensions (Length x Width)", summary.get(0).get("questionText").asText());

        assertEquals("PLOT_WIDTH", summary.get(1).get("key").asText());
        assertEquals("Plot Dimensions (Length x Width)", summary.get(1).get("questionText").asText());
    }

    private Tc createCellWithText(String text) {
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
}
