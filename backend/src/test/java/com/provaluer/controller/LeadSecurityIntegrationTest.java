package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.LeadQuoteRequestDto;
import com.provaluer.dto.LeadRequestDto;
import com.provaluer.dto.LeadStatusUpdateDto;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.model.ValuationLead;
import com.provaluer.repository.UserRepository;
import com.provaluer.repository.ValuationLeadRepository;
import com.provaluer.security.LeadIntakeRateLimitingFilter;
import com.provaluer.security.UserDetailsImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class LeadSecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ValuationLeadRepository leadRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private LeadIntakeRateLimitingFilter rateLimitingFilter;

    private ValuationLead testLead;
    private UsernamePasswordAuthenticationToken adminAuth;
    private UsernamePasswordAuthenticationToken clientAuth;

    @BeforeEach
    public void setup() {
        // Reset rate limiter for clean tests
        rateLimitingFilter.resetTracker();
        SecurityContextHolder.clearContext();

        // Ensure super admin user exists
        User adminUser = userRepository.findByUsernameIgnoreCase("superadmin_test").orElseGet(() -> {
            User u = new User();
            u.setUsername("superadmin_test");
            u.setEmail("superadmin_test@provaluer.com");
            u.setPassword("hashedpass");
            u.setRole(UserRole.SUPER_ADMIN);
            return userRepository.save(u);
        });

        UserDetailsImpl adminDetails = UserDetailsImpl.build(adminUser);
        adminAuth = new UsernamePasswordAuthenticationToken(adminDetails, null, adminDetails.getAuthorities());

        // Ensure non-admin client user exists
        User clientUser = userRepository.findByUsernameIgnoreCase("client_test").orElseGet(() -> {
            User u = new User();
            u.setUsername("client_test");
            u.setEmail("client_test@client.com");
            u.setPassword("hashedpass");
            u.setRole(UserRole.CLIENT);
            return userRepository.save(u);
        });

        UserDetailsImpl clientDetails = UserDetailsImpl.build(clientUser);
        clientAuth = new UsernamePasswordAuthenticationToken(clientDetails, null, clientDetails.getAuthorities());

        // Create a test lead in database
        testLead = new ValuationLead();
        testLead.setReferenceCode("REQ-2026-TEST" + System.currentTimeMillis() % 10000);
        testLead.setServiceVertical("PLANT_AND_MACHINERY");
        testLead.setMandatePurpose("IBC Sec 29A");
        testLead.setAssetName("Heavy Industrial Plant");
        testLead.setValueBracket("25CR_100CR");
        testLead.setUrgencySla("24 Hours Express");
        testLead.setContactName("Vikram Singhania");
        testLead.setContactEmail("vikram@singhaniagroup.com");
        testLead.setContactPhone("+91 98210 11223");
        testLead.setConsentGiven(true);
        testLead = leadRepository.save(testLead);
    }

    @Test
    @DisplayName("P0-1 & P1-4: Anonymous user can successfully submit a lead with DPDP consent")
    public void testAnonymousLeadCreationSuccess() throws Exception {
        SecurityContextHolder.clearContext();

        LeadRequestDto dto = new LeadRequestDto();
        dto.setServiceVertical("SHARE_VALUATION");
        dto.setMandatePurpose("Rule 11UA");
        dto.setAssetName("Alpha Fintech Pvt Ltd");
        dto.setValueBracket("5CR_25CR");
        dto.setUrgencySla("STANDARD_3D");
        dto.setContactName("Sunita Rao");
        dto.setContactEmail("sunita.cfo@alphatech.com");
        dto.setContactPhone("+91 98450 99887");
        dto.setConsentGiven(true);

        mockMvc.perform(post("/api/leads")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isCreated());
    }

    @Test
    @DisplayName("P0-1 & P1-1: Anonymous user can upload valid PDF with genuine binary signature")
    public void testAnonymousUploadValidPdf() throws Exception {
        SecurityContextHolder.clearContext();

        // Valid PDF magic bytes: %PDF-1.4
        byte[] validPdfBytes = "%PDF-1.4 Sample valid PDF document header".getBytes();
        MockMultipartFile file = new MockMultipartFile(
                "files",
                "audited_balance_sheet.pdf",
                "application/pdf",
                validPdfBytes
        );

        mockMvc.perform(multipart("/api/leads/" + testLead.getId() + "/upload")
                        .file(file))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("P1-1: Upload validation blocks spoofed executable renamed as PDF")
    public void testUploadRejectsSpoofedExe() throws Exception {
        SecurityContextHolder.clearContext();

        // Windows PE executable header: MZ...
        byte[] spoofedExeBytes = new byte[]{'M', 'Z', (byte) 0x90, 0x00, 0x03, 0x00, 0x00, 0x00};
        MockMultipartFile file = new MockMultipartFile(
                "files",
                "malicious_disguised.pdf",
                "application/pdf",
                spoofedExeBytes
        );

        mockMvc.perform(multipart("/api/leads/" + testLead.getId() + "/upload")
                        .file(file))
                .andExpect(status().is4xxClientError());
    }

    @Test
    @DisplayName("P1-2: Upload validation blocks ZIP archive on public intake")
    public void testUploadRejectsZipArchive() throws Exception {
        SecurityContextHolder.clearContext();

        byte[] zipBytes = new byte[]{0x50, 0x4B, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00};
        MockMultipartFile file = new MockMultipartFile(
                "files",
                "archive.zip",
                "application/zip",
                zipBytes
        );

        mockMvc.perform(multipart("/api/leads/" + testLead.getId() + "/upload")
                        .file(file))
                .andExpect(status().is4xxClientError());
    }

    @Test
    @DisplayName("P0-1: Anonymous user CANNOT list leads (GET /api/leads returns 401/403)")
    public void testAnonymousLeadListBlocked() throws Exception {
        SecurityContextHolder.clearContext();

        mockMvc.perform(get("/api/leads"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("P0-1: Anonymous user CANNOT view lead details (GET /api/leads/{id} returns 401/403)")
    public void testAnonymousLeadDetailsBlocked() throws Exception {
        SecurityContextHolder.clearContext();

        mockMvc.perform(get("/api/leads/" + testLead.getId()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("P0-2: Non-admin client user CANNOT list or view leads")
    public void testNonAdminClientAccessForbidden() throws Exception {
        SecurityContextHolder.getContext().setAuthentication(clientAuth);

        mockMvc.perform(get("/api/leads"))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/leads/" + testLead.getId()))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("P0-2: Non-admin client user CANNOT change lead status or generate quote")
    public void testNonAdminMutationsForbidden() throws Exception {
        SecurityContextHolder.getContext().setAuthentication(clientAuth);

        LeadStatusUpdateDto statusDto = new LeadStatusUpdateDto();
        statusDto.setStatus("QUALIFIED");

        mockMvc.perform(post("/api/leads/" + testLead.getId() + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(statusDto)))
                .andExpect(status().isForbidden());

        LeadQuoteRequestDto quoteDto = new LeadQuoteRequestDto();
        quoteDto.setEstimatedFee(new BigDecimal("50000.00"));
        quoteDto.setTurnaroundDays(3);

        mockMvc.perform(post("/api/leads/" + testLead.getId() + "/quote")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(quoteDto)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("P0-1 & P0-2: Super Admin has full authorized access to lead management and auditing")
    public void testAdminAccessAllowed() throws Exception {
        SecurityContextHolder.getContext().setAuthentication(adminAuth);

        // Can list leads
        mockMvc.perform(get("/api/leads"))
                .andExpect(status().isOk());

        // Can view lead details (triggers LEAD_VIEWED audit log)
        mockMvc.perform(get("/api/leads/" + testLead.getId()))
                .andExpect(status().isOk());

        // Can update status
        LeadStatusUpdateDto statusDto = new LeadStatusUpdateDto();
        statusDto.setStatus("QUALIFIED");
        mockMvc.perform(post("/api/leads/" + testLead.getId() + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(statusDto)))
                .andExpect(status().isOk());

        // Can issue quotation
        LeadQuoteRequestDto quoteDto = new LeadQuoteRequestDto();
        quoteDto.setEstimatedFee(new BigDecimal("75000.00"));
        quoteDto.setTurnaroundDays(4);
        quoteDto.setScopeOfWork("Statutory report");
        quoteDto.setTermsConditions("50% advance");

        mockMvc.perform(post("/api/leads/" + testLead.getId() + "/quote")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(quoteDto)))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("P1-3: Rate limiting blocks 11th request within 15 minutes window (HTTP 429)")
    public void testRateLimitingEnforcement() throws Exception {
        SecurityContextHolder.clearContext();

        LeadRequestDto dto = new LeadRequestDto();
        dto.setServiceVertical("PROPERTY_VALUATION");
        dto.setMandatePurpose("Capital Gains");
        dto.setAssetName("Warehouse Complex");
        dto.setValueBracket("5CR_25CR");
        dto.setUrgencySla("STANDARD_3D");
        dto.setContactName("Test User");
        dto.setContactEmail("test@testcorp.com");
        dto.setContactPhone("+91 99000 11000");
        dto.setConsentGiven(true);

        String content = objectMapper.writeValueAsString(dto);

        // Fire 10 allowed requests from same remote address
        for (int i = 0; i < 10; i++) {
            mockMvc.perform(post("/api/leads")
                            .with(request -> {
                                request.setRemoteAddr("203.0.113.42");
                                return request;
                            })
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(content))
                    .andExpect(status().isCreated());
        }

        // 11th request must receive HTTP 429 Too Many Requests
        MvcResult result = mockMvc.perform(post("/api/leads")
                        .with(request -> {
                            request.setRemoteAddr("203.0.113.42");
                            return request;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(content))
                .andExpect(status().is(429))
                .andReturn();

        assertTrue(result.getResponse().getContentAsString().contains("Rate limit exceeded"));
    }
}
