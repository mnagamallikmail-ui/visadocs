package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.P;
import org.docx4j.wml.R;
import org.docx4j.wml.Text;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.util.*;
import java.util.zip.ZipInputStream;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
public class Phase8ReportIntegrityRegressionTest {

    @Autowired
    private ValuationCalculationFormulaService formulaService;

    @Autowired
    private ValuationEngineService valuationEngineService;

    @Autowired
    private DocumentWorkspaceService documentWorkspaceService;

    @Autowired
    private DocxTemplateEngine docxTemplateEngine;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderInputRepository orderInputRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private byte[] createTemplateWithDirectives(List<String> lines) throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        var factory = new org.docx4j.wml.ObjectFactory();
        for (String line : lines) {
            P p = factory.createP();
            R r = factory.createR();
            Text t = factory.createText();
            t.setValue(line);
            r.getContent().add(t);
            p.getContent().add(r);
            pkg.getMainDocumentPart().getContent().add(p);
        }
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        pkg.save(out);
        return out.toByteArray();
    }

    private String extractDocumentXml(byte[] docxBytes) throws Exception {
        try (ZipInputStream zis = new ZipInputStream(new ByteArrayInputStream(docxBytes))) {
            var entry = zis.getNextEntry();
            while (entry != null) {
                if ("word/document.xml".equals(entry.getName())) {
                    return new String(zis.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
                }
                entry = zis.getNextEntry();
            }
        }
        return "";
    }

    @Test
    @DisplayName("1. Composite / Apartment / Commercial: Large currency 16560000, Parking depreciation, Total rows, Table width <= 9600 dxa, No header noWrap")
    void testCompositeDocxLayoutAndCalculationParity() throws Exception {
        ValuationCompositeItem mainUnit = new ValuationCompositeItem();
        mainUnit.setItemCategory("MAIN_UNIT");
        mainUnit.setDescription("Commercial Unit 401");
        mainUnit.setEnteredUnit("Sq.Ft");
        mainUnit.setQuantity(new BigDecimal("2070"));
        mainUnit.setRate(new BigDecimal("8000"));
        mainUnit.setConstructionCost(new BigDecimal("2000"));
        mainUnit.setBuildingAge(new BigDecimal("5"));
        mainUnit.setTotalLife(60);

        ValuationCompositeItem parking = new ValuationCompositeItem();
        parking.setItemCategory("PARKING");
        parking.setDescription("Covered Car Parking");
        parking.setEnteredUnit("Slot");
        parking.setQuantity(new BigDecimal("2"));
        parking.setRate(new BigDecimal("250000"));
        parking.setDepreciationMode("PERCENTAGE"); // Default from frontend model
        parking.setDepreciationAmount(new BigDecimal("50000"));

        List<ValuationCompositeItem> items = List.of(mainUnit, parking);
        ValuationData data = new ValuationData();
        data.setValuationMethodology("COMPOSITE_RATE");
        formulaService.calculateCompositeSummary(data, items);

        // Verify Parking depreciation was preserved (5,00,000 - 50,000 = 4,50,000)
        assertEquals(0, new BigDecimal("50000.00").compareTo(parking.getDepreciationAmount()),
                "Parking direct depreciationAmount must be preserved even when depreciationMode=PERCENTAGE");
        assertEquals(0, new BigDecimal("450000.00").compareTo(parking.getFairValue()));

        // Verify Main Unit Amount = 2070 * 8000 = 1,65,60,000
        assertEquals(0, new BigDecimal("16560000.00").compareTo(mainUnit.getAmount()));
        // Main Unit Depr = 2070 * 2000 * 0.90 * 5 / 60 = 3,10,500
        assertEquals(0, new BigDecimal("310500.00").compareTo(mainUnit.getDepreciationAmount()));
        // Main Unit Fair Value = 1,65,60,000 - 3,10,500 = 1,62,49,500
        assertEquals(0, new BigDecimal("16249500.00").compareTo(mainUnit.getFairValue()));
        // Total Fair Value = 1,62,49,500 + 4,50,000 = 1,66,99,500
        assertEquals(0, new BigDecimal("16699500.00").compareTo(data.getRawFairValue()));
        // Say Value = 1,67,00,000
        assertEquals(0, new BigDecimal("16700000.00").compareTo(data.getSayFairValue()));

        Order order = new Order();
        order.setId(9901L);
        Map<String, String> placeholders = valuationEngineService.generatePlaceholders(
                order, data, List.of(), List.of(), List.of(), items);

        assertEquals("1,70,60,000", placeholders.get("TOTAL_AMOUNT"));
        assertEquals("3,60,500", placeholders.get("TOTAL_DEPRECIATION"));
        assertEquals("1,66,99,500", placeholders.get("TOTAL_FAIR_VALUE"));
        assertEquals("1,67,00,000", placeholders.get("SAY_VALUE"));

        Map<String, String> inputs = new HashMap<>(placeholders);
        inputs.put("RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(items));

        byte[] tpl = createTemplateWithDirectives(List.of("<<COMPOSITE_PROPERTY_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        byte[] outDocx = docxTemplateEngine.generateReport(tpl, inputs, Collections.emptyMap());
        String xml = extractDocumentXml(outDocx);

        // Verify large figure 1,65,60,000 and totals appear intact
        String textOnly = xml.replaceAll("<[^>]+>", " ").replaceAll("\\s+", " ");
        assertTrue(xml.contains("Rs 1,65,60,000"), "DOCX must contain full Rs 1,65,60,000 without truncation. Text: " + textOnly.substring(0, Math.min(textOnly.length(), 1000)));
        assertTrue(xml.contains("Total Amount"), "DOCX Composite table must include Total Amount row");
        assertTrue(xml.contains("Rs 1,70,60,000"), "DOCX must contain Total Amount Rs 1,70,60,000");
        assertTrue(xml.contains("Total Depreciation"), "DOCX Composite table must include Total Depreciation row");
        assertTrue(xml.contains("Rs 3,60,500"), "DOCX must contain Total Depreciation Rs 3,60,500");
        assertTrue(xml.contains("Fair Value Of Property"), "DOCX must contain Fair Value Of Property");
        assertTrue(xml.contains("Rs 1,66,99,500"), "DOCX must contain Fair Value Of Property Rs 1,66,99,500");
        assertTrue(xml.contains("Rs 1,67,00,000"), "DOCX must contain Say Value Rs 1,67,00,000");

        // Verify table width == 9600 dxa (fits within A4 9922 dxa printable width) and no header <w:noWrap/>
        assertTrue(xml.contains("w:w=\"9600\""), "Table width must be 9600 dxa");
        assertFalse(xml.contains("<w:noWrap"), "Header cells must not force <w:noWrap/> overflow");
    }

    @Test
    @DisplayName("2. Land & Building (Residential / Industrial / Agricultural): Calculation & DOCX parity")
    void testLandAndBuildingParity() throws Exception {
        ValuationLandItem land = new ValuationLandItem();
        land.setDescription("Industrial Plot");
        land.setEnteredArea(new BigDecimal("1000"));
        land.setEnteredUnit("Sq.Yd");
        land.setRate(new BigDecimal("15000")); // 1,50,00,000

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setDescription("PEB Factory Shed");
        bldg.setBuildingType("PEB Structure");
        bldg.setEnteredArea(new BigDecimal("5000"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("1800")); // 90,00,000
        bldg.setBuildingAge(new BigDecimal("10"));
        bldg.setBuildingUsefulLife(0); // Auto-defaults to 40 for PEB
        bldg.setSalvagePercentage(new BigDecimal("10.00"));

        ValuationData data = new ValuationData();
        data.setValuationMethodology("LAND_AND_BUILDING");
        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(40, bldg.getBuildingUsefulLife());
        // Depr = 90,00,000 * (10/40) * 0.90 = 20,25,000 -> Building Value = 69,75,000
        assertEquals(0, new BigDecimal("6975000.00").compareTo(bldg.getBuildingValue()));

        Order order = new Order();
        order.setId(9902L);
        Map<String, String> placeholders = valuationEngineService.generatePlaceholders(
                order, data, List.of(land), List.of(bldg), List.of(), List.of());

        Map<String, String> inputs = new HashMap<>(placeholders);
        inputs.put("RAW_LAND_ITEMS_JSON", objectMapper.writeValueAsString(List.of(land)));
        inputs.put("RAW_BUILDING_ITEMS_JSON", objectMapper.writeValueAsString(List.of(bldg)));

        byte[] tpl = createTemplateWithDirectives(List.of("<<LAND_TABLE>>", "<<BUILDING_TABLE>>", "<<VALUATION_SUMMARY_TABLE>>"));
        byte[] outDocx = docxTemplateEngine.generateReport(tpl, inputs, Collections.emptyMap());
        String xml = extractDocumentXml(outDocx);

        assertTrue(xml.contains("1,50,00,000"));
        assertTrue(xml.contains("69,75,000"));
        assertTrue(xml.contains("w:w=\"9600\""));
    }

    @Test
    @DisplayName("3. Placeholder Synchronization & Report Cache Invalidation on Save")
    void testStalePlaceholderOverrideAndCacheInvalidation() {
        User uploader = userRepository.findAll().stream().findFirst().orElseGet(() -> {
            User u = new User();
            u.setUsername("phase8_tester_" + System.currentTimeMillis());
            u.setEmail("phase8_" + System.currentTimeMillis() + "@provaluer.in");
            u.setPassword("secret");
            u.setRole(UserRole.SPA);
            return userRepository.save(u);
        });

        Order order = new Order();
        order.setClientId(1L);
        order.setPurpose("Valuation");
        order.setPropertyCategory("Commercial Flat");
        order.setStatus("SPA_GATE");
        order = orderRepository.save(order);
        Long orderId = order.getId();

        // Seed stale non-zero OrderInput values
        orderInputRepository.save(new OrderInput(orderId, "SAY_VALUE", "50,00,000"));
        orderInputRepository.save(new OrderInput(orderId, "RAW_FAIR_VALUE", "49,95,000"));

        // Seed cached FINAL_DOCX and FINAL_SIGNED_PDF
        OrderDocument cachedDocx = new OrderDocument();
        cachedDocx.setOrder(order);
        cachedDocx.setCategory("FINAL_DOCX");
        cachedDocx.setFilename("Report_" + orderId + ".docx");
        cachedDocx.setFileContent(new byte[]{1, 2, 3});
        cachedDocx.setUploadedBy(uploader);
        orderDocumentRepository.save(cachedDocx);

        OrderDocument cachedPdf = new OrderDocument();
        cachedPdf.setOrder(order);
        cachedPdf.setCategory("FINAL_SIGNED_PDF");
        cachedPdf.setFilename("Report_" + orderId + ".pdf");
        cachedPdf.setFileContent(new byte[]{4, 5, 6});
        cachedPdf.setUploadedBy(uploader);
        orderDocumentRepository.save(cachedPdf);

        // Update composite item via saveDocumentValues -> must recalculate AND invalidate cached docs
        ValuationCompositeItem updatedItem = new ValuationCompositeItem();
        updatedItem.setItemCategory("MAIN_UNIT");
        updatedItem.setDescription("Flat 101");
        updatedItem.setEnteredUnit("Sq.Ft");
        updatedItem.setQuantity(new BigDecimal("2070"));
        updatedItem.setRate(new BigDecimal("8000"));
        updatedItem.setConstructionCost(new BigDecimal("2000"));
        updatedItem.setBuildingAge(new BigDecimal("0"));
        updatedItem.setTotalLife(60);

        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        try {
            req.setValues(Map.of("RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(List.of(updatedItem))));
        } catch (Exception e) {
            fail(e);
        }

        com.provaluer.security.UserDetailsImpl spaPrincipal = new com.provaluer.security.UserDetailsImpl(
                uploader.getId(), uploader.getUsername(), uploader.getEmail(), uploader.getPassword(),
                List.of(new org.springframework.security.core.authority.SimpleGrantedAuthority("ROLE_SPA")), true, true);
        documentWorkspaceService.saveDocumentValues(orderId, req, spaPrincipal);

        // Verify cached FINAL_DOCX and FINAL_SIGNED_PDF were invalidated
        List<OrderDocument> remainingDocs = orderDocumentRepository.findAllByOrderId(orderId);
        boolean hasFinalDocx = remainingDocs.stream().anyMatch(d -> "FINAL_DOCX".equalsIgnoreCase(d.getCategory()));
        boolean hasFinalPdf = remainingDocs.stream().anyMatch(d -> "FINAL_SIGNED_PDF".equalsIgnoreCase(d.getCategory()));
        assertFalse(hasFinalDocx, "FINAL_DOCX cache must be invalidated after saveDocumentValues");
        assertFalse(hasFinalPdf, "FINAL_SIGNED_PDF cache must be invalidated after saveDocumentValues");

        // Verify getConsolidatedValues returns fresh calculated values instead of stale 50,00,000
        Map<String, String> consolidated = documentWorkspaceService.getConsolidatedValues(orderId);
        assertEquals("1,65,60,000", consolidated.get("SAY_VALUE"),
                "Stale SAY_VALUE in OrderInput must be overwritten by fresh calculation engine output");
        assertEquals("1,65,60,000", consolidated.get("RAW_FAIR_VALUE"));
    }
}
