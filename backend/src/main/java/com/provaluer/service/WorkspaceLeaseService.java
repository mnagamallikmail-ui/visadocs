package com.provaluer.service;

import com.provaluer.model.Order;
import com.provaluer.model.User;
import com.provaluer.model.WorkspaceLeaseAudit;
import com.provaluer.model.WorkspaceSession;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.repository.WorkspaceLeaseAuditRepository;
import com.provaluer.repository.WorkspaceSessionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;

@Service
public class WorkspaceLeaseService {

    private static final Logger log = LoggerFactory.getLogger(WorkspaceLeaseService.class);

    private final WorkspaceSessionRepository workspaceSessionRepository;
    private final WorkspaceLeaseAuditRepository leaseAuditRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final RealtimePushService realtimePushService;

    @Value("${app.workspace.lease-ttl-seconds:300}")
    private int leaseTtlSeconds;

    @Value("${app.workspace.takeover-autosave-deadline-ms:1500}")
    private long takeoverAutosaveDeadlineMs;

    public WorkspaceLeaseService(WorkspaceSessionRepository workspaceSessionRepository,
                                 WorkspaceLeaseAuditRepository leaseAuditRepository,
                                 OrderRepository orderRepository,
                                 UserRepository userRepository,
                                 RealtimePushService realtimePushService) {
        this.workspaceSessionRepository = workspaceSessionRepository;
        this.leaseAuditRepository = leaseAuditRepository;
        this.orderRepository = orderRepository;
        this.userRepository = userRepository;
        this.realtimePushService = realtimePushService;
    }

    /**
     * Acquires workspace lease or returns read-only role with active editor details.
     */
    @Transactional
    public Map<String, Object> acquireLock(Long orderId, Long userId, String sessionId, String tabSessionId,
                                           String machineName, String platformInfo, String ipAddress) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found: " + orderId));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NoSuchElementException("User not found: " + userId));

        Optional<WorkspaceSession> existingLeaseOpt = workspaceSessionRepository.findByOrderId(orderId);

        boolean canAcquire = false;
        WorkspaceSession existingLease = null;

        if (existingLeaseOpt.isEmpty()) {
            canAcquire = true;
        } else {
            existingLease = existingLeaseOpt.get();
            boolean isInactive = !"ACTIVE".equals(existingLease.getLockStatus());
            boolean isExpired = existingLease.getLastHeartbeat().isBefore(LocalDateTime.now().minusSeconds(leaseTtlSeconds));
            boolean isSameUserSameSession = existingLease.getUser().getId().equals(userId) &&
                                            existingLease.getSessionId().equals(sessionId) &&
                                            existingLease.getTabSessionId().equals(tabSessionId);

            if (isInactive || isExpired || isSameUserSameSession) {
                canAcquire = true;
            }
        }

        if (canAcquire) {
            WorkspaceSession lease;
            if (existingLease == null) {
                lease = new WorkspaceSession(order, user, sessionId, tabSessionId, machineName, platformInfo, ipAddress);
            } else {
                lease = existingLease;
                lease.setUser(user);
                lease.setSessionId(sessionId);
                lease.setTabSessionId(tabSessionId);
                lease.setLockStatus("ACTIVE");
                lease.setAcquiredAt(LocalDateTime.now());
                lease.setLastHeartbeat(LocalDateTime.now());
                lease.setLastActivity(LocalDateTime.now());
                lease.setMachineName(machineName);
                lease.setPlatformInfo(platformInfo);
                lease.setIpAddress(ipAddress);
            }

            workspaceSessionRepository.save(lease);

            // Audit acquisition
            recordLeaseAudit(order, user, sessionId, "ACQUIRED", null, ipAddress, machineName, "Lock acquired as ACTIVE_EDITOR");

            log.info("[WorkspaceLeaseService] User {} acquired lease for order {} (Session: {}, Tab: {})",
                    user.getUsername(), orderId, sessionId, tabSessionId);

            return Map.of(
                    "role", "ACTIVE_EDITOR",
                    "orderId", orderId,
                    "sessionId", sessionId,
                    "tabSessionId", tabSessionId,
                    "leaseTtlSeconds", leaseTtlSeconds,
                    "acquiredAt", lease.getAcquiredAt().toString()
            );
        }

        // Lock is active. Check if it belongs to the SAME user but a DIFFERENT tab
        if (existingLease != null && existingLease.getUser().getId().equals(userId)) {
            log.info("[WorkspaceLeaseService] User {} opened duplicate tab for order {} (Active Tab: {}, Current Tab: {})",
                    user.getUsername(), orderId, existingLease.getTabSessionId(), tabSessionId);

            return Map.of(
                    "role", "SAME_USER_SECONDARY_TAB",
                    "orderId", orderId,
                    "activeTabSessionId", existingLease.getTabSessionId(),
                    "canSwitchTab", true,
                    "activeEditor", Map.of(
                            "fullName", existingLease.getUser().getFullName() != null ? existingLease.getUser().getFullName() : existingLease.getUser().getUsername(),
                            "startedAt", existingLease.getAcquiredAt().toString(),
                            "lastActivitySecondsAgo", ChronoUnit.SECONDS.between(existingLease.getLastActivity(), LocalDateTime.now())
                    )
            );
        }

