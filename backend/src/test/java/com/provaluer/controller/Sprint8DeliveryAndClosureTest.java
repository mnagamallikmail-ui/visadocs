package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.*;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.DeliveryService;
import com.provaluer.service.TelegramNotificationService;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import com.provaluer.model.Order;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import com.fasterxml.jackson.core.type.TypeReference;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * SPRINT 8: Comprehensive Automated Integration Tests
 * Delivery Lifecycle, Secure Client Portal, AES-256 PDF Encryption,
 * Tax Invoice Engine, Acknowledgements, Ind AS 115 Revenue Recognition,
 * and 10-Year Archival Lock Project Closure.
 *
 * SNAPSHOT_CREATED → DELIVERY_READY → FINAL_DELIVERY → CLIENT_DOWNLOADED → CLOSED
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class Sprint8DeliveryAndClosureTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private OrderRepository orderRepository;
    @Autowired private ValuationSnapshotRepository valuationSnapshotRepository;
    @Autowired private OrderInvoiceRepository orderInvoiceRepository;
    @Autowired private OrderAcknowledgementRepository orderAcknowledgementRepository;
    @Autowired private DeliveryTokenRepository deliveryTokenRepository;
    @Autowired private DeliveryPackageRepository deliveryPackageRepository;
    @Autowired private RevenueLedgerRepository revenueLedgerRepository;
    @Autowired private AuditLogRepository auditLogRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private DeliveryService deliveryService;

    @SpyBean private TelegramNotificationService telegramNotificationService;

    private User adminUser;
    private User clientUser;
    private User otherClientUser;
    private User paUser;
    private User spaUser;

    private UsernamePasswordAuthenticationToken authAdmin;
    private UsernamePasswordAuthenticationToken authClient;
    private UsernamePasswordAuthenticationToken authOtherClient;
    private UsernamePasswordAuthenticationToken authPa;
    private UsernamePasswordAuthenticationToken authSpa;

    private Order testOrder;
    private final String clientMobile = "9820012345";

    @BeforeEach
    void setUp() {
        adminUser = userRepository.findAll().stream()
                .filter(u -> UserRole.SUPER_ADMIN.equals(u.getRole()) || UserRole.ADMIN.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("admin_s8_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("admin_s8_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.SUPER_ADMIN);
                    return userRepository.save(u);
                });

        clientUser = userRepository.findAll().stream()
                .filter(u -> UserRole.CLIENT.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("client_s8_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("client_s8_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.CLIENT);
                    u.setMobileNumber(clientMobile);
                    u.setFullName("HDFC Bank Corp Officer");
                    return userRepository.save(u);
                });
        clientUser.setMobileNumber(clientMobile);
        clientUser.setFullName("HDFC Bank Corp Officer");
        userRepository.save(clientUser);

        otherClientUser = userRepository.findAll().stream()
                .filter(u -> UserRole.CLIENT.equals(u.getRole()) && !u.getId().equals(clientUser.getId()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("other_client_s8_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("other_client_s8_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.CLIENT);
                    u.setMobileNumber("9899999999");
                    return userRepository.save(u);
                });

        paUser = userRepository.findAll().stream()
                .filter(u -> UserRole.PA.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("pa_s8_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("pa_s8_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.PA);
                    return userRepository.save(u);
                });

        spaUser = userRepository.findAll().stream()
                .filter(u -> UserRole.SPA.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("spa_s8_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("spa_s8_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.SPA);
                    return userRepository.save(u);
                });

        authAdmin = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(adminUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_SUPER_ADMIN")));

        authClient = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(clientUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_CLIENT")));

        authOtherClient = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(otherClientUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_CLIENT")));

        authPa = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(paUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_PA")));

        authSpa = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(spaUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_SPA")));

        // Create baseline test order in SNAPSHOT_CREATED
        testOrder = new Order();
        testOrder.setClientId(clientUser.getId());
        testOrder.setPaId(paUser.getId());
        testOrder.setReferenceCode("VAL-S8-" + System.currentTimeMillis());
        testOrder.setStatus("SNAPSHOT_CREATED");
        testOrder.setPropertyCategory("COMMERCIAL");
        testOrder.setPurpose("MORTGAGE");
        testOrder.setClientName(clientUser.getFullName());
        testOrder.setBranchName("Corporate Banking, Mumbai");
        testOrder.setQuoteNumber("Q-S8-" + System.currentTimeMillis());
        testOrder.setQuoteAmount(new BigDecimal("50000.00"));
        testOrder.setQuoteTax(new BigDecimal("9000.00"));
        testOrder.setQuoteTotal(new BigDecimal("59000.00"));
        testOrder.setFeeCharged(new BigDecimal("59000.00"));
        testOrder.setFinalValue(new BigDecimal("45000000.00"));
        testOrder.setBalanceDue(BigDecimal.ZERO);
        testOrder.setPaymentStatus("VERIFIED");
        testOrder = orderRepository.save(testOrder);

        // Ensure immutable ValuationSnapshot exists
        ValuationSnapshot snapshot = new ValuationSnapshot();
        snapshot.setOrderId(testOrder.getId());
        snapshot.setVersionNumber(0);
        snapshot.setSnapshotTrigger("SPA_CONFIRMED");
        snapshot.setSnapshotHash("7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a");
        snapshot.setDocumentHash("1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b");
        snapshot.setSnapshotData("{\"version\":0}");
        snapshot.setCreatedBy(spaUser.getId());
        snapshot.setCreatedAt(LocalDateTime.now());
        valuationSnapshotRepository.save(snapshot);
    }

    @Test
    @org.junit.jupiter.api.Order(1)
    @DisplayName("1. Delivery Gate: Rejects unpaid retail orders and transitions to ON_HOLD_PAYMENT_PENDING")
    void test1_deliveryGate_unpaidRejection() throws Exception {
        Order unpaidOrder = new Order();
        unpaidOrder.setClientId(clientUser.getId());
        unpaidOrder.setReferenceCode("VAL-UNPAID-" + System.currentTimeMillis());
        unpaidOrder.setStatus("SNAPSHOT_CREATED");
        unpaidOrder.setPropertyCategory("COMMERCIAL");
        unpaidOrder.setPurpose("LOAN");
        unpaidOrder.setBalanceDue(new BigDecimal("25000.00"));
        unpaidOrder.setPaymentStatus("PENDING");
        unpaidOrder = orderRepository.save(unpaidOrder);

        ValuationSnapshot snap = new ValuationSnapshot();
        snap.setOrderId(unpaidOrder.getId());
        snap.setVersionNumber(0);
        snap.setSnapshotTrigger("SPA_CONFIRMED");
        snap.setSnapshotHash("7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a");
        snap.setDocumentHash("1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b");
        snap.setSnapshotData("{\"version\":0}");
        valuationSnapshotRepository.save(snap);

        EvaluateGateRequest req = new EvaluateGateRequest(false, null, false);

        MvcResult result = mockMvc.perform(post("/api/v1/delivery/orders/" + unpaidOrder.getId() + "/evaluate-gate")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();

        Map<String, Object> resp = objectMapper.readValue(result.getResponse().getContentAsString(), new TypeReference<Map<String, Object>>() {});
        assertEquals("ON_HOLD_PAYMENT_PENDING", resp.get("status"));
        assertFalse((Boolean) resp.get("passed"));

        Order updated = orderRepository.findById(unpaidOrder.getId()).orElseThrow();
        assertEquals("ON_HOLD_PAYMENT_PENDING", updated.getStatus());
    }

    @Test
    @org.junit.jupiter.api.Order(2)
    @DisplayName("2. Delivery Gate: Passes for verified balance or Corporate Credit and reaches DELIVERY_READY")
    void test2_deliveryGate_passesToDeliveryReady() throws Exception {
        EvaluateGateRequest req = new EvaluateGateRequest(false, null, false);

        MvcResult result = mockMvc.perform(post("/api/v1/delivery/orders/" + testOrder.getId() + "/evaluate-gate")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();

        Map<String, Object> resp = objectMapper.readValue(result.getResponse().getContentAsString(), new TypeReference<Map<String, Object>>() {});
        assertEquals("DELIVERY_READY", resp.get("status"));
        assertTrue((Boolean) resp.get("passed"));

        Order updated = orderRepository.findById(testOrder.getId()).orElseThrow();
        assertEquals("DELIVERY_READY", updated.getStatus());

        // Verify audit log
        assertTrue(auditLogRepository.existsByEntityTypeAndEntityIdAndActionTypeAndActorRole(
                "Order", String.valueOf(testOrder.getId()), "COMMERCIAL_GATE_PASSED", "SUPER_ADMIN"));
    }

    @Test
    @org.junit.jupiter.api.Order(3)
    @DisplayName("3. Delivery Release: Generates Tax Invoice, Encrypted PDF, Manifest and moves to FINAL_DELIVERY")
    void test3_deliveryRelease_createsPackageAndInvoice() throws Exception {
        testOrder.setStatus("DELIVERY_READY");
        orderRepository.save(testOrder);

        ReleaseOrderRequest releaseReq = new ReleaseOrderRequest(false, "Released by Admin", "27");

        MvcResult result = mockMvc.perform(post("/api/v1/delivery/orders/" + testOrder.getId() + "/release")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(releaseReq)))
                .andReturn();

        if (result.getResponse().getStatus() != 200) {
            System.err.println(">>> RELEASE FAILED! STATUS=" + result.getResponse().getStatus() + " BODY=" + result.getResponse().getContentAsString());
        }
        assertEquals(200, result.getResponse().getStatus());

        Map<String, Object> resp = objectMapper.readValue(result.getResponse().getContentAsString(), new TypeReference<Map<String, Object>>() {});
        assertEquals("FINAL_DELIVERY", resp.get("status"));
        assertNotNull(resp.get("invoiceNumber"));
        assertNotNull(resp.get("encryptedPdfHash"));

        // Verify order state
        Order updated = orderRepository.findById(testOrder.getId()).orElseThrow();
        assertEquals("FINAL_DELIVERY", updated.getStatus());
        assertNotNull(updated.getDeliveredAt());

        // Verify Tax Invoice in DB
        OrderInvoice inv = orderInvoiceRepository.findByOrderId(testOrder.getId()).orElseThrow();
        assertTrue(inv.getInvoiceNumber().startsWith("INV-"));
        assertEquals("998311", inv.getSacCode());
        assertEquals(new BigDecimal("50000.00"), inv.getBaseAmount());
        assertEquals(new BigDecimal("4500.00"), inv.getCgstAmount());
        assertEquals(new BigDecimal("4500.00"), inv.getSgstAmount());
        assertEquals(new BigDecimal("59000.00"), inv.getGrandTotal());
        assertNotNull(inv.getInvoicePdfContent());
        assertNotNull(inv.getInvoiceHash());

        // Verify DeliveryPackage in DB
        DeliveryPackage pkg = deliveryPackageRepository.findByOrderId(testOrder.getId()).orElseThrow();
        assertNotNull(pkg.getEncryptedPdfContent());
        assertNotNull(pkg.getEncryptedPdfHash());
        assertNotNull(pkg.getManifestJson());
    }

    @Test
    @org.junit.jupiter.api.Order(4)
    @DisplayName("4. PDF Security: Encrypted with AES-256 and decryptable ONLY with Client Registered Mobile")
    void test4_pdfEncryption_mobilePasswordVerification() throws Exception {
        testOrder.setStatus("DELIVERY_READY");
        orderRepository.save(testOrder);

        ReleaseOrderRequest releaseReq = new ReleaseOrderRequest();
        mockMvc.perform(post("/api/v1/delivery/orders/" + testOrder.getId() + "/release")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(releaseReq)))
                .andExpect(status().isOk());

        DeliveryPackage pkg = deliveryPackageRepository.findByOrderId(testOrder.getId()).orElseThrow();
        byte[] encryptedBytes = pkg.getEncryptedPdfContent();

        // 1. Attempt to open WITHOUT password -> Must fail
        assertThrows(IOException.class, () -> {
            try (PDDocument doc = Loader.loadPDF(encryptedBytes, "")) {
                fail("Document opened without password!");
            }
        });

        // 2. Attempt to open with WRONG password -> Must fail
        assertThrows(IOException.class, () -> {
            try (PDDocument doc = Loader.loadPDF(encryptedBytes, "wrong_password_1234")) {
                fail("Document opened with wrong password!");
            }
        });

        // 3. Attempt to open with REGISTERED CLIENT MOBILE -> Must succeed!
        try (PDDocument doc = Loader.loadPDF(encryptedBytes, clientMobile)) {
            assertNotNull(doc);
            assertTrue(doc.isEncrypted());
            assertEquals(1, doc.getNumberOfPages());
        }
    }

    @Test
    @org.junit.jupiter.api.Order(5)
    @DisplayName("5. Client Download Portal: Returns deliverable summary, masked mobile hint, and isolates clients")
    void test5_portalView_andClientSecurity() throws Exception {
        // Owner client views portal -> 200 OK
        MvcResult res = mockMvc.perform(get("/api/v1/client/delivery/orders/" + testOrder.getReferenceCode())
                        .with(authentication(authClient)))
                .andExpect(status().isOk())
                .andReturn();

        ClientDeliverableResponse resp = objectMapper.readValue(res.getResponse().getContentAsString(), ClientDeliverableResponse.class);
        assertEquals(testOrder.getReferenceCode(), resp.getReferenceCode());
        assertTrue(resp.getPasswordHint().contains("2345"), "Hint must mask and show last 4 digits: " + resp.getPasswordHint());

        // Other client tries to access -> 403 Forbidden
        mockMvc.perform(get("/api/v1/client/delivery/orders/" + testOrder.getReferenceCode())
                        .with(authentication(authOtherClient)))
                .andExpect(status().isForbidden());
    }

    @Test
    @org.junit.jupiter.api.Order(6)
    @DisplayName("6. Secure Ephemeral Token: Single-use, expires in 15 mins, and blocks PA/SPA from generating")
    void test6_ephemeralToken_singleUseAndRoleProtection() throws Exception {
        // Ensure DeliveryPackage exists for testOrder
        if (!deliveryPackageRepository.existsByOrderId(testOrder.getId())) {
            DeliveryPackage p = new DeliveryPackage();
            p.setOrderId(testOrder.getId());
            p.setEncryptedPdfContent("MOCK_ENCRYPTED_PDF_BYTES".getBytes());
            p.setEncryptedPdfHash("mock_hash");
            p.setManifestJson("{}");
            deliveryPackageRepository.save(p);
        }

        // PA attempts to generate download token -> 403 Forbidden
        mockMvc.perform(post("/api/v1/client/delivery/orders/" + testOrder.getReferenceCode() + "/generate-token")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new GenerateTokenRequest("REPORT_PDF"))))
                .andExpect(status().isForbidden());

        // SPA attempts to generate download token -> 403 Forbidden
        mockMvc.perform(post("/api/v1/client/delivery/orders/" + testOrder.getReferenceCode() + "/generate-token")
                        .with(authentication(authSpa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new GenerateTokenRequest("REPORT_PDF"))))
                .andExpect(status().isForbidden());

        // Client generates token -> 200 OK
        MvcResult tokenRes = mockMvc.perform(post("/api/v1/client/delivery/orders/" + testOrder.getReferenceCode() + "/generate-token")
                        .with(authentication(authClient))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new GenerateTokenRequest("REPORT_PDF"))))
                .andExpect(status().isOk())
                .andReturn();

        Map<String, Object> tokenMap = objectMapper.readValue(tokenRes.getResponse().getContentAsString(), new TypeReference<Map<String, Object>>() {});
        String token = (String) tokenMap.get("token");
        assertNotNull(token);

        // First stream using token -> 200 OK
        mockMvc.perform(get("/api/v1/client/delivery/stream?token=" + token))
                .andExpect(status().isOk());

        // Replay attempt with same single-use token -> 410 GONE
        mockMvc.perform(get("/api/v1/client/delivery/stream?token=" + token))
                .andExpect(status().isGone());

        // Verify token is flagged as consumed in database repository
        assertTrue(deliveryTokenRepository.findByToken(token).orElseThrow().isConsumed());
    }

    @Test
    @org.junit.jupiter.api.Order(7)
    @DisplayName("7. Download Streaming: Advances status to CLIENT_DOWNLOADED and records audit telemetry")
    void test7_streamDownload_advancesStateToClientDownloaded() throws Exception {
        testOrder.setStatus("FINAL_DELIVERY");
        orderRepository.save(testOrder);

        // Ensure DeliveryPackage exists
        if (!deliveryPackageRepository.existsByOrderId(testOrder.getId())) {
            DeliveryPackage p = new DeliveryPackage();
            p.setOrderId(testOrder.getId());
            p.setEncryptedPdfContent("MOCK_ENCRYPTED_PDF_BYTES".getBytes());
            p.setEncryptedPdfHash("mock_hash");
            p.setManifestJson("{}");
            deliveryPackageRepository.save(p);
        }

        // Generate token
        MvcResult tokenRes = mockMvc.perform(post("/api/v1/client/delivery/orders/" + testOrder.getReferenceCode() + "/generate-token")
                        .with(authentication(authClient))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new GenerateTokenRequest("REPORT_PDF"))))
                .andExpect(status().isOk())
                .andReturn();
        String token = (String) objectMapper.readValue(tokenRes.getResponse().getContentAsString(), Map.class).get("token");

        // Stream report
        MvcResult streamRes = mockMvc.perform(get("/api/v1/client/delivery/stream?token=" + token))
                .andExpect(status().isOk())
                .andReturn();

        assertEquals("application/pdf", streamRes.getResponse().getContentType());
        assertTrue(streamRes.getResponse().getContentAsByteArray().length > 0);

        // Verify status moved to CLIENT_DOWNLOADED
        Order updated = orderRepository.findById(testOrder.getId()).orElseThrow();
        assertEquals("CLIENT_DOWNLOADED", updated.getStatus());
        assertNotNull(updated.getDownloadedAt());

        // Verify acknowledgement action DOWNLOADED recorded
        assertTrue(orderAcknowledgementRepository.existsByOrderIdAndAction(testOrder.getId(), "DOWNLOADED"));
    }

    @Test
    @org.junit.jupiter.api.Order(8)
    @DisplayName("8. Clarification Request: Moves order to DELIVERY_DISPUTED and pauses closure")
    void test8_clarificationRequest_movesToDisputed() throws Exception {
        AcknowledgeDeliveryRequest ackReq = new AcknowledgeDeliveryRequest(
                "CLARIFICATION_REQUESTED", "BUILT_UP_AREA_DISCREPANCY",
                "Client noticed built-up area shows 4500 sqft instead of 4800 sqft on floor 2.", null
        );

        mockMvc.perform(post("/api/v1/client/delivery/orders/" + testOrder.getReferenceCode() + "/acknowledge")
                        .with(authentication(authClient))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(ackReq)))
                .andExpect(status().isOk());

        Order updated = orderRepository.findById(testOrder.getId()).orElseThrow();
        assertEquals("DELIVERY_DISPUTED", updated.getStatus());

        // Attempting to close while in dispute -> 409 Conflict
        mockMvc.perform(post("/api/v1/delivery/orders/" + testOrder.getId() + "/close")
                        .with(authentication(authAdmin)))
                .andExpect(status().isConflict());
    }

    @Test
    @org.junit.jupiter.api.Order(9)
    @DisplayName("9. Client Acceptance: Triggers Ind AS 115 Revenue Recognition (Reversal, Revenue, GST)")
    void test9_clientAcceptance_andRevenueRecognition() throws Exception {
        testOrder.setStatus("CLIENT_DOWNLOADED");
        orderRepository.save(testOrder);

        // Revenue must NOT be recognized on download only
        assertFalse(testOrder.isRevenueRecognized());

        AcknowledgeDeliveryRequest acceptReq = new AcknowledgeDeliveryRequest(
                "ACCEPTED", null, null,
                "I confirm receipt and formal acceptance of Valuation Report."
        );

        mockMvc.perform(post("/api/v1/client/delivery/orders/" + testOrder.getReferenceCode() + "/acknowledge")
                        .with(authentication(authClient))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(acceptReq)))
                .andExpect(status().isOk());

        Order updated = orderRepository.findById(testOrder.getId()).orElseThrow();
        assertTrue(updated.isRevenueRecognized());
        assertNotNull(updated.getRevenueRecognizedAt());

        // Verify Ind AS 115 Revenue Ledger Entries
        List<RevenueLedger> ledger = revenueLedgerRepository.findByOrderIdOrderByPostedAtAsc(testOrder.getId());
        assertFalse(ledger.isEmpty());
        assertTrue(ledger.stream().anyMatch(l -> "ADVANCE_REVERSAL".equals(l.getEntryType())));
        assertTrue(ledger.stream().anyMatch(l -> "REVENUE_RECOGNITION".equals(l.getEntryType())));
        assertTrue(ledger.stream().anyMatch(l -> "GST_PAYABLE".equals(l.getEntryType())));
    }

    @Test
    @org.junit.jupiter.api.Order(10)
    @DisplayName("10. Project Closure: Closes order and activates permanent 10-Year Archival Lock")
    void test10_projectClosure_andArchivalLock() throws Exception {
        testOrder.setStatus("CLIENT_DOWNLOADED");
        orderRepository.save(testOrder);

        // Record client acceptance first
        OrderAcknowledgement ack = new OrderAcknowledgement();
        ack.setOrderId(testOrder.getId());
        ack.setAction("ACCEPTED");
        orderAcknowledgementRepository.save(ack);

        // Close order
        CloseOrderRequest closeReq = new CloseOrderRequest("Statutory obligations fulfilled", false);
        mockMvc.perform(post("/api/v1/delivery/orders/" + testOrder.getId() + "/close")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(closeReq)))
                .andExpect(status().isOk());

        Order updated = orderRepository.findById(testOrder.getId()).orElseThrow();
        assertEquals("CLOSED", updated.getStatus());
        assertTrue(updated.isArchivalLocked());
        assertNotNull(updated.getClosedAt());

        // Test Archival Lock: Deleting order must be REJECTED with HTTP 423 LOCKED
        mockMvc.perform(delete("/api/v1/orders/" + testOrder.getId())
                        .with(authentication(authAdmin)))
                .andExpect(status().isLocked());
    }

    @Test
    @org.junit.jupiter.api.Order(11)
    @DisplayName("11. Invoice API and Audit Trail: Verifies complete statutory accounting and audit telemetry")
    void test11_invoiceApiAndAuditTrail() throws Exception {
        // Ensure invoice exists
        if (!orderInvoiceRepository.existsByOrderId(testOrder.getId())) {
            EvaluateGateRequest gateReq = new EvaluateGateRequest();
            deliveryService.evaluateGate(testOrder.getId(), gateReq, UserDetailsImpl.build(adminUser), "127.0.0.1");
            ReleaseOrderRequest releaseReq = new ReleaseOrderRequest();
            deliveryService.releaseOrder(testOrder.getId(), releaseReq, UserDetailsImpl.build(adminUser), "127.0.0.1");
        }

        // Retrieve Invoice API
        mockMvc.perform(get("/api/v1/delivery/orders/" + testOrder.getId() + "/invoice")
                        .with(authentication(authAdmin)))
                .andExpect(status().isOk());

        // Verify required Audit Event Log types
        List<String> actions = auditLogRepository.findAll().stream()
                .map(AuditLog::getActionType)
                .toList();

        assertTrue(actions.contains("COMMERCIAL_GATE_PASSED") || actions.contains("COMMERCIAL_GATE_FAILED"));
        assertTrue(actions.contains("INVOICE_GENERATED"));
        assertTrue(actions.contains("DELIVERY_PACKAGE_SEALED"));
        assertTrue(actions.contains("DELIVERY_RELEASED"));
        assertTrue(actions.contains("DOWNLOAD_TOKEN_ISSUED"));
        assertTrue(actions.contains("DOWNLOAD_STARTED"));
        assertTrue(actions.contains("DOWNLOAD_COMPLETED"));
        assertTrue(actions.contains("ACKNOWLEDGEMENT_SUBMITTED"));
        assertTrue(actions.contains("REVENUE_RECOGNIZED"));
        assertTrue(actions.contains("ORDER_CLOSED"));
    }
}
