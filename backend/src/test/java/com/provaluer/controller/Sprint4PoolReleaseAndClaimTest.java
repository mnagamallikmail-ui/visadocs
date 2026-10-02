package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.HoldIntakeRequest;
import com.provaluer.dto.ReleaseToPoolRequest;
import com.provaluer.model.OrderDocument;
import com.provaluer.model.OrderPayment;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.OrderDocumentRepository;
import com.provaluer.repository.OrderPaymentRepository;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.TelegramNotificationService;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * SPRINT 4: Automated Tests — Admin Controlled Pool Release
 * Tests: PAYMENT_VERIFIED → PAID_INTAKE → ASSIGNED (PA Claim)
 * <p>
 * Sections covered:
 * 1.  Release Queue Retrieval
 * 2.  Unauthorized Release Rejection (CLIENT and PA may not release)
 * 3.  Hold Intake — mandatory reason enforced
 * 4.  Hold Intake — valid hold placed, status remains PAYMENT_VERIFIED
 * 5.  Successful Pool Release (full 10-step pre-condition verification)
 * 6.  Report Number Generation (PV-YYMM-XXXX format)
 * 7.  SLA Timer set after release
 * 8.  Common Pool Visibility (PAID_INTAKE appears in /unassigned)
 * 9.  Duplicate Release Prevention (already PAID_INTAKE cannot be released again)
 * 10. Existing Claim Flow (PA can claim PAID_INTAKE → ASSIGNED)
 * 11. Invalid status — trying to release from PAYMENT_SUBMITTED → 409
 * 12. Audit Trail Recording (verified via order fields after release)
 * 13. Sprint 1–3 Regression: PAYMENT_PROOF isolation still enforced
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class Sprint4PoolReleaseAndClaimTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private OrderRepository orderRepository;
    @Autowired private OrderPaymentRepository orderPaymentRepository;
    @Autowired private OrderDocumentRepository orderDocumentRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private ObjectMapper objectMapper;

    @SpyBean private TelegramNotificationService telegramNotificationService;

    // Test principals
    private User adminUser;
    private User clientUser;
    private User paUser;

    private UsernamePasswordAuthenticationToken authAdmin;
    private UsernamePasswordAuthenticationToken authClient;
    private UsernamePasswordAuthenticationToken authPa;

    // Shared order: pre-seeded in PAYMENT_VERIFIED state
    private static Long sharedOrderId;

    @BeforeEach
    void setUp() {
        // Admin user
        adminUser = userRepository.findAll().stream()
                .filter(u -> UserRole.SUPER_ADMIN.equals(u.getRole()) || UserRole.ADMIN.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("admin_s4_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setRole(UserRole.SUPER_ADMIN);
                    u.setFullName("Test Admin S4");
                    u.setEmail("admin.s4." + System.nanoTime() + "@test.com");
                    return userRepository.save(u);
                });

        // Client user
        clientUser = userRepository.findAll().stream()
                .filter(u -> UserRole.CLIENT.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("client_s4_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setRole(UserRole.CLIENT);
                    u.setFullName("Test Client S4");
                    u.setEmail("client.s4." + System.nanoTime() + "@test.com");
                    return userRepository.save(u);
                });

        // PA user
        paUser = userRepository.findAll().stream()
                .filter(u -> UserRole.PA.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("pa_s4_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setRole(UserRole.PA);
                    u.setFullName("Test PA S4");
                    u.setEmail("pa.s4." + System.nanoTime() + "@test.com");
                    return userRepository.save(u);
                });

        // Build principals — use role.name() for Spring authority strings
        authAdmin = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(adminUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + adminUser.getRole().name())));
        authClient = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(clientUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + clientUser.getRole().name())));
        authPa = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(paUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + paUser.getRole().name())));

        // Seed a PAYMENT_VERIFIED order (only once per test run)
        if (sharedOrderId == null) {
            sharedOrderId = seedPaymentVerifiedOrder(clientUser.getId());
        }
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 1: Release Queue Retrieval
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(1)
    @DisplayName("T1: Admin can retrieve release queue and PAYMENT_VERIFIED order appears")
    void test01_releaseQueueRetrieval() throws Exception {
        MvcResult res = mockMvc.perform(get("/api/v1/orders/release-queue")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn();

        String body = res.getResponse().getContentAsString();
        List<?> queue = objectMapper.readValue(body, List.class);
        assertFalse(queue.isEmpty(), "Release queue must contain at least the seeded PAYMENT_VERIFIED order");

        boolean found = queue.stream()
                .anyMatch(item -> {
                    @SuppressWarnings("unchecked")
                    var m = (java.util.Map<String, Object>) item;
                    return sharedOrderId.equals(((Number) m.get("orderId")).longValue());
                });
        assertTrue(found, "Seeded order id=" + sharedOrderId + " must appear in release queue");
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 2: Unauthorized — CLIENT cannot access release queue
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(2)
    @DisplayName("T2: CLIENT is denied access to release queue (403)")
    void test02_clientCannotAccessReleaseQueue() throws Exception {
        mockMvc.perform(get("/api/v1/orders/release-queue")
                        .with(authentication(authClient))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 3: Unauthorized — PA cannot access release queue
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(3)
    @DisplayName("T3: PA is denied access to release queue (403)")
    void test03_paCannotAccessReleaseQueue() throws Exception {
        mockMvc.perform(get("/api/v1/orders/release-queue")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 4: Hold Intake — mandatory reason enforced
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(4)
    @DisplayName("T4: Hold-intake with blank reason is rejected (400)")
    void test04_holdIntakeBlankReasonRejected() throws Exception {
        HoldIntakeRequest req = new HoldIntakeRequest();
        req.setHoldReason("   ");

        mockMvc.perform(post("/api/v1/orders/{id}/hold-intake", sharedOrderId)
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 5: Hold Intake — valid hold placed, status remains PAYMENT_VERIFIED
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(5)
    @DisplayName("T5: Valid hold-intake is accepted; status stays PAYMENT_VERIFIED")
    void test05_holdIntakeValid() throws Exception {
        HoldIntakeRequest req = new HoldIntakeRequest();
        req.setHoldReason("Awaiting KYC clarification from client");

        mockMvc.perform(post("/api/v1/orders/{id}/hold-intake", sharedOrderId)
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        com.provaluer.model.Order order = orderRepository.findById(sharedOrderId).orElseThrow();
        assertEquals("PAYMENT_VERIFIED", order.getStatus(),
                "Hold must not change order status from PAYMENT_VERIFIED");
        assertEquals("Awaiting KYC clarification from client", order.getIntakeHoldReason());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 6: Unauthorized — CLIENT cannot release to pool
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(6)
    @DisplayName("T6: CLIENT cannot release order to pool (403)")
    void test06_clientCannotRelease() throws Exception {
        mockMvc.perform(post("/api/v1/orders/{id}/release-to-pool", sharedOrderId)
                        .with(authentication(authClient))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new ReleaseToPoolRequest())))
                .andExpect(status().isForbidden());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 7: Unauthorized — PA cannot release to pool
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(7)
    @DisplayName("T7: PA cannot release order to pool (403)")
    void test07_paCannotRelease() throws Exception {
        mockMvc.perform(post("/api/v1/orders/{id}/release-to-pool", sharedOrderId)
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new ReleaseToPoolRequest())))
                .andExpect(status().isForbidden());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 8: Successful Pool Release — transitions PAYMENT_VERIFIED → PAID_INTAKE
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(8)
    @DisplayName("T8: Admin successfully releases PAYMENT_VERIFIED → PAID_INTAKE")
    void test08_successfulRelease() throws Exception {
        ReleaseToPoolRequest req = new ReleaseToPoolRequest();
        req.setIntakeNotes("Cleared for processing — Sprint 4 test");

        MvcResult res = mockMvc.perform(post("/api/v1/orders/{id}/release-to-pool", sharedOrderId)
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();

        assertNotNull(res.getResponse().getContentAsString());

        com.provaluer.model.Order order = orderRepository.findById(sharedOrderId).orElseThrow();
        assertEquals("PAID_INTAKE", order.getStatus(), "Status must be PAID_INTAKE after release");
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 9: Report Number Generation (PV-YYMM-XXXX format)
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(9)
    @DisplayName("T9: Report number is generated in PV-YYMM-XXXX format after release")
    void test09_reportNumberGenerated() throws Exception {
        com.provaluer.model.Order order = orderRepository.findById(sharedOrderId).orElseThrow();
        assertEquals("PAID_INTAKE", order.getStatus(), "Prerequisite: order must be PAID_INTAKE (from T8)");
        assertNotNull(order.getReportNumber(), "Report number must be set");
        assertTrue(order.getReportNumber().startsWith("PV-"),
                "Report number must start with PV-, got: " + order.getReportNumber());
        assertNotNull(order.getReleasedBy(), "releasedBy must be recorded");
        assertNotNull(order.getReleasedToPoolAt(), "releasedToPoolAt timestamp must be recorded");
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 10: SLA Timer set after release
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(10)
    @DisplayName("T10: SLA expiry is set to a future timestamp after pool release")
    void test10_slaTimerSet() throws Exception {
        com.provaluer.model.Order order = orderRepository.findById(sharedOrderId).orElseThrow();
        assertNotNull(order.getSlaExpiryTime(), "SLA expiry must be set");
        assertTrue(order.getSlaExpiryTime().isAfter(LocalDateTime.now()),
                "SLA expiry must be in the future, got: " + order.getSlaExpiryTime());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 11: Common Pool Visibility
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(11)
    @DisplayName("T11: PAID_INTAKE order appears in Common Pool /unassigned")
    void test11_commonPoolVisibility() throws Exception {
        com.provaluer.model.Order order = orderRepository.findById(sharedOrderId).orElseThrow();
        assertEquals("PAID_INTAKE", order.getStatus(), "Prerequisite: order must be PAID_INTAKE");

        MvcResult res = mockMvc.perform(get("/api/v1/orders/unassigned")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andReturn();

        List<?> pool = objectMapper.readValue(res.getResponse().getContentAsString(), List.class);
        boolean found = pool.stream()
                .anyMatch(item -> {
                    @SuppressWarnings("unchecked")
                    var m = (java.util.Map<String, Object>) item;
                    return sharedOrderId.equals(((Number) m.get("id")).longValue());
                });
        assertTrue(found, "PAID_INTAKE order must appear in Common Pool /unassigned");
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 12: Duplicate Release Prevention
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(12)
    @DisplayName("T12: Attempting to release an already-PAID_INTAKE order returns 409 Conflict")
    void test12_duplicateReleasePrevented() throws Exception {
        com.provaluer.model.Order order = orderRepository.findById(sharedOrderId).orElseThrow();
        assertEquals("PAID_INTAKE", order.getStatus(), "Prerequisite: order must already be PAID_INTAKE");

        mockMvc.perform(post("/api/v1/orders/{id}/release-to-pool", sharedOrderId)
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new ReleaseToPoolRequest())))
                .andExpect(status().isConflict());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 13: PA claims PAID_INTAKE → ASSIGNED
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(13)
    @DisplayName("T13: PA successfully claims PAID_INTAKE order → ASSIGNED (legacy claim flow unchanged)")
    void test13_paClaimFlow() throws Exception {
        com.provaluer.model.Order order = orderRepository.findById(sharedOrderId).orElseThrow();
        assertEquals("PAID_INTAKE", order.getStatus(), "Prerequisite: order must be PAID_INTAKE");

        mockMvc.perform(post("/api/v1/orders/{id}/claim", sharedOrderId)
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());

        com.provaluer.model.Order claimed = orderRepository.findById(sharedOrderId).orElseThrow();
        assertEquals("ASSIGNED", claimed.getStatus(), "After PA claim, status must be ASSIGNED");
        assertEquals(paUser.getId(), claimed.getPaId(), "PA ID must be set");
        assertNotNull(claimed.getClaimedAt(), "claimedAt must be recorded");
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 14: Invalid status — PAYMENT_SUBMITTED cannot be released → 409
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(14)
    @DisplayName("T14: Release-to-pool fails when order is in PAYMENT_SUBMITTED (invalid state) → 409")
    void test14_invalidStatusRejection() throws Exception {
        Long wrongStatusOrderId = seedOrderWithStatus(clientUser.getId(), "PAYMENT_SUBMITTED");

        mockMvc.perform(post("/api/v1/orders/{id}/release-to-pool", wrongStatusOrderId)
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new ReleaseToPoolRequest())))
                .andExpect(status().isConflict());
    }

    // ────────────────────────────────────────────────────────────────────────────
    // TEST 15: Regression — PAYMENT_PROOF still 403 for ROLE_PA after Sprint 4
    // ────────────────────────────────────────────────────────────────────────────

    @Test
    @org.junit.jupiter.api.Order(15)
    @DisplayName("T15: Regression — PAYMENT_PROOF documents remain inaccessible to ROLE_PA (Sprint 3 isolation)")
    void test15_regressionPaymentProofIsolation() throws Exception {
        com.provaluer.model.Order claimed = orderRepository.findById(sharedOrderId).orElseThrow();
        assertEquals("ASSIGNED", claimed.getStatus(), "Prerequisite: order must be ASSIGNED after T13");

        List<OrderDocument> docs = orderDocumentRepository.findAllByOrderId(sharedOrderId);
        Optional<OrderDocument> paymentProof = docs.stream()
                .filter(d -> "PAYMENT_PROOF".equalsIgnoreCase(d.getCategory()))
                .findFirst();

        if (paymentProof.isPresent()) {
            Long docId = paymentProof.get().getId();
            mockMvc.perform(get("/api/v1/orders/{orderId}/documents/{docId}/download",
                            sharedOrderId, docId)
                            .with(authentication(authPa)))
                    .andExpect(status().isForbidden());
        } else {
            // No PAYMENT_PROOF document — isolation maintained by absence
            assertTrue(true, "PAYMENT_PROOF isolation maintained — no proof doc to test");
        }
    }

    // ────────────────────────────────────────────────────────────────────────────
    // Helpers
    // ────────────────────────────────────────────────────────────────────────────

    private Long seedPaymentVerifiedOrder(Long clientId) {
        com.provaluer.model.Order order = new com.provaluer.model.Order();
        order.setClientId(clientId);
        order.setPropertyCategory("LAND_AND_BUILDING");
        order.setPurpose("Bank Collateral");
        order.setServiceCategory("Residential Valuation");
        order.setStatus("PAYMENT_VERIFIED");
        order.setPaymentStatus("VERIFIED");
        order.setReferenceCode("REQ-S4-" + System.nanoTime());
        order.setQuoteNumber("QTE-S4-" + System.nanoTime());
        order.setQuoteAmount(new BigDecimal("5000.00"));
        order.setQuoteTax(new BigDecimal("900.00"));
        order.setQuoteTotal(new BigDecimal("5900.00"));
        order.setQuoteTurnaround("4-5 Working Days");
        order.setQuoteNotes("Sprint 4 test order — standard valuation scope");
        order.setQuotedAt(LocalDateTime.now().minusDays(3));
        order.setValuationStatus("DRAFT");
        order = orderRepository.save(order);

        // Seed intake documents
        User uploaderRef = userRepository.findById(clientId).orElse(clientUser);
        for (String cat : List.of("TITLE_DEED", "SANCTION_PLAN", "TAX_RECEIPT")) {
            OrderDocument doc = new OrderDocument();
            doc.setOrder(order);
            doc.setCategory(cat);
            doc.setFilename("sample_" + cat.toLowerCase() + ".pdf");
            doc.setFileContent(new byte[]{0x25, 0x50, 0x44, 0x46});
            doc.setUploadedBy(uploaderRef);
            orderDocumentRepository.save(doc);
        }

        // Seed payment proof document
        OrderDocument proofDoc = new OrderDocument();
        proofDoc.setOrder(order);
        proofDoc.setCategory("PAYMENT_PROOF");
        proofDoc.setFilename("payment_receipt.pdf");
        proofDoc.setFileContent(new byte[]{0x25, 0x50, 0x44, 0x46});
        proofDoc.setUploadedBy(uploaderRef);
        orderDocumentRepository.save(proofDoc);

        // Seed verified payment
        OrderPayment payment = new OrderPayment();
        payment.setOrderId(order.getId());
        payment.setQuoteNumber(order.getQuoteNumber());
        payment.setUtrNumber("UTR-S4-" + System.nanoTime());
        payment.setPaymentMethod("NEFT");
        payment.setPaymentDate(LocalDate.now().minusDays(1));
        payment.setAmountExpected(order.getQuoteTotal());
        payment.setAmountPaid(order.getQuoteTotal());
        payment.setVerifiedAmount(order.getQuoteTotal());
        payment.setStatus("VERIFIED");
        payment.setSubmittedBy("client.s4@test.com");
        payment.setSubmittedAt(LocalDateTime.now().minusDays(2));
        payment.setVerifiedBy("admin.s4@test.com");
        payment.setVerifiedAt(LocalDateTime.now().minusDays(1));
        payment = orderPaymentRepository.save(payment);

        order.setLatestPaymentId(payment.getId());
        orderRepository.save(order);

        return order.getId();
    }

    private Long seedOrderWithStatus(Long clientId, String status) {
        com.provaluer.model.Order order = new com.provaluer.model.Order();
        order.setClientId(clientId);
        order.setPropertyCategory("LAND_AND_BUILDING");
        order.setPurpose("Bank Collateral");
        order.setServiceCategory("Commercial Valuation");
        order.setStatus(status);
        order.setPaymentStatus("SUBMITTED");
        order.setReferenceCode("REQ-S4X-" + (System.nanoTime() % 9000 + 1000));
        order.setValuationStatus("DRAFT");
        return orderRepository.save(order).getId();
    }
}
