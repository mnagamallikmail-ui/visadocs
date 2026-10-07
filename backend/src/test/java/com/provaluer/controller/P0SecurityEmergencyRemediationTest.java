package com.provaluer.controller;

import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
public class P0SecurityEmergencyRemediationTest {

    @Autowired private AuthController authController;
    @Autowired private OrderController orderController;
    @Autowired private OrderDocumentController orderDocumentController;
    @Autowired private ValuationController valuationController;
    @Autowired private PaymentController paymentController;
    @Autowired private SuperAdminController superAdminController;

    @Autowired private UserRepository userRepository;
    @Autowired private OrderRepository orderRepository;
    @Autowired private OrderDocumentRepository orderDocumentRepository;
    @Autowired private AuditLogRepository auditLogRepository;

    private User clientA;
    private User clientB;
    private User pa1;
    private User pa2;
    private User adminUser;
    private User superAdminUser;

    private Order orderClientB;
    private Order orderPa2;

    @BeforeEach
    void setUp() {
        clientA = createUser("client_a", "client_a@test.com", UserRole.CLIENT);
        clientB = createUser("client_b", "client_b@test.com", UserRole.CLIENT);
        pa1 = createUser("pa_1", "pa_1@test.com", UserRole.PA);
        pa2 = createUser("pa_2", "pa_2@test.com", UserRole.PA);
        adminUser = createUser("admin_user", "admin@test.com", UserRole.ADMIN);
        superAdminUser = createUser("super_admin_user", "superadmin@test.com", UserRole.SUPER_ADMIN);

        // Order owned by Client B
        orderClientB = new Order();
        orderClientB.setClientId(clientB.getId());
        orderClientB.setClientName(clientB.getUsername());
        orderClientB.setPurpose("VALUATION");
        orderClientB.setPropertyCategory("LAND_AND_BUILDING");
        orderClientB.setStatus("FINAL_DELIVERY");
        orderClientB.setReferenceCode("ORD-CLIENT-B");
        orderClientB = orderRepository.save(orderClientB);

        // Order assigned to PA-2
        orderPa2 = new Order();
        orderPa2.setClientId(clientB.getId());
        orderPa2.setPaId(pa2.getId());
        orderPa2.setPurpose("VALUATION");
        orderPa2.setPropertyCategory("LAND_AND_BUILDING");
        orderPa2.setStatus("SPA_GATE");
        orderPa2.setReferenceCode("ORD-PA2");
        orderPa2 = orderRepository.save(orderPa2);
    }

    private User createUser(String username, String email, UserRole role) {
        User u = new User();
        u.setUsername(username);
        u.setEmail(email);
        u.setPassword("Secret123!");
        u.setRole(role);
        return userRepository.save(u);
    }

