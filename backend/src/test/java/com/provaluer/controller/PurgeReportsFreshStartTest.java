package com.provaluer.controller;

import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
public class PurgeReportsFreshStartTest {

    @Autowired
    private SuperAdminController superAdminController;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private OrderInputRepository orderInputRepository;

    @Autowired
    private RevisionRepository revisionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TemplateRepository templateRepository;

    private User superAdmin;

    @BeforeEach
    void setUp() {
        superAdmin = new User();
        superAdmin.setEmail("super.admin@provaluer.com");
        superAdmin.setPassword("Password@123");
        superAdmin.setRole(UserRole.SUPER_ADMIN);
        superAdmin = userRepository.save(superAdmin);

        UserDetailsImpl principal = UserDetailsImpl.build(superAdmin);
        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);

        // Seed some test orders, inputs, documents, and revisions
        Template template = new Template();
        template.setName("Valuation Report Template");
        template.setIsActive("Y");
        template.setStatus("ACTIVE");
        template.setFieldMapping("{}");
        template.setTemplateContent(new byte[10]);
        template = templateRepository.save(template);

        Order order = new Order();
        order.setClientId(superAdmin.getId());
        order.setPaId(superAdmin.getId());
        order.setTemplateId(template.getId());
        order.setPurpose("Fresh Start Test");
        order.setPropertyCategory("Commercial");
        order.setStatus("IN_PROGRESS");
        order.setEstimatedValue(BigDecimal.valueOf(5000000));
        order = orderRepository.save(order);

        OrderInput input = new OrderInput(order.getId(), "PROPERTY_ADDRESS", "123 Main St");
        orderInputRepository.save(input);

        OrderDocument doc = new OrderDocument();
        doc.setOrder(order);
        doc.setCategory("DOCX");
        doc.setFilename("valuation_report.docx");
        doc.setFileContent(new byte[10]);
        doc.setUploadedBy(superAdmin);
        orderDocumentRepository.save(doc);

        Revision rev = new Revision();
        rev.setOrderId(order.getId());
        rev.setRoundNumber(1);
        rev.setErrorClassification("FORMATTING");
        rev.setFeedback("Initial draft notes");
        rev.setStatus("PENDING");
        revisionRepository.save(rev);
    }

    @Test
    @DisplayName("Purge all reports and orders: Confirms complete database reset for fresh start")
    void testPurgeAllReports() {
        assertTrue(orderRepository.count() > 0, "Orders must exist before purge");
        assertTrue(orderInputRepository.count() > 0, "Order inputs must exist before purge");
        assertTrue(orderDocumentRepository.count() > 0, "Order documents must exist before purge");
        assertTrue(revisionRepository.count() > 0, "Revisions must exist before purge");

        ResponseEntity<?> response = superAdminController.purgeAllReports();
        assertNotNull(response);
        assertEquals(200, response.getStatusCode().value());

        @SuppressWarnings("unchecked")
        Map<String, Object> body = (Map<String, Object>) response.getBody();
        assertNotNull(body);
        assertEquals("SUCCESS", body.get("status"));

        assertEquals(0, orderRepository.count(), "All orders must be deleted");
        assertEquals(0, orderInputRepository.count(), "All inputs must be deleted");
        assertEquals(0, orderDocumentRepository.count(), "All documents must be deleted");
        assertEquals(0, revisionRepository.count(), "All revisions must be deleted");

        System.out.println("Purge Complete: " + body);
    }
}
