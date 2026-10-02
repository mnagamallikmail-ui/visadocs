package com.provaluer.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.BindTemplateRequest;
import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.TelegramNotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
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

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * SPRINT 6: Comprehensive Automated Integration Tests
 * Document Workspace & SPA Submission Gate:
 * INSPECTION_COMPLETED → WORKSPACE_READY → DRAFTING → SPA_GATE
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class Sprint6WorkspaceLifecycleTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private OrderRepository orderRepository;
    @Autowired private OrderInspectionRepository orderInspectionRepository;
    @Autowired private InspectionPhotoRepository inspectionPhotoRepository;
    @Autowired private TemplateRepository templateRepository;
    @Autowired private AuditLogRepository auditLogRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private ObjectMapper objectMapper;

    @SpyBean private TelegramNotificationService telegramNotificationService;

    private User paUser;
    private User otherPaUser;
    private User clientUser;
    private User spaUser;

    private UsernamePasswordAuthenticationToken authPa;
    private UsernamePasswordAuthenticationToken authOtherPa;
    private UsernamePasswordAuthenticationToken authClient;
    private UsernamePasswordAuthenticationToken authSpa;

    @BeforeEach
    void setUp() {
        paUser = userRepository.findAll().stream()
                .filter(u -> UserRole.PA.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("pa_s6_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("pa_s6_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.PA);
                    u.setMobileNumber("+919876543210");
                    return userRepository.save(u);
                });

        otherPaUser = userRepository.findAll().stream()
                .filter(u -> UserRole.PA.equals(u.getRole()) && !u.getId().equals(paUser.getId()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("other_pa_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("other_pa_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.PA);
                    return userRepository.save(u);
                });

        clientUser = userRepository.findAll().stream()
                .filter(u -> UserRole.CLIENT.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("client_s6_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("client_s6_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.CLIENT);
                    return userRepository.save(u);
                });

        spaUser = userRepository.findAll().stream()
                .filter(u -> UserRole.SPA.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("spa_s6_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("spa_s6_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.SPA);
                    return userRepository.save(u);
                });

        authPa = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(paUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + paUser.getRole().name())));

        authOtherPa = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(otherPaUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + otherPaUser.getRole().name())));

        authClient = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(clientUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + clientUser.getRole().name())));

        authSpa = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(spaUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + spaUser.getRole().name())));
    }

    private com.provaluer.model.Order createCompletedInspectionOrder() {
        com.provaluer.model.Order order = new com.provaluer.model.Order();
        order.setClientId(clientUser.getId());
        order.setPaId(paUser.getId());
        order.setStatus("INSPECTION_COMPLETED");
        order.setPurpose("Commercial Valuation");
        order.setPropertyCategory("Commercial Complex");
        order.setReferenceCode("PV-REQ-" + System.nanoTime());
        order.setReportNumber("PV-2610-" + System.nanoTime());
        order.setEstimatedValue(BigDecimal.valueOf(10000000));
        order.setClientName("Apex Commercial Bank");
        order.setBankName("Apex Bank");
        order.setBranchName("Commercial Main Branch");
        order = orderRepository.save(order);

        // Attach Inspection details
        OrderInspection inspection = new OrderInspection();
        inspection.setOrderId(order.getId());
        inspection.setPaId(paUser.getId());
        inspection.setVisitStatus("COMPLETED");
        inspection.setCompletedAt(LocalDateTime.now());
        inspection.setInspectionDate(LocalDate.now());
        inspection.setInspectionTime(LocalTime.of(11, 30));
        inspection.setSiteContactName("John Doe");
        inspection.setSiteContactNumber("+919123456780");
        inspection.setGpsLatStart(BigDecimal.valueOf(18.5204300));
        inspection.setGpsLngStart(BigDecimal.valueOf(73.8567400));
        inspection.setGpsLatEnd(BigDecimal.valueOf(18.5204350));
        inspection.setGpsLngEnd(BigDecimal.valueOf(73.8567450));
        orderInspectionRepository.save(inspection);

        // Attach Inspection Photos for all 7 mandatory categories
        for (PhotoCategory cat : PhotoCategory.getMandatoryCategories()) {
            for (int i = 0; i < cat.getMinPhotos(); i++) {
                InspectionPhoto photo = new InspectionPhoto();
                photo.setOrderId(order.getId());
                photo.setInspectionId(inspection.getId());
                photo.setPaId(paUser.getId());
                photo.setCategory(cat.name());
                photo.setFilename(cat.name().toLowerCase() + "_" + i + ".jpg");
                photo.setMimeType("image/jpeg");
                photo.setFileContent(new byte[]{1, 2, 3, 4, 5});
                photo.setUploadedBy(paUser.getId());
                photo.setUploadedAt(LocalDateTime.now());
                photo.setCaptureSequence(i + 1);
                inspectionPhotoRepository.save(photo);
            }
        }

        return order;
    }

    @Test
    @Order(1)
    @DisplayName("Verify Workspace Initialization: Resolves template, locks version, generates DOM snapshot, imports inspection data and photos")
    void testWorkspaceInitialization() throws Exception {
        com.provaluer.model.Order order = createCompletedInspectionOrder();

        String responseJson = mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/initialize-workspace")
                        .with(authentication(authPa)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        JsonNode responseNode = objectMapper.readTree(responseJson);
        assertTrue(responseNode.has("documentDom"), "DOM snapshot must be returned");
        assertTrue(responseNode.has("values"), "Values map must be returned");

        // Verify order in database
        com.provaluer.model.Order updatedOrder = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("WORKSPACE_READY", updatedOrder.getStatus());
        assertNotNull(updatedOrder.getTemplateVersionId(), "Template version ID must be locked");
        assertNotNull(updatedOrder.getDocumentDomSnapshot(), "DOM snapshot must be stored in database");

        // Verify imported inspection and photo data
        assertNotNull(updatedOrder.getInputValues());
        Map<String, String> values = objectMapper.readValue(updatedOrder.getInputValues(), new TypeReference<Map<String, String>>() {});
        assertEquals("Apex Commercial Bank", values.get("CLIENT_NAME"));
        assertEquals("Apex Bank", values.get("BANK_NAME"));
        assertEquals("John Doe", values.get("SITE_CONTACT_PERSON"));
        assertEquals("+919123456780", values.get("SITE_CONTACT_PHONE"));
        assertTrue(values.containsKey("IMG_FRONT_PAGE") || values.containsKey("IMG_FRONT_ELEVATION"));
        assertTrue(values.containsKey("IMG_STREET_VIEW"));
        assertTrue(values.containsKey("IMG_SURROUNDINGS_1") || values.containsKey("IMG_SURROUNDINGS"));

        // Verify Audit Logs
        List<AuditLog> auditLogs = auditLogRepository.findAllByEntityTypeAndEntityIdOrderByTimestampDesc("ORDER", String.valueOf(order.getId()));
        Set<String> actionTypes = new HashSet<>();
        for (AuditLog log : auditLogs) {
            actionTypes.add(log.getActionType());
        }
        assertTrue(actionTypes.contains("WORKSPACE_INITIALIZED"));
        assertTrue(actionTypes.contains("TEMPLATE_BOUND"));
        assertTrue(actionTypes.contains("INSPECTION_DATA_IMPORTED"));
        assertTrue(actionTypes.contains("PHOTO_BOUND"));
    }

    @Test
    @Order(2)
    @DisplayName("Verify Template Binding: Lock template version permanently with audit entry")
    void testTemplateBinding() throws Exception {
        com.provaluer.model.Order order = createCompletedInspectionOrder();

        // Find an active template or default
        Template template = templateRepository.findAll().stream().findFirst().orElseGet(() -> {
            Template t = new Template();
            t.setName("Standard Commercial Template");
            t.setCode("COMMERCIAL_STANDARD");
            t.setIsActive("true");
            t.setStatus("PUBLISHED");
            t.setVersion(1);
            t.setTemplateContent(new byte[]{1, 2, 3});
            t.setFieldMapping("{}");
            t.setDocumentDom("{\"sections\":[]}");
            return templateRepository.save(t);
        });

        BindTemplateRequest bindRequest = new BindTemplateRequest(template.getId(), false);

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/bind-template")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(bindRequest)))
                .andExpect(status().isOk());

        com.provaluer.model.Order updatedOrder = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals(template.getId(), updatedOrder.getTemplateId());
        assertNotNull(updatedOrder.getTemplateVersionId());
        assertNotNull(updatedOrder.getDocumentDomSnapshot());

        boolean boundLogged = auditLogRepository.findAllByEntityTypeAndEntityIdOrderByTimestampDesc("ORDER", String.valueOf(order.getId()))
                .stream().anyMatch(l -> "TEMPLATE_BOUND".equals(l.getActionType()));
        assertTrue(boundLogged, "TEMPLATE_BOUND audit log must be recorded");
    }

    @Test
    @Order(3)
    @DisplayName("Verify Autosave and Status Transition from WORKSPACE_READY to DRAFTING")
    void testAutosaveAndDraftingTransition() throws Exception {
        com.provaluer.model.Order order = createCompletedInspectionOrder();

        // Initialize workspace first
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/initialize-workspace")
                .with(authentication(authPa)))
                .andExpect(status().isOk());

        com.provaluer.model.Order readyOrder = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("WORKSPACE_READY", readyOrder.getStatus());

        // Perform autosave edit
        Map<String, String> delta = new HashMap<>();
        delta.put("BUILDING_AGE_YEARS", "5");
        delta.put("TOTAL_FLOORS", "4");

        SaveDocumentValuesRequest saveReq = new SaveDocumentValuesRequest(delta);

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(saveReq)))
                .andExpect(status().isOk());

        com.provaluer.model.Order draftingOrder = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("DRAFTING", draftingOrder.getStatus());
        Map<String, String> values = objectMapper.readValue(draftingOrder.getInputValues(), new TypeReference<Map<String, String>>() {});
        assertEquals("5", values.get("BUILDING_AGE_YEARS"));
        assertEquals("4", values.get("TOTAL_FLOORS"));

        boolean draftSavedLogged = auditLogRepository.findAllByEntityTypeAndEntityIdOrderByTimestampDesc("ORDER", String.valueOf(order.getId()))
                .stream().anyMatch(l -> "DRAFT_SAVED".equals(l.getActionType()));
        assertTrue(draftSavedLogged, "DRAFT_SAVED audit log must be recorded");
    }

    @Test
    @Order(4)
    @DisplayName("Verify Dynamic Table Support and Formula Field Storage")
    void testDynamicTablesAndFormulas() throws Exception {
        com.provaluer.model.Order order = createCompletedInspectionOrder();
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/initialize-workspace")
                .with(authentication(authPa)))
                .andExpect(status().isOk());

        Map<String, String> tableValues = new HashMap<>();
        tableValues.put("RAW_LAND_ITEMS_JSON", "[{\"description\":\"Main Plot\",\"area\":\"10000\",\"rate\":\"500\",\"amount\":\"5000000\"}]");
        tableValues.put("TOTAL_LAND_VALUE", "5000000");
        tableValues.put("RAW_BUILDING_ITEMS_JSON", "[{\"floor\":\"Ground\",\"area\":\"5000\",\"rate\":\"1000\",\"amount\":\"5000000\"}]");
        tableValues.put("TOTAL_BUILDING_VALUE", "5000000");
        tableValues.put("TOTAL_VALUATION", "10000000");

        SaveDocumentValuesRequest saveReq = new SaveDocumentValuesRequest(tableValues);

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(saveReq)))
                .andExpect(status().isOk());

        com.provaluer.model.Order updatedOrder = orderRepository.findById(order.getId()).orElseThrow();
        Map<String, String> values = objectMapper.readValue(updatedOrder.getInputValues(), new TypeReference<Map<String, String>>() {});
        assertEquals("5000000", values.get("TOTAL_LAND_VALUE"));
        assertEquals("10000000", values.get("TOTAL_VALUATION"));
        assertTrue(values.get("RAW_LAND_ITEMS_JSON").contains("Main Plot"));
    }

    @Test
    @Order(5)
    @DisplayName("Verify Draft Validation Engine: Reports missing mandatory fields, photos, and placeholders")
    void testDraftValidationEngine() throws Exception {
        com.provaluer.model.Order order = createCompletedInspectionOrder();
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/initialize-workspace")
                .with(authentication(authPa)))
                .andExpect(status().isOk());

        // Validate draft before filling required valuation fields
        String validationJson = mockMvc.perform(get("/api/v1/orders/" + order.getId() + "/validate-draft")
                        .with(authentication(authPa)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        JsonNode valNode = objectMapper.readTree(validationJson);
        assertFalse(valNode.get("valid").asBoolean(), "Draft should be invalid before filling required valuation fields");
        assertTrue(valNode.get("errorCount").asInt() > 0);

        // Fill all required fields
        Map<String, String> completeValues = new HashMap<>();
        completeValues.put("PROPERTY_ADDRESS", "Plot 42, Sector 18, Commercial Zone, Tech Park");
        completeValues.put("TOTAL_VALUATION", "10000000");
        completeValues.put("VALUATION_DATE", LocalDate.now().toString());
        completeValues.put("VALUER_NAME", "Jane Valuer");
        completeValues.put("PROPERTY_TYPE", "Commercial Building");

        SaveDocumentValuesRequest saveReq = new SaveDocumentValuesRequest(completeValues);

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(saveReq)))
                .andExpect(status().isOk());

        // Validate draft after filling all fields
        String validationPassedJson = mockMvc.perform(get("/api/v1/orders/" + order.getId() + "/validate-draft")
                        .with(authentication(authPa)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        JsonNode passedValNode = objectMapper.readTree(validationPassedJson);
        assertTrue(passedValNode.get("valid").asBoolean(), "Draft should be valid when all requirements are met: " + passedValNode);
    }

    @Test
    @Order(6)
    @DisplayName("Verify Draft Submission to SPA Gate: Transitions to SPA_GATE and logs PA_SUBMITTED")
    void testSubmitToSpaGate() throws Exception {
        com.provaluer.model.Order order = createCompletedInspectionOrder();
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/initialize-workspace")
                .with(authentication(authPa)))
                .andExpect(status().isOk());

        // Populate valid fields
        Map<String, String> completeValues = new HashMap<>();
        completeValues.put("PROPERTY_ADDRESS", "Plot 42, Sector 18, Commercial Zone, Tech Park");
        completeValues.put("TOTAL_VALUATION", "10000000");
        completeValues.put("VALUATION_DATE", LocalDate.now().toString());
        completeValues.put("VALUER_NAME", "Jane Valuer");
        completeValues.put("PROPERTY_TYPE", "Commercial Building");

        SaveDocumentValuesRequest saveReq = new SaveDocumentValuesRequest(completeValues);

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(saveReq)))
                .andExpect(status().isOk());

        // Submit to SPA
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/submit-to-spa")
                        .with(authentication(authPa)))
                .andExpect(status().isOk());

        com.provaluer.model.Order lockedOrder = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("SPA_GATE", lockedOrder.getStatus(), "Status must be SPA_GATE");
        assertEquals("SUBMITTED", lockedOrder.getValuationStatus(), "Valuation status must be SUBMITTED");

        boolean paSubmittedLogged = auditLogRepository.findAllByEntityTypeAndEntityIdOrderByTimestampDesc("ORDER", String.valueOf(order.getId()))
                .stream().anyMatch(l -> "PA_SUBMITTED".equals(l.getActionType()));
        assertTrue(paSubmittedLogged, "PA_SUBMITTED audit log must be recorded");
    }

    @Test
    @Order(7)
    @DisplayName("Verify SPA Gate Read-Only Lock: PA save operations are rejected with HTTP 403")
    void testSpaGateReadOnlyLock() throws Exception {
        com.provaluer.model.Order order = createCompletedInspectionOrder();
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/initialize-workspace")
                .with(authentication(authPa)))
                .andExpect(status().isOk());

        // Populate valid fields & submit
        Map<String, String> completeValues = new HashMap<>();
        completeValues.put("PROPERTY_ADDRESS", "Plot 42, Sector 18, Commercial Zone, Tech Park");
        completeValues.put("TOTAL_VALUATION", "10000000");
        completeValues.put("VALUATION_DATE", LocalDate.now().toString());
        completeValues.put("VALUER_NAME", "Jane Valuer");
        completeValues.put("PROPERTY_TYPE", "Commercial Building");

        SaveDocumentValuesRequest saveReq = new SaveDocumentValuesRequest(completeValues);

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(saveReq)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/submit-to-spa")
                        .with(authentication(authPa)))
                .andExpect(status().isOk());

        // Attempting to modify document in SPA_GATE must return HTTP 403 Forbidden
        Map<String, String> tamperingEdit = Map.of("TOTAL_VALUATION", "99999999");
        SaveDocumentValuesRequest tamperReq = new SaveDocumentValuesRequest(tamperingEdit);
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/save-document-values")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(tamperReq)))
                .andExpect(status().isForbidden());

        // Attempting to submit again in SPA_GATE must return HTTP 403 Forbidden
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/submit-to-spa")
                        .with(authentication(authPa)))
                .andExpect(status().isForbidden());
    }

    @Test
    @Order(8)
    @DisplayName("Verify Security Governance: Unassigned PA and Client access rejected with HTTP 403")
    void testSecurityGovernance() throws Exception {
        com.provaluer.model.Order order = createCompletedInspectionOrder();
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/initialize-workspace")
                .with(authentication(authPa)))
                .andExpect(status().isOk());

        // Unassigned PA cannot save values -> HTTP 403
        Map<String, String> edit = Map.of("PROPERTY_TYPE", "Unauthorized");
        SaveDocumentValuesRequest saveReq = new SaveDocumentValuesRequest(edit);
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/save-document-values")
                        .with(authentication(authOtherPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(saveReq)))
                .andExpect(status().isForbidden());

        // Unassigned PA cannot submit to SPA -> HTTP 403
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/submit-to-spa")
                        .with(authentication(authOtherPa)))
                .andExpect(status().isForbidden());

        // Client cannot access document workspace -> HTTP 403
        mockMvc.perform(get("/api/v1/orders/" + order.getId() + "/document-workspace")
                        .with(authentication(authClient)))
                .andExpect(status().isForbidden());

        // SPA cannot edit document values during drafting -> HTTP 403
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/save-document-values")
                        .with(authentication(authSpa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(saveReq)))
                .andExpect(status().isForbidden());
    }
}
