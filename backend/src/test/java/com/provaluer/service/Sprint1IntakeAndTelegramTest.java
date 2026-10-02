package com.provaluer.service;

import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.util.concurrent.CompletableFuture;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
public class Sprint1IntakeAndTelegramTest {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TelegramNotificationService telegramNotificationService;

    private User testClient;
    private Order testOrder;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        orderDocumentRepository.deleteAll();
        orderRepository.deleteAll();

        testClient = new User("client_sprint1", "client1@provaluer.in", "pass123", UserRole.CLIENT, "9876543210", "v1.0");
        testClient.setFullName("John Test Client");
        testClient = userRepository.save(testClient);

        UserDetailsImpl userDetails = UserDetailsImpl.build(testClient);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities())
        );

        testOrder = new Order();
        testOrder.setClientId(testClient.getId());
        testOrder.setServiceCategory("VALUATION");
        testOrder.setPropertyCategory("LAND_AND_BUILDING");
        testOrder.setPurpose("BANK_COLLATERAL");
        testOrder.setStatus("DRAFT");
        testOrder = orderRepository.save(testOrder);
    }

    @Test
    @DisplayName("Sprint 1: Telegram service executes asynchronously and non-blocking in simulation mode without throwing")
    void testTelegramNotificationService_SimulationMode() throws Exception {
        CompletableFuture<Boolean> future = telegramNotificationService.sendNewRequestNotification(
                "REQ-2026-9999",
                "John Test Client",
                "Valuation Report",
                "Land & Building",
                "Bank Collateral / Loan",
                3,
                "9876543210"
        );

        assertNotNull(future);
        Boolean result = future.get(); // Should complete safely with false (simulation mode when unconfigured)
        assertFalse(result, "Unconfigured credentials should safely log and return false without exception");
    }

    @Test
    @DisplayName("Sprint 1: Order model accepts and persists reference_code and service_category")
    void testOrderReferenceCodePersistence() {
        testOrder.setReferenceCode("REQ-2026-1234");
        testOrder.setServiceCategory("VALUATION");
        testOrder.setStatus("QUOTE_PENDING");
        Order saved = orderRepository.save(testOrder);

        assertNotNull(saved.getId());
        assertEquals("REQ-2026-1234", saved.getReferenceCode());
        assertEquals("VALUATION", saved.getServiceCategory());
        assertEquals("QUOTE_PENDING", saved.getStatus());
        assertTrue(orderRepository.existsByReferenceCode("REQ-2026-1234"));
    }

    @Test
    @DisplayName("Sprint 1: Mandatory documents verification for TITLE_DEED, SANCTION_PLAN, TAX_RECEIPT")
    void testMandatoryDocumentsCheck() {
        // Initially no documents
        var initialDocs = orderDocumentRepository.findAllByOrderId(testOrder.getId());
        assertTrue(initialDocs.isEmpty());

        // Upload title deed
        OrderDocument doc1 = new OrderDocument();
        doc1.setOrder(testOrder);
        doc1.setCategory("TITLE_DEED");
        doc1.setFilename("sale_deed.pdf");
        doc1.setFileContent(new byte[]{1, 2, 3});
        doc1.setUploadedBy(testClient);
        orderDocumentRepository.save(doc1);

        // Upload plan
        OrderDocument doc2 = new OrderDocument();
        doc2.setOrder(testOrder);
        doc2.setCategory("SANCTION_PLAN");
        doc2.setFilename("approved_layout.pdf");
        doc2.setFileContent(new byte[]{4, 5, 6});
        doc2.setUploadedBy(testClient);
        orderDocumentRepository.save(doc2);

        // Upload tax receipt
        OrderDocument doc3 = new OrderDocument();
        doc3.setOrder(testOrder);
        doc3.setCategory("TAX_RECEIPT");
        doc3.setFilename("tax_paid.pdf");
        doc3.setFileContent(new byte[]{7, 8, 9});
        doc3.setUploadedBy(testClient);
        orderDocumentRepository.save(doc3);

        var finalDocs = orderDocumentRepository.findAllByOrderId(testOrder.getId());
        assertEquals(3, finalDocs.size());

        var categories = finalDocs.stream().map(d -> d.getCategory().toUpperCase()).toList();
        assertTrue(categories.contains("TITLE_DEED"));
        assertTrue(categories.contains("SANCTION_PLAN"));
        assertTrue(categories.contains("TAX_RECEIPT"));
    }
}
