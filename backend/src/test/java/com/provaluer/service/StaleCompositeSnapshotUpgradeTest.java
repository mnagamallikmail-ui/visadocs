package com.provaluer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.provaluer.dto.DocumentWorkspaceResponse;
import com.provaluer.model.Order;
import com.provaluer.model.Template;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.UserDetailsImpl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class StaleCompositeSnapshotUpgradeTest {

    @Autowired
    private DocumentWorkspaceService documentWorkspaceService;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private UserRepository userRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    @DisplayName("Verify self-healing database persistence for stale COMPOSITE_PROPERTY_TABLE snapshots")
    public void testStaleCompositeSnapshotUpgradeAndPersistence() throws Exception {
        // Setup Template
        Template template = new Template();
        template.setName("Test Apartment Template");
        template.setIsActive("Y");
        template.setStatus("CONFIRMED");
        template.setVersion(1);
        template.setFieldMapping("{}");
        template.setDocumentDom("{}");
        template.setPlaceholderRegistry("[]");
        template.setTemplateContent(new byte[]{1, 2, 3});
        Template savedTemplate = templateRepository.save(template);

        // Setup User
        User user = new User("valuer_test@test.com", "secret", UserRole.SUPER_ADMIN, "9876543210", "v101");
        user.setFullName("Valuer Test");
        User savedUser = userRepository.save(user);
        UserDetailsImpl principal = UserDetailsImpl.build(savedUser);

        // STEP 1: Construct Stale DOM Snapshot with fieldType: "TEXT"
        ObjectNode domRoot = objectMapper.createObjectNode();
        ArrayNode sectionsArray = domRoot.putArray("sections");
        ObjectNode section = sectionsArray.addObject();
        section.put("sectionIndex", 0);
        section.put("title", "VALUATION OF FLAT / APARTMENT");

        ArrayNode elementsArray = section.putArray("elements");
        ObjectNode table = elementsArray.addObject();
        table.put("id", "tbl_001");
        table.put("type", "TABLE");

        ArrayNode rowsArray = table.putArray("rows");
        ObjectNode row = rowsArray.addObject();
        row.put("rowIndex", 0);
        row.put("rowType", "QUESTION_ANSWER");

        ArrayNode cellsArray = row.putArray("cells");
        ObjectNode c0 = cellsArray.addObject();
        c0.put("cellId", "c0");
        c0.put("cellRole", "QUESTION");
        c0.put("plainText", "Assessment Table");

        ObjectNode c1 = cellsArray.addObject();
        c1.put("cellId", "c1");
        c1.put("cellRole", "ANSWER");
        c1.put("plainText", "<<COMPOSITE_PROPERTY_TABLE>>");

        ArrayNode bindings = c1.putArray("placeholderBindings");
        ObjectNode b = bindings.addObject();
        b.put("key", "COMPOSITE_PROPERTY_TABLE");
        b.put("questionText", "Assessment Table");
        b.put("fieldType", "TEXT"); // <-- STALE SNAPSHOT VALUE

        ArrayNode summaries = domRoot.putArray("placeholdersSummary");
        ObjectNode s = summaries.addObject();
        s.put("key", "COMPOSITE_PROPERTY_TABLE");
        s.put("label", "Assessment of Property Value");
        s.put("occurrences", 1);
        s.put("type", "TEXT"); // <-- STALE SNAPSHOT VALUE

        String staleJson = domRoot.toString();

        Order order = new Order();
        order.setReportNumber("PV-STALE-001");
        order.setClientName("Test Client");
        order.setClientId(savedUser.getId());
        order.setTemplateId(savedTemplate.getId());
        order.setTemplateVersion(savedTemplate.getVersion());
        order.setPurpose("Valuation");
        order.setPropertyCategory("Flat");
        order.setStatus("IN_PROGRESS");
        order.setDocumentDomSnapshot(staleJson);
        Order savedOrder = orderRepository.save(order);

        Long orderId = savedOrder.getId();

        // STEP 2 & 3: Load workspace and verify runtime normalization
        DocumentWorkspaceResponse firstResponse = documentWorkspaceService.getDocumentWorkspace(orderId, principal);
        assertNotNull(firstResponse);
        JsonNode firstDom = firstResponse.getDocumentDom();
        assertNotNull(firstDom);

        // Verify runtime response is normalized to DYNAMIC_COMPOSITE_PROPERTY_TABLE
        String returnedFieldType = firstDom.path("sections").get(0).path("elements").get(0)
                .path("rows").get(0).path("cells").get(1).path("placeholderBindings").get(0)
                .path("fieldType").asText();
        assertEquals("DYNAMIC_COMPOSITE_PROPERTY_TABLE", returnedFieldType,
                "First load runtime DOM must be normalized to DYNAMIC_COMPOSITE_PROPERTY_TABLE");

        String returnedSummaryType = firstDom.path("placeholdersSummary").get(0).path("type").asText();
        assertEquals("DYNAMIC_COMPOSITE_PROPERTY_TABLE", returnedSummaryType,
                "First load summary type must be normalized to DYNAMIC_COMPOSITE_PROPERTY_TABLE");

        // STEP 4 & 5: Reload order DIRECTLY from database to verify persistence
        Order reloadedOrder = orderRepository.findById(orderId).orElseThrow();
        String persistedJson = reloadedOrder.getDocumentDomSnapshot();
        assertNotNull(persistedJson);
        assertNotEquals(staleJson, persistedJson, "Persisted JSON snapshot must have been updated in the database");

        JsonNode persistedDom = objectMapper.readTree(persistedJson);
        String persistedFieldType = persistedDom.path("sections").get(0).path("elements").get(0)
                .path("rows").get(0).path("cells").get(1).path("placeholderBindings").get(0)
                .path("fieldType").asText();
        assertEquals("DYNAMIC_COMPOSITE_PROPERTY_TABLE", persistedFieldType,
                "DATABASE snapshot MUST contain DYNAMIC_COMPOSITE_PROPERTY_TABLE after self-healing persistence");

        String persistedSummaryType = persistedDom.path("placeholdersSummary").get(0).path("type").asText();
        assertEquals("DYNAMIC_COMPOSITE_PROPERTY_TABLE", persistedSummaryType,
                "DATABASE snapshot placeholdersSummary MUST contain DYNAMIC_COMPOSITE_PROPERTY_TABLE");

        // Secondary workspace reload (verifies subsequent loads remain upgraded)
        DocumentWorkspaceResponse secondResponse = documentWorkspaceService.getDocumentWorkspace(orderId, principal);
        JsonNode secondDom = secondResponse.getDocumentDom();
        String secondFieldType = secondDom.path("sections").get(0).path("elements").get(0)
                .path("rows").get(0).path("cells").get(1).path("placeholderBindings").get(0)
                .path("fieldType").asText();
        assertEquals("DYNAMIC_COMPOSITE_PROPERTY_TABLE", secondFieldType,
                "Second workspace load must retain DYNAMIC_COMPOSITE_PROPERTY_TABLE from database");
    }
}
