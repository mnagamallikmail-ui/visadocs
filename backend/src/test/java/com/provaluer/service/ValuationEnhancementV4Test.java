package com.provaluer.service;

import com.provaluer.model.ValuationBuildingItem;
import com.provaluer.model.ValuationData;
import com.provaluer.model.ValuationLandItem;
import com.provaluer.util.DocxTemplateEngine;
import com.provaluer.util.IndianNumberFormatter;
import org.docx4j.XmlUtils;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.P;
import org.docx4j.wml.Tbl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class ValuationEnhancementV4Test {

    @Autowired
    private ValuationCalculationFormulaService formulaService;

    @Autowired
    private ValuationEngineService valuationEngineService;

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Test
    @DisplayName("Phase 1: Land Unit & Rate Consistency - Rate belongs to selected unit")
    public void testLandUnitAndRateConsistency() {
        // Test Case 1: Sq.Yd unit with Rate ₹ 2,000 / Sq.Yd
        ValuationLandItem landSqYd = new ValuationLandItem();
        landSqYd.setEnteredArea(new BigDecimal("100"));
        landSqYd.setEnteredUnit("Sq.Yd");
        landSqYd.setRate(new BigDecimal("2000"));

        formulaService.calculateLandItem(landSqYd);

        // Value must be enteredArea * rate = 100 * 2000 = 200,000
        assertEquals(new BigDecimal("200000.00"), landSqYd.getValue());
        // Standard Area in Sq.Ft must be 100 * 9 = 900 Sq.Ft
        assertEquals(new BigDecimal("900.0000"), landSqYd.getStandardAreaSqft());

        // Test Case 2: Acre unit with Rate ₹ 50,00,000 / Acre
        ValuationLandItem landAcre = new ValuationLandItem();
        landAcre.setEnteredArea(new BigDecimal("2.5"));
        landAcre.setEnteredUnit("Acre");
        landAcre.setRate(new BigDecimal("5000000"));

        formulaService.calculateLandItem(landAcre);

        // Value = 2.5 * 5,000,000 = 1,25,00,000
        assertEquals(new BigDecimal("12500000.00"), landAcre.getValue());
        // Standard Area = 2.5 * 43560 = 108,900 Sq.Ft
        assertEquals(new BigDecimal("108900.0000"), landAcre.getStandardAreaSqft());
    }

    @Test
    @DisplayName("Phase 2: Default Useful Life for PEB Structures and Steel Sheds is 40 Years")
    public void testPebAndSteelShedDefaultUsefulLife() {
        // PEB Structure
        ValuationBuildingItem peb = new ValuationBuildingItem();
        peb.setBuildingType("PEB Structure");
        peb.setEnteredArea(new BigDecimal("5000"));
        peb.setReplacementRate(new BigDecimal("1800"));
        peb.setBuildingAge(new BigDecimal("5"));
        peb.setBuildingUsefulLife(0); // auto-default

        formulaService.calculateBuildingItem(peb);
        assertEquals(40, peb.getBuildingUsefulLife(), "PEB Structure must default to 40 years useful life");

        // Steel Shed
        ValuationBuildingItem shed = new ValuationBuildingItem();
        shed.setBuildingType("Steel Shed");
        shed.setEnteredArea(new BigDecimal("3000"));
        shed.setReplacementRate(new BigDecimal("1400"));
        shed.setBuildingAge(new BigDecimal("3"));
        shed.setBuildingUsefulLife(60); // default 60 should be overridden to 40 for shed

        formulaService.calculateBuildingItem(shed);
        assertEquals(40, shed.getBuildingUsefulLife(), "Steel Shed must default to 40 years useful life");

        // Standard RCC Residential should retain 60
        ValuationBuildingItem rcc = new ValuationBuildingItem();
        rcc.setBuildingType("RCC Residential");
        rcc.setEnteredArea(new BigDecimal("2000"));
        rcc.setReplacementRate(new BigDecimal("2500"));
        rcc.setBuildingAge(new BigDecimal("10"));
        rcc.setBuildingUsefulLife(60);

        formulaService.calculateBuildingItem(rcc);
        assertEquals(60, rcc.getBuildingUsefulLife(), "RCC Residential must default to 60 years useful life");
    }

    @Test
    @DisplayName("Phase 4 & 9: Say Value Driven Model - Fair Value equals Say Land + Say Building")
    public void testSayValueDrivenModelAndFairValue() {
        ValuationData data = new ValuationData(101L);

        // Land Parcel: 1,34,72,913
        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("6736.4565"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("2000"));

        // Building: 25,000 * 2500 = 62,500,000 - 4,687,500 (5 yrs / 60 yrs * 0.9) = 57,812,500
        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("RCC Commercial");
        bldg.setEnteredArea(new BigDecimal("25000"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("2500"));
        bldg.setBuildingAge(new BigDecimal("5"));
        bldg.setBuildingUsefulLife(60);

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        // Total Land Value = 1,34,72,913 -> Say Land Value = 1,35,00,000 (rounded to nearest Lakh)
        assertEquals(new BigDecimal("13472913.00"), data.getTotalLandValue());
        assertEquals(new BigDecimal("13500000.00"), data.getSayLandValue());

        // Total Building Value = 5,78,12,500 -> Say Building Value = 5,78,00,000
        assertEquals(new BigDecimal("57812500.00"), data.getTotalBuildingValue());
        assertEquals(new BigDecimal("57800000.00"), data.getSayBuildingValue());

        // Fair Value must equal Say Land (1,35,00,000) + Say Building (5,78,00,000) = 7,13,00,000 (NOT raw sum 7,12,85,413)
        assertEquals(new BigDecimal("71300000.00"), data.getFairValue());
    }

    @Test
    @DisplayName("Phase 6 & 7: Separate Realizable & Distress Percentages for Land and Building")
    public void testSeparateRealizableAndDistressPercentages() {
        ValuationData data = new ValuationData(102L);
        data.setLandRealizablePercentage(new BigDecimal("90.00"));
        data.setBuildingRealizablePercentage(new BigDecimal("80.00"));
        data.setLandDistressPercentage(new BigDecimal("80.00"));
        data.setBuildingDistressPercentage(new BigDecimal("70.00"));

        // Land: 6,750 * 2,000 = 1,35,00,000 -> Say = 1,35,00,000
        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("6750"));
        land.setRate(new BigDecimal("2000"));

        // Building: 24,783.7838 * 2500, age 5 -> Say = 5,73,00,000
        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("RCC Commercial");
        bldg.setEnteredArea(new BigDecimal("24783.7838"));
        bldg.setReplacementRate(new BigDecimal("2500"));
        bldg.setBuildingAge(new BigDecimal("5"));
        bldg.setBuildingUsefulLife(60);

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(new BigDecimal("13500000.00"), data.getSayLandValue());
        assertEquals(new BigDecimal("57300000.00"), data.getSayBuildingValue());

        // Land Realizable = 1,35,00,000 * 90% = 1,21,50,000
        assertEquals(new BigDecimal("12150000.00"), data.getLandRealizableValue());
        // Building Realizable = 5,73,00,000 * 80% = 4,58,40,000
        assertEquals(new BigDecimal("45840000.00"), data.getBuildingRealizableValue());
        // Total Realizable = 1,21,50,000 + 4,58,40,000 = 5,79,90,000
        assertEquals(new BigDecimal("57990000.00"), data.getRealizableValue());

        // Land Distress = 1,35,00,000 * 80% = 1,08,00,000
        assertEquals(new BigDecimal("10800000.00"), data.getLandDistressValue());
        // Building Distress = 5,73,00,000 * 70% = 4,01,10,000
        assertEquals(new BigDecimal("40110000.00"), data.getBuildingDistressValue());
        // Total Distress = 1,08,00,000 + 4,01,10,000 = 5,09,10,000
        assertEquals(new BigDecimal("50910000.00"), data.getDistressSaleValue());
    }

    @Test
    @DisplayName("Phase 5: Property Value Table has 3 rows (Land, Building, Total) and NO Say row")
    public void testPropertyValueTableStructure() throws Exception {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("say_land_value", "13500000");
        inputs.put("say_building_value", "57300000");
        inputs.put("fair_value", "70800000");

        // Template containing <<PROPERTY_VALUE_TABLE>>
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        P p = pkg.getMainDocumentPart().createParagraphOfText("<<PROPERTY_VALUE_TABLE>>");
        pkg.getMainDocumentPart().getContent().add(p);

        java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
        pkg.save(out);

        byte[] generated = templateEngine.generateReport(out.toByteArray(), inputs, Collections.emptyMap());

        WordprocessingMLPackage genPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));
        List<Object> content = genPkg.getMainDocumentPart().getContent();

        Tbl table = null;
        for (Object elem : content) {
            Object unwrapped = XmlUtils.unwrap(elem);
            if (unwrapped instanceof Tbl t) {
                table = t;
                break;
            }
        }

        assertNotNull(table, "PROPERTY_VALUE_TABLE must be dynamically generated");
        String tableXml = XmlUtils.marshaltoString(table);

        // Verify headers & rows
        assertTrue(tableXml.contains("Value of Land"), "Must contain 'Value of Land'");
        assertTrue(tableXml.contains("Value of Building"), "Must contain 'Value of Building'");
        assertTrue(tableXml.contains("Total Property Value"), "Must contain 'Total Property Value'");
        assertFalse(tableXml.contains("<w:t>Say</w:t>") || tableXml.contains("Say (Rounded)"), "Must NOT contain 'Say' row");
        assertTrue(tableXml.contains("1,35,00,000"), "Must contain Indian formatted land value");
        assertTrue(tableXml.contains("5,73,00,000"), "Must contain Indian formatted building value");
        assertTrue(tableXml.contains("7,08,00,000"), "Must contain Indian formatted total property value");
    }

    @Test
    @DisplayName("Phase 8 to 13: Valuation Summary Table has 4 columns (Parameter | Land | Building | Total)")
    public void testValuationSummaryTableFourColumns() throws Exception {
        Map<String, String> inputs = new HashMap<>();
        inputs.put("say_land_value", "13500000");
        inputs.put("say_building_value", "57300000");
        inputs.put("fair_value", "70800000");

        inputs.put("land_realizable_value", "12150000");
        inputs.put("building_realizable_value", "45840000");
        inputs.put("realizable_value", "57990000");

        inputs.put("land_distress_value", "10800000");
        inputs.put("building_distress_value", "40110000");
        inputs.put("distress_sale_value", "50910000");

        inputs.put("land_government_value", "37125000");
        inputs.put("building_government_value", "60000000");
        inputs.put("government_value", "97125000");

        inputs.put("insurable_value", "62500000");

        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        P p = pkg.getMainDocumentPart().createParagraphOfText("<<VALUATION_SUMMARY_TABLE>>");
        pkg.getMainDocumentPart().getContent().add(p);

        java.io.ByteArrayOutputStream out = new java.io.ByteArrayOutputStream();
        pkg.save(out);

        byte[] generated = templateEngine.generateReport(out.toByteArray(), inputs, Collections.emptyMap());

        WordprocessingMLPackage genPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(generated));
        List<Object> content = genPkg.getMainDocumentPart().getContent();

        Tbl table = null;
        for (Object elem : content) {
            Object unwrapped = XmlUtils.unwrap(elem);
            if (unwrapped instanceof Tbl t) {
                table = t;
                break;
            }
        }

        assertNotNull(table, "VALUATION_SUMMARY_TABLE must be dynamically generated");
        String tableXml = XmlUtils.marshaltoString(table);

        // Verify column headers
        assertTrue(tableXml.contains("VALUATION PARAMETER"), "Must contain VALUATION PARAMETER");
        assertTrue(tableXml.contains("LAND (₹)"), "Must contain LAND (₹)");
        assertTrue(tableXml.contains("BUILDING (₹)"), "Must contain BUILDING (₹)");
        assertTrue(tableXml.contains("TOTAL (₹)"), "Must contain TOTAL (₹)");

        // Verify rows
        assertTrue(tableXml.contains("Fair Value"), "Must contain Fair Value row");
        assertTrue(tableXml.contains("Realizable Value"), "Must contain Realizable Value row");
        assertTrue(tableXml.contains("Distress Sale Value"), "Must contain Distress Sale Value row");
        assertTrue(tableXml.contains("Government Value"), "Must contain Government Value row");
        assertTrue(tableXml.contains("Insurable Value"), "Must contain Insurable Value row");
        assertTrue(tableXml.contains("N/A"), "Insurable value for Land must be N/A");
    }
}
