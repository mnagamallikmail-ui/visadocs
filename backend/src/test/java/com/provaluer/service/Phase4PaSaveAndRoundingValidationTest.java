package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.util.DocxTemplateEngine;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
public class Phase4PaSaveAndRoundingValidationTest {

    @Autowired private ValuationCalculationFormulaService formulaService;
    @Autowired private DocumentWorkspaceService documentWorkspaceService;
    @Autowired private DocxTemplateEngine docxTemplateEngine;
    @Autowired private OrderRepository orderRepository;
    @Autowired private OrderInputRepository orderInputRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private TemplateRepository templateRepository;
    @Autowired private ObjectMapper objectMapper;

    @Test
    @DisplayName("1. Rounding Governance: All 6 benchmark examples (< 1Cr -> 1,000; >= 1Cr -> 10,000) & all 4 fields")
    void testRoundingGovernanceBenchmarks() {
        // Below 1 Crore -> nearest 1,000
        assertEquals(0, new BigDecimal("1235000.00").compareTo(
                ValuationCalculationFormulaService.roundValuationOutput(new BigDecimal("1234567"))));
        assertEquals(0, new BigDecimal("8749000.00").compareTo(
                ValuationCalculationFormulaService.roundValuationOutput(new BigDecimal("8749251"))));
        assertEquals(0, new BigDecimal("8750000.00").compareTo(
                ValuationCalculationFormulaService.roundValuationOutput(new BigDecimal("8749751"))));

        // >= 1 Crore -> nearest 10,000
        assertEquals(0, new BigDecimal("16750000.00").compareTo(
                ValuationCalculationFormulaService.roundValuationOutput(new BigDecimal("16749500"))));
        assertEquals(0, new BigDecimal("23420000.00").compareTo(
                ValuationCalculationFormulaService.roundValuationOutput(new BigDecimal("23423100"))));
        assertEquals(0, new BigDecimal("54400000.00").compareTo(
                ValuationCalculationFormulaService.roundValuationOutput(new BigDecimal("54396501"))));

        // End-to-end Composite: Fair Value, Realizable Value, Distress Sale Value, Insurable Value rounded; Government Value untouched
        ValuationCompositeItem unit = new ValuationCompositeItem();
        unit.setItemCategory("MAIN_UNIT");
        unit.setDescription("Flat 302");
        unit.setEnteredUnit("Sq.Ft");
        unit.setQuantity(new BigDecimal("1234"));
        unit.setRate(new BigDecimal("6543")); // 80,74,062 (< 1 Cr)
        unit.setConstructionCost(new BigDecimal("2123")); // Insurable: 1234 * 2123 = 26,19,782 -> 26,20,000
        unit.setBuildingAge(new BigDecimal("0"));
        unit.setTotalLife(60);

        ValuationData data = new ValuationData();
        data.setValuationMethodology("COMPOSITE_RATE");
        data.setCompositeGovernmentRate(new BigDecimal("3333")); // 1234 * 3333 = 41,12,922 (MUST NOT BE ROUNDED!)
        formulaService.calculateCompositeSummary(data, List.of(unit));

        assertEquals(0, new BigDecimal("8074000.00").compareTo(data.getSayFairValue()), "Fair Value < 1Cr rounded to 1,000");
        assertEquals(0, new BigDecimal("6863000.00").compareTo(data.getRealizableValue()), "Realizable (85% of 80,74,000 = 68,62,900) -> 68,63,000");
        assertEquals(0, new BigDecimal("6056000.00").compareTo(data.getDistressSaleValue()), "Distress (75% of 80,74,000 = 60,55,500) -> 60,56,000");
        assertEquals(0, new BigDecimal("2620000.00").compareTo(data.getInsurableValue()), "Insurable (26,19,782) -> 26,20,000");
        assertEquals(0, new BigDecimal("4112922.00").compareTo(data.getGovernmentValue()), "Government Value MUST NOT be rounded");
    }

