package com.provaluer.controller;

import com.provaluer.model.Order;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.repository.AuditLogRepository;
import com.provaluer.security.UserDetailsImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
public class OrderDeletionPermissionTest {

    @Autowired
    private OrderController orderController;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuditLogRepository auditLogRepository;

    private User clientUser;
    private User paCreator;
    private User paOther;
    private User superAdmin;

    @BeforeEach
    void setUp() {
        long ts = System.currentTimeMillis();
        paCreator = new User();
        paCreator.setUsername("pa_creator_" + ts);
        paCreator.setEmail("pa.creator." + ts + "@provaluer.com");
        paCreator.setPassword("Password@123");
        paCreator.setRole(UserRole.PA);
        paCreator = userRepository.save(paCreator);

        paOther = new User();
        paOther.setUsername("pa_other_" + ts);
        paOther.setEmail("pa.other." + ts + "@provaluer.com");
        paOther.setPassword("Password@123");
        paOther.setRole(UserRole.PA);
        paOther = userRepository.save(paOther);

        superAdmin = new User();
        superAdmin.setUsername("sa_" + ts);
        superAdmin.setEmail("sa." + ts + "@provaluer.com");
        superAdmin.setPassword("Password@123");
        superAdmin.setRole(UserRole.SUPER_ADMIN);
        superAdmin = userRepository.save(superAdmin);

        clientUser = new User();
        clientUser.setUsername("client_" + ts);
        clientUser.setEmail("client." + ts + "@provaluer.com");
        clientUser.setPassword("Password@123");
        clientUser.setRole(UserRole.CLIENT);
        clientUser = userRepository.save(clientUser);
    }

    private void authenticateAs(User user) {
        UserDetailsImpl principal = UserDetailsImpl.build(user);
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("Creator can delete unfinalized report")
    void testCreatorCanDeleteUnfinalizedReport() {
        Order order = new Order();
        order.setPropertyCategory("RESIDENTIAL");
        order.setPurpose("VALUATION");
        order.setClientId(paCreator.getId());
        order.setPaId(paCreator.getId());
        order.setStatus("ASSIGNED");
        order.setValuationStatus("DRAFT");
        order.setReportNumber("PV-TEST-001");
        order = orderRepository.save(order);

        authenticateAs(paCreator);

        ResponseEntity<?> response = orderController.deleteOrder(order.getId());
        assertEquals(HttpStatus.OK, response.getStatusCode());

        Order reloaded = orderRepository.findById(order.getId()).orElseThrow();
        assertTrue(reloaded.isDeleted());
        assertEquals(paCreator.getId(), reloaded.getDeletedBy());
        assertNotNull(reloaded.getDeletedAt());
    }

    @Test
    @DisplayName("Non-creator cannot delete unfinalized report")
    void testNonCreatorCannotDeleteUnfinalizedReport() {
        Order order = new Order();
        order.setPropertyCategory("RESIDENTIAL");
        order.setPurpose("VALUATION");
        order.setClientId(paCreator.getId());
        order.setPaId(paCreator.getId());
        order.setStatus("ASSIGNED");
        order.setValuationStatus("DRAFT");
        order.setReportNumber("PV-TEST-002");
        order = orderRepository.save(order);

        authenticateAs(paOther);

        ResponseEntity<?> response = orderController.deleteOrder(order.getId());
        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());

        Order reloaded = orderRepository.findById(order.getId()).orElseThrow();
        assertFalse(reloaded.isDeleted());
    }

    @Test
    @DisplayName("Super Admin can delete unfinalized report")
    void testSuperAdminCanDeleteUnfinalizedReport() {
        Order order = new Order();
        order.setPropertyCategory("RESIDENTIAL");
        order.setPurpose("VALUATION");
        order.setClientId(paCreator.getId());
        order.setPaId(paCreator.getId());
        order.setStatus("ASSIGNED");
        order.setValuationStatus("DRAFT");
        order.setReportNumber("PV-TEST-003");
        order = orderRepository.save(order);

        authenticateAs(superAdmin);

        ResponseEntity<?> response = orderController.deleteOrder(order.getId());
        assertEquals(HttpStatus.OK, response.getStatusCode());

        Order reloaded = orderRepository.findById(order.getId()).orElseThrow();
        assertTrue(reloaded.isDeleted());
        assertEquals(superAdmin.getId(), reloaded.getDeletedBy());
    }

