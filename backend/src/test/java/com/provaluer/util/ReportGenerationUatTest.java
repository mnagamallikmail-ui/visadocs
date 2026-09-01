package com.provaluer.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.docx4j.Docx4J;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.openpackaging.parts.WordprocessingML.MainDocumentPart;
import org.docx4j.wml.*;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

public class ReportGenerationUatTest {

    private final DocxTemplateEngine engine = new DocxTemplateEngine();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    public void testFullReportGenerationWithPropertyValueTableAndSpacing() throws Exception {
        // 1. Create a mock DOCX template with all dynamic table directives
        WordprocessingMLPackage templatePkg = WordprocessingMLPackage.createPackage();
        MainDocumentPart mainPart = templatePkg.getMainDocumentPart();
        ObjectFactory factory = new ObjectFactory();

        mainPart.addParagraphOfText("OFFICIAL VALUATION REPORT");
        mainPart.addParagraphOfText("Client: <<CLIENT_NAME>> | Report No: <<REPORT_NO>>");
        mainPart.addParagraphOfText("<<LAND_TABLE>>");
        mainPart.addParagraphOfText("<<BUILDING_TABLE>>");
        mainPart.addParagraphOfText("<<PROPERTY_VALUE_TABLE>>");
        mainPart.addParagraphOfText("<<VALUATION_SUMMARY_TABLE>>");
        mainPart.addParagraphOfText("Valuation Remarks: Certified by Senior Property Analyst.");

        ByteArrayOutputStream tplOut = new ByteArrayOutputStream();
        templatePkg.save(tplOut);
        byte[] templateBytes = tplOut.toByteArray();

        // 2. Prepare real valuation inputs
        Map<String, String> inputs = new HashMap<>();
        inputs.put("CLIENT_NAME", "State Bank of India");
        inputs.put("REPORT_NO", "PV-2609-0003");

        // Land JSON
        List<Map<String, Object>> landList = List.of(
                Map.of(
                        "description", "Commercial Plot (Sy.No.42/A)",
                        "surveyNo", "42/A",
                        "enteredUnit", "Sq.Ft",
                        "enteredArea", "1500",
                        "rate", "1500",
                        "value", "2250000"
                )
        );
        inputs.put("RAW_LAND_ITEMS_JSON", objectMapper.writeValueAsString(landList));
        inputs.put("TOTAL_LAND_VALUE", "22,50,000");

        // Building JSON
        List<Map<String, Object>> bldgList = List.of(
                Map.of(
                        "description", "Commercial Office Building",
                        "buildingType", "RCC Commercial",
                        "enteredUnit", "Sq.Ft",
                        "enteredArea", "2000",
                        "replacementRate", "2500",
                        "replacementCost", "5000000",
                        "depreciationAmount", "375000",
                        "buildingValue", "4625000"
                )
        );
        inputs.put("RAW_BUILDING_ITEMS_JSON", objectMapper.writeValueAsString(bldgList));
        inputs.put("TOTAL_BUILDING_VALUE", "46,25,000");
        inputs.put("TOTAL_REPLACEMENT_COST", "50,00,000");

        // Summary Values
        inputs.put("FAIR_VALUE", "68,75,000");
        inputs.put("REALIZABLE_VALUE", "58,43,750");
        inputs.put("DISTRESS_SALE_VALUE", "51,56,250");
        inputs.put("GOVERNMENT_VALUE", "1,30,50,000");
        inputs.put("INSURABLE_VALUE", "50,00,000");
        inputs.put("SAY_VALUE", "68,75,000");

        // 3. Generate Hydrated Report
        byte[] generatedBytes = engine.generateReport(templateBytes, inputs, Collections.emptyMap());
        assertNotNull(generatedBytes);
        assertTrue(generatedBytes.length > 0);

        // 4. Inspect Document Structure
        WordprocessingMLPackage genPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generatedBytes));
        List<Object> content = genPkg.getMainDocumentPart().getContent();

        int tableCount = 0;
        int blankParagraphCount = 0;
        List<String> foundTableHeaders = new ArrayList<>();
        List<List<String>> allRows = new ArrayList<>();

        for (Object obj : content) {
            Object item = (obj instanceof jakarta.xml.bind.JAXBElement) ? ((jakarta.xml.bind.JAXBElement<?>) obj).getValue() : obj;
            if (item instanceof Tbl) {
                tableCount++;
                Tbl tbl = (Tbl) item;
                for (Object rowObj : tbl.getContent()) {
                    Object row = (rowObj instanceof jakarta.xml.bind.JAXBElement) ? ((jakarta.xml.bind.JAXBElement<?>) rowObj).getValue() : rowObj;
                    if (row instanceof Tr) {
                        List<String> rowCells = new ArrayList<>();
                        for (Object cellObj : ((Tr) row).getContent()) {
                            Object cell = (cellObj instanceof jakarta.xml.bind.JAXBElement) ? ((jakarta.xml.bind.JAXBElement<?>) cellObj).getValue() : cellObj;
                            if (cell instanceof Tc) {
                                StringBuilder cellText = new StringBuilder();
                                for (Object pObj : ((Tc) cell).getContent()) {
                                    Object p = (pObj instanceof jakarta.xml.bind.JAXBElement) ? ((jakarta.xml.bind.JAXBElement<?>) pObj).getValue() : pObj;
                                    if (p instanceof P) {
                                        for (Object rObj : ((P) p).getContent()) {
                                            Object r = (rObj instanceof jakarta.xml.bind.JAXBElement) ? ((jakarta.xml.bind.JAXBElement<?>) rObj).getValue() : rObj;
                                            if (r instanceof R) {
                                                for (Object tObj : ((R) r).getContent()) {
                                                    Object t = (tObj instanceof jakarta.xml.bind.JAXBElement) ? ((jakarta.xml.bind.JAXBElement<?>) tObj).getValue() : tObj;
                                                    if (t instanceof Text) {
                                                        cellText.append(((Text) t).getValue());
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                rowCells.add(cellText.toString().trim());
                            }
                        }
                        allRows.add(rowCells);
                    }
                }
            } else if (item instanceof P) {
                P p = (P) item;
                if (p.getPPr() != null && p.getPPr().getSpacing() != null) {
                    blankParagraphCount++;
                }
            }
        }

        System.out.println("=== UAT REPORT VERIFICATION EVIDENCE ===");
        System.out.println("Total Generated Tables: " + tableCount);
        System.out.println("Total Spacing Blank Paragraphs: " + blankParagraphCount);
        for (List<String> r : allRows) {
            System.out.println("ROW: " + String.join(" | ", r));
        }

        // Assertions
        assertEquals(4, tableCount, "Must generate exactly 4 dynamic tables (LAND, BUILDING, PROPERTY VALUE, SUMMARY)");
        assertTrue(blankParagraphCount >= 8, "Must have two blank spacing paragraphs after each of the 4 tables");
    }
}