    @Test
    @DisplayName("3. Land & Building: No double rounding when crossing 1 Crore threshold")
    void testLandAndBuildingNoDoubleRoundingAcrossOneCrore() {
        // sayLand = 58,85,000 -> 85% raw = 50,02,250 (rounded individually would be 50,02,000)
        // sayBldg = 58,85,000 -> 85% raw = 50,02,250 (rounded individually would be 50,02,000)
        // Sum of raw = 1,00,04,500 -> rounded ONCE (>= 1Cr) = 1,00,00,000
        // (Double rounding would have been 50,02,000 + 50,02,000 = 1,00,04,000 -> 1,00,00,000,
        //  and for 58,85,000 * 85% vs 58,86,000 * 85%: 50,02,250 + 50,03,100 = 1,00,05,350 -> 1,00,10,000;
        //  whereas 58,85,000 * 85% + 58,85,500? Use 58,85,000 and 58,86,000:
        //  rawLand = 50,02,250 (ind: 50,02,000), rawBldg = 50,03,100 (ind: 50,03,000),
        //  rawSum = 1,00,05,350 -> 1,00,10,000; whereas indSum = 1,00,05,000 -> 1,00,10,000.
        //  True divergence case: rawLand = 50,02,400 (ind: 50,02,000), rawBldg = 50,02,400 (ind: 50,02,000)
        //  via 58,85,000 at 85% = 50,02,250 and 58,86,000 at 85% = 50,03,100; or 58,85,000 at 85.01%...
        //  With 58,85,000 (85% = 50,02,250) + 58,85,000 (85.01%? No, 58,85,000 at 85% = 50,02,250,
        //  and sayBldg = 58,85,000 at 85% = 50,02,250 -> rawSum = 1,00,04,500):
        //  Even sharper: sayLand = 66,70,000 (75% = 50,02,500 -> ind 50,03,000),
        //  sayBldg = 66,70,000 (75% = 50,02,500 -> ind 50,03,000):
        //  Wait: rawSum = 1,00,05,000 -> 1,00,10,000; indSum = 1,00,06,000 -> 1,00,10,000.
        //  Divergence case: sayLand = 58,86,000 * 85% = 50,03,100 (ind: 50,03,000)
        //                   sayBldg = 58,84,000 * 85% = 50,01,400 (ind: 50,01,000)
        //  Wait: 58,85,000 * 85.01% or 58,86,000 * 85% = 50,03,100 + 58,85,000 * 85% = 50,02,250.
        //  With 58,85,000 (85% = 50,02,250 -> ind 50,02,000) and 58,86,000 (85% = 50,03,100 -> ind 50,03,000)...
        //  Try 66,69,000 * 75% = 50,01,750 (ind: 50,02,000) + 66,71,000 * 75% = 50,03,250 (ind: 50,03,000) -> rawSum = 1,00,05,000 -> 1,00,10,000
        //  Try 66,69,000 * 75% = 50,01,750 (ind: 50,02,000) + 66,70,000 * 75% = 50,02,500 (ind: 50,03,000):
        //  rawSum = 1,00,04,250 -> rounded ONCE = 1,00,00,000!
        //  (Whereas double-rounded indSum = 50,02,000 + 50,03,000 = 1,00,05,000 -> would have rounded to 1,00,10,000!)
        ValuationLandItem land = new ValuationLandItem();
        land.setDescription("Plot A");
        land.setEnteredArea(new BigDecimal("6669"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("1000")); // sayLand = 66,69,000

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setDescription("Building B");
        bldg.setBuildingType("RCC");
        bldg.setEnteredArea(new BigDecimal("6670"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("1000"));
        bldg.setBuildingAge(BigDecimal.ZERO);
        bldg.setBuildingUsefulLife(60); // sayBldg = 66,70,000

        ValuationData data = new ValuationData();
        data.setValuationMethodology("LAND_AND_BUILDING");
        data.setLandRealizablePercentage(new BigDecimal("75.00"));
        data.setBuildingRealizablePercentage(new BigDecimal("75.00"));
        data.setLandDistressPercentage(new BigDecimal("75.00"));
        data.setBuildingDistressPercentage(new BigDecimal("75.00"));

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        // Exact components preserved unrounded
        assertEquals(0, new BigDecimal("5001750.00").compareTo(data.getLandRealizableValue()));
        assertEquals(0, new BigDecimal("5002500.00").compareTo(data.getBuildingRealizableValue()));
        // Sum of raw = 1,00,04,250 -> rounded ONCE to nearest 10,000 = 1,00,00,000 (NOT 1,00,10,000!)
        BigDecimal expected = ValuationCalculationFormulaService.roundValuationOutput(
                data.getLandRealizableValue().add(data.getBuildingRealizableValue()));
        assertEquals(0, new BigDecimal("10000000.00").compareTo(expected));
        assertEquals(0, expected.compareTo(data.getRealizableValue()));
        assertEquals(0, expected.compareTo(data.getDistressSaleValue()));
    }

    @Test
    @DisplayName("2. Property Analyst & Admin Save -> Reload -> DOCX -> PDF Full Parity")
    void testPaAndAdminSaveReloadDocxPdfParity() throws Exception {
        User paUser = new User();
        paUser.setUsername("pa_val_" + System.currentTimeMillis());
        paUser.setEmail("pa_val_" + System.currentTimeMillis() + "@provaluer.in");
        paUser.setPassword("secret");
        paUser.setRole(UserRole.PA);
        paUser = userRepository.save(paUser);

        User adminUser = new User();
        adminUser.setUsername("admin_val_" + System.currentTimeMillis());
        adminUser.setEmail("admin_val_" + System.currentTimeMillis() + "@provaluer.in");
        adminUser.setPassword("secret");
        adminUser.setRole(UserRole.ADMIN);
        adminUser = userRepository.save(adminUser);

        byte[] tplBytes = Files.readAllBytes(Path.of("official_flat_apartment_valuation_report.docx"));
        Template tpl = new Template();
        tpl.setName("Phase4 Composite Test Template");
        tpl.setFieldMapping("{}");
        tpl.setTemplateContent(tplBytes);
        tpl.setIsActive("Y");
        tpl.setVersion(1);
        tpl = templateRepository.save(tpl);

        Order order = new Order();
        order.setClientId(1L);
        order.setPaId(paUser.getId());
        order.setPurpose("Valuation");
        order.setPropertyCategory("Commercial Flat");
        order.setStatus("DRAFTING");
        order.setTemplateId(tpl.getId());
        order.setTemplateVersion(1);
        order = orderRepository.save(order);
        Long orderId = order.getId();

        // Seed stale lowercase OrderInput row that previously shadowed uppercase saves
        orderInputRepository.save(new OrderInput(orderId, "owner_name", "STALE OWNER"));

        UserDetailsImpl paPrincipal = new UserDetailsImpl(
                paUser.getId(), paUser.getUsername(), paUser.getEmail(), paUser.getPassword(),
                List.of(new SimpleGrantedAuthority("ROLE_PA")), true, true);
        UserDetailsImpl adminPrincipal = new UserDetailsImpl(
                adminUser.getId(), adminUser.getUsername(), adminUser.getEmail(), adminUser.getPassword(),
                List.of(new SimpleGrantedAuthority("ROLE_ADMIN")), true, true);

        // PA enters values and saves
        ValuationCompositeItem item = new ValuationCompositeItem();
        item.setItemCategory("MAIN_UNIT");
        item.setDescription("Office 707");
        item.setEnteredUnit("Sq.Ft");
        item.setQuantity(new BigDecimal("1234"));
        item.setRate(new BigDecimal("6543")); // 80,74,062 -> Say 80,74,000
        item.setConstructionCost(new BigDecimal("2123")); // Insurable -> 26,20,000
        item.setBuildingAge(new BigDecimal("0"));
        item.setTotalLife(60);

        SaveDocumentValuesRequest paReq = new SaveDocumentValuesRequest();
        paReq.setWorkspaceRevision(order.getWorkspaceRevision() != null ? order.getWorkspaceRevision() : 1);
        paReq.setValues(Map.of(
                "OWNER_NAME", "Verified PA Owner Pvt Ltd",
                "RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(List.of(item))
        ));
        Map<String, String> saveRes = documentWorkspaceService.saveDocumentValues(orderId, paReq, paPrincipal);
        assertEquals("SAVED", saveRes.get("status"));

        // Simulate Logout -> Login -> Reopen Workspace as PA
        var reloadedWs = documentWorkspaceService.getDocumentWorkspace(orderId, paPrincipal);
        assertEquals("Verified PA Owner Pvt Ltd", reloadedWs.getValues().get("OWNER_NAME"));
        assertEquals("80,74,000", reloadedWs.getValues().get("SAY_VALUE"));
        assertEquals("68,63,000", reloadedWs.getValues().get("REALIZABLE_VALUE"));
        assertEquals("60,56,000", reloadedWs.getValues().get("DISTRESS_SALE_VALUE"));
        assertEquals("26,20,000", reloadedWs.getValues().get("INSURABLE_VALUE"));

        // Verify Admin also sees exact same persisted values & can generate DOCX/PDF
        Map<String, String> adminConsolidated = documentWorkspaceService.getConsolidatedValues(orderId);
        assertEquals("80,74,000", adminConsolidated.get("SAY_VALUE"));

        byte[] docxBytes = docxTemplateEngine.generateReport(tplBytes, adminConsolidated, Collections.emptyMap());
        byte[] pdfBytes = docxTemplateEngine.convertDocxToPdf(docxBytes);
        try (PDDocument pdf = Loader.loadPDF(pdfBytes)) {
            String text = new PDFTextStripper().getText(pdf);
            assertTrue(text.contains("80,74,000"), "PDF must contain rounded Fair Value 80,74,000");
            assertTrue(text.contains("68,63,000"), "PDF must contain rounded Realizable Value 68,63,000");
            assertTrue(text.contains("60,56,000"), "PDF must contain rounded Distress Sale Value 60,56,000");
            assertTrue(text.contains("26,20,000"), "PDF must contain rounded Insurable Value 26,20,000");
            assertTrue(text.contains("Verified PA Owner Pvt Ltd"), "PDF must contain PA-saved OWNER_NAME");
        }

        // Verify SPA_GATE marks workspace readOnly = true for PA (consistent with validateOrderAccess)
        order.setStatus("SPA_GATE");
        orderRepository.save(order);
        var spaGateWsForPa = documentWorkspaceService.getDocumentWorkspace(orderId, paPrincipal);
        assertTrue(spaGateWsForPa.isReadOnly(), "PA must see readOnly=true in SPA_GATE");
        var spaGateWsForAdmin = documentWorkspaceService.getDocumentWorkspace(orderId, adminPrincipal);
        assertFalse(spaGateWsForAdmin.isReadOnly(), "Admin must retain edit access in SPA_GATE");
    }
}

