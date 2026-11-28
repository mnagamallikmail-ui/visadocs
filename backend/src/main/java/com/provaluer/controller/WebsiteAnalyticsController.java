package com.provaluer.controller;

import com.provaluer.service.WebsiteAnalyticsService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@CrossOrigin(origins = "*", maxAge = 3600)
public class WebsiteAnalyticsController {

    private final WebsiteAnalyticsService websiteAnalyticsService;

    public WebsiteAnalyticsController(WebsiteAnalyticsService websiteAnalyticsService) {
        this.websiteAnalyticsService = websiteAnalyticsService;
    }

    /**
     * Public fire-and-forget visit beacon for landing and SEO pages.
     */
    @PostMapping("/api/v1/analytics/visit")
    public ResponseEntity<Map<String, Object>> recordVisit(
            @RequestBody(required = false) Map<String, Object> payload,
            HttpServletRequest request) {
        websiteAnalyticsService.recordVisit(payload, request);
        return ResponseEntity.accepted().body(Map.of("status", "recorded"));
    }

    /**
     * Admin Website Analytics summary endpoint.
     */
    @GetMapping("/api/v1/admin/analytics/summary")
    @PreAuthorize("hasAnyRole('ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<Map<String, Object>> getSummary() {
        return ResponseEntity.ok(websiteAnalyticsService.getSummary());
    }
}