    private void authenticateAs(User u) {
        UserDetailsImpl principal = UserDetailsImpl.build(u);
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // =========================================================================
    // TEST 1 & TEST 12: Public SUPER_ADMIN Registration / Role Injection
    // =========================================================================
    @Test
    @DisplayName("TEST 1 & 12: Public registration with SUPER_ADMIN role must be ignored and create CLIENT role")
    void test1_and_test12_publicSuperAdminRegistration_roleIgnored() {
        AuthController.RegisterRequest req = new AuthController.RegisterRequest();
        req.setUsername("injected_user");
        req.setEmail("injected@evil.com");
        req.setPassword("Password123!");
        req.setRole("SUPER_ADMIN");

        ResponseEntity<?> response = authController.registerUser(req);
        assertEquals(HttpStatus.OK, response.getStatusCode());

        Optional<User> createdOpt = userRepository.findByUsernameIgnoreCase("injected_user");
        assertTrue(createdOpt.isPresent());
        assertEquals(UserRole.CLIENT, createdOpt.get().getRole(), "User role MUST default to CLIENT, ignoring SUPER_ADMIN injection");
    }

    // =========================================================================
    // TEST 2: Foreign Report Download (IDOR)
    // =========================================================================
    @Test
    @DisplayName("TEST 2: Client A cannot download Client B's final report (403 Forbidden)")
    void test2_foreignReportDownload_forbidden() {
        authenticateAs(clientA);
        ResponseEntity<?> resp = orderController.downloadReportSecure(orderClientB.getId());
        assertEquals(HttpStatus.FORBIDDEN, resp.getStatusCode());
    }

    // =========================================================================
    // TEST 3: Foreign Valuation Access (IDOR)
    // =========================================================================
    @Test
    @DisplayName("TEST 3: Client A cannot access Client B's valuation details (403 Forbidden)")
    void test3_foreignValuationAccess_forbidden() {
        authenticateAs(clientA);
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        assertThrows(AccessDeniedException.class, () -> {
            valuationController.getValuation(orderClientB.getId(), principal);
        });
    }

    // =========================================================================
    // TEST 4: Foreign Document Access (IDOR)
    // =========================================================================
    @Test
    @DisplayName("TEST 4: Client A cannot access Client B's documents (403 Forbidden)")
    void test4_foreignDocumentAccess_forbidden() {
        OrderDocument doc = new OrderDocument();
        doc.setOrder(orderClientB);
        doc.setCategory("TITLE_DEED");
        doc.setFilename("deed.pdf");
        doc.setFileContent("deed-data".getBytes());
        doc.setUploadedBy(clientB);
        doc = orderDocumentRepository.save(doc);

        authenticateAs(clientA);
        ResponseEntity<?> listResp = orderDocumentController.getDocuments(orderClientB.getId());
        assertEquals(HttpStatus.FORBIDDEN, listResp.getStatusCode());

        ResponseEntity<?> downloadResp = orderDocumentController.downloadDocument(orderClientB.getId(), doc.getId());
        assertEquals(HttpStatus.FORBIDDEN, downloadResp.getStatusCode());
    }

    // =========================================================================
    // TEST 5: Payment Bypass Attempt
    // =========================================================================
    @Test
    @DisplayName("TEST 5: Foreign user cannot execute payment process-balance on another order (403 Forbidden)")
    void test5_paymentBypass_forbidden() {
        authenticateAs(clientA);
        ResponseEntity<?> resp = paymentController.processBalancePayment(orderClientB.getId(), BigDecimal.valueOf(0.01));
        assertEquals(HttpStatus.FORBIDDEN, resp.getStatusCode());
    }

    // =========================================================================
    // TEST 6: Draft Ownership Hijack Attempt
    // =========================================================================
    @Test
    @DisplayName("TEST 6: Client A cannot hijack or overwrite Client B's draft (403 Forbidden)")
    void test6_draftOwnershipHijack_forbidden() {
        Order draftB = new Order();
        draftB.setClientId(clientB.getId());
        draftB.setPurpose("VALUATION");
        draftB.setPropertyCategory("LAND_AND_BUILDING");
        draftB.setStatus("DRAFT");
        draftB = orderRepository.save(draftB);

        authenticateAs(clientA);
        OrderController.OrderDraftRequest req = new OrderController.OrderDraftRequest();
        req.setId(draftB.getId());
        req.setPropertyCategory("COMMERCIAL");

        ResponseEntity<?> resp = orderController.saveDraft(req);
        assertEquals(HttpStatus.FORBIDDEN, resp.getStatusCode());
    }

    // =========================================================================
    // TEST 7: PA Cross-Assignment Valuation Access
    // =========================================================================
    @Test
    @DisplayName("TEST 7: PA-1 cannot access or edit Order assigned to PA-2 (403 Forbidden)")
    void test7_paCrossAssignment_forbidden() {
        authenticateAs(pa1);
        UserDetailsImpl principal = (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        assertThrows(AccessDeniedException.class, () -> {
            valuationController.getValuation(orderPa2.getId(), principal);
        });
    }

    // =========================================================================
    // TEST 8: PA Cross-Assignment DOCX Download
    // =========================================================================
    @Test
    @DisplayName("TEST 8: PA-1 cannot download DOCX for Order assigned to PA-2 (403 Forbidden)")
    void test8_paCrossAssignmentDocxDownload_forbidden() {
        authenticateAs(pa1);
        ResponseEntity<?> resp = orderController.downloadReportDocx(orderPa2.getId());
        assertEquals(HttpStatus.FORBIDDEN, resp.getStatusCode());
    }

    // =========================================================================
    // TEST 9: ADMIN Self-Promotion Attempt
    // =========================================================================
    @Test
    @DisplayName("TEST 9: Admin cannot self-promote to SUPER_ADMIN (Forbidden / Access Denied)")
    void test9_adminSelfPromotion_rejected() {
        authenticateAs(adminUser);
        SuperAdminController.RoleChangeRequest req = new SuperAdminController.RoleChangeRequest();
        req.setRole("SUPER_ADMIN");

        // ADMIN cannot invoke changeUserRole due to @PreAuthorize("hasRole('SUPER_ADMIN')") -> 403 Forbidden
        assertThrows(Exception.class, () -> {
            superAdminController.changeUserRole(adminUser.getId(), req);
        });

        // Furthermore, even if invoking with SUPER_ADMIN, self-promotion/role modification on own account is rejected
        authenticateAs(superAdminUser);
        ResponseEntity<?> resp = superAdminController.changeUserRole(superAdminUser.getId(), req);
        assertEquals(HttpStatus.BAD_REQUEST, resp.getStatusCode());
        Object body = resp.getBody();
        assertNotNull(body, "Response body should not be null");
        assertTrue(String.valueOf(body).contains("Self-promotion"));
    }

    // =========================================================================
    // TEST 10: Audit Log Immutability on User Deletion
    // =========================================================================
    @Test
    @DisplayName("TEST 10: Deleting a user must retain all historical audit logs (Audit Immutability)")
    void test10_auditDeletion_auditRetained() {
        // Create an audit entry where clientA was the actor
        AuditLog logEntry = new AuditLog();
        logEntry.setActorId(clientA.getId());
        logEntry.setActorEmail(clientA.getEmail());
        logEntry.setActorRole("CLIENT");
        logEntry.setActionType("TEST_EVENT");
        logEntry.setEntityType("ORDER");
        logEntry.setTimestamp(java.time.LocalDateTime.now());
        logEntry = auditLogRepository.save(logEntry);

        authenticateAs(superAdminUser);
        ResponseEntity<?> resp = superAdminController.hardDeleteUser(clientA.getId());
        assertEquals(HttpStatus.OK, resp.getStatusCode());

        // Verify audit log still exists!
        Optional<AuditLog> retained = auditLogRepository.findById(logEntry.getId());
        assertTrue(retained.isPresent(), "Audit log MUST remain preserved after user hard deletion");
    }

    // =========================================================================
    // TEST 11: Report Purge by ADMIN
    // =========================================================================
    @Test
    @DisplayName("TEST 11: Report purge and purge-all cannot be executed by non-SUPER_ADMIN")
    void test11_reportPurgeByAdmin_restricted() {
        // 1. Verify purgeAllReports method requires SUPER_ADMIN
        try {
            java.lang.reflect.Method m = SuperAdminController.class.getMethod("purgeAllReports");
            org.springframework.security.access.prepost.PreAuthorize pa = m.getAnnotation(org.springframework.security.access.prepost.PreAuthorize.class);
            assertNotNull(pa, "purgeAllReports must have @PreAuthorize");
            assertEquals("hasRole('SUPER_ADMIN')", pa.value().trim());
        } catch (NoSuchMethodException e) {
            fail("purgeAllReports method not found");
        }

        // 2. Verify ADMIN invoking purgeAllReports or purgeOrder triggers AccessDenied / AuthorizationDenied
        authenticateAs(adminUser);
        assertThrows(Exception.class, () -> {
            superAdminController.purgeAllReports();
        });
        assertThrows(Exception.class, () -> {
            superAdminController.purgeOrder(orderClientB.getId());
        });
    }
}
