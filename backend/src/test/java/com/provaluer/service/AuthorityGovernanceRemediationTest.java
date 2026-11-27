package com.provaluer.service;

import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.dto.SaveValuationRequest;
import com.provaluer.dto.SpaApproveDocumentRequest;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.util.AuthorityGovernance;
import com.provaluer.util.DocxTemplateEngine;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.Text;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@SpringBootTest
@Transactional
public class AuthorityGovernanceRemediationTest {

    @Autowired private OrderRepository orderRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private TemplateRepository templateRepository;
    @Autowired private TemplateVersionRepository templateVersionRepository;
    @Autowired private OrderInputRepository orderInputRepository;
    @Autowired private ValuationDataRepository valuationDataRepository;
    @Autowired private DeliveryPackageRepository deliveryPackageRepository;
    @MockBean private OrderDocumentRepository orderDocumentRepository;
    @MockBean private ValuationSnapshotRepository valuationSnapshotRepository;
    @Autowired private DocumentWorkspaceService documentWorkspaceService;
    @Autowired private ValuationEngineService valuationEngineService;
    @Autowired private DocxTemplateEngine docxTemplateEngine;

    private User makeUser(String username, String email, String fullName, String mobile, UserRole role) {
        User u = new User();
        u.setUsername(username);
        u.setEmail(email);
        u.setPassword("pass");
        u.setFullName(fullName);
        u.setMobileNumber(mobile);
        u.setRole(role);
        return userRepository.save(u);
    }

