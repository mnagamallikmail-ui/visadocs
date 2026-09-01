package com.provaluer.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.provaluer.dto.TemplateDetailDTO;
import com.provaluer.dto.TemplateListDTO;
import com.provaluer.dto.TemplateVersionDTO;
import com.provaluer.model.Template;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.repository.TemplateVersionRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.TemplateProcessingService;
import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.ByteArrayOutputStream;
import java.util.*;

@RestController
@RequestMapping("/api/v1/templates")
public class TemplateController {

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private TemplateVersionRepository templateVersionRepository;

    @Autowired
    private TemplateProcessingService templateProcessingService;

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Autowired
    private com.provaluer.util.DocxStructureParser docxStructureParser;

    @Autowired
    private com.provaluer.repository.TemplateQuestionRepository templateQuestionRepository;

    @Autowired
    private com.provaluer.repository.DocumentStudioConfigRepository studioConfigRepository;

    @Autowired
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private Long currentUserId() {
        try {
            Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            if (principal instanceof UserDetailsImpl) {
                return ((UserDetailsImpl) principal).getId();
            }
        } catch (Exception ignored) {}
        return null;
    }

    /**
     * GET /api/v1/templates
     * Retrieves all templates (active or inactive) as lightweight DTOs for Admin management screen.
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<List<TemplateListDTO>> getAllTemplates() {
        List<TemplateListDTO> dtos = templateRepository.findAll().stream()
                .map(TemplateListDTO::new)
                .toList();
        return ResponseEntity.ok(dtos);
    }

    /**
     * POST /api/v1/templates/upload
     * Validates DOCX integrity, saves template in PENDING state immediately, and triggers async processing.
     */
    @PostMapping("/upload")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> uploadTemplate(@RequestParam("file") MultipartFile file, @RequestParam("name") String name) {
        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body("File cannot be empty.");
            }

            byte[] rawBytes = file.getBytes();

            // 0.13: Validate DOCX package structure before saving
            templateProcessingService.validateDocxPackage(rawBytes, file.getOriginalFilename());

            // 0.6: Save immediately with status = PENDING
            Template template = new Template();
            template.setName((name != null && !name.trim().isEmpty()) ? name.trim() : file.getOriginalFilename());
            template.setTemplateContent(rawBytes);
            template.setFieldMapping("{}");
            template.setIsActive("N");
            template.setStatus("PENDING");
            template.setProcessingError(null);

            Template saved = templateRepository.save(template);

            // Trigger non-blocking async background processing
            templateProcessingService.processTemplateAsync(saved.getId(), rawBytes, currentUserId());

