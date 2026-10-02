package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.VerifyPaymentRequest;
import com.provaluer.model.*;
import com.provaluer.repository.AuditLogRepository;
import com.provaluer.repository.OrderPaymentRepository;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.UserDetailsImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class PaymentVerificationAndPoolLifecycleTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderPaymentRepository orderPaymentRepository;

    @Autowired
    private com.provaluer.repository.OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private User adminUser;
    private User superAdminUser;
    private User clientUser;
    private User paUser;

    private UsernamePasswordAuthenticationToken authAdmin;
    private UsernamePasswordAuthenticationToken authSuperAdmin;
    private UsernamePasswordAuthenticationToken authClient;
    private UsernamePasswordAuthenticationToken authPa;

    @BeforeEach
    void setUp() {
        adminUser = userRepository.findByUsernameIgnoreCase("admin_pv_test").orElseGet(() -> {
            User u = new User("admin_pv_test", "admin_pv_test@test.com", "pass123", UserRole.ADMIN, "9876540001", "v1.0");
            u.setFullName("Admin PV Test");
            return userRepository.save(u);
        });

        superAdminUser = userRepository.findByUsernameIgnoreCase("superadmin_pv_test").orElseGet(() -> {
            User u = new User("superadmin_pv_test", "superadmin_pv_test@test.com", "pass123", UserRole.SUPER_ADMIN, "9876540002", "v1.0");
            u.setFullName("SuperAdmin PV Test");
            return userRepository.save(u);
        });

        clientUser = userRepository.findByUsernameIgnoreCase("client_pv_test").orElseGet(() -> {
            User u = new User("client_pv_test", "client_pv_test@test.com", "pass123", UserRole.CLIENT, "9876540003", "v1.0");
            u.setFullName("Client PV Test");
            return userRepository.save(u);
        });

        paUser = userRepository.findByUsernameIgnoreCase("pa_pv_test").orElseGet(() -> {
            User u = new User("pa_pv_test", "pa_pv_test@test.com", "pass123", UserRole.PA, "9876540004", "v1.0");
            u.setFullName("Valuer PA Test");
            return userRepository.save(u);
        });

        authAdmin = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(adminUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + adminUser.getRole().name())));
        authSuperAdmin = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(superAdminUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + superAdminUser.getRole().name())));
        authClient = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(clientUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + clientUser.getRole().name())));
        authPa = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(paUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + paUser.getRole().name())));
    }

    private Order createTestOrder(String status, String paymentStatus) {
        Order o = new Order();
        o.setClientId(clientUser.getId());
        o.setStatus(status);
        o.setPaymentStatus(paymentStatus);
        o.setBalanceDue(BigDecimal.valueOf(10000.00));
        o.setQuoteAmount(BigDecimal.valueOf(10000.00));
        o.setQuoteTotal(BigDecimal.valueOf(11800.00));
        o.setQuoteTax(BigDecimal.valueOf(1800.00));
        o.setServiceCategory("Valuation Report");
        o.setPropertyCategory("Commercial Office");
        o.setPurpose("Bank Collateral");
        o.setReferenceCode("REQ-2026-" + System.nanoTime());
        o.setQuoteNumber("QTE-2026-" + System.nanoTime());
        o.setCreatedAt(LocalDateTime.now());
        return orderRepository.save(o);
    }

    @Test
    @DisplayName("Fix 1 & 2: Payment Review Queue is accessible by ADMIN and SUPER_ADMIN, displays PAYMENT_SUBMITTED orders")
    void testPaymentReviewQueueSecurityAndVisibility() throws Exception {
        Order submittedOrder = createTestOrder("PAYMENT_SUBMITTED", "SUBMITTED");

        // Admin can access
        mockMvc.perform(get("/api/v1/orders/payment-review-queue")
                        .with(authentication(authAdmin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[?(@.orderId == " + submittedOrder.getId() + ")]").exists());

        // SuperAdmin can access
        mockMvc.perform(get("/api/v1/orders/payment-review-queue")
                        .with(authentication(authSuperAdmin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.orderId == " + submittedOrder.getId() + ")]").exists());

        // PA cannot access
        mockMvc.perform(get("/api/v1/orders/payment-review-queue")
                        .with(authentication(authPa)))
                .andExpect(status().isForbidden());

        // Client cannot access
        mockMvc.perform(get("/api/v1/orders/payment-review-queue")
                        .with(authentication(authClient)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Fix 4 & 6: Verify Payment moves order to PAYMENT_VERIFIED, sets verifiedBy/verifiedAt, records audit log")
    void testPaymentVerificationLifecycleAndAudit() throws Exception {
        Order order = createTestOrder("PAYMENT_SUBMITTED", "SUBMITTED");

        OrderPayment payment = new OrderPayment();
        payment.setOrderId(order.getId());
        payment.setQuoteNumber(order.getQuoteNumber());
        payment.setUtrNumber("UTR" + System.currentTimeMillis());
        payment.setPaymentMethod("IMPS");
        payment.setPaymentDate(LocalDate.now());
        payment.setAmountExpected(order.getQuoteTotal());
        payment.setAmountPaid(order.getQuoteTotal());
        payment.setStatus("SUBMITTED");
        payment.setSubmittedBy(clientUser.getUsername());
        payment = orderPaymentRepository.save(payment);

        order.setLatestPaymentId(payment.getId());
        order = orderRepository.save(order);

        VerifyPaymentRequest request = new VerifyPaymentRequest();
        request.setVerifiedAmount(order.getQuoteTotal());
        request.setAdminNotes("Verified with bank settlement batch");

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/verify-payment")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("VERIFIED"));

        // Verify order state
        Order updated = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("PAYMENT_VERIFIED", updated.getStatus());
        assertEquals("VERIFIED", updated.getPaymentStatus());

        // Verify payment record
        List<OrderPayment> payments = orderPaymentRepository.findAllByOrderIdOrderBySubmittedAtDesc(order.getId());
        assertFalse(payments.isEmpty());
        OrderPayment verifiedPayment = payments.get(0);
        assertEquals("VERIFIED", verifiedPayment.getStatus());
        assertNotNull(verifiedPayment.getVerifiedBy());
        assertNotNull(verifiedPayment.getVerifiedAt());

        // Verify Audit Log
        List<AuditLog> auditLogs = auditLogRepository.findAllByEntityTypeAndEntityIdOrderByTimestampDesc("ORDER", String.valueOf(order.getId()));
        boolean foundVerifiedLog = auditLogs.stream().anyMatch(l -> "PAYMENT_VERIFIED".equals(l.getActionType()));
        assertTrue(foundVerifiedLog, "Audit log must contain PAYMENT_VERIFIED event");
    }

    @Test
    @DisplayName("Fix 5 & 6: Waive Payment zeroes balance, moves state to PAYMENT_VERIFIED, updates payment, records reason and audit log")
    void testWaivePaymentLifecycleAndAudit() throws Exception {
        Order order = createTestOrder("PAYMENT_SUBMITTED", "SUBMITTED");
        assertTrue(order.getBalanceDue().compareTo(BigDecimal.ZERO) > 0);

        Map<String, String> body = new HashMap<>();
        body.put("reason", "Corporate SLA pre-approved exemption");

        mockMvc.perform(post("/api/v1/admin/orders/" + order.getId() + "/waive-payment")
                        .with(authentication(authSuperAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(body)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balanceDue").value(0))
                .andExpect(jsonPath("$.paymentStatus").value("VERIFIED"))
                .andExpect(jsonPath("$.status").value("PAYMENT_VERIFIED"));

        // Verify database state
        Order updated = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("PAYMENT_VERIFIED", updated.getStatus());
        assertEquals("VERIFIED", updated.getPaymentStatus());
        assertEquals(0, BigDecimal.ZERO.compareTo(updated.getBalanceDue()));

        // Verify OrderPayment created / updated
        List<OrderPayment> payments = orderPaymentRepository.findAllByOrderIdOrderBySubmittedAtDesc(order.getId());
        assertFalse(payments.isEmpty());
        OrderPayment waivedPayment = payments.get(0);
        assertEquals("VERIFIED", waivedPayment.getStatus());
        assertTrue(waivedPayment.getAdminNotes().contains("Corporate SLA pre-approved exemption"));
        assertNotNull(waivedPayment.getVerifiedBy());
        assertNotNull(waivedPayment.getVerifiedAt());

        // Verify Audit Log recorded PAYMENT_WAIVED
        List<AuditLog> auditLogs = auditLogRepository.findAllByEntityTypeAndEntityIdOrderByTimestampDesc("ORDER", String.valueOf(order.getId()));
        boolean foundWaivedLog = auditLogs.stream().anyMatch(l -> "PAYMENT_WAIVED".equals(l.getActionType()));
        assertTrue(foundWaivedLog, "Audit log must contain PAYMENT_WAIVED event");
    }

    @Test
    @DisplayName("Fix 6 & 7: General Pool Release: PAYMENT_VERIFIED -> PAID_INTAKE (POOL_RELEASED), appears in Pool, PA claims to ASSIGNED")
    void testReleaseToPoolAndPaClaimLifecycle() throws Exception {
        Order order = createTestOrder("PAYMENT_VERIFIED", "VERIFIED");

        // Seed required intake document for clearance gate
        OrderDocument doc = new OrderDocument();
        doc.setOrder(order);
        doc.setCategory("TITLE_DEED");
        doc.setFilename("sample_title_deed.pdf");
        doc.setFileContent(new byte[]{0x25, 0x50, 0x44, 0x46});
        doc.setUploadedBy(clientUser);
        orderDocumentRepository.save(doc);

        // 1. Admin releases order to pool
        Map<String, String> releasePayload = new HashMap<>();
        releasePayload.put("intakeNotes", "Ready for fast-track processing");

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/release-to-pool")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(releasePayload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PAID_INTAKE"))
                .andExpect(jsonPath("$.orderId").value(order.getId()));

        Order inPool = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("PAID_INTAKE", inPool.getStatus());
        assertNotNull(inPool.getReportNumber());
        assertTrue(inPool.getReportNumber().startsWith("PV-"));

        // Verify Audit Log for POOL_RELEASED
        List<AuditLog> auditLogs = auditLogRepository.findAll().stream()
                .filter(l -> String.valueOf(order.getId()).equals(l.getEntityId()))
                .toList();
        boolean foundPoolReleaseLog = auditLogs.stream().anyMatch(l -> "POOL_RELEASED".equals(l.getActionType()));
        assertTrue(foundPoolReleaseLog, "Audit log must contain POOL_RELEASED event");

        // 2. PA views General Pool
        mockMvc.perform(get("/api/v1/orders/unassigned")
                        .with(authentication(authPa)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[?(@.id == " + order.getId() + ")]").exists());

        // 3. PA claims the order
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/claim")
                        .with(authentication(authPa)))
                .andExpect(status().isOk());

        Order claimed = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("ASSIGNED", claimed.getStatus());
        assertEquals(paUser.getId(), claimed.getPaId());
    }
}
