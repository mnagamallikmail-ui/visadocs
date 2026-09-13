package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.model.Template;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.TemplateRepository;
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
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class OrderCreateStaffReportTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private User paUser;
    private UsernamePasswordAuthenticationToken auth;

    @BeforeEach
    public void setup() {
        paUser = userRepository.findByUsernameIgnoreCase("poojitha").orElseGet(() -> {
            User u = new User();
            u.setUsername("poojitha");
            u.setEmail("poojitha@provaluer.com");
            u.setPassword("pass");
            u.setRole(UserRole.PA);
            return userRepository.save(u);
        });

        UserDetailsImpl userDetails = UserDetailsImpl.build(paUser);
        auth = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    @DisplayName("Validation Governance: Successful staff report creation with valid active template")
    public void testCreateStaffReport_Success() throws Exception {
        Template template = new Template();
        template.setName("Active Gov Template " + System.currentTimeMillis());
        template.setTemplateContent("test".getBytes());
        template.setFieldMapping("{}");
        template.setIsActive("Y");
        template.setStatus(Template.STATUS_ACTIVE);
        template = templateRepository.save(template);

        Map<String, Object> req = new HashMap<>();
        req.put("clientName", "Valid Client");
        req.put("bankName", "State Bank of India");
        req.put("branchName", "Main Branch");
        req.put("templateId", template.getId());

        MvcResult result = mockMvc.perform(post("/api/v1/orders/create-by-staff")
                        .principal(auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andReturn();

        assertEquals(200, result.getResponse().getStatus());
        String body = result.getResponse().getContentAsString();
        assertTrue(body.contains("PV-"));
        assertTrue(body.contains("Valid Client"));
    }

    @Test
    @DisplayName("Validation Governance: Block creation with Missing Template (HTTP 400)")
    public void testCreateStaffReport_MissingTemplate() throws Exception {
        Map<String, Object> req = new HashMap<>();
        req.put("clientName", "John Doe");
        req.put("bankName", "State Bank of India");
        req.put("branchName", "Main Branch");
        req.put("templateId", 999999L); // Missing / non-existent

        MvcResult result = mockMvc.perform(post("/api/v1/orders/create-by-staff")
                        .principal(auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andReturn();

        assertEquals(400, result.getResponse().getStatus());
        String body = result.getResponse().getContentAsString();
        assertTrue(body.contains("Cannot create report with missing template"));
    }

    @Test
    @DisplayName("Validation Governance: Block creation with Deleted Template (HTTP 400)")
    public void testCreateStaffReport_DeletedTemplate() throws Exception {
        Template template = new Template();
        template.setName("Deleted Template " + System.currentTimeMillis());
        template.setTemplateContent("test".getBytes());
        template.setFieldMapping("{}");
        template.setIsActive("N");
        template.setStatus(Template.STATUS_DELETED);
        template.setDeletedAt(LocalDateTime.now());
        template = templateRepository.save(template);

        Map<String, Object> req = new HashMap<>();
        req.put("clientName", "John Doe");
        req.put("bankName", "State Bank of India");
        req.put("branchName", "Main Branch");
        req.put("templateId", template.getId());

        MvcResult result = mockMvc.perform(post("/api/v1/orders/create-by-staff")
                        .principal(auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andReturn();

        assertEquals(400, result.getResponse().getStatus());
        String body = result.getResponse().getContentAsString();
        assertTrue(body.contains("Cannot create report with deleted template"));
    }

    @Test
    @DisplayName("Validation Governance: Block creation with Inactive Template (HTTP 400)")
    public void testCreateStaffReport_InactiveTemplate() throws Exception {
        Template template = new Template();
        template.setName("Inactive Template " + System.currentTimeMillis());
        template.setTemplateContent("test".getBytes());
        template.setFieldMapping("{}");
        template.setIsActive("N");
        template.setStatus(Template.STATUS_ARCHIVED);
        template = templateRepository.save(template);

        Map<String, Object> req = new HashMap<>();
        req.put("clientName", "John Doe");
        req.put("bankName", "State Bank of India");
        req.put("branchName", "Main Branch");
        req.put("templateId", template.getId());

        MvcResult result = mockMvc.perform(post("/api/v1/orders/create-by-staff")
                        .principal(auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andReturn();

        assertEquals(400, result.getResponse().getStatus());
        String body = result.getResponse().getContentAsString();
        assertTrue(body.contains("Cannot create report with inactive template"));
    }

    @Test
    @DisplayName("Validation Governance: Block creation with Template in PARSING state (HTTP 400)")
    public void testCreateStaffReport_ParsingTemplate() throws Exception {
        Template template = new Template();
        template.setName("Parsing Template " + System.currentTimeMillis());
        template.setTemplateContent("test".getBytes());
        template.setFieldMapping("{}");
        template.setIsActive("Y");
        template.setStatus("PARSING");
        template = templateRepository.save(template);

        Map<String, Object> req = new HashMap<>();
        req.put("clientName", "John Doe");
        req.put("bankName", "State Bank of India");
        req.put("branchName", "Main Branch");
        req.put("templateId", template.getId());

        MvcResult result = mockMvc.perform(post("/api/v1/orders/create-by-staff")
                        .principal(auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andReturn();

        assertEquals(400, result.getResponse().getStatus());
        String body = result.getResponse().getContentAsString();
        assertTrue(body.contains("Cannot create report until parsing completes"));
    }

    @Test
    @DisplayName("Validation Governance: Block creation with Template in FAILED state (HTTP 400)")
    public void testCreateStaffReport_FailedTemplate() throws Exception {
        Template template = new Template();
        template.setName("Failed Template " + System.currentTimeMillis());
        template.setTemplateContent("test".getBytes());
        template.setFieldMapping("{}");
        template.setIsActive("Y");
        template.setStatus("FAILED");
        template.setProcessingError("Corrupted XML stream in document part");
        template = templateRepository.save(template);

        Map<String, Object> req = new HashMap<>();
        req.put("clientName", "John Doe");
        req.put("bankName", "State Bank of India");
        req.put("branchName", "Main Branch");
        req.put("templateId", template.getId());

        MvcResult result = mockMvc.perform(post("/api/v1/orders/create-by-staff")
                        .principal(auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andReturn();

        assertEquals(400, result.getResponse().getStatus());
        String body = result.getResponse().getContentAsString();
        assertTrue(body.contains("Cannot create report with failed template"));
    }

    @Test
    @DisplayName("Validation Governance: Block creation with missing required fields (HTTP 400)")
    public void testCreateStaffReport_MissingFields() throws Exception {
        Map<String, Object> req = new HashMap<>();
        req.put("clientName", "   "); // Empty client name
        req.put("bankName", "State Bank of India");
        req.put("branchName", "Main Branch");
        req.put("templateId", 1L);

        MvcResult result = mockMvc.perform(post("/api/v1/orders/create-by-staff")
                        .principal(auth)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andReturn();

        assertEquals(400, result.getResponse().getStatus());
        String body = result.getResponse().getContentAsString();
        assertTrue(body.contains("Client Name is required"));
    }
}
