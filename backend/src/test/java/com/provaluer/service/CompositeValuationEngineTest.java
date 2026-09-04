package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.model.ValuationCompositeItem;
import com.provaluer.model.ValuationData;
import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.XmlUtils;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.P;
import org.docx4j.wml.Tbl;
import org.docx4j.wml.Text;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class CompositeValuationEngineTest {

    @Autowired
    private ValuationCalculationFormulaService formulaService;

    @Autowired
    private DocxTemplateEngine templateEngine;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("V5 Composite Calculation: Depreciation, Interior Works, Say Rounding, and Downstream Consumption")
    public void testCompositeCalculationAndDownstreamSummary() {
        // 1. Main Unit: Area = 1,200 Sq.Ft, Rate = ₹8,500/Sq.Ft -> Amount = ₹1,02,00,000
        // Construction Cost = ₹2,000/Sq.Ft, Age = 10, Life = 60
        // Depreciation = 1,200 × 2,000 × 0.90 × (10 ÷ 60) = ₹3,60,000
        // Fair Value = ₹1,02,00,000 - ₹3,60,000 = ₹98,40,000
        ValuationCompositeItem mainUnit = new ValuationCompositeItem();
        mainUnit.setItemCategory("MAIN_UNIT");
        mainUnit.setDescription("Flat No. 302, 3rd Floor");
        mainUnit.setEnteredUnit("Sq.Ft");
        mainUnit.setQuantity(new BigDecimal("1200"));
        mainUnit.setRate(new BigDecimal("8500"));
        mainUnit.setConstructionCost(new BigDecimal("2000"));
        mainUnit.setBuildingAge(new BigDecimal("10"));
        mainUnit.setTotalLife(60);

        formulaService.calculateCompositeItem(mainUnit);

        assertEquals(0, new BigDecimal("10200000.00").compareTo(mainUnit.getAmount()));
        assertEquals(0, new BigDecimal("360000.00").compareTo(mainUnit.getDepreciationAmount()));
        assertEquals(0, new BigDecimal("9840000.00").compareTo(mainUnit.getFairValue()));

        // 2. Interior Works: "Interior Works & Improvements" -> Unit LS, Qty 1, Rate ₹15,00,000
        // Option B Direct Depreciation = ₹1,63,750 -> Fair Value = ₹13,36,250
        ValuationCompositeItem interior = new ValuationCompositeItem();
        interior.setItemCategory("INTERIOR_WORK");
        interior.setDescription("Interior Works & Improvements");
        interior.setEnteredUnit("LS");
        interior.setQuantity(new BigDecimal("1"));
        interior.setRate(new BigDecimal("1500000"));
        interior.setDepreciationMode("DIRECT_AMOUNT");
        interior.setDepreciationAmount(new BigDecimal("163750"));
        interior.setIsInsurable(true);

        formulaService.calculateCompositeItem(interior);

        assertEquals(0, new BigDecimal("1500000.00").compareTo(interior.getAmount()));
        assertEquals(0, new BigDecimal("163750.00").compareTo(interior.getDepreciationAmount()));
        assertEquals(0, new BigDecimal("1336250.00").compareTo(interior.getFairValue()));

        // 3. Composite Summary & Downstream
        ValuationData data = new ValuationData();
        data.setValuationMethodology("COMPOSITE");
        data.setCompositeGovernmentRate(new BigDecimal("4687.50")); // 1,200 * 4687.50 = 56,25,000
        data.setRealizablePercentage(new BigDecimal("85.00"));
        data.setDistressSalePercentage(new BigDecimal("75.00"));

        formulaService.calculateCompositeSummary(data, List.of(mainUnit, interior));

        // Raw Fair Value = 98,40,000 + 13,36,250 = 1,11,76,250
        assertEquals(0, new BigDecimal("11176250.00").compareTo(data.getRawFairValue()));

        // Say Fair Value (Tiered rounding for >= 1 Crore -> nearest 1 Lakh) = 1,12,00,000
        assertEquals(0, new BigDecimal("11200000.00").compareTo(data.getSayFairValue()));

        // Fair Value in Summary consumes Say Fair Value
        assertEquals(0, new BigDecimal("11200000.00").compareTo(data.getFairValue()));

        // Realizable Value = 1,12,00,000 * 85% = 95,20,000
        assertEquals(0, new BigDecimal("9520000.00").compareTo(data.getRealizableValue()));

        // Distress Sale Value = 1,12,00,000 * 75% = 84,00,000
        assertEquals(0, new BigDecimal("8400000.00").compareTo(data.getDistressSaleValue()));

        // Government Value = Area * Government Composite Rate = 1,200 * 4,687.50 = 56,25,000
        assertEquals(0, new BigDecimal("5625000.00").compareTo(data.getGovernmentValue()));

        // Insurable Value = (1,200 * 2,000) + 15,00,000 = 24,00,000 + 15,00,000 = 39,00,000
        assertEquals(0, new BigDecimal("3900000.00").compareTo(data.getInsurableValue()));
    }

    @Test
    @DisplayName("DOCX Composite Property Table Footer Formatting: Raw Total, Conditional 'Say' Row, and Summary Card")
    public void testDocxCompositeTableGeneration() throws Exception {
        // Create a minimal docx template containing <<COMPOSITE_PROPERTY_TABLE>>
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        org.docx4j.wml.ObjectFactory factory = new org.docx4j.wml.ObjectFactory();
        P p = factory.createP();
        org.docx4j.wml.R r = factory.createR();
        Text text = factory.createText();
        text.setValue("<<COMPOSITE_PROPERTY_TABLE>>");
        r.getContent().add(text);
        p.getContent().add(r);
        pkg.getMainDocumentPart().getContent().add(p);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        pkg.save(out);
        byte[] templateBytes = out.toByteArray();

        // Prepare Inputs
        Map<String, String> inputs = new HashMap<>();
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE");
        inputs.put("PROPERTY_CATEGORY", "Flat");

        List<Map<String, Object>> compositeItems = new ArrayList<>();
        compositeItems.add(Map.of(
                "description", "Flat No. 101",
                "enteredUnit", "Sq.Ft",
                "quantity", "1200",
                "rate", "8500",
                "amount", "10200000",
                "depreciationAmount", "360000",
                "fairValue", "9840000"
        ));
        compositeItems.add(Map.of(
                "description", "Interior Works & Improvements",
                "enteredUnit", "LS",
                "quantity", "1",
                "rate", "1500000",
                "amount", "1500000",
                "depreciationAmount", "163750",
                "fairValue", "1336250"
        ));
        inputs.put("RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(compositeItems));

        inputs.put("RAW_FAIR_VALUE", "11176250");
        inputs.put("SAY_FAIR_VALUE", "11200000");
        inputs.put("FAIR_VALUE", "11200000");
        inputs.put("REALIZABLE_VALUE", "9520000");
        inputs.put("DISTRESS_SALE_VALUE", "8400000");
        inputs.put("GOVERNMENT_VALUE", "5625000");
        inputs.put("INSURABLE_VALUE", "3300000");

        byte[] generated = templateEngine.generateReport(templateBytes, inputs, Collections.emptyMap());
        assertNotNull(generated);

        WordprocessingMLPackage genPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));
        String xml = XmlUtils.marshaltoString(genPkg.getMainDocumentPart().getJaxbElement());

        // Assert 1: Fair Value Of Property arithmetic total is present
        assertTrue(xml.contains("Fair Value Of Property"), "Must contain Total Row: 'Fair Value Of Property'");
        assertTrue(xml.contains("1,11,76,250"), "Must show Raw Fair Value: 1,11,76,250");

        // Assert 1b: Column headers must contain 'Amount (₹)' and NOT 'Replacement Cost (₹)'
        assertTrue(xml.contains("Amount (₹)"), "Table must contain approved column header 'Amount (₹)'");
        assertFalse(xml.contains("Replacement Cost (₹)"), "Table must NOT contain 'Replacement Cost (₹)'");

        // Assert 2: Say row is present and strictly labeled 'Say' (NOT 'Say Fair Value')
        assertTrue(xml.contains("<w:t>Say</w:t>"), "Must contain row strictly labeled 'Say'");
        assertFalse(xml.contains("Say Fair Value"), "Must NOT display 'Say Fair Value'");
        assertFalse(xml.contains("Say Fair Value Of Property"), "Must NOT display 'Say Fair Value Of Property'");
        assertTrue(xml.contains("1,12,00,000"), "Must show Say Fair Value: 1,12,00,000");

        // Assert 3: Valuation Parameters Summary table is present
        assertTrue(xml.contains("Valuation Parameters Summary"), "Must attach Valuation Parameters Summary");
        assertTrue(xml.contains("Realizable Value"), "Must contain Realizable Value");
        assertTrue(xml.contains("95,20,000"), "Must show Realizable Value: 95,20,000");
        assertTrue(xml.contains("Distress Sale Value"), "Must contain Distress Sale Value");
        assertTrue(xml.contains("84,00,000"), "Must show Distress Sale Value: 84,00,000");
        assertTrue(xml.contains("56,25,000"), "Must show Government Value: 56,25,000");
    }

    @Test
    @DisplayName("DOCX Composite Table: Say Row Suppression when Fair Value equals Say Value")
    public void testDocxSayRowSuppressionWhenEqual() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        org.docx4j.wml.ObjectFactory factory = new org.docx4j.wml.ObjectFactory();
        P p = factory.createP();
        org.docx4j.wml.R r = factory.createR();
        Text text = factory.createText();
        text.setValue("<<COMPOSITE_PROPERTY_TABLE>>");
        r.getContent().add(text);
        p.getContent().add(r);
        pkg.getMainDocumentPart().getContent().add(p);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        pkg.save(out);
        byte[] templateBytes = out.toByteArray();

        Map<String, String> inputs = new HashMap<>();
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE");
        inputs.put("PROPERTY_CATEGORY", "Flat");

        List<Map<String, Object>> compositeItems = new ArrayList<>();
        compositeItems.add(Map.of(
                "description", "Flat Unit",
                "enteredUnit", "Sq.Ft",
                "quantity", "1000",
                "rate", "11200",
                "amount", "11200000",
                "depreciationAmount", "0",
                "fairValue", "11200000"
        ));
        inputs.put("RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(compositeItems));
        inputs.put("RAW_FAIR_VALUE", "11200000");
        inputs.put("SAY_FAIR_VALUE", "11200000"); // Equal!

        byte[] generated = templateEngine.generateReport(templateBytes, inputs, Collections.emptyMap());
        WordprocessingMLPackage genPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));
        String xml = XmlUtils.marshaltoString(genPkg.getMainDocumentPart().getJaxbElement());

        assertTrue(xml.contains("Fair Value Of Property"), "Must contain Total Row: 'Fair Value Of Property'");
        // When Say Value == Fair Value, Say row must be completely suppressed
        assertFalse(xml.contains("<w:t>Say</w:t>"), "Must suppress 'Say' row when Fair Value == Say Value");
    }

    @Test
    @DisplayName("Legacy Template Backward Compatibility: Replaces first legacy table and suppresses subsequent ones")
    public void testLegacyTemplateSuppressionForComposite() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        org.docx4j.wml.ObjectFactory factory = new org.docx4j.wml.ObjectFactory();

        // Add legacy table placeholders
        List.of("<<LAND_TABLE>>", "<<BUILDING_TABLE>>", "<<PROPERTY_VALUE_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>").forEach(tag -> {
            P p = factory.createP();
            org.docx4j.wml.R r = factory.createR();
            Text t = factory.createText();
            t.setValue(tag);
            r.getContent().add(t);
            p.getContent().add(r);
            pkg.getMainDocumentPart().getContent().add(p);
        });

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        pkg.save(out);
        byte[] templateBytes = out.toByteArray();

        Map<String, String> inputs = new HashMap<>();
        inputs.put("VALUATION_METHODOLOGY", "COMPOSITE");
        inputs.put("PROPERTY_CATEGORY", "Apartment");
        inputs.put("RAW_FAIR_VALUE", "5000000");
        inputs.put("SAY_FAIR_VALUE", "5000000");

        byte[] generated = templateEngine.generateReport(templateBytes, inputs, Collections.emptyMap());
        WordprocessingMLPackage genPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));
        String xml = XmlUtils.marshaltoString(genPkg.getMainDocumentPart().getJaxbElement());

        // Composite table must be rendered
        assertTrue(xml.contains("Valuation of Property (Composite Rate Method)"), "Must render Composite table");
        // Legacy Land / Building headers must NOT appear
        assertFalse(xml.contains("Value Of Land"), "Must suppress Value Of Land table");
        assertFalse(xml.contains("Value Of Buildings"), "Must suppress Value Of Buildings table");
    }
}
