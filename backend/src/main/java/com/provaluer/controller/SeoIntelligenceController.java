package com.provaluer.controller;

import com.provaluer.dto.SeoOverviewResponse;
import com.provaluer.dto.SeoSyncRequest;
import com.provaluer.dto.SeoConnectRequest;
import com.provaluer.dto.SeoConfigUpdateRequest;
import com.provaluer.model.SeoCrawlError;
import com.provaluer.service.BingWebmasterService;
import com.provaluer.service.GoogleSearchConsoleService;
import com.provaluer.service.SeoIntelligenceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin/seo")
@PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
public class SeoIntelligenceController {

    @Autowired
    private SeoIntelligenceService seoIntelligenceService;

    @Autowired
    private GoogleSearchConsoleService gscService;

    @Autowired
    private BingWebmasterService bingService;

    /**
     * Get complete SEO Intelligence dashboard overview
     */
    @GetMapping("/overview")
    public ResponseEntity<SeoOverviewResponse> getOverview() {
        return ResponseEntity.ok(seoIntelligenceService.getOverview());
    }

    /**
     * Trigger real-time synchronization
     */
    @PostMapping("/sync")
    public ResponseEntity<Map<String, Object>> triggerSync(@RequestBody(required = false) SeoSyncRequest request) {
        String provider = request != null && request.getProvider() != null ? request.getProvider() : "ALL";
        Map<String, Object> result = seoIntelligenceService.executeSync(provider);
        return ResponseEntity.ok(result);
    }

    /**
     * Connect search provider account
     */
    @PostMapping("/connect")
    public ResponseEntity<Map<String, Object>> connectProvider(@RequestBody SeoConnectRequest request) {
        if ("GSC".equalsIgnoreCase(request.getProvider())) {
            gscService.connectGoogleAccount(request.getPropertyId(), request.getAuthCode(), request.getOwnerPermissions());
        } else if ("BING".equalsIgnoreCase(request.getProvider())) {
            bingService.connectBingAccount(request.getPropertyId(), request.getApiKey());
        } else {
            return ResponseEntity.badRequest().body(Map.of("error", "Unknown provider: " + request.getProvider()));
        }

        return ResponseEntity.ok(Map.of(
                "status", "CONNECTED",
                "provider", request.getProvider().toUpperCase()
        ));
    }

    /**
     * Disconnect search provider account
     */
    @PostMapping("/disconnect/{provider}")
    public ResponseEntity<Map<String, Object>> disconnectProvider(@PathVariable String provider) {
        if ("GSC".equalsIgnoreCase(provider)) {
            gscService.disconnectGoogleAccount();
        } else if ("BING".equalsIgnoreCase(provider)) {
            bingService.disconnectBingAccount();
        } else {
            return ResponseEntity.badRequest().body(Map.of("error", "Unknown provider: " + provider));
        }

        return ResponseEntity.ok(Map.of(
                "status", "DISCONNECTED",
                "provider", provider.toUpperCase()
        ));
    }

    /**
     * Update synchronization frequency
     */
    @PostMapping("/frequency")
    public ResponseEntity<Map<String, Object>> updateFrequency(@RequestBody SeoConfigUpdateRequest request) {
        seoIntelligenceService.updateSyncFrequency(request.getSyncFrequency());
        return ResponseEntity.ok(Map.of(
                "status", "UPDATED",
                "syncFrequency", request.getSyncFrequency().toUpperCase()
        ));
    }

    /**
     * Get sitemap status across search engines
     */
    @GetMapping("/sitemaps")
    public ResponseEntity<List<BingWebmasterService.BingSitemapStatus>> getSitemapStatus() {
        return ResponseEntity.ok(bingService.pullSitemapStatus());
    }

    /**
     * Get crawl diagnostics & unresolved crawl errors
     */
    @GetMapping("/crawl-errors")
    public ResponseEntity<List<SeoCrawlError>> getCrawlErrors() {
        return ResponseEntity.ok(bingService.pullCrawlErrors());
    }
}
