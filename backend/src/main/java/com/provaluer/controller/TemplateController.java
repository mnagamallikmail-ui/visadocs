package com.provaluer.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.provaluer.model.Template;
import com.provaluer.repository.TemplateRepository;
import com.provaluer.util.DocxTemplateEngine;
import org.docx4j.openpackaging.packages.WordprocessingMLPackage;
import org.docx4j.wml.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.util.*;
import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api/v1/templates")
public class TemplateController {

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private DocxTemplateEngine templateEngine;

    @Autowired
    private com.provaluer.repository.TemplateQuestionRepository templateQuestionRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * GET /api/v1/templates
     * Retrieves all templates (active or inactive) for Admin management screen.
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<List<Template>> getAllTemplates() {
        return ResponseEntity.ok(templateRepository.findAll());
    }

    /**
     * POST /api/v1/templates/upload
     * Ingests a new .docx template, sets status to PENDING, and processes parsing asynchronously in background.
     */
    @PostMapping("/upload")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> uploadTemplate(@RequestParam("file") MultipartFile file, @RequestParam("name") String name) {
        try {
            byte[] rawBytes = file.getBytes();

            byte[] normalizedBytes = templateEngine.normalizeTemplate(rawBytes);
            String fieldMappingJson = templateEngine.parseTemplate(normalizedBytes);

            Template template = new Template();
            template.setName(name);
            template.setTemplateContent(normalizedBytes);
            template.setFieldMapping(fieldMappingJson);
            template.setIsActive("N");
            template.setStatus("PARSED");

            Template saved = templateRepository.save(template);
            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Upload failed: " + e.getMessage());
        }
    }

    /**
     * POST /api/v1/templates/generate-mock
     * Programmatically constructs a valid Word Document (.docx) package with headings,
     * tables, and drawing shapes matching keys, and runs it through the async parser.
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
            extent.setCx(2743200L); // 3 inches (3 * 914,400)
            extent.setCy(1828800L); // 2 inches (2 * 914,400)
            inline.setExtent(extent);

            org.docx4j.dml.CTNonVisualDrawingProps docPr = new org.docx4j.dml.CTNonVisualDrawingProps();
            docPr.setId(1001L);
            docPr.setName("IMG_SITE_MAP");
            docPr.setDescr("IMG_SITE_MAP");
            inline.setDocPr(docPr);

            org.docx4j.dml.Graphic graphic = new org.docx4j.dml.Graphic();
            inline.setGraphic(graphic);

            // Wrap the Inline drawing in a Drawing object before adding to Run
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

            // Async parsing execution
            CompletableFuture.runAsync(() -> {
                try {
                    Thread.sleep(2000);
                    byte[] normalizedBytes = templateEngine.normalizeTemplate(docxBytes);
                    String fieldMappingJson = templateEngine.parseTemplate(normalizedBytes);

                    saved.setTemplateContent(normalizedBytes);
                    saved.setFieldMapping(fieldMappingJson);
                    saved.setStatus("PARSED");
                    templateRepository.save(saved);
                } catch (Exception e) {
                    saved.setStatus("FAILED");
                    templateRepository.save(saved);
                }
            });

            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Failed to generate mock template: " + e.getMessage());
        }
    }

    /**
     * GET /api/v1/templates/active
     * Retrieves all templates confirmed and active for Client/PA usage.
     */
    @GetMapping("/active")
    public ResponseEntity<List<Template>> getActiveTemplates() {
        return ResponseEntity.ok(templateRepository.findAllByIsActive("Y"));
    }

    /**
     * GET /api/v1/templates/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getTemplateById(@PathVariable Long id) {
        return templateRepository.findById(id)
                .map(ResponseEntity::ok)
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
                templateRepository.save(template);
                return ResponseEntity.ok(template);
            } catch (Exception e) {
                return ResponseEntity.badRequest().body("Invalid mapping configuration JSON.");
            }
        }
        return ResponseEntity.notFound().build();
    }

    /**
     * DELETE /api/v1/templates/{id}
     * Deletes a template from the database.
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> deleteTemplate(@PathVariable Long id) {
        return templateRepository.findById(id)
                .map(t -> {
                    templateRepository.delete(t);
                    return ResponseEntity.ok().build();
                })
                .orElse(ResponseEntity.notFound().build());
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
            Template newTemplate = new Template();
            newTemplate.setName(oldTemplate.getName() + " (v2)");
            newTemplate.setTemplateContent(normalizedBytes);
            newTemplate.setFieldMapping(objectMapper.writeValueAsString(newSchema));
            newTemplate.setIsActive("Y");
            newTemplate.setStatus("CONFIRMED");

            Template saved = templateRepository.save(newTemplate);
            return ResponseEntity.ok(saved);

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