        // Lock is held by another user -> Read-Only Viewer
        boolean canTakeOver = isPrivilegedRole(user);

        String editorUsername = existingLease != null ? existingLease.getUser().getUsername() : "another user";
        long secondsAgo = existingLease != null ? ChronoUnit.SECONDS.between(existingLease.getLastHeartbeat(), LocalDateTime.now()) : 0;
        log.info("[WorkspaceLeaseService] Order {} is locked by {} (last heartbeat {}s ago). User {} entered READ_ONLY mode.",
                orderId, editorUsername, secondsAgo, user.getUsername());

        Map<String, Object> response = new HashMap<>();
        response.put("role", "READ_ONLY_VIEWER");
        response.put("orderId", orderId);
        response.put("canTakeOver", canTakeOver);
        if (existingLease != null) {
            response.put("activeEditor", Map.of(
                    "fullName", existingLease.getUser().getFullName() != null ? existingLease.getUser().getFullName() : existingLease.getUser().getUsername(),
                    "role", existingLease.getUser().getRole() != null ? existingLease.getUser().getRole().name() : "PA",
                    "machineName", existingLease.getMachineName() != null ? existingLease.getMachineName() : "Desktop",
                    "platformInfo", existingLease.getPlatformInfo() != null ? existingLease.getPlatformInfo() : "Windows",
                    "startedAt", existingLease.getAcquiredAt().toString(),
                    "lastActivitySecondsAgo", ChronoUnit.SECONDS.between(existingLease.getLastActivity(), LocalDateTime.now())
            ));
        }

