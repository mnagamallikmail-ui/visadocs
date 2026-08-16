package com.provaluer.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.provaluer.dto.SaveStudioConfigRequest;
import com.provaluer.model.DocumentStudioConfig;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.DocumentStudioService;
import com.provaluer.service.FeatureFlagService;
import com.provaluer.service.TemplateQuestionSyncService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/v1/studio")
public class DocumentStudioController {

    @Autowired
    private DocumentStudioService studioService;

    @Autowired
    private FeatureFlagService featureFlagService;

    @Autowired
    private TemplateQuestionSyncService syncService;

    private UserDetailsImpl getCurrentPrincipal() {
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (principal instanceof UserDetailsImpl) {
            return (UserDetailsImpl) principal;
        }
        return null;
    }

    /**
     * GET /api/v1/studio/templates/{id}/structure
     * Returns the structured JsonNode DOM of a template's OpenXML document.
     */
    @GetMapping("/templates/{id}/structure")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'SPA', 'PA')")
    public ResponseEntity<?> getTemplateStructure(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null || !featureFlagService.isStudioEnabled(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Document Studio is currently disabled or restricted for your role."));
        }

        try {
            JsonNode structure = studioService.getTemplateStructure(id);
            return ResponseEntity.ok(structure);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                    .body(Map.of("error", "Failed to process template structure: " + e.getMessage()));
        }
    }

    /**
     * GET /api/v1/studio/templates/{id}/config
     * Retrieves saved designer configuration and custom label overrides.
     */
    @GetMapping("/templates/{id}/config")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'SPA', 'PA')")
    public ResponseEntity<?> getStudioConfig(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null || !featureFlagService.isStudioEnabled(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Document Studio is currently disabled or restricted for your role."));
        }

        DocumentStudioConfig config = studioService.getStudioConfig(id);
        if (config == null) {
            // Return empty default configuration if no record has been created yet
            return ResponseEntity.ok(Map.of(
                    "templateId", id,
                    "customLabels", "{}",
                    "tableConfigs", "[]"
            ));
        }

        return ResponseEntity.ok(config);
    }

    /**
     * POST /api/v1/studio/templates/{id}/config
     * Persists or updates visual designer configuration for a template.
     */
    @PostMapping("/templates/{id}/config")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'SPA', 'PA')")
    public ResponseEntity<?> saveStudioConfig(@PathVariable Long id, @RequestBody SaveStudioConfigRequest request) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null || !featureFlagService.isStudioEnabled(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Document Studio is currently disabled or restricted for your role."));
        }

        if (request == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "Request payload must not be null"));
        }

        try {
            DocumentStudioConfig saved = studioService.saveStudioConfig(
                    id,
                    request.getCustomLabels(),
                    request.getTableConfigs(),
                    principal.getId()
            );
            return ResponseEntity.ok(saved);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to save studio configuration: " + e.getMessage()));
        }
    }

    /**
     * POST /api/v1/studio/templates/{id}/publish-intake
     * Synchronizes customized Document Studio placeholder questions into the central
     * template questions dictionary and refreshes Template.fieldMapping schema.
     */
    @PostMapping("/templates/{id}/publish-intake")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> publishToIntake(@PathVariable Long id) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null || !featureFlagService.isStudioEnabled(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Document Studio is currently disabled or restricted for your role."));
        }

        try {
            TemplateQuestionSyncService.SyncResult result = syncService.syncTemplateQuestions(id, principal.getId());
            return ResponseEntity.ok(result);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        } catch (IllegalArgumentException | IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to publish template questions to intake: " + e.getMessage()));
        }
    }
}