            // Return 202 Accepted immediately
            return ResponseEntity.status(HttpStatus.ACCEPTED).body(new TemplateDetailDTO(saved));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Validation failed: " + e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Upload failed: " + e.getMessage());
        }
    }

    /**
     * POST /api/v1/templates/generate-mock
     * Programmatically constructs a valid Word Document (.docx) package with headings,
     * tables, and drawing shapes matching keys, and runs it through async parser.
     */
    @PostMapping("/generate-mock")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> generateMockTemplate() {
        try {
            WordprocessingMLPackage wordMLPackage = WordprocessingMLPackage.createPackage();
            org.docx4j.wml.ObjectFactory factory = new org.docx4j.wml.ObjectFactory();

            // Section 1 Heading
            P p1 = factory.createP();
            R r1 = factory.createR();
            Text t1 = factory.createText();
            t1.setValue("1. General Information Section");
            r1.getContent().add(t1);
            p1.getContent().add(r1);
            wordMLPackage.getMainDocumentPart().getContent().add(p1);

            // Placeholders
            P p2 = factory.createP();
            R r2 = factory.createR();
            Text t2 = factory.createText();
            t2.setValue("The valuation is for <<CLIENT_NAME>> scheduled on <<DATE_INSPECTION>>.");
            r2.getContent().add(t2);
            p2.getContent().add(r2);
            wordMLPackage.getMainDocumentPart().getContent().add(p2);

            // Section 2 Heading
            P p3 = factory.createP();
            R r3 = factory.createR();
            Text t3 = factory.createText();
            t3.setValue("2. Valuation Parameters");
            r3.getContent().add(t3);
            p3.getContent().add(r3);
            wordMLPackage.getMainDocumentPart().getContent().add(p3);

            // Numeric field & Dropdown field
            P p4 = factory.createP();
            R r4 = factory.createR();
            Text t4 = factory.createText();
            t4.setValue("Estimated registration value is INR <<NUM_VALUATION_VALUE>> and zoning category is <<SELECT_ZONING>>.");
            r4.getContent().add(t4);
            p4.getContent().add(r4);
            wordMLPackage.getMainDocumentPart().getContent().add(p4);

            // Inline Image shape
            P p5 = factory.createP();
            R r5 = factory.createR();
            
            org.docx4j.dml.wordprocessingDrawing.Inline inline = new org.docx4j.dml.wordprocessingDrawing.Inline();
            org.docx4j.dml.CTPositiveSize2D extent = new org.docx4j.dml.CTPositiveSize2D();
            extent.setCx(2743200L); // 3 inches
            extent.setCy(1828800L); // 2 inches
            inline.setExtent(extent);

            org.docx4j.dml.CTNonVisualDrawingProps docPr = new org.docx4j.dml.CTNonVisualDrawingProps();
            docPr.setId(1001L);
            docPr.setName("IMG_SITE_MAP");
            docPr.setDescr("IMG_SITE_MAP");
            inline.setDocPr(docPr);

            org.docx4j.dml.Graphic graphic = new org.docx4j.dml.Graphic();
            inline.setGraphic(graphic);

            Drawing drawing = factory.createDrawing();
            drawing.getAnchorOrInline().add(inline);

            r5.getContent().add(drawing);
            p5.getContent().add(r5);
            wordMLPackage.getMainDocumentPart().getContent().add(p5);

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            wordMLPackage.save(out);
            byte[] docxBytes = out.toByteArray();

            Template template = new Template();
            template.setName("Standard Commercial Template");
            template.setTemplateContent(docxBytes);
            template.setFieldMapping("{}");
            template.setIsActive("N");
            template.setStatus("PENDING");

            Template saved = templateRepository.save(template);

            // Run async processing pipeline
            templateProcessingService.processTemplateAsync(saved.getId(), docxBytes, currentUserId());

            return ResponseEntity.status(HttpStatus.ACCEPTED).body(new TemplateDetailDTO(saved));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to generate mock template: " + e.getMessage());
        }
    }

    /**
     * GET /api/v1/templates/active
     * Retrieves all templates confirmed and active for Client/PA usage.
     */
    @GetMapping("/active")
    public ResponseEntity<List<TemplateListDTO>> getActiveTemplates() {
        List<TemplateListDTO> dtos = templateRepository.findAllByIsActive("Y").stream()
                .map(TemplateListDTO::new)
                .toList();
        return ResponseEntity.ok(dtos);
    }

    /**
     * GET /api/v1/templates/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getTemplateById(@PathVariable Long id) {
        return templateRepository.findById(id)
                .map(t -> ResponseEntity.ok(new TemplateDetailDTO(t)))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * POST /api/v1/templates/{id}/confirm
     * Locks the template configuration, making it active for client consumption.
     */
    @PostMapping("/{id}/confirm")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> confirmTemplate(@PathVariable Long id, @RequestBody String fieldMappingUpdates) {
        Optional<Template> templateOpt = templateRepository.findById(id);
        if (templateOpt.isPresent()) {
            Template template = templateOpt.get();
            try {
                // Verify valid JSON
                objectMapper.readTree(fieldMappingUpdates);
                template.setFieldMapping(fieldMappingUpdates);
                template.setIsActive("Y");
                template.setStatus("CONFIRMED");
                Template saved = templateRepository.save(template);

                // Create version snapshot on confirmation
                templateProcessingService.saveVersionSnapshot(saved, "Template confirmed and activated", currentUserId());

                return ResponseEntity.ok(new TemplateDetailDTO(saved));
            } catch (Exception e) {
                return ResponseEntity.badRequest().body("Invalid mapping configuration JSON: " + e.getMessage());
            }
        }
        return ResponseEntity.notFound().build();
    }

    /**
     * DELETE /api/v1/templates/{id}
     * Deletes a template from the database after cascading dependent records.
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    @Transactional
    public ResponseEntity<?> deleteTemplate(@PathVariable Long id) {
        Optional<Template> optionalTemplate = templateRepository.findById(id);
        if (optionalTemplate.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        try {
            Template template = optionalTemplate.get();

            // 1. Unlink orders using this template to avoid foreign key violation
            jdbcTemplate.update("UPDATE orders SET template_id = NULL WHERE template_id = ?", id);

            // 2. Delete dependent document studio configs
            studioConfigRepository.deleteByTemplateId(id);

            // 3. Delete dependent template versions
            templateVersionRepository.deleteAllByTemplateId(id);

            // 4. Delete the parent template
            templateRepository.delete(template);

            return ResponseEntity.ok(Map.of("status", "SUCCESS", "message", "Template deleted successfully."));
        } catch (Exception e) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.CONFLICT)
                    .body(Map.of("status", "ERROR", "message", "Cannot delete template due to dependent records: " + e.getMessage()));
        }
    }

    /**
     * GET /api/v1/templates/{id}/versions
     * Retrieves version history for a given template.
     */
    @GetMapping("/{id}/versions")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<List<TemplateVersionDTO>> getTemplateVersions(@PathVariable Long id) {
        List<TemplateVersionDTO> list = templateVersionRepository.findAllByTemplateIdOrderByVersionDesc(id).stream()
                .map(TemplateVersionDTO::new)
                .toList();
        return ResponseEntity.ok(list);
    }

    /**
     * POST /api/v1/templates/{id}/rollback/{version}
     * Restores template to a previously saved version state.
     */
    @PostMapping("/{id}/rollback/{version}")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> rollbackTemplateVersion(@PathVariable Long id, @PathVariable int version) {
        try {
            Template restored = templateProcessingService.rollbackTemplateVersion(id, version, currentUserId());
            return ResponseEntity.ok(new TemplateDetailDTO(restored));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Rollback failed: " + e.getMessage());
        }
    }

    /**
     * PATCH /api/v1/templates/{id}/archive
     * Stateless Deep-Copy Inheritance: archives the old template version and inherits configurations for matching keys.
     */
    @PatchMapping("/{id}/archive")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> archiveAndInheritTemplate(@PathVariable Long id, @RequestParam("file") MultipartFile file) {
        Optional<Template> oldTemplateOpt = templateRepository.findById(id);
        if (!oldTemplateOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }

        Template oldTemplate = oldTemplateOpt.get();

        try {
            byte[] rawBytes = file.getBytes();
            templateProcessingService.validateDocxPackage(rawBytes, file.getOriginalFilename());

            byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes);
            String newFieldMappingJson = templateEngine.parseTemplate(normalizedBytes);

            JsonNode oldSchema = objectMapper.readTree(oldTemplate.getFieldMapping());
            JsonNode newSchema = objectMapper.readTree(newFieldMappingJson);

            Map<String, JsonNode> oldFieldsMap = new HashMap<>();
            if (oldSchema.has("fields")) {
                for (JsonNode field : oldSchema.get("fields")) {
                    oldFieldsMap.put(field.get("key").asText(), field);
                }
            }

            // Inherit configurations (display label, question, validations) for unchanged placeholders
            if (newSchema.has("fields")) {
                ArrayNode newFields = (ArrayNode) newSchema.get("fields");
                for (int i = 0; i < newFields.size(); i++) {
                    ObjectNode newField = (ObjectNode) newFields.get(i);
                    String key = newField.get("key").asText();
                    if (oldFieldsMap.containsKey(key)) {
                        JsonNode oldField = oldFieldsMap.get(key);
                        newField.put("label", oldField.get("label").asText());
                        newField.put("question", oldField.get("question").asText());
                        newField.put("isRequired", oldField.get("isRequired").asBoolean());
                    }
                }
            }

            // Soft-archive old version
            oldTemplate.setIsActive("N");
            oldTemplate.setStatus("CONFIRMED");
            templateRepository.save(oldTemplate);

            // Create new inherited active template
            JsonNode domNode = docxStructureParser.parseDocumentStructure(normalizedBytes);
            String documentDomJson = domNode.toString();
            String placeholderRegistryJson = docxStructureParser.generatePlaceholderRegistry(domNode);

            Template newTemplate = new Template();
            newTemplate.setName(oldTemplate.getName() + " (v" + (oldTemplate.getVersion() + 1) + ")");
            newTemplate.setTemplateContent(normalizedBytes);
            newTemplate.setDocumentDom(documentDomJson);
            newTemplate.setPlaceholderRegistry(placeholderRegistryJson);
            newTemplate.setFieldMapping(objectMapper.writeValueAsString(newSchema));
            newTemplate.setVersion(oldTemplate.getVersion() + 1);
            newTemplate.setIsActive("Y");
            newTemplate.setStatus("CONFIRMED");

            Template saved = templateRepository.save(newTemplate);
            templateProcessingService.saveVersionSnapshot(saved, "Inherited from v" + oldTemplate.getVersion(), currentUserId());

            return ResponseEntity.ok(new TemplateDetailDTO(saved));

        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Inheritance copy failed: " + e.getMessage());
        }
    }

    @GetMapping("/questions")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<List<com.provaluer.model.TemplateQuestion>> getQuestions() {
        return ResponseEntity.ok(templateQuestionRepository.findAll());
    }

    @PutMapping("/questions")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    @Transactional
    public ResponseEntity<?> updateQuestion(@RequestBody com.provaluer.model.TemplateQuestion update) {
        Optional<com.provaluer.model.TemplateQuestion> existingOpt = templateQuestionRepository.findById(update.getPlaceholderKey());
        com.provaluer.model.TemplateQuestion existing;
        if (existingOpt.isPresent()) {
            existing = existingOpt.get();
            existing.setQuestionText(update.getQuestionText());
        } else {
            existing = new com.provaluer.model.TemplateQuestion(update.getPlaceholderKey(), update.getQuestionText());
        }
        templateQuestionRepository.save(existing);

        // Update all templates containing this placeholder key in fieldMapping
        List<Template> templates = templateRepository.findAll();
        for (Template t : templates) {
            String mapping = t.getFieldMapping();
            if (mapping != null && mapping.contains(update.getPlaceholderKey())) {
                try {
                    JsonNode root = objectMapper.readTree(mapping);
                    if (root.has("fields")) {
                        ArrayNode fields = (ArrayNode) root.get("fields");
                        boolean updated = false;
                        for (int i = 0; i < fields.size(); i++) {
                            ObjectNode field = (ObjectNode) fields.get(i);
                            if (update.getPlaceholderKey().equalsIgnoreCase(field.get("key").asText())) {
                                field.put("question", update.getQuestionText());
                                updated = true;
                            }
                        }
                        if (updated) {
                            t.setFieldMapping(objectMapper.writeValueAsString(root));
                            templateRepository.save(t);
                        }
                    }
                } catch (Exception e) {
                    // Skip templates with invalid json
                }
            }
        }

        return ResponseEntity.ok(existing);
    }
}