        return response;
    }

    /**
     * Isolated Non-Entity Heartbeat Renewal.
     * Updates ONLY workspace_sessions.last_heartbeat. Never touches Order or version.
     */
    @Transactional
    public Map<String, Object> renewHeartbeat(Long orderId, String sessionId) {
        int updated = workspaceSessionRepository.renewHeartbeat(orderId, sessionId);

        if (updated > 0) {
            return Map.of("status", "ACTIVE", "serverTime", System.currentTimeMillis());
        }

        // If update was 0, check why the lease was lost
        Optional<WorkspaceSession> currentLease = workspaceSessionRepository.findByOrderId(orderId);
        if (currentLease.isPresent()) {
            WorkspaceSession lease = currentLease.get();
            if (!lease.getSessionId().equals(sessionId)) {
                return Map.of(
                        "status", "LEASE_LOST",
                        "reason", "ADMIN_TAKEOVER",
                        "message", "Workspace editing session was taken over by an Administrator.",
                        "newEditor", lease.getUser().getFullName() != null ? lease.getUser().getFullName() : lease.getUser().getUsername()
                );
            }
        }

        return Map.of(
                "status", "LEASE_EXPIRED",
                "message", "Session lease expired due to inactivity."
        );
    }

    /**
     * Same-User Tab Transfer. Smoothly swaps editing lease from Tab 1 to Tab 2.
     */
    @Transactional
    public Map<String, Object> switchTab(Long orderId, Long userId, String sessionId, String newTabSessionId) {
        WorkspaceSession lease = workspaceSessionRepository.findByOrderId(orderId)
                .orElseThrow(() -> new NoSuchElementException("No active lease found for order: " + orderId));

        if (!lease.getUser().getId().equals(userId)) {
            throw new SecurityException("Cannot switch tab: Lease belongs to another user");
        }

        String oldTabSessionId = lease.getTabSessionId();

        int updated = workspaceSessionRepository.switchTabSession(orderId, userId, newTabSessionId);
        if (updated > 0) {
            // Push real-time event to Tab 1 to switch to Read-Only
            realtimePushService.broadcastLeaseLost(lease.getSessionId(), orderId, "TAB_SWITCH", lease.getUser().getFullName());

            recordLeaseAudit(lease.getOrder(), lease.getUser(), sessionId, "TAB_SWITCH", null,
                    lease.getIpAddress(), lease.getMachineName(),
                    "Switched editing from tab " + oldTabSessionId + " to " + newTabSessionId);

            log.info("[WorkspaceLeaseService] User {} switched editing lease for order {} from tab {} to {}",
                    lease.getUser().getUsername(), orderId, oldTabSessionId, newTabSessionId);

            return Map.of("status", "TAB_SWITCHED", "orderId", orderId, "tabSessionId", newTabSessionId, "role", "ACTIVE_EDITOR");
        }

        throw new IllegalStateException("Failed to switch tab session");
    }

    /**
     * Admin Break-Glass Takeover with Pre-Flight Forced Autosave Request.
     */
    @Transactional
    public Map<String, Object> takeoverLease(Long orderId, Long adminUserId, String adminSessionId,
                                            String adminTabSessionId, String machineName,
                                            String platformInfo, String ipAddress) {
        User adminUser = userRepository.findById(adminUserId)
                .orElseThrow(() -> new NoSuchElementException("Admin user not found: " + adminUserId));

        if (!isPrivilegedRole(adminUser)) {
            throw new SecurityException("Forbidden: Only SPA, ADMIN, and SUPER_ADMIN can execute break-glass takeover");
        }

        WorkspaceSession currentLease = workspaceSessionRepository.findByOrderId(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order workspace lease not found: " + orderId));

        User previousEditor = currentLease.getUser();
        String previousSessionId = currentLease.getSessionId();

        // STEP 1: Attempt Pre-Flight Autosave Push via SSE to previous editor
        if ("ACTIVE".equals(currentLease.getLockStatus())) {
            realtimePushService.broadcastForceAutosave(
                    previousSessionId,
                    orderId,
                    takeoverAutosaveDeadlineMs,
                    adminUser.getFullName() != null ? adminUser.getFullName() : adminUser.getUsername()
            );

            // Allow client up to takeoverAutosaveDeadlineMs (1.5s) to complete flush
            try {
                Thread.sleep(Math.min(takeoverAutosaveDeadlineMs, 800));
            } catch (InterruptedException ignored) {}
        }

        // STEP 2: Atomic Takeover Reassignment
        workspaceSessionRepository.takeoverLease(
                orderId,
                adminUserId,
                adminSessionId,
                adminTabSessionId,
                machineName,
                platformInfo,
                ipAddress
        );

        // STEP 3: Notify previous editor of lease loss
        realtimePushService.broadcastLeaseLost(
                previousSessionId,
                orderId,
                "ADMIN_TAKEOVER",
                adminUser.getFullName() != null ? adminUser.getFullName() : adminUser.getUsername()
        );

        // STEP 4: High-integrity audit logging
        recordLeaseAudit(currentLease.getOrder(), previousEditor, previousSessionId, "TAKEOVER", adminUser,
                ipAddress, machineName, "Session forcibly taken over by " + adminUser.getUsername());

        log.warn("[WorkspaceLeaseService] BREAK-GLASS TAKEOVER executed on order {} by {} (Previous Editor: {})",
                orderId, adminUser.getUsername(), previousEditor.getUsername());

        return Map.of(
                "status", "TAKEOVER_SUCCESS",
                "orderId", orderId,
                "role", "ACTIVE_EDITOR",
                "sessionId", adminSessionId,
                "previousEditor", previousEditor.getFullName() != null ? previousEditor.getFullName() : previousEditor.getUsername()
        );
    }

    /**
     * User releases lease (e.g. closing workspace or navigating back).
     */
    @Transactional
    public void releaseLock(Long orderId, String sessionId) {
        workspaceSessionRepository.releaseLease(orderId, sessionId);
        workspaceSessionRepository.findByOrderId(orderId).ifPresent(l -> {
            recordLeaseAudit(l.getOrder(), l.getUser(), sessionId, "RELEASED", null,
                    l.getIpAddress(), l.getMachineName(), "Lease voluntarily released");
        });
        log.info("[WorkspaceLeaseService] Released lease for order {} (Session: {})", orderId, sessionId);
    }

    private boolean isPrivilegedRole(User user) {
        if (user.getRole() == null) return false;
        String role = user.getRole().name();
        return "SUPER_ADMIN".equals(role) || "ADMIN".equals(role) || "SPA".equals(role);
    }

    private void recordLeaseAudit(Order order, User user, String sessionId, String eventType,
                                  User triggerUser, String ipAddress, String deviceInfo, String details) {
        try {
            String jsonDetails = (details != null && details.trim().startsWith("{"))
                    ? details
                    : "{\"action\":\"" + (details != null ? details.replace("\"", "\\\"") : "") + "\"}";

            WorkspaceLeaseAudit audit = new WorkspaceLeaseAudit(
                    order,
                    user,
                    user != null ? (user.getEmail() != null ? user.getEmail() : user.getUsername()) : null,
                    sessionId,
                    eventType,
                    triggerUser,
                    triggerUser != null ? (triggerUser.getEmail() != null ? triggerUser.getEmail() : triggerUser.getUsername()) : null,
                    ipAddress,
                    deviceInfo,
                    jsonDetails
            );
            leaseAuditRepository.save(audit);
        } catch (Exception e) {
            log.warn("[WorkspaceLeaseService] Failed to record lease audit: {}", e.getMessage());
        }
    }
}

