package com.provaluer.controller;

import com.provaluer.repository.WebsiteVisitRepository;
import com.provaluer.service.GeoIpService;
import com.provaluer.service.WebsiteAnalyticsService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@SpringBootTest
@ActiveProfiles("test")
public class WebsiteAnalyticsControllerTest {

    @Autowired
    private WebsiteAnalyticsService websiteAnalyticsService;

    @Autowired
    private WebsiteVisitRepository websiteVisitRepository;

    @Autowired
    private GeoIpService geoIpService;

    @BeforeEach
    void setUp() {
        websiteVisitRepository.deleteAll();
    }

    @Test
    void extractsClientIpFromXForwardedForAndXRealIpAndFallsBackToUnknown() {
        MockHttpServletRequest xffReq = new MockHttpServletRequest();
        xffReq.addHeader("X-Forwarded-For", "49.207.201.10, 10.0.0.5");
        assertEquals("49.207.201.10", geoIpService.extractClientIp(xffReq));

        MockHttpServletRequest realIpReq = new MockHttpServletRequest();
        realIpReq.addHeader("X-Real-IP", "103.21.124.5");
        assertEquals("103.21.124.5", geoIpService.extractClientIp(realIpReq));

        GeoIpService.GeoLocation loopback = geoIpService.lookup("127.0.0.1");
        assertEquals(GeoIpService.GeoLocation.UNKNOWN, loopback);
    }

    @Test
    void startupAndVisitRecordingSucceedWhenMmdbIsMissing() {
        assertFalse(geoIpService.isDatabaseLoaded());

        MockHttpServletRequest req = new MockHttpServletRequest();
        req.addHeader("X-Forwarded-For", "49.207.201.10");
        req.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Firefox/130.0");

        var saved = websiteAnalyticsService.recordVisit(Map.of("pagePath", "/"), req);
        assertEquals("Unknown", saved.getCountry());
        assertEquals("Unknown", saved.getState());
        assertEquals("Unknown", saved.getCity());
        assertEquals("Desktop", saved.getDevice());
        assertEquals("Firefox", saved.getBrowser());
    }

    @Test
    void resolvesLocationFromGeoIpServiceWhenCdnHeadersAbsent() {
        GeoIpService mockGeoIp = mock(GeoIpService.class);
        MockHttpServletRequest req = new MockHttpServletRequest();
        req.addHeader("X-Forwarded-For", "49.207.201.10");
        req.addHeader("User-Agent", "Mozilla/5.0 (Linux; Android 14) Chrome/128.0.0.0 Mobile Safari/537.36");

        when(mockGeoIp.extractClientIp(req)).thenReturn("49.207.201.10");
        when(mockGeoIp.lookup("49.207.201.10"))
                .thenReturn(new GeoIpService.GeoLocation("India", "Telangana", "Hyderabad"));

        WebsiteAnalyticsService svc = new WebsiteAnalyticsService(websiteVisitRepository, mockGeoIp);
        var saved = svc.recordVisit(Map.of("pagePath", "/services/bank-collateral-valuation"), req);

        assertEquals("India", saved.getCountry());
        assertEquals("Telangana", saved.getState());
        assertEquals("Hyderabad", saved.getCity());
        assertEquals("Mobile", saved.getDevice());
        assertEquals("Chrome", saved.getBrowser());
    }

    @Test
    @SuppressWarnings("unchecked")
    void recordsVisitAndComputesSummaryMetrics() {
        MockHttpServletRequest req1 = new MockHttpServletRequest();
        req1.addHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0 Safari/537.36");
        req1.addHeader("CF-IPCountry", "India");
        req1.addHeader("CF-Region", "Telangana");
        req1.addHeader("CF-IPCity", "Hyderabad");
        req1.addHeader("Referer", "https://www.google.com/");

        websiteAnalyticsService.recordVisit(Map.of("pagePath", "/services/property-valuation"), req1);

        MockHttpServletRequest req2 = new MockHttpServletRequest();
        req2.addHeader("User-Agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Mobile Safari/604.1");
        req2.addHeader("CF-IPCountry", "India");
        req2.addHeader("CF-Region", "Maharashtra");
        req2.addHeader("CF-IPCity", "Mumbai");

        websiteAnalyticsService.recordVisit(Map.of("pagePath", "/"), req2);

        Map<String, Object> summary = websiteAnalyticsService.getSummary();

        assertEquals(2L, summary.get("totalVisits"));
        assertEquals(2L, summary.get("todayVisits"));
        assertEquals(2L, summary.get("last7DaysVisits"));
        assertEquals(2L, summary.get("last30DaysVisits"));

        List<Map<String, Object>> topPages = (List<Map<String, Object>>) summary.get("topPages");
        assertEquals(2, topPages.size());

        List<Map<String, Object>> topReferrers = (List<Map<String, Object>>) summary.get("topReferrers");
        assertEquals(2, topReferrers.size());

        List<Map<String, Object>> locations = (List<Map<String, Object>>) summary.get("locations");
        assertEquals(2, locations.size());

        List<Map<String, Object>> recentVisitors = (List<Map<String, Object>>) summary.get("recentVisitors");
        assertEquals(2, recentVisitors.size());
        assertEquals("Mobile", recentVisitors.get(0).get("device"));
        assertEquals("Safari", recentVisitors.get(0).get("browser"));
        assertEquals("Desktop", recentVisitors.get(1).get("device"));
        assertEquals("Chrome", recentVisitors.get(1).get("browser"));
        assertEquals("https://www.google.com/", recentVisitors.get(1).get("referrer"));
    }
}