    @Test
    @DisplayName("Super Admin can delete finalized report")
    void testSuperAdminCanDeleteFinalizedReport() {
        Order order = new Order();
        order.setPropertyCategory("RESIDENTIAL");
        order.setPurpose("VALUATION");
        order.setClientId(paCreator.getId());
        order.setPaId(paCreator.getId());
        order.setStatus("SPA_CONFIRMED");
        order.setValuationStatus("FINALIZED");
        order.setReportNumber("PV-TEST-004");
        order = orderRepository.save(order);

        authenticateAs(superAdmin);

        ResponseEntity<?> response = orderController.deleteOrder(order.getId());
        assertEquals(HttpStatus.OK, response.getStatusCode());

        Order reloaded = orderRepository.findById(order.getId()).orElseThrow();
        assertTrue(reloaded.isDeleted());
        assertEquals(superAdmin.getId(), reloaded.getDeletedBy());
    }

    @Test
    @DisplayName("Creator cannot delete finalized report")
    void testCreatorCannotDeleteFinalizedReport() {
        Order order = new Order();
        order.setPropertyCategory("RESIDENTIAL");
        order.setPurpose("VALUATION");
        order.setClientId(paCreator.getId());
        order.setPaId(paCreator.getId());
        order.setStatus("FINAL_DELIVERY");
        order.setValuationStatus("LOCKED");
        order.setReportNumber("PV-TEST-005");
        order = orderRepository.save(order);

        authenticateAs(paCreator);

        ResponseEntity<?> response = orderController.deleteOrder(order.getId());
        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());

        Order reloaded = orderRepository.findById(order.getId()).orElseThrow();
        assertFalse(reloaded.isDeleted());
    }

    @Test
    @DisplayName("Client CANNOT delete report created by Super Admin on their behalf")
    void testClientCannotDeleteSuperAdminCreatedReport() {
        Order order = new Order();
        order.setPropertyCategory("COMMERCIAL");
        order.setPurpose("VALUATION");
        order.setClientId(clientUser.getId());
        order.setStatus("DRAFT");
        order.setValuationStatus("DRAFT");
        order.setReportNumber("PV-SA-001");
        order = orderRepository.save(order);

        // Record audit log matching SuperAdminController.createOrder
        auditLogRepository.save(new com.provaluer.model.AuditLog(
                superAdmin.getId(), superAdmin.getEmail(), "SUPER_ADMIN", "ORDER_CREATE",
                "ORDER", String.valueOf(order.getId()), null, null, "Created order directly by SUPER_ADMIN"));

        // Client attempts to delete order
        authenticateAs(clientUser);

        ResponseEntity<?> response = orderController.deleteOrder(order.getId());
        assertEquals(HttpStatus.FORBIDDEN, response.getStatusCode());

        Order reloaded = orderRepository.findById(order.getId()).orElseThrow();
        assertFalse(reloaded.isDeleted());
    }

    @Test
    @DisplayName("Super Admin CAN delete report created by Super Admin on behalf of a Client")
    void testSuperAdminCanDeleteSuperAdminCreatedReport() {
        Order order = new Order();
        order.setPropertyCategory("COMMERCIAL");
        order.setPurpose("VALUATION");
        order.setClientId(clientUser.getId());
        order.setStatus("DRAFT");
        order.setValuationStatus("DRAFT");
        order.setReportNumber("PV-SA-002");
        order = orderRepository.save(order);

        // Record audit log matching SuperAdminController.createOrder
        auditLogRepository.save(new com.provaluer.model.AuditLog(
                superAdmin.getId(), superAdmin.getEmail(), "SUPER_ADMIN", "ORDER_CREATE",
                "ORDER", String.valueOf(order.getId()), null, null, "Created order directly by SUPER_ADMIN"));

        authenticateAs(superAdmin);

        ResponseEntity<?> response = orderController.deleteOrder(order.getId());
        assertEquals(HttpStatus.OK, response.getStatusCode());

        Order reloaded = orderRepository.findById(order.getId()).orElseThrow();
        assertTrue(reloaded.isDeleted());
        assertEquals(superAdmin.getId(), reloaded.getDeletedBy());
    }
}
