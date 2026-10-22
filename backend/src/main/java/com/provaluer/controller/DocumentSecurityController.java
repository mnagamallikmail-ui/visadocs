package com.provaluer.controller;

import com.provaluer.model.DocumentAccessLog;
import com.provaluer.repository.DocumentAccessLogRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.DocumentSecurityService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * DPDP Act 2023 - Document Security & Secure Delivery Controller
 * Exposes signed URL / download token generation and secure streaming endpoints.
 */
@RestController
@RequestMapping("/api/v1/documents")
@CrossOrigin(origins = "*", maxAge = 3600)
public class DocumentSecurityController {

    @Autowired
    private DocumentSecurityService documentSecurityService;

    @Autowired
    private DocumentAccessLogRepository accessLogRepository;

    /**
     * Generate secure expiring download token (default 10 minutes)
     */
    @PostMapping("/token")
    @PreAuthorize("hasAnyRole('CLIENT', 'PA', 'SPA', 'ADMIN', 'SUPER_ADMIN')")
    public ResponseEntity<?> generateDownloadToken(
            @RequestBody Map<String, Object> request,
            @AuthenticationPrincipal UserDetailsImpl principal,
            HttpServletRequest httpRequest) {

        String documentType = (String) request.get("documentType");
        String documentId = String.valueOf(request.get("documentId"));
        Long expirySeconds = request.containsKey("expirySeconds") ? ((Number) request.get("expirySeconds")).longValue() : 600L;
        boolean singleUse = request.containsKey("singleUse") && Boolean.TRUE.equals(request.get("singleUse"));

        if (documentType == null || documentId == null) {
            return ResponseEntity.badRequest().body("documentType and documentId are required");
        }

        String ip = extractClientIp(httpRequest);
        String ua = httpRequest.getHeader(HttpHeaders.USER_AGENT);

        DocumentSecurityService.DownloadTokenResult tokenResult = documentSecurityService.generateDownloadToken(
                documentType,
                documentId,
                principal != null ? principal.getId() : null,
                principal != null ? principal.getUsername() : "ANONYMOUS",
                expirySeconds,
                singleUse,
                ip,
                ua
        );

        Map<String, Object> response = new HashMap<>();
        response.put("token", tokenResult.token);
        response.put("expiresAt", tokenResult.expiresAt);
        response.put("expiresInSeconds", tokenResult.expiresInSeconds);
        response.put("downloadUrl", "/api/v1/documents/download?token=" + tokenResult.token);

        return ResponseEntity.ok(response);
    }

    /**
     * Download / stream document with signed expiring token.
     * Accessible without Bearer token if token signature is valid and unexpired.
     */
    @GetMapping("/download")
    public ResponseEntity<?> downloadWithToken(
            @RequestParam("token") String token,
            HttpServletRequest httpRequest) {

        String ip = extractClientIp(httpRequest);
        String ua = httpRequest.getHeader(HttpHeaders.USER_AGENT);

        try {
            DocumentSecurityService.DecryptedDocumentResult doc =
                    documentSecurityService.downloadDocumentWithToken(token, ip, ua);

            MediaType mediaType;
            try {
                mediaType = MediaType.parseMediaType(doc.contentType);
            } catch (Exception e) {
                mediaType = MediaType.APPLICATION_OCTET_STREAM;
            }

            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + doc.filename + "\"")
                    .contentType(mediaType)
                    .body(doc.data);
        } catch (SecurityException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                    "status", "ERROR",
                    "error", "FORBIDDEN",
                    "message", e.getMessage()
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "status", "ERROR",
                    "error", "BAD_REQUEST",
                    "message", e.getMessage()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", "ERROR",
                    "error", "SERVER_ERROR",
                    "message", "Failed to retrieve decrypted document: " + e.getMessage()
            ));
        }
    }

    /**
     * Audit log retrieval for Super Admins
     */
    @GetMapping("/access-logs")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<List<DocumentAccessLog>> getAccessLogs() {
        return ResponseEntity.ok(accessLogRepository.findTop50ByOrderByCreatedAtDesc());
    }

    private String extractClientIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.isEmpty()) {
            return xf.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
