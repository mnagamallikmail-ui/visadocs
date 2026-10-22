package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.model.ConsentLedger;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.ConsentLedgerRepository;
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
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class DpdpConsentBatch1Test {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ConsentLedgerRepository consentLedgerRepository;

    @Autowired
    private UserRepository userRepository;

    private User testClient;

    @BeforeEach
    void setUp() {
        consentLedgerRepository.deleteAll();
        testClient = userRepository.findByUsernameIgnoreCase("dpdp_test_client").orElseGet(() -> {
            User u = new User();
            u.setUsername("dpdp_test_client");
            u.setEmail("dpdp_test_client@provaluer.in");
            u.setPassword("Password123!");
            u.setRole(UserRole.CLIENT);
            u.setFullName("DPDP Audit Client");
            u.setMobileNumber("+919876543210");
            u.setAcceptedTcVersion("v2.4");
            return userRepository.save(u);
        });
    }

    @Test
    @DisplayName("DPDP Batch 1: Governance endpoint returns statutory notice version and DPO contact details")
    void testGetGovernanceMetadata() throws Exception {
        mockMvc.perform(get("/api/v1/privacy/governance"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.statutoryAct").value("Digital Personal Data Protection Act, 2023 (India)"))
                .andExpect(jsonPath("$.dpoName").exists())
                .andExpect(jsonPath("$.dpoEmail").value("dpo@provaluer.com"))
                .andExpect(jsonPath("$.noticeVersion").value("DPDP-NOTICE-V1.0"))
                .andExpect(jsonPath("$.termsVersion").value("v2.4"));
    }

    @Test
    @DisplayName("DPDP Batch 1: Record consent saves IP, User-Agent, notice version and terms in consent_ledger")
    void testRecordConsent() throws Exception {
        Map<String, Object> payload = Map.of(
                "actorIdentifier", testClient.getEmail(),
                "consentType", "VALUATION_PROCESSING",
                "consentGiven", true,
                "noticeVersion", "DPDP-NOTICE-V1.0",
                "termsVersion", "v2.4"
        );

        mockMvc.perform(post("/api/v1/privacy/consent")
                        .with(authentication(new UsernamePasswordAuthenticationToken(
                                UserDetailsImpl.build(testClient), null, UserDetailsImpl.build(testClient).getAuthorities())))
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("User-Agent", "Mozilla/5.0 DPDP-Audit-Agent/1.0")
                        .header("X-Forwarded-For", "203.0.113.195")
                        .content(objectMapper.writeValueAsString(payload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("RECORDED"))
                .andExpect(jsonPath("$.consentType").value("VALUATION_PROCESSING"))
                .andExpect(jsonPath("$.consentGiven").value(true));

        List<ConsentLedger> ledger = consentLedgerRepository.findByUserIdOrderByCreatedAtDesc(testClient.getId());
        assertFalse(ledger.isEmpty(), "Consent ledger must persist entry");
        ConsentLedger record = ledger.get(0);
        assertEquals("203.0.113.195", record.getIpAddress());
        assertEquals("Mozilla/5.0 DPDP-Audit-Agent/1.0", record.getUserAgent());
        assertEquals("DPDP-NOTICE-V1.0", record.getNoticeVersion());
        assertEquals("v2.4", record.getTermsVersion());
        assertFalse(record.isWithdrawn());

        // Also check User entity is synchronized
        User reloaded = userRepository.findById(testClient.getId()).orElseThrow();
        assertTrue(reloaded.isDpdpConsentGiven());
        assertEquals("DPDP-NOTICE-V1.0", reloaded.getDpdpConsentVersion());
        assertNotNull(reloaded.getDpdpConsentTimestamp());
    }

    @Test
    @DisplayName("DPDP Batch 1: Withdraw consent workflow marks ledger record withdrawn and updates user state")
    void testWithdrawConsentWorkflow() throws Exception {
        // First grant consent
        ConsentLedger initial = new ConsentLedger(
                testClient.getId(),
                null,
                testClient.getEmail(),
                "VALUATION_PROCESSING",
                true,
                "DPDP-NOTICE-V1.0",
                "v2.4",
                "127.0.0.1",
                "MockBrowser"
        );
        consentLedgerRepository.save(initial);
        testClient.setDpdpConsentGiven(true);
        userRepository.save(testClient);

        // Withdraw consent
        Map<String, Object> withdrawPayload = Map.of(
                "actorIdentifier", testClient.getEmail(),
                "consentType", "VALUATION_PROCESSING",
                "reason", "Client requested deletion under DPDP Sec 6(4)"
        );

        mockMvc.perform(post("/api/v1/privacy/consent/withdraw")
                        .with(authentication(new UsernamePasswordAuthenticationToken(
                                UserDetailsImpl.build(testClient), null, UserDetailsImpl.build(testClient).getAuthorities())))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(withdrawPayload)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("WITHDRAWN"));

        List<ConsentLedger> ledger = consentLedgerRepository.findByUserIdOrderByCreatedAtDesc(testClient.getId());
        assertEquals(1, ledger.size());
        assertTrue(ledger.get(0).isWithdrawn(), "Ledger record must be marked withdrawn");
        assertNotNull(ledger.get(0).getWithdrawnAt());
        assertEquals("Client requested deletion under DPDP Sec 6(4)", ledger.get(0).getWithdrawalReason());

        User reloaded = userRepository.findById(testClient.getId()).orElseThrow();
        assertFalse(reloaded.isDpdpConsentGiven(), "User DPDP consent flag must be revoked upon withdrawal");
    }
}
