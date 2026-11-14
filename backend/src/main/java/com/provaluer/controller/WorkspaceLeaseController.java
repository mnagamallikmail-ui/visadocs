package com.provaluer.controller;

import com.provaluer.model.Order;
import com.provaluer.model.User;
import com.provaluer.model.WorkspaceSyncEvent;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.repository.WorkspaceSyncEventRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.WorkspaceLeaseService;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/v1/orders")
public class WorkspaceLeaseController {

    private static final Logger log = LoggerFactory.getLogger(WorkspaceLeaseController.class);

    private final WorkspaceLeaseService workspaceLeaseService;
    private final WorkspaceSyncEventRepository syncEventRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    public WorkspaceLeaseController(WorkspaceLeaseService workspaceLeaseService,
                                    WorkspaceSyncEventRepository syncEventRepository,
                                    OrderRepository orderRepository,
                                    UserRepository userRepository) {
        this.workspaceLeaseService = workspaceLeaseService;
        this.syncEventRepository = syncEventRepository;
        this.orderRepository = orderRepository;
        this.userRepository = userRepository;
    }

    private String getClientIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.isBlank()) {
            return xf.split(",")[0].trim();
        }
        return request.getRemoteAddr() != null ? request.getRemoteAddr() : "127.0.0.1";
    }

    /**
     * POST /api/v1/orders/{id}/acquire-lock
     * Pessimistic lease acquisition or read-only status return.
     */
    @PostMapping("/{id}/acquire-lock")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> acquireLock(
            @PathVariable Long id,
            @RequestHeader(value = "X-Session-ID", required = false) String sessionId,
            @RequestBody(required = false) Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal,
            HttpServletRequest request) {

        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        String actualSessionId = sessionId != null ? sessionId : (body != null ? body.get("sessionId") : "sess_" + principal.getId());
        String tabSessionId = body != null && body.containsKey("tabSessionId") ? body.get("tabSessionId") : "tab_default";
        String machineName = body != null && body.containsKey("machineName") ? body.get("machineName") : "Desktop Browser";
        String platformInfo = body != null && body.containsKey("platformInfo") ? body.get("platformInfo") : "Web";
        String ipAddress = getClientIp(request);

        try {
            Map<String, Object> result = workspaceLeaseService.acquireLock(
                    id,
                    principal.getId(),
                    actualSessionId,
                    tabSessionId,
                    machineName,
                    platformInfo,
                    ipAddress
            );
            return ResponseEntity.ok(result);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("[WorkspaceLeaseController] Error acquiring lock on order {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/heartbeat
     * Isolated non-entity heartbeat. Never touches Order entity or version.
     */
    @PostMapping("/{id}/heartbeat")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> heartbeat(
            @PathVariable Long id,
            @RequestHeader(value = "X-Session-ID", required = false) String sessionId,
            @RequestBody(required = false) Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {

        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        String actualSessionId = sessionId != null ? sessionId : (body != null ? body.get("sessionId") : "sess_" + principal.getId());

        try {
            Map<String, Object> result = workspaceLeaseService.renewHeartbeat(id, actualSessionId);
            String status = (String) result.get("status");

            if ("ACTIVE".equals(status)) {
                return ResponseEntity.ok(result);
            } else if ("LEASE_LOST".equals(status)) {
                return ResponseEntity.status(HttpStatus.LOCKED).body(result);
            } else {
                return ResponseEntity.status(HttpStatus.GONE).body(result);
            }
        } catch (Exception e) {
            log.error("[WorkspaceLeaseController] Error renewing heartbeat on order {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/switch-tab
     * Same-user multi-tab transfer.
     */
    @PostMapping("/{id}/switch-tab")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> switchTab(
            @PathVariable Long id,
            @RequestHeader(value = "X-Session-ID", required = false) String sessionId,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {

        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        String newTabSessionId = body != null ? body.get("newTabSessionId") : null;
        if (newTabSessionId == null || newTabSessionId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "newTabSessionId is required"));
        }

        String actualSessionId = sessionId != null ? sessionId : (body != null && body.containsKey("sessionId") ? body.get("sessionId") : "sess_" + principal.getId());

        try {
            Map<String, Object> result = workspaceLeaseService.switchTab(id, principal.getId(), actualSessionId, newTabSessionId);
            return ResponseEntity.ok(result);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/takeover-lock
     * Privileged Admin / SPA break-glass takeover with pre-flight autosave push.
     */
    @PostMapping("/{id}/takeover-lock")
    @PreAuthorize("hasAnyRole('SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> takeoverLock(
            @PathVariable Long id,
            @RequestHeader(value = "X-Session-ID", required = false) String sessionId,
            @RequestBody(required = false) Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal,
            HttpServletRequest request) {

        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        String actualSessionId = sessionId != null ? sessionId : (body != null ? body.get("sessionId") : "sess_" + principal.getId());
        String tabSessionId = body != null && body.containsKey("tabSessionId") ? body.get("tabSessionId") : "tab_admin";
        String machineName = body != null && body.containsKey("machineName") ? body.get("machineName") : "Admin Console";
        String platformInfo = body != null && body.containsKey("platformInfo") ? body.get("platformInfo") : "Web";
        String ipAddress = getClientIp(request);

        try {
            Map<String, Object> result = workspaceLeaseService.takeoverLease(
                    id,
                    principal.getId(),
                    actualSessionId,
                    tabSessionId,
                    machineName,
                    platformInfo,
                    ipAddress
            );
            return ResponseEntity.ok(result);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", e.getMessage()));
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("[WorkspaceLeaseController] Error taking over lock on order {}: {}", id, e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * POST /api/v1/orders/{id}/release-lock
     * Clean release of workspace lock on exit or tab close.
     */
    @PostMapping("/{id}/release-lock")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> releaseLock(
            @PathVariable Long id,
            @RequestHeader(value = "X-Session-ID", required = false) String sessionId,
            @RequestBody(required = false) Map<String, String> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {

        String actualSessionId = sessionId != null ? sessionId : (body != null ? body.get("sessionId") : null);
        if (actualSessionId != null) {
            workspaceLeaseService.releaseLock(id, actualSessionId);
        }
        return ResponseEntity.ok(Map.of("status", "RELEASED", "orderId", id));
    }

    /**
     * POST /api/v1/orders/{id}/sync-events
     * IndexedDB offline sync event recording & diagnostic audit.
     */
    @PostMapping("/{id}/sync-events")
    @PreAuthorize("hasAnyRole('PA', 'SPA', 'SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> recordSyncEvent(
            @PathVariable Long id,
            @RequestHeader(value = "X-Session-ID", required = false) String sessionId,
            @RequestBody Map<String, Object> body,
            @AuthenticationPrincipal UserDetailsImpl principal) {

        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Authentication required"));
        }

        try {
            Order order = orderRepository.findById(id)
                    .orElseThrow(() -> new NoSuchElementException("Order not found: " + id));
            User user = userRepository.findById(principal.getId()).orElse(null);

            String actualSessionId = sessionId != null ? sessionId : (body != null ? (String) body.get("sessionId") : "sess_" + principal.getId());
            String tabSessionId = body != null && body.containsKey("tabSessionId") && body.get("tabSessionId") != null ? (String) body.get("tabSessionId") : "tab_default";
            String eventType = body != null && body.containsKey("eventType") && body.get("eventType") != null ? (String) body.get("eventType") : "AUTOSAVE_FLUSH";
            String payload = body != null && body.containsKey("payload") && body.get("payload") != null ? body.get("payload").toString() : "{}";

            WorkspaceSyncEvent event = new WorkspaceSyncEvent(
                    order,
                    user,
                    actualSessionId != null ? actualSessionId : "unknown",
                    tabSessionId,
                    eventType,
                    payload
            );
            event.setSyncStatus("COMMITTED");
            event.setProcessedAt(java.time.LocalDateTime.now());
            syncEventRepository.save(event);

            return ResponseEntity.ok(Map.of("status", "COMMITTED", "eventId", event.getId()));
        } catch (Exception e) {
            log.warn("[WorkspaceLeaseController] Failed to record sync event on order {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", e.getMessage()));
        }
    }
}

