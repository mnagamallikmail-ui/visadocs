package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.XmlUtils;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.openpackaging.parts.WordprocessingML.MainDocumentPart;
import org.docx4j.wml.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

import java.io.ByteArrayInputStream;
import java.math.BigInteger;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class ReportPolishingFinalStandardizationTest {

    @Autowired
    private DocxTemplateEngine docxTemplateEngine;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("Runtime Verification: Report Polishing & Final Table Standardization (All Phases)")
    public void testReportPolishingAndTableStandardization() throws Exception {
        System.out.println("========================================================================");
        System.out.println("REPORT POLISHING & FINAL TABLE STANDARDIZATION RUNTIME VERIFICATION");
        System.out.println("========================================================================");

        // 1. Prepare realistic valuation template with all dynamic table markers
        WordprocessingMLPackage templatePkg = WordprocessingMLPackage.createPackage();
        MainDocumentPart mainPart = templatePkg.getMainDocumentPart();
        ObjectFactory factory = new ObjectFactory();

        P p1 = factory.createP();
        R r1 = factory.createR();
        Text t1 = factory.createText();
        t1.setValue("<<LAND_TABLE>>");
        r1.getContent().add(t1);
        p1.getContent().add(r1);
        mainPart.getContent().add(p1);

        P p2 = factory.createP();
        R r2 = factory.createR();
        Text t2 = factory.createText();
        t2.setValue("<<BUILDING_TABLE>>");
        r2.getContent().add(t2);
        p2.getContent().add(r2);
        mainPart.getContent().add(p2);

        P p3 = factory.createP();
        R r3 = factory.createR();
        Text t3 = factory.createText();
        t3.setValue("<<PROPERTY_VALUE_TABLE>>");
        r3.getContent().add(t3);
        p3.getContent().add(r3);
        mainPart.getContent().add(p3);

        P p4 = factory.createP();
        R r4 = factory.createR();
        Text t4 = factory.createText();
        t4.setValue("<<VALUATION_SUMMARY_TABLE>>");
        r4.getContent().add(t4);
        p4.getContent().add(r4);
        mainPart.getContent().add(p4);

        java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
        templatePkg.save(baos);
        byte[] templateBytes = baos.toByteArray();

        // 2. Prepare mock valuation inputs (single parcel & single building to test < 7 row pagination rule)
        Map<String, String> inputs = new HashMap<>();
        List<Map<String, Object>> landItems = List.of(
                Map.of("description", "Commercial Land", "surveyNo", "101/A", "enteredArea", "2500", "enteredUnit", "Sq.Ft", "rate", "4000", "value", "10000000")
        );
        inputs.put("RAW_LAND_ITEMS_JSON", objectMapper.writeValueAsString(landItems));
        inputs.put("TOTAL_LAND_VALUE", "10000000");
        inputs.put("SAY_LAND_VALUE", "10000000");

        List<Map<String, Object>> buildingItems = List.of(
                Map.of("description", "RCC Commercial Complex", "buildingType", "RCC Commercial", "enteredArea", "5000", "enteredUnit", "Sq.Ft", "replacementRate", "3000", "replacementCost", "15000000", "depreciationAmount", "3000000", "buildingValue", "12000000")
        );
        inputs.put("RAW_BUILDING_ITEMS_JSON", objectMapper.writeValueAsString(buildingItems));
        inputs.put("TOTAL_BUILDING_VALUE", "12000000");
        inputs.put("SAY_BUILDING_VALUE", "12000000");

        inputs.put("FAIR_VALUE", "22000000");
        inputs.put("REALIZABLE_VALUE", "18700000");
        inputs.put("LAND_REALIZABLE_VALUE", "8500000");
        inputs.put("BUILDING_REALIZABLE_VALUE", "10200000");
        inputs.put("DISTRESS_SALE_VALUE", "16500000");
        inputs.put("LAND_DISTRESS_VALUE", "7500000");
        inputs.put("BUILDING_DISTRESS_VALUE", "9000000");
        inputs.put("GOVERNMENT_VALUE", "13750000");
        inputs.put("LAND_GOVERNMENT_VALUE", "6250000");
        inputs.put("BUILDING_GOVERNMENT_VALUE", "7500000");
        inputs.put("INSURABLE_VALUE", "15000000");

        // 3. Generate document
        byte[] outputDocx = docxTemplateEngine.generateReport(templateBytes, inputs, Collections.<String, byte[]>emptyMap());
        assertNotNull(outputDocx);
        assertTrue(outputDocx.length > 5000);

        WordprocessingMLPackage resultDocx = WordprocessingMLPackage.load(new ByteArrayInputStream(outputDocx));
        List<Object> content = resultDocx.getMainDocumentPart().getContent();

        List<Tbl> tables = new ArrayList<>();
        for (Object item : content) {
            Object unwrapped = XmlUtils.unwrap(item);
            if (unwrapped instanceof Tbl) {
                tables.add((Tbl) unwrapped);
            }
        }
        assertEquals(4, tables.size(), "Must generate exactly 4 dynamic tables");

        Tbl landTbl = tables.get(0);
        Tbl bldgTbl = tables.get(1);
        Tbl propTbl = tables.get(2);
        Tbl summaryTbl = tables.get(3);

        // ==========================================
        // PHASE 1: STANDARD TABLE TITLE ROWS
        // ==========================================
        System.out.println("PHASE 1: Verifying Standard Table Title Rows...");

        // Land Table Title Row
        Tr landTitleRow = (Tr) XmlUtils.unwrap(landTbl.getContent().get(0));
        Tc landTitleCell = (Tc) XmlUtils.unwrap(landTitleRow.getContent().get(0));
        String landTitleXml = XmlUtils.marshaltoString(landTitleCell);
        assertTrue(landTitleXml.contains("Value Of Land"), "Land table title text must be 'Value Of Land'");
        assertTrue(landTitleCell.getTcPr().getGridSpan().getVal().equals(BigInteger.valueOf(6)), "Land table title must span all 6 columns");
        assertNull(landTitleCell.getTcPr().getShd(), "Land table title must have no background color");
        assertTrue(landTitleXml.contains("<w:jc w:val=\"center\"/>"), "Land table title must be center aligned");
        assertTrue(landTitleXml.contains("<w:b/>"), "Land table title must be bold");

        // Building Table Title Row
        Tr bldgTitleRow = (Tr) XmlUtils.unwrap(bldgTbl.getContent().get(0));
        Tc bldgTitleCell = (Tc) XmlUtils.unwrap(bldgTitleRow.getContent().get(0));
        String bldgTitleXml = XmlUtils.marshaltoString(bldgTitleCell);
        assertTrue(bldgTitleXml.contains("Value Of Buildings"), "Building table title text must be 'Value Of Buildings'");
        assertTrue(bldgTitleCell.getTcPr().getGridSpan().getVal().equals(BigInteger.valueOf(8)), "Building table title must span all 8 columns");
        assertNull(bldgTitleCell.getTcPr().getShd(), "Building table title must have no background color");
        assertTrue(bldgTitleXml.contains("<w:jc w:val=\"center\"/>"), "Building table title must be center aligned");
        assertTrue(bldgTitleXml.contains("<w:b/>"), "Building table title must be bold");

        // Property Value Table Title Row
        Tr propTitleRow = (Tr) XmlUtils.unwrap(propTbl.getContent().get(0));
        Tc propTitleCell = (Tc) XmlUtils.unwrap(propTitleRow.getContent().get(0));
        String propTitleXml = XmlUtils.marshaltoString(propTitleCell);
        assertTrue(propTitleXml.contains("Value Of The Property"), "Property Value table title text must be 'Value Of The Property'");
        assertTrue(propTitleCell.getTcPr().getGridSpan().getVal().equals(BigInteger.valueOf(2)), "Property Value table title must span all 2 columns");
        assertNull(propTitleCell.getTcPr().getShd(), "Property Value table title must have no background color");
        assertTrue(propTitleXml.contains("<w:jc w:val=\"center\"/>"), "Property Value table title must be center aligned");
        assertTrue(propTitleXml.contains("<w:b/>"), "Property Value table title must be bold");

        System.out.println("-> PHASE 1 PASSED: Title rows 'Value Of Land', 'Value Of Buildings', 'Value Of The Property' merged across full width, center-aligned, bold, no background color.");

        // ==========================================
        // PHASE 2: TABLE HEADINGS CAPITALIZATION STANDARD
        // ==========================================
        System.out.println("PHASE 2: Verifying Title Case Capitalization Standard...");
        String fullDocXml = XmlUtils.marshaltoString(resultDocx.getMainDocumentPart().getJaxbElement());

        // Assert Title Case headings present
        assertTrue(fullDocXml.contains("Value Of Land"));
        assertTrue(fullDocXml.contains("Value Of Buildings"));
        assertTrue(fullDocXml.contains("Value Of The Property"));
        assertTrue(fullDocXml.contains("Property Value Component"));
        assertTrue(fullDocXml.contains("Amount (₹)"));
        assertTrue(fullDocXml.contains("Valuation Parameter"));
        assertTrue(fullDocXml.contains("Building Type"));
        assertTrue(fullDocXml.contains("Government Value"));
        assertTrue(fullDocXml.contains("Total Property Value"));
        assertTrue(fullDocXml.contains("Total Land Value"));
        assertTrue(fullDocXml.contains("Say Land Value"));
        assertTrue(fullDocXml.contains("Total Building Value"));
        assertTrue(fullDocXml.contains("Say Building Value"));

        // Assert ALL-CAPS versions are NOT present in XML as tags/text
        assertFalse(fullDocXml.contains(">VALUE OF LAND<"));
        assertFalse(fullDocXml.contains(">VALUE OF BUILDINGS<"));
        assertFalse(fullDocXml.contains(">VALUE OF THE PROPERTY<"));
        assertFalse(fullDocXml.contains(">PROPERTY VALUE COMPONENT<"));
        assertFalse(fullDocXml.contains(">VALUATION PARAMETER<"));
        assertFalse(fullDocXml.contains(">TOTAL BUILDING VALUE<"));
        assertFalse(fullDocXml.contains(">SAY LAND VALUE<"));
        assertFalse(fullDocXml.contains(">TOTAL LAND VALUE<"));

        System.out.println("-> PHASE 2 PASSED: All table titles, headers, row labels, and totals use strict Title Case.");

        // ==========================================
        // PHASE 2 (Standard Total Row Separation): BLANK SEPARATOR ROW
        // ==========================================
        System.out.println("PHASE 2 (Total Row Separation): Verifying Blank Separator Rows...");

        // Land Table: Rows are: 0:Title, 1:Header, 2:Data, 3:Blank, 4:Total, 5:Say
        assertEquals(6, landTbl.getContent().size(), "Land table has 6 rows (Title, Header, 1 Data, Blank, Total, Say)");
        Tr landBlankRow = (Tr) XmlUtils.unwrap(landTbl.getContent().get(3));
        assertEquals(2, landBlankRow.getContent().size(), "Blank row must have exactly 2 cells (merged 5 columns + 1 final numeric column)");
        Tc landBlankCell1 = (Tc) XmlUtils.unwrap(landBlankRow.getContent().get(0));
        Tc landBlankCell2 = (Tc) XmlUtils.unwrap(landBlankRow.getContent().get(1));
        assertEquals(BigInteger.valueOf(5), landBlankCell1.getTcPr().getGridSpan().getVal(), "Blank row cell 1 must merge all 5 initial columns");
        assertNull(landBlankCell2.getTcPr().getGridSpan(), "Blank row cell 2 must not have gridSpan (single final column)");

        // Building Table: Rows are: 0:Title, 1:Header, 2:Data, 3:Blank, 4:Total, 5:Say
        assertEquals(6, bldgTbl.getContent().size(), "Building table has 6 rows (Title, Header, 1 Data, Blank, Total, Say)");
        Tr bldgBlankRow = (Tr) XmlUtils.unwrap(bldgTbl.getContent().get(3));
        assertEquals(2, bldgBlankRow.getContent().size(), "Blank row must have exactly 2 cells (merged 7 columns + 1 final numeric column)");
        Tc bldgBlankCell1 = (Tc) XmlUtils.unwrap(bldgBlankRow.getContent().get(0));
        Tc bldgBlankCell2 = (Tc) XmlUtils.unwrap(bldgBlankRow.getContent().get(1));
        assertEquals(BigInteger.valueOf(7), bldgBlankCell1.getTcPr().getGridSpan().getVal(), "Blank row cell 1 must merge all 7 initial columns");
        assertNull(bldgBlankCell2.getTcPr().getGridSpan(), "Blank row cell 2 must not have gridSpan (single final column)");

        // Property Value Table: Rows are: 0:Title, 1:Header, 2:Land Data, 3:Building Data, 4:Blank, 5:Total
        assertEquals(6, propTbl.getContent().size(), "Property Value table has 6 rows (Title, Header, 2 Data, Blank, Total)");
        Tr propBlankRow = (Tr) XmlUtils.unwrap(propTbl.getContent().get(4));
        assertEquals(2, propBlankRow.getContent().size(), "Blank row in Property Value table has 2 cells (col 0 + final col 1)");

        System.out.println("-> PHASE 2 (Blank Separator Row) PASSED: Blank row inserted immediately above first Total row with all columns merged except final numeric column.");

        // ==========================================
        // PHASE 3: REMOVE TOTAL ROW COLOURING
        // ==========================================
        System.out.println("PHASE 3: Verifying Removal of Total Row Colouring...");

        // Land Table Total Row (Row 4) & Say Row (Row 5)
        Tr landTotalRow = (Tr) XmlUtils.unwrap(landTbl.getContent().get(4));
        String landTotalXml = XmlUtils.marshaltoString(landTotalRow);
        assertFalse(landTotalXml.contains("0070C0"), "Total Land Value row must NOT contain blue font (0070C0)");
        assertFalse(landTotalXml.contains("EBF2F7") || landTotalXml.contains("F0F5F8"), "Total Land Value row must NOT contain background shading");
        assertTrue(landTotalXml.contains("<w:b/>"), "Total Land Value row must be bold");

        Tr landSayRow = (Tr) XmlUtils.unwrap(landTbl.getContent().get(5));
        String landSayXml = XmlUtils.marshaltoString(landSayRow);
        assertFalse(landSayXml.contains("0070C0"), "Say Land Value row must NOT contain blue font (0070C0)");
        assertFalse(landSayXml.contains("EBF2F7") || landSayXml.contains("F0F5F8"), "Say Land Value row must NOT contain background shading");
        assertTrue(landSayXml.contains("<w:b/>"), "Say Land Value row must be bold");

        // Building Table Total Row (Row 4) & Say Row (Row 5)
        Tr bldgTotalRow = (Tr) XmlUtils.unwrap(bldgTbl.getContent().get(4));
        String bldgTotalXml = XmlUtils.marshaltoString(bldgTotalRow);
        assertFalse(bldgTotalXml.contains("0070C0"), "Total Building Value row must NOT contain blue font (0070C0)");
        assertFalse(bldgTotalXml.contains("EBF2F7") || bldgTotalXml.contains("F0F5F8"), "Total Building Value row must NOT contain background shading");
        assertTrue(bldgTotalXml.contains("<w:b/>"), "Total Building Value row must be bold");

        // Property Value Table Total Row (Row 5)
        Tr propTotalRow = (Tr) XmlUtils.unwrap(propTbl.getContent().get(5));
        String propTotalXml = XmlUtils.marshaltoString(propTotalRow);
        assertFalse(propTotalXml.contains("0070C0"), "Total Property Value row must NOT contain blue font (0070C0)");
        assertFalse(propTotalXml.contains("EBF2F7") || propTotalXml.contains("F0F5F8"), "Total Property Value row must NOT contain background shading");
        assertTrue(propTotalXml.contains("<w:b/>"), "Total Property Value row must be bold");

        System.out.println("-> PHASE 3 PASSED: Total and Say rows have NO blue font (0070C0) and NO background shading; retain bold text only.");

        // ==========================================
        // PHASE 4: TABLE PAGINATION RULE (< 7 rows)
        // ==========================================
        System.out.println("PHASE 4: Verifying Table Pagination Rule (< 7 rows keep together on one page)...");

        List<Tbl> smallTables = List.of(landTbl, bldgTbl, propTbl, summaryTbl);
        for (int tIdx = 0; tIdx < smallTables.size(); tIdx++) {
            Tbl tbl = smallTables.get(tIdx);
            int rowCount = tbl.getContent().size();
            assertTrue(rowCount < 7, "Table " + tIdx + " has " + rowCount + " rows (< 7)");

            for (int rIdx = 0; rIdx < rowCount; rIdx++) {
                Tr tr = (Tr) XmlUtils.unwrap(tbl.getContent().get(rIdx));
                String trXml = XmlUtils.marshaltoString(tr);

                // CantSplit on row
                assertTrue(trXml.contains("<w:cantSplit/>"), "Row " + rIdx + " must have CantSplit");

                // Keep Together (keepLines) on cell paragraphs
                assertTrue(trXml.contains("<w:keepLines/>"), "Row " + rIdx + " must have Keep Together (keepLines)");

                // Keep With Next (keepNext) on all rows except final row
                if (rIdx < rowCount - 1) {
                    assertTrue(trXml.contains("<w:keepNext/>"), "Row " + rIdx + " must have Keep With Next (keepNext) to bind to subsequent row");
                }
            }
        }

        System.out.println("-> PHASE 4 PASSED: All tables with < 7 rows have CantSplit, KeepLines, and KeepNext applied so they never split across pages.");
        System.out.println("========================================================================");
        System.out.println("ALL REPORT POLISHING & FINAL STANDARDIZATION PHASES VERIFIED SUCCESSFULLY!");
        System.out.println("========================================================================");
    }
}
