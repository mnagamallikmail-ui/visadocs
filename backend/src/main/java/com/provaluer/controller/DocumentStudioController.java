package com.provaluer.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.provaluer.dto.SaveStudioConfigRequest;
import com.provaluer.dto.VisualPreviewResponse;
import com.provaluer.model.DocumentStudioConfig;
import com.provaluer.model.Template;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.DocxCoordinateExtractor;
import com.provaluer.service.DocxPreviewGenerator;
import com.provaluer.service.DocumentStudioService;
import com.provaluer.service.FeatureFlagService;
import com.provaluer.service.TemplateQuestionSyncService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/v1/studio")
public class DocumentStudioController {

    @Autowired
    private DocumentStudioService studioService;

    @Autowired
    private FeatureFlagService featureFlagService;

    @Autowired
    private TemplateQuestionSyncService syncService;

    @Autowired
    private DocxPreviewGenerator previewGenerator;

    @Autowired
    private DocxCoordinateExtractor coordinateExtractor;

    @Autowired
    private TemplateRepository templateRepository;

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

    /**
     * GET /api/v1/studio/templates/{id}/visual-preview
     * Generates or retrieves the pixel-perfect visual preview page assets and normalized placeholder coordinates.
     */
    @GetMapping("/templates/{id}/visual-preview")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'SPA', 'PA')")
    public ResponseEntity<?> getVisualPreview(@PathVariable Long id, @RequestParam(defaultValue = "false") boolean force) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null || !featureFlagService.isStudioEnabled(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Document Studio is currently disabled or restricted for your role."));
        }

        Template template = templateRepository.findById(id).orElse(null);
        if (template == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "Template not found with ID: " + id));
        }

        byte[] docxBytes = template.getTemplateContent();
        if (docxBytes == null || docxBytes.length == 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(Map.of("error", "Template has no binary document content"));
        }

        try {
            // 1. Generate/load 200 DPI preview page images
            DocxPreviewGenerator.PreviewMetadata metadata = previewGenerator.generatePreview(id, docxBytes, force);

            // 2. Generate PDF bytes to extract normalized coordinates
            byte[] pdfBytes = previewGenerator.convertDocxToPdf(id, docxBytes);
            Map<Integer, List<VisualPreviewResponse.VisualPlaceholder>> coordinatesMap =
                    coordinateExtractor.extractCoordinates(pdfBytes);

            // 3. Assemble VisualPreviewResponse DTO
            VisualPreviewResponse.PageDimensions dims = new VisualPreviewResponse.PageDimensions(
                    metadata.getWidthPt(),
                    metadata.getHeightPt(),
                    metadata.getAspectRatio()
            );

            List<VisualPreviewResponse.VisualPage> pages = new ArrayList<>();
            for (DocxPreviewGenerator.PageAsset pageAsset : metadata.getPages()) {
                int pIdx = pageAsset.getPageIndex();
                List<VisualPreviewResponse.VisualPlaceholder> placeholders =
                        coordinatesMap.getOrDefault(pIdx, Collections.emptyList());

                pages.add(new VisualPreviewResponse.VisualPage(
                        pIdx,
                        pageAsset.getImageUrl(),
                        placeholders
                ));
            }

            VisualPreviewResponse response = new VisualPreviewResponse(
                    id,
                    metadata.getTotalPages(),
                    dims,
                    pages
            );

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to generate visual preview: " + e.getMessage()));
        }
    }

    /**
     * GET /api/v1/studio/templates/{id}/pages/{pageIndex}.png
     * Streams a high-DPI rendered page image tile from the preview cache.
     */
    @GetMapping(value = "/templates/{id}/pages/{pageIndex}.png", produces = MediaType.IMAGE_PNG_VALUE)
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN', 'SPA', 'PA')")
    public ResponseEntity<byte[]> getPageImage(@PathVariable Long id, @PathVariable int pageIndex) {
        UserDetailsImpl principal = getCurrentPrincipal();
        if (principal == null || !featureFlagService.isStudioEnabled(principal)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        try {
            byte[] imageBytes = previewGenerator.getPageImage(id, pageIndex);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"page_" + pageIndex + ".png\"")
                    .cacheControl(CacheControl.maxAge(1, TimeUnit.HOURS).cachePublic())
                    .body(imageBytes);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
