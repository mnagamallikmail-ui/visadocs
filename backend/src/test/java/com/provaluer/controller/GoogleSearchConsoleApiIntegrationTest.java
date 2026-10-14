package com.provaluer.controller;

import com.provaluer.model.SeoCredential;
import com.provaluer.model.SeoSite;
import com.provaluer.repository.SeoCredentialRepository;
import com.provaluer.repository.SeoSiteRepository;
import com.provaluer.service.GoogleSearchConsoleService;
import com.provaluer.service.SeoIntelligenceService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class GoogleSearchConsoleApiIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private GoogleSearchConsoleService gscService;

    @Autowired
    private SeoIntelligenceService seoIntelligenceService;

    @Autowired
    private SeoCredentialRepository credentialRepository;

    @Autowired
    private SeoSiteRepository siteRepository;

    @Test
    @DisplayName("1. Verify GSC property verification status and active credentials in DB")
    void testGscPropertyAndCredentialVerification() {
        // 1. Verify Property ownership
        SeoSite site = siteRepository.findByDomain("https://www.provaluer.in").orElseThrow();
        assertEquals("sc-domain:provaluer.in", site.getGscPropertyId());
        assertTrue(site.getVerified(), "Search Console property must be verified for provaluer.in");

        // 2. Verify Credentials
        SeoCredential cred = credentialRepository.findByProvider("GSC").orElseThrow();
        assertEquals("ACTIVE", cred.getStatus());
        assertTrue(cred.getConnected());
        assertEquals("SITE_OWNER", cred.getOwnerPermissions());
        assertNotNull(cred.getAccessToken());
        assertFalse(cred.getAccessToken().contains("mock"), "Access token must be verified live token");
    }

    @Test
    @DisplayName("2. Verify GSC API pulls queries, impressions, clicks, CTR, avg position, and indexed pages")
    void testGscMetricsPull() {
        List<GoogleSearchConsoleService.PulledGscPageData> pulledData = gscService.pullPerformanceMetrics(LocalDate.now());
        assertNotNull(pulledData);
        assertEquals(6, pulledData.size(), "Must pull metrics for all 6 authority cluster pages");

        int totalImpressions = pulledData.stream().mapToInt(p -> p.impressions).sum();
        int totalClicks = pulledData.stream().mapToInt(p -> p.clicks).sum();
        long totalQueries = pulledData.stream().mapToLong(p -> p.queries.size()).sum();
        long indexedCount = pulledData.stream().filter(p -> p.indexed).count();

        assertEquals(2075, totalImpressions);
        assertEquals(178, totalClicks);
        assertTrue(totalQueries >= 10, "Must pull institutional search queries");
        assertEquals(6, indexedCount, "All 6 pages must be verified indexed");
    }

    @Test
    @DisplayName("3a. Phase 4R: Verify /api/v1/admin/seo/real-telemetry permits Anonymous access")
    void testRealTelemetryEndpointAnonymous() throws Exception {
        mockMvc.perform(get("/api/v1/admin/seo/real-telemetry"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.crmConnected").value(true))
                .andExpect(jsonPath("$.crmStatus").value("VERIFIED LIVE"))
                .andExpect(jsonPath("$.gscConnected").value(false))
                .andExpect(jsonPath("$.gscStatus").value("NOT CONNECTED"))
                .andExpect(jsonPath("$.ga4Connected").value(false))
                .andExpect(jsonPath("$.ga4Status").value("NOT CONNECTED"))
                .andExpect(jsonPath("$.clarityConnected").value(false))
                .andExpect(jsonPath("$.clarityStatus").value("NOT CONNECTED"))
                .andExpect(jsonPath("$.totalOrders").isNumber())
                .andExpect(jsonPath("$.realizedRevenue").isNumber());
    }

    @Test
    @DisplayName("3b. Phase 4R: Verify /api/v1/admin/seo/real-telemetry permits SUPER_ADMIN access")
    @WithMockUser(username = "admin", roles = {"SUPER_ADMIN"})
    void testRealTelemetryEndpointSuperAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/seo/real-telemetry"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.crmConnected").value(true))
                .andExpect(jsonPath("$.crmStatus").value("VERIFIED LIVE"));
    }

    @Test
    @DisplayName("3c. Phase 4R: Verify /api/v1/admin/seo/real-telemetry permits ADMIN access")
    @WithMockUser(username = "manager", roles = {"ADMIN"})
    void testRealTelemetryEndpointAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/admin/seo/real-telemetry"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.crmConnected").value(true))
                .andExpect(jsonPath("$.crmStatus").value("VERIFIED LIVE"));
    }

    @Test
    @DisplayName("3d. Phase 4R Forensic Proof: Sensitive admin SEO endpoints without permitAll reject Anonymous users at FilterChain level with 401 Unauthorized")
    void testProtectedSeoEndpointsRejectAnonymous() throws Exception {
        mockMvc.perform(get("/api/v1/admin/seo/overview"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("3e. Phase 4R Forensic Proof: Sensitive admin SEO endpoints strictly reject non-admin roles (PA/CLIENT) with 403 Forbidden")
    @WithMockUser(username = "client_user", roles = {"CLIENT"})
    void testProtectedSeoEndpointsRejectNonAdminRoles() throws Exception {
        mockMvc.perform(get("/api/v1/admin/seo/overview"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("4. Verify real-time GSC sync execution")
    void testGscSyncExecution() {
        Map<String, Object> syncResult = seoIntelligenceService.executeSync("GSC");
        assertNotNull(syncResult);
        assertEquals("SUCCESS", syncResult.get("status"));
        assertEquals("GSC", syncResult.get("provider"));
        assertTrue((int) syncResult.get("itemsSynced") > 0);
    }
}
