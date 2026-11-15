package com.provaluer.service;

import com.provaluer.model.User;
import com.provaluer.model.UserSession;
import com.provaluer.repository.UserSessionRepository;
import com.provaluer.repository.WorkspaceSessionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.*;

@Service
public class AuthSessionService {

    private static final Logger log = LoggerFactory.getLogger(AuthSessionService.class);

    private final UserSessionRepository userSessionRepository;
    private final WorkspaceSessionRepository workspaceSessionRepository;
    private final RealtimePushService realtimePushService;
    private final AuditLogService auditLogService;

    public AuthSessionService(UserSessionRepository userSessionRepository,
                              WorkspaceSessionRepository workspaceSessionRepository,
                              RealtimePushService realtimePushService,
                              AuditLogService auditLogService) {
        this.userSessionRepository = userSessionRepository;
        this.workspaceSessionRepository = workspaceSessionRepository;
        this.realtimePushService = realtimePushService;
        this.auditLogService = auditLogService;
    }

    public static String hashToken(String token) {
        if (token == null) return "";
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    /**
     * Checks if user already has an active session on another device.
     */
    @Transactional(readOnly = true)
    public Optional<UserSession> getActiveSession(Long userId) {
        List<UserSession> activeSessions = userSessionRepository.findAllByUserIdAndIsActiveTrue(userId);
        return activeSessions.isEmpty() ? Optional.empty() : Optional.of(activeSessions.get(0));
    }

    /**
     * Creates and activates a new user session, terminating any conflicting sessions.
     */
    @Transactional
    public UserSession createAndActivateSession(User user, String sessionId, String jwtToken, String refreshToken,
                                                String deviceInfo, String platformInfo, String approximateLocation,
                                                String ipAddress) {
        // Terminate any previous active sessions for this user
        terminateAllSessionsForUser(user.getId(), "NEW_DEVICE_ACTIVATION");

        UserSession session = new UserSession(
                user,
                sessionId,
                hashToken(jwtToken),
                hashToken(refreshToken),
                deviceInfo,
                platformInfo,
                approximateLocation,
                ipAddress
        );

        UserSession saved = userSessionRepository.save(session);

        auditLogService.log(
                user.getId(),
                user.getEmail() != null ? user.getEmail() : user.getUsername(),
                user.getRole() != null ? user.getRole().name() : "USER",
                "USER_SESSION_STARTED",
                "USER_SESSION",
                sessionId,
                null,
                "Device: " + deviceInfo,
                "Active login session established on " + deviceInfo
        );

        return saved;
    }

    /**
     * Evicts a session, pushes real-time event, and releases all workspace leases.
     */
    @Transactional
    public void evictSession(UserSession session, String reason) {
        session.setIsActive(false);
        session.setTerminatedAt(LocalDateTime.now());
        session.setTerminationReason(reason);
        userSessionRepository.save(session);

        // Cascade release any workspace leases owned by this session
        try {
            workspaceSessionRepository.releaseAllActiveLeases(session.getUser().getId(), session.getSessionId());
        } catch (Exception e) {
            log.warn("[AuthSessionService] Could not release workspace leases for evicted session {}: {}", session.getSessionId(), e.getMessage());
        }

        // Notify client via real-time SSE push (best effort; database eviction remains authoritative)
        try {
            realtimePushService.broadcastSessionEviction(session.getSessionId(), Map.of(
                    "reason", reason,
                    "terminatedAt", LocalDateTime.now().toString(),
                    "message", "Your session was ended because this account logged in from another device."
            ));
            realtimePushService.removeEmitter(session.getSessionId());
        } catch (Exception e) {
            log.warn("[AuthSessionService] Realtime SSE push failed for evicted session {}: {}", session.getSessionId(), e.getMessage());
        }

        log.info("[AuthSessionService] Evicted session {} for user {}: {}",
                session.getSessionId(), session.getUser().getUsername(), reason);
    }

    /**
     * Terminates all active sessions for a user.
     */
    @Transactional
    public void terminateAllSessionsForUser(Long userId, String reason) {
        List<UserSession> activeSessions = userSessionRepository.findAllByUserIdAndIsActiveTrue(userId);
        for (UserSession s : activeSessions) {
            evictSession(s, reason);
        }
    }

    /**
     * User explicit logout.
     */
    @Transactional
    public void logout(String sessionId) {
        userSessionRepository.findBySessionId(sessionId).ifPresent(s -> {
            s.setIsActive(false);
            s.setTerminatedAt(LocalDateTime.now());
            s.setTerminationReason("USER_LOGOUT");
            userSessionRepository.save(s);

            // Cascade release any workspace leases
            workspaceSessionRepository.releaseAllActiveLeases(s.getUser().getId(), sessionId);

            // Remove emitter
            realtimePushService.removeEmitter(sessionId);

            auditLogService.log(
                    s.getUser().getId(),
                    s.getUser().getEmail() != null ? s.getUser().getEmail() : s.getUser().getUsername(),
                    s.getUser().getRole() != null ? s.getUser().getRole().name() : "USER",
                    "USER_SESSION_ENDED",
                    "USER_SESSION",
                    sessionId,
                    null,
                    null,
                    "User logged out successfully"
            );
        });
    }

    /**
     * Validates that the session is still active and touches last activity.
     */
    @Transactional
    public boolean validateAndTouchSession(String sessionId) {
        Optional<UserSession> sessionOpt = userSessionRepository.findActiveBySessionId(sessionId);
        if (sessionOpt.isPresent()) {
            userSessionRepository.touchActivity(sessionId);
            return true;
        }
        return false;
    }
}

