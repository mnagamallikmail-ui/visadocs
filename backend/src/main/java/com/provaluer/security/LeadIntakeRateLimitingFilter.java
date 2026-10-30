package com.provaluer.security;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * P1-3 Lead Intake Rate Limiting Filter
 * Protects public lead submission endpoints against spam and DoS.
 * Limit: 10 requests per 15 minutes per client IP.
 * Scope: POST /api/leads and POST /api/leads/{id}/upload.
 */
@Component
public class LeadIntakeRateLimitingFilter implements Filter {

    public static final int MAX_REQUESTS_PER_WINDOW = 10;
    public static final long WINDOW_DURATION_MS = 15 * 60 * 1000L; // 15 minutes

    public static final int MAX_AUTH_PER_WINDOW = 5;
    public static final long WINDOW_AUTH_MS = 60 * 1000L; // 1 minute

    public static class RequestTracker {
        public int count = 0;
        public long windowStartTime = System.currentTimeMillis();

        public synchronized boolean allowRequest(long now, int maxRequests, long windowMs) {
            if (now - windowStartTime > windowMs) {
                // Window expired; reset
                windowStartTime = now;
                count = 1;
                return true;
            }
            if (count < maxRequests) {
                count++;
                return true;
            }
            return false;
        }
    }

    private final Map<String, RequestTracker> ipTracker = new ConcurrentHashMap<>();
    private final Map<String, RequestTracker> authIpTracker = new ConcurrentHashMap<>();

    @Override
    public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) servletRequest;
        HttpServletResponse response = (HttpServletResponse) servletResponse;

        String path = request.getRequestURI();
        String method = request.getMethod();

        // 1. Strict Protection for Auth and Privacy Export Routes (5 req/min)
        if (isSensitiveAuthOrExportUri(path)) {
            String clientIp = extractClientIp(request);
            long now = System.currentTimeMillis();

            RequestTracker tracker = authIpTracker.computeIfAbsent(clientIp + ":" + path, k -> new RequestTracker());
            boolean allowed = tracker.allowRequest(now, MAX_AUTH_PER_WINDOW, WINDOW_AUTH_MS);

            if (!allowed) {
                response.setStatus(429); // Too Many Requests
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                response.getWriter().write("{\"error\": \"Rate limit exceeded. Maximum 5 attempts per minute permitted for security endpoints.\", \"status\": 429}");
                return;
            }
        }

        // 2. Lead Intake Protection (10 req/15 min)
        if ("POST".equalsIgnoreCase(method) && isLeadIntakeUri(path)) {
            String clientIp = extractClientIp(request);
            long now = System.currentTimeMillis();

            RequestTracker tracker = ipTracker.computeIfAbsent(clientIp, k -> new RequestTracker());
            boolean allowed = tracker.allowRequest(now, MAX_REQUESTS_PER_WINDOW, WINDOW_DURATION_MS);

            if (!allowed) {
                response.setStatus(429); // Too Many Requests
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                response.getWriter().write("{\"error\": \"Rate limit exceeded. Maximum 10 intake requests per 15 minutes allowed.\", \"status\": 429}");
                return;
            }
        }

        filterChain.doFilter(servletRequest, servletResponse);
    }

    private boolean isSensitiveAuthOrExportUri(String path) {
        if (path == null) return false;
        return path.endsWith("/api/v1/auth/login") || path.endsWith("/api/v1/auth/register")
                || path.endsWith("/api/v1/auth/password/reset") || path.endsWith("/api/v1/privacy/export");
    }

    private boolean isLeadIntakeUri(String path) {
        if (path == null) return false;
        // Matches /api/leads or /api/v1/leads and their /upload endpoints
        return path.equals("/api/leads") || path.equals("/api/leads/") || path.matches("^/api/leads/\\d+/upload/?$")
                || path.equals("/api/v1/leads") || path.equals("/api/v1/leads/") || path.matches("^/api/v1/leads/\\d+/upload/?$");
    }

    private String extractClientIp(HttpServletRequest request) {
        String xfHeader = request.getHeader("X-Forwarded-For");
        if (xfHeader != null && !xfHeader.trim().isEmpty()) {
            return xfHeader.split(",")[0].trim();
        }
        return request.getRemoteAddr() != null ? request.getRemoteAddr() : "UNKNOWN";
    }

    public void resetTracker() {
        ipTracker.clear();
    }
}
