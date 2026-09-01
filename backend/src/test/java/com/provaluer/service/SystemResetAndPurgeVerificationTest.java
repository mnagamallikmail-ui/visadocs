package com.provaluer.service;

import com.provaluer.controller.SuperAdminController;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class SystemResetAndPurgeVerificationTest {

    @Autowired private SuperAdminController superAdminController;
    @Autowired private UserRepository userRepository;
    @Autowired private OrderRepository orderRepository;
    @Autowired private OrderInputRepository orderInputRepository;
    @Autowired private OrderDocumentRepository orderDocumentRepository;
    @Autowired private RevisionRepository revisionRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private PerformanceLedgerRepository performanceLedgerRepository;
    @Autowired private SystemSettingRepository systemSettingRepository;
    @Autowired private TemplateRepository templateRepository;
    @Autowired private TemplateVersionRepository templateVersionRepository;
    @Autowired private TemplateQuestionRepository templateQuestionRepository;
    @Autowired private DocumentStudioConfigRepository documentStudioConfigRepository;
    @Autowired private ValuationDataRepository valuationDataRepository;
    @Autowired private ValuationLandItemRepository valuationLandItemRepository;
    @Autowired private ValuationBuildingItemRepository valuationBuildingItemRepository;
    @Autowired private ValuationComparableSaleRepository valuationComparableSaleRepository;
    @Autowired private ValuationSnapshotRepository valuationSnapshotRepository;
    @Autowired private ValuationAuditLogRepository valuationAuditLogRepository;
    @Autowired private AuditLogRepository auditLogRepository;

    @Test
    @Transactional
    @WithMockUser(username = "superadmin@provaluer.com", roles = {"SUPER_ADMIN"})
    public void testFullSystemResetPreservesUsersAndSettings() {
        // 1. Ensure a user exists
        User user = userRepository.findByEmail("superadmin@provaluer.com")
                .orElseGet(() -> {
                    User u = new User();
                    u.setEmail("superadmin@provaluer.com");
                    u.setPassword("hashedpass");
                    u.setFullName("Super Admin");
                    u.setRole(UserRole.SUPER_ADMIN);
                    return userRepository.save(u);
                });
        long initialUsersCount = userRepository.count();
        assertTrue(initialUsersCount >= 1);

        // 2. Create mock template and version
        Template template = new Template();
        template.setName("Test Reset Template");
        template.setFieldMapping("{}");
        template.setTemplateContent(new byte[]{1, 2, 3});
        template = templateRepository.save(template);

        TemplateVersion version = new TemplateVersion(template, "Initial Version", user.getId());
        templateVersionRepository.save(version);

        // 3. Create mock order and valuation items
        Order order = new Order();
        order.setClientId(user.getId());
        order.setPurpose("MORTGAGE");
        order.setPropertyCategory("COMMERCIAL");
        order.setStatus("DRAFT");
        order.setEstimatedValue(new BigDecimal("10000000"));
        order = orderRepository.save(order);

        ValuationData valData = new ValuationData(order.getId());
        valData.setFairValue(new BigDecimal("10000000"));
        valuationDataRepository.save(valData);

        ValuationLandItem land = new ValuationLandItem();
        land.setOrderId(order.getId());
        land.setDescription("Plot 1");
        land.setRate(new BigDecimal("1000"));
        valuationLandItemRepository.save(land);

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setOrderId(order.getId());
        bldg.setStructureType("Ground Floor");
        bldg.setReplacementCost(new BigDecimal("5000000"));
        valuationBuildingItemRepository.save(bldg);

        ValuationSnapshot snapshot = new ValuationSnapshot();
        snapshot.setOrderId(order.getId());
        snapshot.setSnapshotTrigger("TEST_RESET");
        snapshot.setSnapshotHash("0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef");
        snapshot.setSnapshotData("{}");
        valuationSnapshotRepository.save(snapshot);

        // Verify pre-reset counts
        assertTrue(orderRepository.count() >= 1);
        assertTrue(valuationDataRepository.count() >= 1);
        assertTrue(valuationLandItemRepository.count() >= 1);
        assertTrue(valuationBuildingItemRepository.count() >= 1);
        assertTrue(valuationSnapshotRepository.count() >= 1);
        assertTrue(templateRepository.count() >= 1);
        assertTrue(templateVersionRepository.count() >= 1);

        // 4. Execute Full System Reset via SuperAdminController
        ResponseEntity<?> reportPurgeRes = superAdminController.purgeAllReports();
        assertEquals(200, reportPurgeRes.getStatusCode().value());

        ResponseEntity<?> templatePurgeRes = superAdminController.purgeAllTemplates();
        assertEquals(200, templatePurgeRes.getStatusCode().value());

        // 5. Verify post-reset state: Target tables are EMPTY
        assertEquals(0, orderRepository.count(), "Orders must be 0");
        assertEquals(0, valuationDataRepository.count(), "ValuationData must be 0");
        assertEquals(0, valuationLandItemRepository.count(), "Land items must be 0");
        assertEquals(0, valuationBuildingItemRepository.count(), "Building items must be 0");
        assertEquals(0, valuationSnapshotRepository.count(), "Snapshots must be 0");
        assertEquals(0, templateRepository.count(), "Templates must be 0");
        assertEquals(0, templateVersionRepository.count(), "Template versions must be 0");

        // 6. Verify preserved entities: Users and Audit logs MUST REMAIN INTACT
        assertEquals(initialUsersCount, userRepository.count(), "Users MUST NOT be deleted");
        assertTrue(userRepository.findByEmail("superadmin@provaluer.com").isPresent());
    }
}
