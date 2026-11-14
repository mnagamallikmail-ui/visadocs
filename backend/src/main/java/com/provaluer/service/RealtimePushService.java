package com.provaluer.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class RealtimePushService {

    private static final Logger log = LoggerFactory.getLogger(RealtimePushService.class);

    // Key: sessionId -> SseEmitter
    private final Map<String, SseEmitter> emitters = new ConcurrentHashMap<>();

    // Timeout: 30 minutes for SSE stream
    private static final Long SSE_TIMEOUT_MS = 1800000L;

    public SseEmitter registerEmitter(String sessionId) {
        // If an old emitter exists for this session, complete it
        SseEmitter existing = emitters.remove(sessionId);
        if (existing != null) {
            try {
                existing.complete();
            } catch (Exception ignored) {}
        }

        SseEmitter emitter = new SseEmitter(SSE_TIMEOUT_MS);

        emitter.onCompletion(() -> {
            log.debug("[RealtimePushService] SSE completed for session {}", sessionId);
            emitters.remove(sessionId);
        });

        emitter.onTimeout(() -> {
            log.debug("[RealtimePushService] SSE timeout for session {}", sessionId);
            emitters.remove(sessionId);
        });

        emitter.onError(e -> {
            log.debug("[RealtimePushService] SSE error for session {}: {}", sessionId, e.getMessage());
            emitters.remove(sessionId);
        });

        emitters.put(sessionId, emitter);

        // Send initial CONNECTED handshake event
        try {
            emitter.send(SseEmitter.event()
                    .name("CONNECTED")
                    .data(Map.of("status", "CONNECTED", "sessionId", sessionId, "serverTime", System.currentTimeMillis())));
        } catch (IOException e) {
            log.warn("[RealtimePushService] Failed to send CONNECTED handshake: {}", e.getMessage());
            emitters.remove(sessionId);
        }

        return emitter;
    }

    public void removeEmitter(String sessionId) {
        SseEmitter emitter = emitters.remove(sessionId);
        if (emitter != null) {
            try {
                emitter.complete();
            } catch (Exception ignored) {}
        }
    }

    public boolean sendEvent(String sessionId, String eventName, Object data) {
        SseEmitter emitter = emitters.get(sessionId);
        if (emitter == null) {
            log.debug("[RealtimePushService] No active SSE emitter for session {} when sending {}", sessionId, eventName);
            return false;
        }

        try {
            emitter.send(SseEmitter.event()
                    .name(eventName)
                    .data(data));
            log.info("[RealtimePushService] Successfully dispatched event '{}' to session {}", eventName, sessionId);
            return true;
        } catch (IOException e) {
            log.warn("[RealtimePushService] Failed to push event '{}' to session {}: {}", eventName, sessionId, e.getMessage());
            emitters.remove(sessionId);
            return false;
        }
    }

    public void broadcastLoginChallenge(String targetSessionId, Map<String, Object> challengeData) {
        sendEvent(targetSessionId, "LOGIN_CHALLENGE", challengeData);
    }

    public void broadcastSessionEviction(String targetSessionId, Map<String, Object> evictionData) {
        sendEvent(targetSessionId, "SESSION_EVICTED", evictionData);
    }

    public void broadcastForceAutosave(String targetSessionId, Long orderId, long deadlineMs, String initiator) {
        Map<String, Object> data = new java.util.HashMap<>();
        data.put("orderId", orderId != null ? orderId : -1L);
        data.put("deadlineMs", deadlineMs);
        data.put("initiator", initiator != null ? initiator : "SYSTEM");
        sendEvent(targetSessionId, "FORCE_AUTOSAVE_REQUEST", data);
    }

    public void broadcastLeaseLost(String targetSessionId, Long orderId, String reason, String newEditor) {
        Map<String, Object> data = new java.util.HashMap<>();
        data.put("orderId", orderId != null ? orderId : -1L);
        data.put("reason", reason != null ? reason : "LEASE_LOST");
        data.put("newEditor", newEditor != null ? newEditor : "Unknown");
        sendEvent(targetSessionId, "LEASE_LOST", data);
    }

    public void broadcastWorkspaceInvalidated(String targetSessionId, Long orderId, String reason) {
        Map<String, Object> data = new java.util.HashMap<>();
        data.put("orderId", orderId != null ? orderId : -1L);
        data.put("reason", reason != null ? reason : "WORKSPACE_INVALIDATED");
        sendEvent(targetSessionId, "WORKSPACE_INVALIDATED", data);
    }

    public int getActiveEmitterCount() {
        return emitters.size();
    }
}