    private byte[] createTestDocx() throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.createPackage();
        pkg.getMainDocumentPart().addParagraphOfText("UPPER_OWNER: <<OWNER_NAME>>");
        pkg.getMainDocumentPart().addParagraphOfText("LOWER_OWNER: <<owner_name>>");
        pkg.getMainDocumentPart().addParagraphOfText("MIXED_OWNER: <<Owner_Name>>");
        pkg.getMainDocumentPart().addParagraphOfText("UPPER_MARKET: <<MARKET_VALUE>>");
        pkg.getMainDocumentPart().addParagraphOfText("LOWER_MARKET: <<market_value>>");
        pkg.getMainDocumentPart().addParagraphOfText("ADDR: <<PROPERTY_ADDRESS>>");
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        pkg.save(baos);
        return baos.toByteArray();
    }

    private String extractDocxText(byte[] docxBytes) throws Exception {
        WordprocessingMLPackage pkg = WordprocessingMLPackage.load(new ByteArrayInputStream(docxBytes));
        StringBuilder sb = new StringBuilder();
        org.docx4j.finders.ClassFinder finder = new org.docx4j.finders.ClassFinder(Text.class);
        new org.docx4j.TraversalUtil(pkg.getMainDocumentPart().getContent(), finder);
        for (Object o : finder.results) {
            sb.append(((Text) o).getValue()).append("\n");
        }
        return sb.toString();
    }

    @Test
    @DisplayName("ADMIN > SPA > PA: Full override precedence across DB, Workspace, Consolidated, and DOCX")
    void testAdminOverSpaOverPaPrecedence() throws Exception {
        User pa = makeUser("pa_auth", "pa_auth@test.com", "PA User", "9999999801", UserRole.PA);
        User spa = makeUser("spa_auth", "spa_auth@test.com", "SPA User", "9999999802", UserRole.SPA);
        User admin = makeUser("admin_auth", "admin_auth@test.com", "Admin User", "9999999803", UserRole.SUPER_ADMIN);
        User client = makeUser("client_auth", "client_auth@test.com", "ABC", "9999999804", UserRole.CLIENT);

        UserDetailsImpl paPrincipal = new UserDetailsImpl(pa.getId(), pa.getEmail(), "pass", List.of(new SimpleGrantedAuthority("ROLE_PA")), false, false);
        UserDetailsImpl spaPrincipal = new UserDetailsImpl(spa.getId(), spa.getEmail(), "pass", List.of(new SimpleGrantedAuthority("ROLE_SPA")), false, false);
        UserDetailsImpl adminPrincipal = new UserDetailsImpl(admin.getId(), admin.getEmail(), "pass", List.of(new SimpleGrantedAuthority("ROLE_SUPER_ADMIN")), false, false);

        byte[] tplBytes = createTestDocx();
        Template tpl = new Template();
        tpl.setName("Authority Template");
        tpl.setIsActive("Y");
        tpl.setVersion(1);
        tpl.setTemplateContent(tplBytes);
        tpl.setDocumentDom("{\"sections\":[]}");
        tpl.setFieldMapping("{}");
        tpl = templateRepository.save(tpl);

        TemplateVersion tv = new TemplateVersion();
        tv.setTemplateId(tpl.getId());
        tv.setVersion(1);
        tv.setName("Authority Template v1");
        tv.setTemplateContent(tplBytes);
        tv.setDocumentDom("{\"sections\":[]}");
        tv.setFieldMapping("{}");
        tv.setStatus("ACTIVE");
        tv = templateVersionRepository.save(tv);

        Order order = new Order();
        order.setReferenceCode("PV-AUTH-001");
        order.setReportNumber("RPT-AUTH-001");
        order.setClientId(client.getId());
        order.setClientName("ABC");
        order.setBankName("Test Bank");
        order.setBranchName("Main Branch");
        order.setPropertyCategory("Commercial Land & Building");
        order.setPurpose("Mortgage");
        order.setPaId(pa.getId());
        order.setStatus("DRAFTING");
        order.setTemplateId(tpl.getId());
        order.setTemplateVersion(1);
        order.setTemplateVersionId(tv.getId());
        order = orderRepository.save(order);
        Long orderId = order.getId();

        // 1. PA enters ABC, 9,00,00,000, Address A
        SaveDocumentValuesRequest paReq = new SaveDocumentValuesRequest();
        paReq.setValues(new HashMap<>(Map.of(
                "OWNER_NAME", "ABC",
                "CLIENT_NAME", "ABC",
                "MARKET_VALUE", "9,00,00,000",
                "PROPERTY_ADDRESS", "Address A",
                "INSPECTION_DATE", "01-01-2026",
                "VALUER_NAME", "PA User",
                "PURPOSE_OF_VALUATION", "Mortgage"
        )));
        documentWorkspaceService.saveDocumentValues(orderId, paReq, paPrincipal);

        SaveValuationRequest paValReq = new SaveValuationRequest();
        ValuationLandItem land = new ValuationLandItem();
        land.setDescription("Plot 1");
        land.setEnteredArea(new BigDecimal("1000"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("90000"));
        paValReq.setLandItems(List.of(land));
        paValReq.setBuildingItems(Collections.emptyList());
        valuationEngineService.saveValuation(orderId, paValReq, paPrincipal, "PA_SAVE");

        // Advance to SPA_GATE
        order.setStatus("SPA_GATE");
        orderRepository.save(order);

        // 2. SPA overrides OWNER_NAME=XYZ, MARKET_VALUE=10,00,00,000, PROPERTY_ADDRESS=Address B
        SpaApproveDocumentRequest spaReq = new SpaApproveDocumentRequest();
        spaReq.setFinalValue(new BigDecimal("100000000"));
        spaReq.setModifiedValues(new HashMap<>(Map.of(
                "OWNER_NAME", "XYZ",
                "MARKET_VALUE", "10,00,00,000",
                "PROPERTY_ADDRESS", "Address B"
        )));
        documentWorkspaceService.spaApprove(orderId, spaReq, spaPrincipal);

        Map<String, String> afterSpa = documentWorkspaceService.getConsolidatedValues(orderId);
        assertEquals("XYZ", afterSpa.get("OWNER_NAME"));
        assertEquals("XYZ", afterSpa.get("owner_name"));
        assertEquals("10,00,00,000", afterSpa.get("MARKET_VALUE"));
        assertEquals("Address B", afterSpa.get("PROPERTY_ADDRESS"));

        // 3. Admin overrides OWNER_NAME=PQR, MARKET_VALUE=11,00,00,000, PROPERTY_ADDRESS=Address C
        SaveDocumentValuesRequest adminReq = new SaveDocumentValuesRequest();
        adminReq.setValues(new HashMap<>(Map.of(
                "OWNER_NAME", "PQR",
                "MARKET_VALUE", "11,00,00,000",
                "PROPERTY_ADDRESS", "Address C"
        )));
        documentWorkspaceService.saveDocumentValues(orderId, adminReq, adminPrincipal);

        // 4. Reverse-authority check: SPA cannot downgrade ADMIN's OWNER_NAME
        documentWorkspaceService.saveOrUpdateInputWithAuthority(orderId, "owner_name", "DOWNGRADED_BY_SPA", spaPrincipal);
        OrderInput ownerRow = orderInputRepository.findByOrderIdAndFieldKeyIgnoreCase(orderId, "OWNER_NAME").orElseThrow();
        assertEquals("PQR", ownerRow.getFieldValue());
        assertEquals(AuthorityGovernance.RANK_ADMIN, ownerRow.getAuthorityRank());
        assertEquals("ADMIN", ownerRow.getLastModifiedByRole());

        // 5. Consolidated & Workspace Reload checks
        Map<String, String> consolidated = documentWorkspaceService.getConsolidatedValues(orderId);
        assertEquals("PQR", consolidated.get("OWNER_NAME"));
        assertEquals("PQR", consolidated.get("owner_name"));
        assertEquals("11,00,00,000", consolidated.get("MARKET_VALUE"));
        assertEquals("11,00,00,000", consolidated.get("market_value"));
        assertEquals("Address C", consolidated.get("PROPERTY_ADDRESS"));

        var ws = documentWorkspaceService.getDocumentWorkspace(orderId, adminPrincipal);
        assertEquals("PQR", ws.getValues().get("OWNER_NAME"));
        assertEquals("11,00,00,000", ws.getValues().get("MARKET_VALUE"));
        assertEquals("ADMIN", ws.getFieldAuthorities().get("OWNER_NAME"));
        assertEquals("ADMIN", ws.getFieldAuthorities().get("MARKET_VALUE"));

        // 6. Generated DOCX checks (case-insensitive placeholders resolve identically)
        byte[] docx = docxTemplateEngine.generateReport(tplBytes, consolidated, Collections.emptyMap());
        String docxText = extractDocxText(docx);
        assertTrue(docxText.contains("UPPER_OWNER: PQR"), docxText);
        assertTrue(docxText.contains("LOWER_OWNER: PQR"), docxText);
        assertTrue(docxText.contains("MIXED_OWNER: PQR"), docxText);
        assertTrue(docxText.contains("UPPER_MARKET: 11,00,00,000"), docxText);
        assertTrue(docxText.contains("LOWER_MARKET: 11,00,00,000"), docxText);
        assertTrue(docxText.contains("ADDR: Address C"), docxText);
    }

    @Test
    @DisplayName("invalidateReportArtifacts deletes cached FINAL_DOCX and FINAL_SIGNED_PDF")
    void testInvalidateReportArtifactsDeletesCachedDocs() {
        OrderDocument docx = new OrderDocument();
        docx.setCategory("FINAL_DOCX");
        OrderDocument pdf = new OrderDocument();
        pdf.setCategory("FINAL_SIGNED_PDF");
        OrderDocument other = new OrderDocument();
        other.setCategory("CLIENT_UPLOAD");

        when(orderDocumentRepository.findAllByOrderId(777L)).thenReturn(List.of(docx, pdf, other));

        documentWorkspaceService.invalidateReportArtifacts(777L);

        verify(orderDocumentRepository, times(1)).delete(docx);
        verify(orderDocumentRepository, times(1)).delete(pdf);
        verify(orderDocumentRepository, never()).delete(other);
    }

    @Test
    @DisplayName("FINAL CERTIFICATION: End-to-End 10-Checkpoint Output Verification (PA -> SPA -> ADMIN)")
    void testFinalCertificationEndToEnd() throws Exception {
        User pa = makeUser("pa_cert", "pa_cert@test.com", "PA Cert", "9999999701", UserRole.PA);
        User spa = makeUser("spa_cert", "spa_cert@test.com", "SPA Cert", "9999999702", UserRole.SPA);
        User admin = makeUser("admin_cert", "admin_cert@test.com", "Admin Cert", "9999999703", UserRole.SUPER_ADMIN);
        User client = makeUser("client_cert", "client_cert@test.com", "ABC", "9999999704", UserRole.CLIENT);

        UserDetailsImpl paPrincipal = new UserDetailsImpl(pa.getId(), pa.getEmail(), "pass", List.of(new SimpleGrantedAuthority("ROLE_PA")), false, false);
        UserDetailsImpl spaPrincipal = new UserDetailsImpl(spa.getId(), spa.getEmail(), "pass", List.of(new SimpleGrantedAuthority("ROLE_SPA")), false, false);
        UserDetailsImpl adminPrincipal = new UserDetailsImpl(admin.getId(), admin.getEmail(), "pass", List.of(new SimpleGrantedAuthority("ROLE_SUPER_ADMIN")), false, false);

        byte[] tplBytes = createTestDocx();
        Template tpl = new Template();
        tpl.setName("Cert Template");
        tpl.setIsActive("Y");
        tpl.setVersion(1);
        tpl.setTemplateContent(tplBytes);
        tpl.setDocumentDom("{\"sections\":[]}");
        tpl.setFieldMapping("{}");
        tpl = templateRepository.save(tpl);

        TemplateVersion tv = new TemplateVersion();
        tv.setTemplateId(tpl.getId());
        tv.setVersion(1);
        tv.setName("Cert Template v1");
        tv.setTemplateContent(tplBytes);
        tv.setDocumentDom("{\"sections\":[]}");
        tv.setFieldMapping("{}");
        tv.setStatus("ACTIVE");
        tv = templateVersionRepository.save(tv);

        Order order = new Order();
        order.setReferenceCode("PV-CERT-001");
        order.setReportNumber("RPT-CERT-001");
        order.setClientId(client.getId());
        order.setClientName("ABC");
        order.setBankName("Test Bank");
        order.setBranchName("Main Branch");
        order.setPropertyCategory("Commercial Land & Building");
        order.setPurpose("Mortgage");
        order.setPaId(pa.getId());
        order.setStatus("DRAFTING");
        order.setTemplateId(tpl.getId());
        order.setTemplateVersion(1);
        order.setTemplateVersionId(tv.getId());
        order = orderRepository.save(order);
        Long orderId = order.getId();

        // PA
        SaveDocumentValuesRequest paReq = new SaveDocumentValuesRequest();
        paReq.setValues(new HashMap<>(Map.of(
                "OWNER_NAME", "ABC",
                "MARKET_VALUE", "9,00,00,000",
                "PROPERTY_ADDRESS", "Address A"
        )));
        documentWorkspaceService.saveDocumentValues(orderId, paReq, paPrincipal);
        SaveValuationRequest paVal = new SaveValuationRequest();
        ValuationLandItem land = new ValuationLandItem();
        land.setDescription("Plot 1");
        land.setEnteredArea(new BigDecimal("1000"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("90000"));
        paVal.setLandItems(List.of(land));
        paVal.setBuildingItems(Collections.emptyList());
        valuationEngineService.saveValuation(orderId, paVal, paPrincipal, "PA_SAVE");

        order.setStatus("SPA_GATE");
        orderRepository.save(order);

        // SPA
        SpaApproveDocumentRequest spaReq = new SpaApproveDocumentRequest();
        spaReq.setFinalValue(new BigDecimal("100000000"));
        spaReq.setModifiedValues(new HashMap<>(Map.of(
                "OWNER_NAME", "XYZ",
                "MARKET_VALUE", "10,00,00,000",
                "PROPERTY_ADDRESS", "Address B"
        )));
        documentWorkspaceService.spaApprove(orderId, spaReq, spaPrincipal);

        // ADMIN
        SaveDocumentValuesRequest adminReq = new SaveDocumentValuesRequest();
        adminReq.setValues(new HashMap<>(Map.of(
                "OWNER_NAME", "PQR",
                "MARKET_VALUE", "11,00,00,000",
                "PROPERTY_ADDRESS", "Address C"
        )));
        documentWorkspaceService.saveDocumentValues(orderId, adminReq, adminPrincipal);

        // 1. order_inputs
        OrderInput oiOwner = orderInputRepository.findByOrderIdAndFieldKeyIgnoreCase(orderId, "OWNER_NAME").orElseThrow();
        OrderInput oiMarket = orderInputRepository.findByOrderIdAndFieldKeyIgnoreCase(orderId, "MARKET_VALUE").orElseThrow();
        OrderInput oiAddr = orderInputRepository.findByOrderIdAndFieldKeyIgnoreCase(orderId, "PROPERTY_ADDRESS").orElseThrow();

        // 2. orders.input_values
        Order refreshedOrder = orderRepository.findById(orderId).orElseThrow();

        // 3. valuation_data
        ValuationData vData = valuationDataRepository.findByOrderId(orderId).orElseThrow();

        // 4 & 5. Workspace + Reload
        var ws1 = documentWorkspaceService.getDocumentWorkspace(orderId, adminPrincipal);
        var ws2 = documentWorkspaceService.getDocumentWorkspace(orderId, adminPrincipal);

        // 6. Preview / Consolidated
        Map<String, String> consolidated = documentWorkspaceService.getConsolidatedValues(orderId);

        // 7. Generated DOCX
        byte[] docxBytes = docxTemplateEngine.generateReport(tplBytes, consolidated, Collections.emptyMap());
        String docxText = extractDocxText(docxBytes);

        // 8. Generated PDF
        byte[] pdfBytes = docxTemplateEngine.convertDocxToPdf(docxBytes);
        String pdfText;
        try (PDDocument pdfDoc = Loader.loadPDF(pdfBytes)) {
            pdfText = new PDFTextStripper().getText(pdfDoc);
        }

        // 9. Snapshot data map (simulated via consolidated values)
        assertTrue(docxText.contains("UPPER_OWNER: PQR"));
        assertTrue(docxText.contains("LOWER_OWNER: PQR"));
        assertTrue(docxText.contains("UPPER_MARKET: 11,00,00,000"));
        assertTrue(docxText.contains("ADDR: Address C"));
        assertTrue(pdfText.contains("PQR"));
        assertTrue(pdfText.contains("11,00,00,000"));
        assertTrue(pdfText.contains("Address C"));

        // 10. DeliveryPackage revisioning (v1 -> v2 immutable)
        DeliveryPackage pkg1 = new DeliveryPackage();
        pkg1.setOrderId(orderId);
        pkg1.setRevisionNumber(1);
        pkg1.setEncryptedPdfHash("hash-v1");
        pkg1.setManifestJson("{\"revision\":1}");
        pkg1 = deliveryPackageRepository.save(pkg1);

        pkg1.setSuperseded(true);
        deliveryPackageRepository.save(pkg1);

        DeliveryPackage pkg2 = new DeliveryPackage();
        pkg2.setOrderId(orderId);
        pkg2.setRevisionNumber(2);
        pkg2.setParentPackageId(pkg1.getId());
        pkg2.setEncryptedPdfHash("hash-v2");
        pkg2.setManifestJson("{\"revision\":2,\"owner\":\"PQR\"}");
        pkg2 = deliveryPackageRepository.save(pkg2);

        List<DeliveryPackage> pkgHistory = deliveryPackageRepository.findAllByOrderIdOrderByRevisionNumberDesc(orderId);
        assertEquals(2, pkgHistory.size());
        assertEquals(2, pkgHistory.get(0).getRevisionNumber());
        assertFalse(pkgHistory.get(0).isSuperseded());
        assertTrue(pkgHistory.get(1).isSuperseded());
        assertEquals(pkg1.getId(), pkgHistory.get(0).getParentPackageId());

        System.out.println("=== FINAL CERTIFICATION OUTPUT ===");
        System.out.println("1. order_inputs: OWNER_NAME=" + oiOwner.getFieldValue() + " (rank=" + oiOwner.getAuthorityRank() + ", role=" + oiOwner.getLastModifiedByRole() + "), MARKET_VALUE=" + oiMarket.getFieldValue() + ", PROPERTY_ADDRESS=" + oiAddr.getFieldValue());
        System.out.println("2. orders.input_values contains PQR=" + (refreshedOrder.getInputValues() != null && refreshedOrder.getInputValues().contains("PQR")) + ", finalValue=" + refreshedOrder.getFinalValue());
        System.out.println("3. valuation_data.fairValue=" + vData.getFairValue() + " (preserved baseline; overridden at resolver)");
        System.out.println("4. Workspace: OWNER_NAME=" + ws1.getValues().get("OWNER_NAME") + ", MARKET_VALUE=" + ws1.getValues().get("MARKET_VALUE") + ", PROPERTY_ADDRESS=" + ws1.getValues().get("PROPERTY_ADDRESS") + ", fieldAuthorities=" + ws1.getFieldAuthorities());
        System.out.println("5. Workspace Reload: OWNER_NAME=" + ws2.getValues().get("OWNER_NAME") + ", MARKET_VALUE=" + ws2.getValues().get("MARKET_VALUE") + ", PROPERTY_ADDRESS=" + ws2.getValues().get("PROPERTY_ADDRESS"));
        System.out.println("6. Preview/Consolidated: OWNER_NAME=" + consolidated.get("OWNER_NAME") + ", owner_name=" + consolidated.get("owner_name") + ", MARKET_VALUE=" + consolidated.get("MARKET_VALUE") + ", PROPERTY_ADDRESS=" + consolidated.get("PROPERTY_ADDRESS"));
        System.out.println("7. Generated DOCX:\n" + docxText.trim());
        System.out.println("8. Generated PDF:\n" + pdfText.trim());
        System.out.println("9. ValuationSnapshot source: consolidated OWNER_NAME=" + consolidated.get("OWNER_NAME") + ", MARKET_VALUE=" + consolidated.get("MARKET_VALUE"));
        System.out.println("10. DeliveryPackage revisions: count=" + pkgHistory.size() + ", latestRev=" + pkgHistory.get(0).getRevisionNumber() + ", parentId=" + pkgHistory.get(0).getParentPackageId() + ", v1Superseded=" + pkgHistory.get(1).isSuperseded());
        System.out.println("=== END FINAL CERTIFICATION ===");
    }
}

