package com.provaluer.service;

import com.provaluer.dto.SeoOverviewResponse;
import com.provaluer.model.SeoCredential;
import com.provaluer.repository.SeoCredentialRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class SeoIntelligencePlatformTest {

    @Autowired
    private SeoIntelligenceService seoIntelligenceService;

    @Autowired
    private BingWebmasterService bingService;

    @Autowired
    private SeoCredentialRepository credentialRepository;

    @Test
    public void testGetOverviewStructure() {
        SeoOverviewResponse overview = seoIntelligenceService.getOverview();
        assertNotNull(overview);
        assertNotNull(overview.getPages());
        assertNotNull(overview.getQueries());
        assertNotNull(overview.getDailyTrends());
        assertNotNull(overview.getSyncLogs());
    }

    @Test
    public void testExecuteSyncAll() {
        Map<String, Object> result = seoIntelligenceService.executeSync("ALL");
        assertNotNull(result);
        assertEquals("SUCCESS", result.get("status"));
        assertEquals("ALL", result.get("provider"));
        assertTrue(result.containsKey("itemsSynced"));
        assertTrue(result.containsKey("durationMs"));
    }

    @Test
    public void testUpdateSyncFrequency() {
        seoIntelligenceService.updateSyncFrequency("WEEKLY");
        SeoCredential cred = credentialRepository.findByProvider("GSC").orElse(null);
        if (cred != null) {
            assertEquals("WEEKLY", cred.getSyncFrequency());
        }
    }

    @Test
    public void testBingSitemapsAndCrawlErrors() {
        var sitemaps = bingService.pullSitemapStatus();
        assertNotNull(sitemaps);
        assertFalse(sitemaps.isEmpty());

        var crawlErrors = bingService.pullCrawlErrors();
        assertNotNull(crawlErrors);
    }
}

