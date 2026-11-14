package com.provaluer.controller;

import com.provaluer.service.RealtimePushService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api/v1/events")
public class SseNotificationController {

    private static final Logger log = LoggerFactory.getLogger(SseNotificationController.class);

    private final RealtimePushService realtimePushService;

    public SseNotificationController(RealtimePushService realtimePushService) {
        this.realtimePushService = realtimePushService;
    }

    /**
     * GET /api/v1/events/session-stream
     * Server-Sent Events real-time event pipeline for single-session eviction,
     * login challenges, takeover notifications, and lease loss.
     */
    @GetMapping(value = "/session-stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter subscribeSessionStream(
            @RequestHeader(value = "X-Session-ID", required = false) String headerSessionId,
            @RequestParam(value = "sessionId", required = false) String paramSessionId) {

        String sessionId = headerSessionId != null ? headerSessionId : paramSessionId;
        if (sessionId == null || sessionId.isBlank()) {
            SseEmitter errorEmitter = new SseEmitter(0L);
            errorEmitter.completeWithError(new IllegalArgumentException("sessionId is required"));
            return errorEmitter;
        }

        log.info("[SseNotificationController] New SSE subscription initiated for session {}", sessionId);
        return realtimePushService.registerEmitter(sessionId);
    }
}

