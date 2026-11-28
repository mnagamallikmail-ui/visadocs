package com.provaluer.service;

import com.provaluer.model.WebsiteVisit;
import com.provaluer.repository.WebsiteVisitRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Lightweight first-party Website Analytics service.
 * Tracks page path, geo headers (country/state/city), device, browser, referrer, and timestamp.
 */
@Service
public class WebsiteAnalyticsService {

    private final WebsiteVisitRepository visitRepository;
    private final GeoIpService geoIpService;

    public WebsiteAnalyticsService(WebsiteVisitRepository visitRepository, GeoIpService geoIpService) {
        this.visitRepository = visitRepository;
        this.geoIpService = geoIpService;
    }

    public WebsiteVisit recordVisit(Map<String, Object> payload, HttpServletRequest request) {
        WebsiteVisit visit = new WebsiteVisit();

        String pagePath = str(payload != null ? payload.get("pagePath") : null);
        if (pagePath.isEmpty()) pagePath = "/";
        visit.setPagePath(truncate(pagePath, 500));

        String referrer = str(payload != null ? payload.get("referrer") : null);
        if (referrer.isEmpty() && request != null) {
            referrer = str(request.getHeader("Referer"));
        }
        visit.setReferrer(referrer.isEmpty() ? null : truncate(referrer, 500));

        String country = firstNonEmpty(
                str(payload != null ? payload.get("country") : null),
                header(request, "CF-IPCountry"),
                header(request, "X-Vercel-IP-Country"),
                header(request, "CloudFront-Viewer-Country"),
                header(request, "X-Country-Code")
        );
        String state = firstNonEmpty(
                str(payload != null ? payload.get("state") : null),
                header(request, "CF-Region"),
                header(request, "X-Vercel-IP-Country-Region"),
                header(request, "CloudFront-Viewer-Country-Region-Name"),
                header(request, "X-Region")
        );
        String city = firstNonEmpty(
                str(payload != null ? payload.get("city") : null),
                header(request, "CF-IPCity"),
                header(request, "X-Vercel-IP-City"),
                header(request, "CloudFront-Viewer-City"),
                header(request, "X-City")
        );

        if (country.isEmpty() || state.isEmpty() || city.isEmpty()) {
            String clientIp = geoIpService.extractClientIp(request);
            GeoIpService.GeoLocation geo = geoIpService.lookup(clientIp);
            if (country.isEmpty()) country = geo.country();
            if (state.isEmpty()) state = geo.state();
            if (city.isEmpty()) city = geo.city();
        }

        visit.setCountry(country.isEmpty() ? "Unknown" : truncate(country, 100));
        visit.setState(state.isEmpty() ? "Unknown" : truncate(state, 100));
        visit.setCity(city.isEmpty() ? "Unknown" : truncate(city, 100));

        String userAgent = request != null ? str(request.getHeader("User-Agent")) : "";
        String device = str(payload != null ? payload.get("device") : null);
        visit.setDevice(device.isEmpty() ? detectDevice(userAgent) : truncate(device, 50));

        String browser = str(payload != null ? payload.get("browser") : null);
        visit.setBrowser(browser.isEmpty() ? detectBrowser(userAgent) : truncate(browser, 100));

        visit.setVisitedAt(LocalDateTime.now());
        return visitRepository.save(visit);
    }

    public Map<String, Object> getSummary() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime startOfToday = LocalDate.now().atStartOfDay();
        LocalDateTime last7Days = now.minusDays(7);
        LocalDateTime last30Days = now.minusDays(30);

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("totalVisits", visitRepository.count());
        summary.put("todayVisits", visitRepository.countByVisitedAtAfter(startOfToday));
        summary.put("last7DaysVisits", visitRepository.countByVisitedAtAfter(last7Days));
        summary.put("last30DaysVisits", visitRepository.countByVisitedAtAfter(last30Days));

        List<Map<String, Object>> topPages = new ArrayList<>();
        for (Object[] row : visitRepository.findTopPages(PageRequest.of(0, 15))) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("pagePath", row[0]);
            item.put("visits", ((Number) row[1]).longValue());
            topPages.add(item);
        }
        summary.put("topPages", topPages);

        List<Map<String, Object>> topReferrers = new ArrayList<>();
        for (Object[] row : visitRepository.findTopReferrers(PageRequest.of(0, 15))) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("referrer", row[0]);
            item.put("visits", ((Number) row[1]).longValue());
            topReferrers.add(item);
        }
        summary.put("topReferrers", topReferrers);

        List<Map<String, Object>> locations = new ArrayList<>();
        for (Object[] row : visitRepository.findVisitorLocations(PageRequest.of(0, 25))) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("country", row[0]);
            item.put("state", row[1]);
            item.put("city", row[2]);
            item.put("visits", ((Number) row[3]).longValue());
            locations.add(item);
        }
        summary.put("locations", locations);

        List<Map<String, Object>> recentVisitors = new ArrayList<>();
        for (WebsiteVisit v : visitRepository.findTop50ByOrderByVisitedAtDesc()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("visitedAt", v.getVisitedAt() != null ? v.getVisitedAt().toString() : "");
            item.put("pagePath", v.getPagePath());
            item.put("country", v.getCountry());
            item.put("state", v.getState());
            item.put("city", v.getCity());
            item.put("device", v.getDevice());
            item.put("browser", v.getBrowser());
            item.put("referrer", v.getReferrer() != null ? v.getReferrer() : "Direct");
            recentVisitors.add(item);
        }
        summary.put("recentVisitors", recentVisitors);

        return summary;
    }

    static String detectDevice(String ua) {
        if (ua == null || ua.isEmpty()) return "Desktop";
        String lower = ua.toLowerCase();
        if (lower.contains("bot") || lower.contains("crawler") || lower.contains("spider")) return "Bot";
        if (lower.contains("ipad") || lower.contains("tablet")) return "Tablet";
        if (lower.contains("mobile") || lower.contains("android") || lower.contains("iphone")) return "Mobile";
        return "Desktop";
    }

    static String detectBrowser(String ua) {
        if (ua == null || ua.isEmpty()) return "Unknown";
        String lower = ua.toLowerCase();
        if (lower.contains("edg/")) return "Edge";
        if (lower.contains("opr/") || lower.contains("opera")) return "Opera";
        if (lower.contains("chrome/") && !lower.contains("chromium")) return "Chrome";
        if (lower.contains("safari/") && !lower.contains("chrome")) return "Safari";
        if (lower.contains("firefox/")) return "Firefox";
        return "Other";
    }

    private static String header(HttpServletRequest req, String name) {
        return req != null ? str(req.getHeader(name)) : "";
    }

    private static String firstNonEmpty(String... values) {
        for (String v : values) {
            if (v != null && !v.isBlank()) return v.trim();
        }
        return "";
    }

    private static String str(Object val) {
        return val != null ? val.toString().trim() : "";
    }

    private static String truncate(String val, int maxLen) {
        return val.length() <= maxLen ? val : val.substring(0, maxLen);
    }
}

