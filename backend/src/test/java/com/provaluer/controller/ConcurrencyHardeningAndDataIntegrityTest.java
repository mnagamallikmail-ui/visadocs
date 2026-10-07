package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.model.*;
import com.provaluer.repository.*;
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
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class ConcurrencyHardeningAndDataIntegrityTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private OrderRepository orderRepository;
    @Autowired private TemplateRepository templateRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private ValuationLandItemRepository landItemRepository;
    @Autowired private ObjectMapper objectMapper;

    private User paUser;
    private User otherPaUser;
    private User adminUser;
    private Template template;

    private UsernamePasswordAuthenticationToken authPa;
    private UsernamePasswordAuthenticationToken authAdmin;

    @BeforeEach
    void setUp() {
        paUser = userRepository.findAll().stream()
                .filter(u -> UserRole.PA.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("pa_test_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("pa_test_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.PA);
                    u.setMobileNumber("+919876543210");
                    return userRepository.save(u);
                });

        otherPaUser = userRepository.findAll().stream()
                .filter(u -> UserRole.PA.equals(u.getRole()) && !u.getId().equals(paUser.getId()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("pa_other_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("pa_other_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.PA);
                    return userRepository.save(u);
                });

        adminUser = userRepository.findAll().stream()
                .filter(u -> UserRole.SUPER_ADMIN.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("admin_test_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("admin_test_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.SUPER_ADMIN);
                    return userRepository.save(u);
                });

        template = templateRepository.findAll().stream().findFirst().orElseGet(() -> {
            Template t = new Template();
            t.setName("Concurrency Test Template");
            t.setVersion(1);
            t.setIsActive("Y");
            t.setTemplateContent(new byte[]{1, 2, 3});
            t.setFieldMapping("{}");
            t.setDocumentDom("{\"sections\":[]}");
            return templateRepository.save(t);
        });

        authPa = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(paUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + paUser.getRole().name())));

        authAdmin = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(adminUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + adminUser.getRole().name())));
    }

    private Order createDraftingOrder(Long assignedPaId) {
        Order order = new Order();
        order.setClientId(1L);
        order.setPaId(assignedPaId);
        order.setTemplateId(template.getId());
        order.setPropertyCategory("VALUATION");
        order.setPurpose("VALUATION");
        order.setStatus("DRAFTING");
        order.setWorkspaceRevision(1);
        order.setInputValues("{}");
        return orderRepository.save(order);
    }

    @Test
    @DisplayName("Scenario A: Same PA 2 Tabs — Stale revision returns 409 Conflict (No silent overwrite)")
    void testScenarioA_MultiTabCollisionDetection() throws Exception {
        Order order = createDraftingOrder(paUser.getId());
        Long orderId = order.getId();
        assertEquals(1, order.getWorkspaceRevision());

        // Tab 1 submits save at Revision 1 -> Expect HTTP 200 and increment to Revision 2
        SaveDocumentValuesRequest tab1Save = new SaveDocumentValuesRequest(
                Map.of("CLIENT_NAME", "Tab 1 Name", "PROPERTY_ADDRESS", "Tab 1 Address"),
                1
        );
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(tab1Save)))
                .andExpect(status().isOk());

        Order afterTab1 = orderRepository.findById(orderId).orElseThrow();
        assertEquals(2, afterTab1.getWorkspaceRevision());

        // Tab 2 (still on Revision 1) tries to submit save -> Expect HTTP 409 Conflict!
        SaveDocumentValuesRequest tab2StaleSave = new SaveDocumentValuesRequest(
                Map.of("CLIENT_NAME", "Tab 2 Name Stale Overwrite"),
                1 // Stale revision!
        );
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(tab2StaleSave)))
                .andExpect(status().isConflict());

        // Verify Tab 2 DID NOT overwrite Tab 1's data
        Order finalOrder = orderRepository.findById(orderId).orElseThrow();
        assertTrue(finalOrder.getInputValues().contains("Tab 1 Name"));
        assertFalse(finalOrder.getInputValues().contains("Tab 2 Name Stale Overwrite"));
        assertEquals(2, finalOrder.getWorkspaceRevision());
    }

    @Test
    @DisplayName("Scenario B: PA + Admin Collision — Admin editing with stale revision gets 409 Conflict")
    void testScenarioB_AdminPaCollisionProtection() throws Exception {
        Order order = createDraftingOrder(paUser.getId());
        Long orderId = order.getId();

        // PA advances order from Rev 1 to Rev 2
        SaveDocumentValuesRequest paSave = new SaveDocumentValuesRequest(
                Map.of("CLIENT_NAME", "PA Author Work"),
                1
        );
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(paSave)))
                .andExpect(status().isOk());

        // Admin session with stale Rev 1 attempts to save -> Must be rejected with 409 Conflict
        SaveDocumentValuesRequest adminStaleSave = new SaveDocumentValuesRequest(
                Map.of("CLIENT_NAME", "Admin Stale Overwrite"),
                1
        );
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/save-document-values")
                        .with(authentication(authAdmin))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(adminStaleSave)))
                .andExpect(status().isConflict());

        Order finalOrder = orderRepository.findById(orderId).orElseThrow();
        assertTrue(finalOrder.getInputValues().contains("PA Author Work"));
        assertFalse(finalOrder.getInputValues().contains("Admin Stale Overwrite"));
    }

    @Test
    @DisplayName("Scenario C: Reassignment Collision — Old PA tab rejected with 403 Forbidden")
    void testScenarioC_ReassignmentCollision() throws Exception {
        Order order = createDraftingOrder(paUser.getId());
        Long orderId = order.getId();

        // SuperAdmin reassigns to other PA
        order.setPaId(otherPaUser.getId());
        orderRepository.save(order);

        // Original PA tries to save -> Expect 403 Forbidden
        SaveDocumentValuesRequest oldPaSave = new SaveDocumentValuesRequest(
                Map.of("CLIENT_NAME", "Displaced PA Edit"),
                1
        );
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(oldPaSave)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Scenario D: Recovered Order — Displaced PA tab cannot save to recovered order")
    void testScenarioD_RecoveredOrderCollision() throws Exception {
        Order order = createDraftingOrder(paUser.getId());
        Long orderId = order.getId();

        // Admin forces recovery to PAID_INTAKE (paId cleared)
        order.setPaId(null);
        order.setStatus("PAID_INTAKE");
        orderRepository.save(order);

        // Original PA tries to save -> Expect 403 Forbidden
        SaveDocumentValuesRequest oldPaSave = new SaveDocumentValuesRequest(
                Map.of("CLIENT_NAME", "Orphaned Tab Edit"),
                1
        );
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(oldPaSave)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Scenario E: Dynamic Table Safety — Row-level reconciliation preserves existing row identities")
    void testScenarioE_DynamicTableRowLevelReconciliation() throws Exception {
        Order order = createDraftingOrder(paUser.getId());
        Long orderId = order.getId();

        // 1. Initial Land Item in DB
        ValuationLandItem item1 = new ValuationLandItem();
        item1.setOrderId(orderId);
        item1.setDescription("Plot A");
        item1.setEnteredArea(new BigDecimal("1000.00"));
        item1.setEnteredUnit("Sq.Ft");
        item1.setStandardAreaSqft(new BigDecimal("1000.00"));
        item1.setRate(new BigDecimal("500.00"));
        item1.setValue(new BigDecimal("500000.00"));
        item1.setSortOrder(1);
        ValuationLandItem savedItem1 = landItemRepository.save(item1);
        Long initialId = savedItem1.getId();

        // 2. Client submits updated table: Item 1 modified, Item 2 added
        Map<String, Object> incomingItem1 = new HashMap<>();
        incomingItem1.put("id", initialId);
        incomingItem1.put("description", "Plot A (Modified)");
        incomingItem1.put("enteredArea", 1200.0);
        incomingItem1.put("enteredUnit", "Sq.Ft");
        incomingItem1.put("rate", 550.0);

        Map<String, Object> incomingItem2 = new HashMap<>();
        incomingItem2.put("id", null); // New row
        incomingItem2.put("description", "Plot B (New Row)");
        incomingItem2.put("enteredArea", 800.0);
        incomingItem2.put("enteredUnit", "Sq.Ft");
        incomingItem2.put("rate", 600.0);

        String landJson = objectMapper.writeValueAsString(List.of(incomingItem1, incomingItem2));

        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest(
                Map.of("RAW_LAND_ITEMS_JSON", landJson),
                1
        );

        mockMvc.perform(post("/api/v1/orders/" + orderId + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        // 3. Verify: Item 1 retained its primary key ID, and Item 2 was safely appended
        List<ValuationLandItem> afterItems = landItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
        assertEquals(2, afterItems.size());

        ValuationLandItem fetchedItem1 = afterItems.stream()
                .filter(i -> "Plot A (Modified)".equals(i.getDescription()))
                .findFirst()
                .orElse(null);
        assertNotNull(fetchedItem1);
        assertEquals(initialId, fetchedItem1.getId(), "Row-level reconciliation must PRESERVE row identity ID!");

        ValuationLandItem fetchedItem2 = afterItems.stream()
                .filter(i -> "Plot B (New Row)".equals(i.getDescription()))
                .findFirst()
                .orElse(null);
        assertNotNull(fetchedItem2);
        assertNotEquals(initialId, fetchedItem2.getId());
    }
}
