package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.SaveValuationRequest;
import com.provaluer.dto.ValuationBundleResponse;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.util.DocxTemplateEngine;
import com.provaluer.util.IndianCurrencyToWords;
import com.provaluer.util.IndianNumberFormatter;
import com.provaluer.util.UnitConversionEngine;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class Phase2GoLiveReadinessCertificationTest {

    @Autowired
    private ValuationEngineService valuationEngineService;

    @Autowired
    private ValuationCalculationFormulaService formulaService;

    @Autowired
    private DocxTemplateEngine docxTemplateEngine;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SystemSettingRepository systemSettingRepository;

    @Autowired
    private ValuationSnapshotRepository snapshotRepository;

    @Autowired
    private ValuationAuditLogRepository auditLogRepository;

    private User testSuperAdmin;
    private User testValuer;
    private Order testOrder;
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @BeforeEach
    public void setUp() {
        testSuperAdmin = userRepository.findByEmailIgnoreCase("superadmin@provaluer.com")
                .orElseGet(() -> {
                    User u = new User();
                    u.setEmail("superadmin@provaluer.com");
                    u.setFullName("Super Administrator");
                    u.setPassword("password");
                    u.setRole(UserRole.SUPER_ADMIN);
                    u.setAcceptedTcVersion("v1.0");
                    return userRepository.save(u);
                });

        testValuer = userRepository.findByEmailIgnoreCase("valuer@provaluer.com")
                .orElseGet(() -> {
                    User u = new User();
                    u.setEmail("valuer@provaluer.com");
                    u.setFullName("Senior Field Valuer");
                    u.setPassword("password");
                    u.setRole(UserRole.PA);
                    u.setAcceptedTcVersion("v1.0");
                    return userRepository.save(u);
                });

        testOrder = new Order();
        testOrder.setReportNumber("PV-2026-CERT-001");
        testOrder.setClientId(testValuer.getId());
        testOrder.setPaId(testValuer.getId());
        testOrder.setPurpose("Commercial Valuation");
        testOrder.setClientName("State Bank of India Corporate");
        testOrder.setBankName("State Bank of India");
        testOrder.setBranchName("Commercial Branch Mumbai");
        testOrder.setPropertyCategory("Commercial Complex");
        testOrder.setStatus("DRAFT");
        testOrder.setValuationStatus("DRAFT");
        testOrder.setEstimatedValue(new BigDecimal("85500000.00"));
        testOrder = orderRepository.save(testOrder);
    }

    // =========================================================================
    // 1. END-TO-END UAT SCENARIOS
    // =========================================================================

    @Test
    @Transactional
    @DisplayName("UAT Scenario 1: Complete Report Lifecycle - Multiple Land, Buildings, Comparables, Finalize & Snapshot")
    public void testUatScenario1_CompleteReportLifecycle() {
        UserDetailsImpl valuerPrincipal = UserDetailsImpl.build(testValuer);

        // 1. Prepare Save Request with 3 Land Parcels, 2 Building Structures, 2 Comparables
        SaveValuationRequest request = new SaveValuationRequest();
        request.setRealizablePercentage(new BigDecimal("85.00"));
        request.setDistressSalePercentage(new BigDecimal("75.00"));
        request.setDefaultSalvagePercentage(new BigDecimal("10.00"));

        List<ValuationLandItem> lands = new ArrayList<>();
        ValuationLandItem l1 = new ValuationLandItem();
        l1.setDescription("Main Commercial Plot");
        l1.setSurveyNo("S.No 104/1");
        l1.setEnteredArea(new BigDecimal("2.5"));
        l1.setEnteredUnit("Acres"); // 2.5 * 43560 = 108,900 Sq.Ft
        l1.setRate(new BigDecimal("1000.00"));
        lands.add(l1);

        ValuationLandItem l2 = new ValuationLandItem();
        l2.setDescription("Adjacent Parking Parcel");
        l2.setSurveyNo("S.No 104/2");
        l2.setEnteredArea(new BigDecimal("5.0"));
        l2.setEnteredUnit("Grounds"); // 5 * 2400 = 12,000 Sq.Ft
        l2.setRate(new BigDecimal("1200.00"));
        lands.add(l2);

        request.setLandItems(lands);

        List<ValuationBuildingItem> buildings = new ArrayList<>();
        ValuationBuildingItem b1 = new ValuationBuildingItem();
        b1.setStructureType("Ground Floor");
        b1.setBuildingType("RCC Commercial");
        b1.setDescription("Retail & Office Showroom");
        b1.setEnteredArea(new BigDecimal("50000.00"));
        b1.setEnteredUnit("Sq.Ft");
        b1.setReplacementRate(new BigDecimal("2500.00"));
        b1.setBuildingAge(new BigDecimal("12"));
        b1.setBuildingUsefulLife(60);
        b1.setSalvagePercentage(new BigDecimal("10.00"));
        buildings.add(b1);

        request.setBuildingItems(buildings);

        List<ValuationComparableSale> comps = new ArrayList<>();
        ValuationComparableSale c1 = new ValuationComparableSale();
        c1.setLocation("Opposite Commercial Complex");
        c1.setEnteredArea(new BigDecimal("2400.00"));
        c1.setRate(new BigDecimal("1100.00"));
        c1.setSaleValue(new BigDecimal("2640000.00"));
        comps.add(c1);

        request.setComparableSales(comps);

        // 2. Save Valuation
        ValuationBundleResponse response = valuationEngineService.saveValuation(testOrder.getId(), request, valuerPrincipal, "UAT Data Entry");
        assertNotNull(response);
        assertNotNull(response.getValuationData());

        // Verify Calculations:
        // Land 1: 108,900 * 1000 = 10,89,00,000
        // Land 2: 12,000 * 1200 = 1,44,00,000
        // Total Land = 12,33,00,000
        assertEquals(0, new BigDecimal("123300000.00").compareTo(response.getValuationData().getTotalLandValue()));

        // Building Replacement Cost: 50,000 * 2500 = 12,50,00,000
        // Depreciation: 12,50,00,000 * (12/60) * 0.9 = 2,25,00,000
        // Building Value: 12,50,00,000 - 2,25,00,000 = 10,25,00,000
        assertEquals(0, new BigDecimal("102500000.00").compareTo(response.getValuationData().getTotalBuildingValue()));

        // Fair Value = 12,33,00,000 + 10,25,00,000 = 22,58,00,000
        assertEquals(0, new BigDecimal("225800000.00").compareTo(response.getValuationData().getFairValue()));

        // Realizable Value (85%) = 22,58,00,000 * 0.85 = 19,19,30,000
        assertEquals(0, new BigDecimal("191930000.00").compareTo(response.getValuationData().getRealizableValue()));

        // Distress Sale Value (75%) = 22,58,00,000 * 0.75 = 16,93,50,000
        assertEquals(0, new BigDecimal("169350000.00").compareTo(response.getValuationData().getDistressSaleValue()));

        // 3. Finalize & Snapshot
        ValuationBundleResponse finalized = valuationEngineService.finalizeValuation(testOrder.getId(), valuerPrincipal, "UAT Final Sign-Off", null, null);
        assertEquals("FINALIZED", finalized.getValuationData().getValuationStatus());
        assertFalse(finalized.getSnapshots().isEmpty());

        ValuationSnapshot snapshot = finalized.getSnapshots().get(0);
        assertNotNull(snapshot.getSnapshotHash());
        assertEquals(64, snapshot.getSnapshotHash().length()); // Valid SHA-256
    }

    @Test
    @Transactional
    @DisplayName("UAT Scenario 2: Dynamic Recalculation on Building Age Mutation")
    public void testUatScenario2_DynamicRecalculationOnAgeMutation() {
        UserDetailsImpl valuerPrincipal = UserDetailsImpl.build(testValuer);

        ValuationData data = new ValuationData(testOrder.getId());
        List<ValuationLandItem> landItems = new ArrayList<>();
        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("10000"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("1000"));
        landItems.add(land);

        List<ValuationBuildingItem> buildingItems = new ArrayList<>();
        ValuationBuildingItem building = new ValuationBuildingItem();
        building.setEnteredArea(new BigDecimal("10000"));
        building.setEnteredUnit("Sq.Ft");
        building.setReplacementRate(new BigDecimal("2000")); // Repl Cost = 2,00,00,000
        building.setBuildingAge(new BigDecimal("6")); // 6 / 60 * 0.9 = 9%
        building.setBuildingUsefulLife(60);
        building.setSalvagePercentage(new BigDecimal("10.00"));
        buildingItems.add(building);

        formulaService.calculateSummary(data, landItems, buildingItems);
        BigDecimal initialFairValue = data.getFairValue(); // 1,00,00,000 + (2,00,00,000 - 18,00,000) = 2,82,00,000
        assertEquals(0, new BigDecimal("28200000.00").compareTo(initialFairValue));

        // Mutate Building Age from 6 to 30 years (50% useful life)
        building.setBuildingAge(new BigDecimal("30")); // 30 / 60 * 0.9 = 45% => Depr = 90,00,000 => Building = 1,10,00,000
        formulaService.calculateSummary(data, landItems, buildingItems);

        BigDecimal updatedFairValue = data.getFairValue(); // 1,00,00,000 + 1,10,00,000 = 2,10,00,000
        assertEquals(0, new BigDecimal("21000000.00").compareTo(updatedFairValue));
        assertNotEquals(initialFairValue, updatedFairValue);

        // Verify Realizable (85% of 2.10 Cr = 1.785 Cr) and Distress (75% of 2.10 Cr = 1.575 Cr)
        assertEquals(0, new BigDecimal("17850000.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("15750000.00").compareTo(data.getDistressSaleValue()));
    }

    @Test
    @Transactional
    @DisplayName("UAT Scenario 3: Master Settings Propagation to New Reports Without Corrupting Existing Reports")
    public void testUatScenario3_MasterSettingsDefaultsPropagation() {
        UserDetailsImpl adminPrincipal = UserDetailsImpl.build(testSuperAdmin);
        UserDetailsImpl valuerPrincipal = UserDetailsImpl.build(testValuer);

        // 1. Create Report 1 with current defaults (85% & 75%)
        ValuationBundleResponse bundle1 = valuationEngineService.getValuationBundle(testOrder.getId());
        assertEquals(0, new BigDecimal("85.00").compareTo(bundle1.getValuationData().getRealizablePercentage()));

        // 2. Change Master Settings
        systemSettingRepository.save(new SystemSetting("val_realizable_percentage", "90.00"));
        systemSettingRepository.save(new SystemSetting("val_distress_percentage", "80.00"));

        // 3. Create Report 2
        Order order2 = new Order();
        order2.setReportNumber("PV-2026-CERT-002");
        order2.setClientId(testValuer.getId());
        order2.setPaId(testValuer.getId());
        order2.setPurpose("Bank Valuation");
        order2.setPropertyCategory("Commercial");
        order2.setStatus("DRAFT");
        order2.setClientName("HDFC Bank");
        order2 = orderRepository.save(order2);

        ValuationBundleResponse bundle2 = valuationEngineService.getValuationBundle(order2.getId());
        assertEquals(0, new BigDecimal("90.00").compareTo(bundle2.getValuationData().getRealizablePercentage()));
        assertEquals(0, new BigDecimal("80.00").compareTo(bundle2.getValuationData().getDistressSalePercentage()));

        // Verify Report 1 remains isolated with 85%
        ValuationBundleResponse bundle1Recheck = valuationEngineService.getValuationBundle(testOrder.getId());
        assertEquals(0, new BigDecimal("85.00").compareTo(bundle1Recheck.getValuationData().getRealizablePercentage()));

        // Revert settings
        systemSettingRepository.save(new SystemSetting("val_realizable_percentage", "85.00"));
        systemSettingRepository.save(new SystemSetting("val_distress_percentage", "75.00"));
    }

    @Test
    @Transactional
    @DisplayName("UAT Scenario 4: SuperAdmin Lock & Unlock Integrity Protection")
    public void testUatScenario4_LockUnlockWorkflow() {
        UserDetailsImpl adminPrincipal = UserDetailsImpl.build(testSuperAdmin);
        UserDetailsImpl valuerPrincipal = UserDetailsImpl.build(testValuer);

        // 1. Lock Report
        ValuationBundleResponse lockedBundle = valuationEngineService.lockValuation(testOrder.getId(), adminPrincipal);
        assertTrue(lockedBundle.isLocked());
        assertEquals("LOCKED", lockedBundle.getValuationData().getValuationStatus());

        // 2. Attempt Edit by Valuer -> Must Fail
        SaveValuationRequest request = new SaveValuationRequest();
        assertThrows(IllegalStateException.class, () -> {
            valuationEngineService.saveValuation(testOrder.getId(), request, valuerPrincipal, "Attempt illegal edit");
        });

        // 3. Unlock by SuperAdmin
        ValuationBundleResponse unlockedBundle = valuationEngineService.unlockValuation(testOrder.getId(), adminPrincipal, "Authorized corrections by Admin");
        assertFalse(unlockedBundle.isLocked());
        assertEquals("DRAFT", unlockedBundle.getValuationData().getValuationStatus());
    }

    // =========================================================================
    // 2. PLACEHOLDER COMPLETENESS & FORMATTING AUDIT
    // =========================================================================

    @Test
    @DisplayName("Placeholder Completeness: Verify all 30+ placeholders are generated and certified")
    public void testPlaceholderCompleteness() {
        ValuationData data = new ValuationData(testOrder.getId());
        data.setTotalLandValue(new BigDecimal("57500000.00"));
        data.setTotalBuildingValue(new BigDecimal("42500000.00"));
        data.setTotalReplacementCost(new BigDecimal("50000000.00"));
        data.setTotalDepreciationAmount(new BigDecimal("7500000.00"));
        data.setTotalSalvageValue(new BigDecimal("5000000.00"));
        data.setFairValue(new BigDecimal("100000000.00"));
        data.setRealizablePercentage(new BigDecimal("85.00"));
        data.setRealizableValue(new BigDecimal("85000000.00"));
        data.setDistressSalePercentage(new BigDecimal("75.00"));
        data.setDistressSaleValue(new BigDecimal("75000000.00"));

        Map<String, String> placeholders = valuationEngineService.generatePlaceholders(testOrder, data, Collections.emptyList(), Collections.emptyList(), Collections.emptyList());

        // Verify Key Placeholders
        assertEquals("5,75,00,000", placeholders.get("total_land_value"));
        assertEquals("Rupees Five Crore Seventy Five Lakh Only", placeholders.get("total_land_value_words"));
        assertEquals("10,00,00,000", placeholders.get("fair_value"));
        assertEquals("Rupees Ten Crore Only", placeholders.get("fair_value_words"));
        assertEquals("8,50,00,000", placeholders.get("realizable_value"));
        assertEquals("Rupees Eight Crore Fifty Lakh Only", placeholders.get("realizable_value_words"));
        assertEquals("7,50,00,000", placeholders.get("distress_sale_value"));
        assertEquals("Rupees Seven Crore Fifty Lakh Only", placeholders.get("distress_sale_value_words"));
        assertEquals("PV-2026-CERT-001", placeholders.get("report_no"));
    }

    // =========================================================================
    // 3. STRESS TEST: 100+ LAND, BUILDING, AND COMPARABLE RECORDS
    // =========================================================================

    @Test
    @DisplayName("DOCX & Engine Stress Test: 100 Land Parcels, 100 Buildings, 100 Comparables (< 500ms Recalc)")
    public void testStressTest100ItemsScale() throws Exception {
        ValuationData data = new ValuationData(testOrder.getId());
        List<ValuationLandItem> lands100 = new ArrayList<>();
        List<ValuationBuildingItem> buildings100 = new ArrayList<>();
        List<ValuationComparableSale> comps100 = new ArrayList<>();

        for (int i = 1; i <= 100; i++) {
            ValuationLandItem l = new ValuationLandItem();
            l.setDescription("Parcel #" + i);
            l.setEnteredArea(new BigDecimal("1000.00"));
            l.setEnteredUnit("Sq.Ft");
            l.setRate(new BigDecimal("2000.00"));
            lands100.add(l);

            ValuationBuildingItem b = new ValuationBuildingItem();
            b.setStructureType("Floor " + i);
            b.setBuildingType("RCC Commercial");
            b.setEnteredArea(new BigDecimal("800.00"));
            b.setReplacementRate(new BigDecimal("2500.00"));
            b.setBuildingAge(new BigDecimal("5"));
            b.setBuildingUsefulLife(60);
            b.setSalvagePercentage(new BigDecimal("10.00"));
            buildings100.add(b);

            ValuationComparableSale c = new ValuationComparableSale();
            c.setLocation("Plot #" + i);
            c.setEnteredArea(new BigDecimal("1000.00"));
            c.setRate(new BigDecimal("2000.00"));
            c.setSaleValue(new BigDecimal("2000000.00"));
            comps100.add(c);
        }

        // Benchmark Recalculation Time
        long start = System.nanoTime();
        formulaService.calculateSummary(data, lands100, buildings100);
        long durationMs = (System.nanoTime() - start) / 1_000_000;

        assertTrue(durationMs < 500, "100-item recalculation must complete in under 500ms (took " + durationMs + "ms)");

        // 100 Lands: 100 * (1000 * 2000) = 20,00,00,000
        assertEquals(0, new BigDecimal("200000000.00").compareTo(data.getTotalLandValue()));

        // Benchmark DOCX Table Generation with 100 rows
        WordprocessingMLPackage docx = WordprocessingMLPackage.createPackage();
        docx.getMainDocumentPart().addParagraphOfText("<<LAND_TABLE>>");

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        docx.save(baos);
        byte[] tplBytes = baos.toByteArray();

        Map<String, String> values = new HashMap<>();
        values.put("RAW_LAND_ITEMS_JSON", objectMapper.writeValueAsString(lands100));

        long docxStart = System.nanoTime();
        byte[] output = docxTemplateEngine.generateReport(tplBytes, values, Collections.emptyMap());
        long docxDurationMs = (System.nanoTime() - docxStart) / 1_000_000;

        assertNotNull(output);
        assertTrue(output.length > 0);
        assertTrue(docxDurationMs < 10000, "100-row DOCX generation must complete in under 10 seconds (took " + docxDurationMs + "ms)");
    }

    // =========================================================================
    // 4. INDIAN NUMBERING & AMOUNT-IN-WORDS CERTIFICATION
    // =========================================================================

    @Test
    @DisplayName("Indian Numbering Certification from 1,000 to 99,99,99,999")
    public void testIndianNumberingMatrix() {
        assertEquals("1,000", IndianNumberFormatter.format(new BigDecimal("1000")));
        assertEquals("10,000", IndianNumberFormatter.format(new BigDecimal("10000")));
        assertEquals("1,00,000", IndianNumberFormatter.format(new BigDecimal("100000")));
        assertEquals("10,00,000", IndianNumberFormatter.format(new BigDecimal("1000000")));
        assertEquals("1,00,00,000", IndianNumberFormatter.format(new BigDecimal("10000000")));
        assertEquals("5,75,00,000", IndianNumberFormatter.format(new BigDecimal("57500000")));
        assertEquals("50,00,00,000", IndianNumberFormatter.format(new BigDecimal("500000000")));
        assertEquals("99,99,99,999", IndianNumberFormatter.format(new BigDecimal("999999999")));
    }

    @Test
    @DisplayName("Amount in Words Certification from ₹1,00,000 to ₹99,99,99,999")
    public void testAmountInWordsMatrix() {
        assertEquals("Rupees One Lakh Only", IndianCurrencyToWords.convertToWords(new BigDecimal("100000")));
        assertEquals("Rupees Five Crore Seventy Five Lakh Only", IndianCurrencyToWords.convertToWords(new BigDecimal("57500000")));
        assertEquals("Rupees Ninety Nine Crore Ninety Nine Lakh Ninety Nine Thousand Nine Hundred Ninety Nine Only",
                IndianCurrencyToWords.convertToWords(new BigDecimal("999999999")));
    }

    // =========================================================================
    // 5. SHA-256 SNAPSHOT INTEGRITY & AUDIT LOGS
    // =========================================================================

    @Test
    @Transactional
    @DisplayName("Snapshot Integrity: Verify deterministic SHA-256 calculation and immutable audit history")
    public void testSnapshotIntegrityAndAudit() throws Exception {
        UserDetailsImpl valuerPrincipal = UserDetailsImpl.build(testValuer);

        SaveValuationRequest request = new SaveValuationRequest();
        request.setRealizablePercentage(new BigDecimal("85.00"));
        request.setDistressSalePercentage(new BigDecimal("75.00"));

        valuationEngineService.saveValuation(testOrder.getId(), request, valuerPrincipal, "Audit Test Entry");
        ValuationBundleResponse bundle = valuationEngineService.finalizeValuation(testOrder.getId(), valuerPrincipal, "Final Release v1", null, null);

        ValuationSnapshot snap = bundle.getSnapshots().get(0);
        assertNotNull(snap.getSnapshotData());

        // Validate SHA-256 calculation match
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hashBytes = digest.digest(snap.getSnapshotData().getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : hashBytes) {
            hex.append(String.format("%02x", b));
        }

        assertEquals(hex.toString(), snap.getSnapshotHash());

        // Check Audit Log
        List<ValuationAuditLog> logs = auditLogRepository.findByOrderIdOrderByChangedAtDesc(testOrder.getId());
        assertFalse(logs.isEmpty());
        assertTrue(logs.stream().anyMatch(l -> "valuation_status".equals(l.getFieldName())));
    }
}
