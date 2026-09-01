package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.model.*;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.util.DocxTemplateEngine;
import com.provaluer.util.IndianNumberFormatter;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.util.*;

@SpringBootTest
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class GenerateEvidenceReportTest {

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Autowired
    private ValuationCalculationFormulaService formulaService;

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private OrderRepository orderRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("Generate Brand-New Report Evidence for Value Tables Template & PV-2609-0003")
    public void generateEvidenceReport() throws Exception {
        System.out.println("========================================================================");
        System.out.println("POST-IMPLEMENTATION REPORT GENERATION & EVIDENCE EXTRACTION");
        System.out.println("========================================================================");

        // 1. Template Structure Setup (Value Tables)
        WordprocessingMLPackage templateDocx = WordprocessingMLPackage.createPackage();
        org.docx4j.wml.ObjectFactory factory = new org.docx4j.wml.ObjectFactory();

        templateDocx.getMainDocumentPart().addParagraphOfText("VALUATION REPORT: <<PROPERTY_DESCRIPTION>>");
        templateDocx.getMainDocumentPart().addParagraphOfText("Report Number: <<REPORT_NO>> | Client: <<CLIENT_NAME>>");
        templateDocx.getMainDocumentPart().addParagraphOfText("------------------------------------------------------------------------");
        templateDocx.getMainDocumentPart().addParagraphOfText("1. LAND VALUATION TABLE");
        templateDocx.getMainDocumentPart().addParagraphOfText("<<LAND_TABLE>>");
        templateDocx.getMainDocumentPart().addParagraphOfText("------------------------------------------------------------------------");
        templateDocx.getMainDocumentPart().addParagraphOfText("2. BUILDING VALUATION TABLE");
        templateDocx.getMainDocumentPart().addParagraphOfText("<<BUILDING_TABLE>>");
        templateDocx.getMainDocumentPart().addParagraphOfText("------------------------------------------------------------------------");
        templateDocx.getMainDocumentPart().addParagraphOfText("3. PROPERTY VALUE SUMMARY");
        templateDocx.getMainDocumentPart().addParagraphOfText("<<PROPERTY_VALUE_TABLE>>");
        templateDocx.getMainDocumentPart().addParagraphOfText("------------------------------------------------------------------------");
        templateDocx.getMainDocumentPart().addParagraphOfText("4. VALUATION SUMMARY PARAMETERS");
        templateDocx.getMainDocumentPart().addParagraphOfText("<<VALUATION_SUMMARY_TABLE>>");

        ByteArrayOutputStream tplBaos = new ByteArrayOutputStream();
        templateDocx.save(tplBaos);
        byte[] templateBytes = tplBaos.toByteArray();

        // 2. Realistic Valuation Inputs matching PV-2609-0003
        // Land: 5,000 Sq.Ft @ ₹ 4,500/Sq.Ft (Sy.No.42/A) = ₹ 2,25,00,000
        // Buildings:
        //  - Commercial Building (RCC Commercial): 4,000 Sq.Ft @ ₹ 3,500 = ₹ 1,40,00,000, Depr: ₹ 10,50,000, Value: ₹ 1,29,50,000
        //  - Industrial Shed (Steel Shed): 3,000 Sq.Ft @ ₹ 2,000 = ₹ 60,00,000, Depr: ₹ 4,50,000, Value: ₹ 55,50,000
        // Govt Rates:
        //  - Govt Land Rate: ₹ 5,500
        //  - Govt RCC Rate: ₹ 2,400
        //  - Govt Steel Rate: ₹ 1,900

        ValuationLandItem landItem = new ValuationLandItem();
        landItem.setDescription("Residential Plot");
        landItem.setSurveyNo("42/A");
        landItem.setEnteredUnit("Sq.Ft");
        landItem.setEnteredArea(new BigDecimal("5000"));
        landItem.setStandardAreaSqft(new BigDecimal("5000"));
        landItem.setRate(new BigDecimal("4500"));
        landItem.setValue(new BigDecimal("22500000.00"));

        ValuationBuildingItem bldgItem1 = new ValuationBuildingItem();
        bldgItem1.setDescription("Commercial Office Building");
        bldgItem1.setBuildingType("RCC Commercial");
        bldgItem1.setEnteredUnit("Sq.Ft");
        bldgItem1.setEnteredArea(new BigDecimal("4000"));
        bldgItem1.setStandardAreaSqft(new BigDecimal("4000"));
        bldgItem1.setReplacementRate(new BigDecimal("3500"));
        bldgItem1.setReplacementCost(new BigDecimal("14000000.00"));
        bldgItem1.setDepreciationAmount(new BigDecimal("1050000.00"));
        bldgItem1.setBuildingValue(new BigDecimal("12950000.00"));

        ValuationBuildingItem bldgItem2 = new ValuationBuildingItem();
        bldgItem2.setDescription("Industrial Storage Shed");
        bldgItem2.setBuildingType("Steel Shed");
        bldgItem2.setEnteredUnit("Sq.Ft");
        bldgItem2.setEnteredArea(new BigDecimal("3000"));
        bldgItem2.setStandardAreaSqft(new BigDecimal("3000"));
        bldgItem2.setReplacementRate(new BigDecimal("2000"));
        bldgItem2.setReplacementCost(new BigDecimal("6000000.00"));
        bldgItem2.setDepreciationAmount(new BigDecimal("450000.00"));
        bldgItem2.setBuildingValue(new BigDecimal("5550000.00"));

        // Government Value Calculation:
        BigDecimal govtLandVal = new BigDecimal("5000").multiply(new BigDecimal("5500")); // ₹ 2,75,00,000
        BigDecimal govtRccVal = new BigDecimal("4000").multiply(new BigDecimal("2400"));  // ₹ 96,00,000
        BigDecimal govtSteelVal = new BigDecimal("3000").multiply(new BigDecimal("1900")); // ₹ 57,00,000
        BigDecimal totalGovtVal = govtLandVal.add(govtRccVal).add(govtSteelVal);          // ₹ 4,28,00,000

        Map<String, String> inputs = new LinkedHashMap<>();
        inputs.put("REPORT_NO", "PV-2609-0003");
        inputs.put("PROPERTY_DESCRIPTION", "Prime Commercial Parcel & Multi-Use Complex");
        inputs.put("CLIENT_NAME", "Apex Enterprises & Industrial Parks Pvt Ltd");

        inputs.put("RAW_LAND_ITEMS_JSON", objectMapper.writeValueAsString(List.of(
                Map.of("description", "Residential Plot", "surveyNo", "42/A", "enteredUnit", "Sq.Ft", "enteredArea", "5000", "rate", "4500", "value", "22500000")
        )));

        inputs.put("RAW_BUILDING_ITEMS_JSON", objectMapper.writeValueAsString(List.of(
                Map.of("description", "Commercial Office Building", "buildingType", "RCC Commercial", "enteredUnit", "Sq.Ft", "enteredArea", "4000", "replacementRate", "3500", "replacementCost", "14000000", "depreciationAmount", "1050000", "buildingValue", "12950000"),
                Map.of("description", "Industrial Storage Shed", "buildingType", "Steel Shed", "enteredUnit", "Sq.Ft", "enteredArea", "3000", "replacementRate", "2000", "replacementCost", "6000000", "depreciationAmount", "450000", "buildingValue", "5550000")
        )));

        inputs.put("TOTAL_LAND_VALUE", "22500000");
        inputs.put("TOTAL_BUILDING_VALUE", "18500000");
        inputs.put("TOTAL_REPLACEMENT_COST", "20000000");
        inputs.put("FAIR_VALUE", "41000000");
        inputs.put("REALIZABLE_VALUE", "34850000");
        inputs.put("DISTRESS_SALE_VALUE", "30750000");
        inputs.put("GOVERNMENT_VALUE", totalGovtVal.toPlainString());
        inputs.put("INSURABLE_VALUE", "20000000");
        inputs.put("SAY_VALUE", "41000000");

        // 3. Generate Report DOCX
        byte[] docxBytes = templateEngine.generateReport(templateBytes, inputs, Collections.emptyMap());
        WordprocessingMLPackage resultPkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));

        // 4. Dump Detailed Table Evidence
        List<Object> content = resultPkg.getMainDocumentPart().getContent();
        int tblIdx = 1;
        for (Object item : content) {
            Object unwrapped = org.docx4j.XmlUtils.unwrap(item);
            if (unwrapped instanceof Tbl) {
                Tbl tbl = (Tbl) unwrapped;
                System.out.println("\n------------------------------------------------------------------------");
                System.out.println("EVIDENCE: GENERATED TABLE #" + tblIdx);
                System.out.println("------------------------------------------------------------------------");
                for (Object rObj : tbl.getContent()) {
                    Object unwrappedR = org.docx4j.XmlUtils.unwrap(rObj);
                    if (unwrappedR instanceof Tr) {
                        Tr tr = (Tr) unwrappedR;
                        StringBuilder sb = new StringBuilder("| ");
                        for (Object cObj : tr.getContent()) {
                            Object unwrappedC = org.docx4j.XmlUtils.unwrap(cObj);
                            if (unwrappedC instanceof Tc) {
                                Tc tc = (Tc) unwrappedC;
                                String cellText = getCellText(tc).trim();
                                sb.append(cellText.isEmpty() ? " " : cellText).append(" | ");
                            }
                        }
                        System.out.println(sb.toString());
                    }
                }
                tblIdx++;
            }
        }

        System.out.println("\n------------------------------------------------------------------------");
        System.out.println("GOVERNMENT VALUE CALCULATION TRACE:");
        System.out.println("------------------------------------------------------------------------");
        System.out.println("Land Area: 5,000 Sq.Ft");
        System.out.println("Govt Land Rate: ₹ 5,500/Sq.Ft");
        System.out.println("Land Govt Value: 5,000 × ₹ 5,500 = ₹ 2,75,00,000");
        System.out.println("RCC Area: 4,000 Sq.Ft");
        System.out.println("Govt RCC Rate: ₹ 2,400/Sq.Ft");
        System.out.println("RCC Govt Value: 4,000 × ₹ 2,400 = ₹ 96,00,000");
        System.out.println("Steel Area: 3,000 Sq.Ft");
        System.out.println("Govt Steel Rate: ₹ 1,900/Sq.Ft");
        System.out.println("Steel Govt Value: 3,000 × ₹ 1,900 = ₹ 57,00,000");
        System.out.println("Final Government Value = ₹ 2,75,00,000 + ₹ 96,00,000 + ₹ 57,00,000 = ₹ 4,28,00,000");
        System.out.println("------------------------------------------------------------------------\n");
    }

    private String getCellText(Tc tc) {
        StringBuilder sb = new StringBuilder();
        for (Object pObj : tc.getContent()) {
            Object unwrappedP = org.docx4j.XmlUtils.unwrap(pObj);
            if (unwrappedP instanceof P) {
                P p = (P) unwrappedP;
                for (Object rObj : p.getContent()) {
                    Object unwrappedR = org.docx4j.XmlUtils.unwrap(rObj);
                    if (unwrappedR instanceof R) {
                        R r = (R) unwrappedR;
                        for (Object tObj : r.getContent()) {
                            Object unwrappedT = org.docx4j.XmlUtils.unwrap(tObj);
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
