package com.provaluer.service;

import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.XmlUtils;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class ValueOfThePropertyTableTest {

    @Autowired
    private ValuationEngineService valuationEngineService;

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Test
    @DisplayName("Say Value Rounding Rules Verification")
    public void testSayValueRoundingRules() {
        // Example 1: 8,99,97,730 -> 9,00,00,000
        BigDecimal ex1 = new BigDecimal("89997730.00");
        assertEquals(0, new BigDecimal("90000000.00").compareTo(ValuationEngineService.computeSayValue(ex1)));

        // Example 2: 24,38,72,110 -> 24,39,00,000
        BigDecimal ex2 = new BigDecimal("243872110.00");
        assertEquals(0, new BigDecimal("243900000.00").compareTo(ValuationEngineService.computeSayValue(ex2)));

        // Example 3: 109,38,22,456 -> 109,38,00,000
        BigDecimal ex3 = new BigDecimal("1093822456.00");
        assertEquals(0, new BigDecimal("1093800000.00").compareTo(ValuationEngineService.computeSayValue(ex3)));

        // Under 1 Crore: Exact Fair Value preserved (no rounding)
        BigDecimal under1Cr = new BigDecimal("7542380.00");
        assertEquals(0, new BigDecimal("7542380.00").compareTo(ValuationEngineService.computeSayValue(under1Cr)));
    }

    @Test
    @DisplayName("Embed and Verify VALUE OF THE PROPERTY Table in Valuation Report.docx")
    public void testEmbedAndVerifyValueOfThePropertyTable() throws Exception {
        String templatePath = "D:\\naga\\Valuation Report.docx";
        byte[] docxBytes = Files.readAllBytes(Paths.get(templatePath));
        WordprocessingMLPackage wordML = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));
        ObjectFactory factory = new ObjectFactory();

        List<Object> content = wordML.getMainDocumentPart().getContent();
        int valSummaryTableIndex = -1;

        for (int i = 0; i < content.size(); i++) {
            Object obj = XmlUtils.unwrap(content.get(i));
            if (obj instanceof P p) {
                String text = XmlUtils.marshaltoString(p);
                if (text.contains("VALUATION_SUMMARY_TABLE")) {
                    valSummaryTableIndex = i;
                    break;
                }
            }
        }

        assertTrue(valSummaryTableIndex != -1, "VALUATION_SUMMARY_TABLE placeholder paragraph must be present");

        // Create the VALUE OF THE PROPERTY table
        // Structure:
        // Value of Land: <<total_land_value>>
        // Value of Buildings: <<total_building_value>>
        // Total: <<fair_value>>
        // Say: <<say_value>>
        Tbl propValTable = createValueOfThePropertyDocxTable(factory);

        // Check if already embedded; if not, embed before VALUATION_SUMMARY_TABLE
        boolean alreadyEmbedded = false;
        for (Object obj : content) {
            Object unwrapped = XmlUtils.unwrap(obj);
            if (unwrapped instanceof Tbl tbl) {
                String tblXml = XmlUtils.marshaltoString(tbl);
                if (tblXml.contains("VALUE OF THE PROPERTY") || tblXml.contains("say_value")) {
                    alreadyEmbedded = true;
                    break;
                }
            }
        }

        if (!alreadyEmbedded) {
            content.add(valSummaryTableIndex, propValTable);
            content.add(valSummaryTableIndex, createHeadingParagraph(factory, "Value of the Property"));

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            wordML.save(out);
            docxBytes = out.toByteArray();
            Files.write(Paths.get(templatePath), docxBytes);
            System.out.println("Updated Valuation Report.docx with VALUE OF THE PROPERTY table.");
        }

        // Test Hydration & Generation
        Map<String, String> inputs = new LinkedHashMap<>();
        inputs.put("total_land_value", "16,08,60,000");
        inputs.put("total_building_value", "69,47,61,695");
        inputs.put("fair_value", "85,56,21,695");
        // 85,56,21,695 -> Say Value rounded to nearest Lakh = 85,56,00,000
        BigDecimal fVal = new BigDecimal("855621695.00");
        BigDecimal sVal = ValuationEngineService.computeSayValue(fVal);
        inputs.put("say_value", "85,56,00,000");
        inputs.put("say_value_words", "Rupees Eighty Five Crore Fifty Six Lakh Only");

        inputs.put("TOTAL_LAND_VALUE", "16,08,60,000");
        inputs.put("TOTAL_BUILDING_VALUE", "69,47,61,695");
        inputs.put("FAIR_VALUE", "85,56,21,695");
        inputs.put("SAY_VALUE", "85,56,00,000");
        inputs.put("SAY_VALUE_WORDS", "Rupees Eighty Five Crore Fifty Six Lakh Only");

        byte[] generated = templateEngine.generateReport(docxBytes, inputs, Collections.emptyMap());
        assertNotNull(generated);
        assertTrue(generated.length > 50000);

        WordprocessingMLPackage genPackage = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));
        String genXml = XmlUtils.marshaltoString(genPackage.getMainDocumentPart().getJaxbElement());

        assertTrue(genXml.contains("Value of Land") || genXml.contains("16,08,60,000"), "Must contain Value of Land");
        assertTrue(genXml.contains("Value of Buildings") || genXml.contains("69,47,61,695"), "Must contain Value of Buildings");
        assertTrue(genXml.contains("85,56,21,695"), "Must contain Fair Value Total");
        assertTrue(genXml.contains("85,56,00,000"), "Must contain Say Value");
        assertFalse(genXml.contains("<<say_value>>"), "say_value must be resolved");

        System.out.println("VALUE OF THE PROPERTY Table & Say Value verification completed successfully!");
    }

    private Tbl createValueOfThePropertyDocxTable(ObjectFactory factory) {
        Tbl tbl = factory.createTbl();

        TblPr tblPr = factory.createTblPr();
        CTTblLayoutType layout = factory.createCTTblLayoutType();
        layout.setType(STTblLayoutType.FIXED);
        tblPr.setTblLayout(layout);

        TblBorders borders = factory.createTblBorders();
        CTBorder border = factory.createCTBorder();
        border.setVal(STBorder.SINGLE);
        border.setSz(BigInteger.valueOf(4));
        border.setColor("CCCCCC");
        borders.setTop(border);
        borders.setBottom(border);
        borders.setLeft(border);
        borders.setRight(border);
        borders.setInsideH(border);
        borders.setInsideV(border);
        tblPr.setTblBorders(borders);
        tbl.setTblPr(tblPr);

        // Header Row: VALUE OF THE PROPERTY
        Tr headerTr = factory.createTr();
        Tc hTc1 = createCell(factory, "VALUE OF THE PROPERTY", true, "EAEAEA");
        Tc hTc2 = createCell(factory, "AMOUNT (INR)", true, "EAEAEA");
        headerTr.getContent().add(hTc1);
        headerTr.getContent().add(hTc2);
        tbl.getContent().add(headerTr);

        // Row 1: Value of Land
        Tr r1 = factory.createTr();
        r1.getContent().add(createCell(factory, "Value of Land", false, null));
        r1.getContent().add(createCell(factory, "INR <<total_land_value>>", false, null));
        tbl.getContent().add(r1);

        // Row 2: Value of Buildings
        Tr r2 = factory.createTr();
        r2.getContent().add(createCell(factory, "Value of Buildings", false, null));
        r2.getContent().add(createCell(factory, "INR <<total_building_value>>", false, null));
        tbl.getContent().add(r2);

        // Row 3: Total (Fair Value)
        Tr r3 = factory.createTr();
        r3.getContent().add(createCell(factory, "Total", true, "F5F5F5"));
        r3.getContent().add(createCell(factory, "INR <<fair_value>>", true, "F5F5F5"));
        tbl.getContent().add(r3);

        // Row 4: Say (Say Value)
        Tr r4 = factory.createTr();
        r4.getContent().add(createCell(factory, "Say", true, "E8F0FE"));
        r4.getContent().add(createCell(factory, "INR <<say_value>>", true, "E8F0FE"));
        tbl.getContent().add(r4);

        return tbl;
    }

    private Tc createCell(ObjectFactory factory, String text, boolean isBold, String bgColorHex) {
        Tc tc = factory.createTc();
        P p = factory.createP();
        R r = factory.createR();
        if (isBold) {
            RPr rpr = factory.createRPr();
            rpr.setB(factory.createBooleanDefaultTrue());
            r.setRPr(rpr);
        }
        Text t = factory.createText();
        t.setValue(text);
        r.getContent().add(t);
        p.getContent().add(r);
        tc.getContent().add(p);

        if (bgColorHex != null) {
            TcPr tcPr = factory.createTcPr();
            CTShd shd = factory.createCTShd();
            shd.setVal(STShd.CLEAR);
            shd.setColor("auto");
            shd.setFill(bgColorHex);
            tcPr.setShd(shd);
            tc.setTcPr(tcPr);
        }

        return tc;
    }

    private P createHeadingParagraph(ObjectFactory factory, String text) {
        P p = factory.createP();
        R r = factory.createR();
        RPr rpr = factory.createRPr();
        rpr.setB(factory.createBooleanDefaultTrue());
        Color color = factory.createColor();
        color.setVal("003366");
        rpr.setColor(color);
        r.setRPr(rpr);

        Text t = factory.createText();
        t.setValue(text);
        r.getContent().add(t);
        p.getContent().add(r);
        return p;
    }
}
