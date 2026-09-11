package com.provaluer.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.DocumentWorkspaceResponse;
import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.dto.SpaApproveDocumentRequest;
import com.provaluer.dto.VisualPreviewResponse;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.util.DocxStructureParser;
import com.provaluer.util.DocxTemplateEngine;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class DocumentWorkspaceService {

    private static final Logger log = LoggerFactory.getLogger(DocumentWorkspaceService.class);

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private TemplateRepository templateRepository;

    @Autowired
    private OrderInputRepository orderInputRepository;

    @Autowired
    private com.provaluer.repository.TemplateVersionRepository templateVersionRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private DocxPreviewGenerator previewGenerator;

    @Autowired
    private DocxCoordinateExtractor coordinateExtractor;

    @Autowired
    private DocxStructureParser docxStructureParser;

    @Autowired
    private DocxTemplateEngine docxTemplateEngine;

    @Autowired
    private PricingService pricingService;

    @Autowired
    private AuditLogService auditLogService;

    @Autowired
    private PerformanceLedgerRepository performanceLedgerRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DocumentStudioConfigRepository studioConfigRepository;

    @Autowired
    private TemplateQuestionRepository templateQuestionRepository;

    @Autowired
    private ValuationEngineService valuationEngineService;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final Map<Long, CachedOrderPreview> orderPreviewCache = new java.util.concurrent.ConcurrentHashMap<>();

    private static class CachedOrderPreview {
        final String contentHash;
        final VisualPreviewResponse response;

        CachedOrderPreview(String contentHash, VisualPreviewResponse response) {
            this.contentHash = contentHash;
            this.response = response;
        }
    }

    private String computePreviewContentHash(Long templateId, Integer templateVersion, Map<String, String> inputsMap, Map<String, byte[]> imagesMap) {
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
            md.update(("TPL:" + templateId + ":V:" + templateVersion).getBytes(java.nio.charset.StandardCharsets.UTF_8));
            inputsMap.entrySet().stream()
                    .sorted(Map.Entry.comparingByKey())
                    .forEach(e -> {
                        md.update((e.getKey() + "=" + (e.getValue() != null ? e.getValue() : "") + ";").getBytes(java.nio.charset.StandardCharsets.UTF_8));
                    });
            imagesMap.entrySet().stream()
                    .sorted(Map.Entry.comparingByKey())
                    .forEach(e -> {
                        md.update(("IMG:" + e.getKey() + ":LEN:" + (e.getValue() != null ? e.getValue().length : 0) + ";").getBytes(java.nio.charset.StandardCharsets.UTF_8));
                    });
            byte[] digest = md.digest();
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.substring(0, 16);
        } catch (Exception e) {
            return String.valueOf(Objects.hash(templateId, templateVersion, inputsMap));
        }
    }

    /**
     * Validates order ownership and role permissions against security policy.
     * Throws AccessDeniedException (HTTP 403) when access criteria are not satisfied.
     */
    public void validateOrderAccess(Order order, UserDetailsImpl principal, String action) {
        if (principal == null) {
            throw new AccessDeniedException("Unauthenticated access to order #" + order.getId());
        }

        boolean isSuperAdmin = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"));
        boolean isAdmin = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        boolean isSpa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_SPA"));
        boolean isPa = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_PA"));
        boolean isClient = principal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_CLIENT"));

        // Super Admin & Admin have unrestricted access
        if (isSuperAdmin || isAdmin) {
            return;
        }

        // PA Validation: May access only orders assigned to this PA
        if (isPa) {
            if ("APPROVE".equalsIgnoreCase(action)) {
                throw new AccessDeniedException("Property Analysts (PA) are not authorized to execute report approval");
            }
            if ("VIEW".equalsIgnoreCase(action)) {
                return;
            }
            if (order.getPaId() == null || !order.getPaId().equals(principal.getId())) {
                throw new AccessDeniedException("Access denied: You are not the assigned Property Analyst for Order #" + order.getId());
            }

            // Strict Locking Rule:
            // PA editing/resubmit rights are available ONLY until SPA approval/finalization.
            // If report reaches any of: SPA_CONFIRMED, FINALIZED, LOCKED, FINAL_DELIVERY
            // PA must NOT be able to: Edit, Save, Revise, Resubmit.
            boolean isLockedOrFinalized = "SPA_CONFIRMED".equalsIgnoreCase(order.getStatus())
                    || "FINAL_DELIVERY".equalsIgnoreCase(order.getStatus())
                    || "FINALIZED".equalsIgnoreCase(order.getValuationStatus())
                    || "LOCKED".equalsIgnoreCase(order.getValuationStatus());

            if (isLockedOrFinalized && ("SAVE".equalsIgnoreCase(action) || "SUBMIT_TO_SPA".equalsIgnoreCase(action))) {
                throw new AccessDeniedException("Report is finalized/locked (" + order.getStatus() + "/" + order.getValuationStatus() + ") and cannot be modified or resubmitted by Property Analyst");
            }

            return;
        }

        // SPA Validation: May inspect, save, live-preview, and approve orders
        if (isSpa) {
            return;
        }

        // Client Validation: May view only their own orders
        if (isClient) {
            if ("SAVE".equalsIgnoreCase(action) || "SUBMIT_TO_SPA".equalsIgnoreCase(action) || "APPROVE".equalsIgnoreCase(action)) {
                throw new AccessDeniedException("Clients have read-only access to valuation workspace");
            }
            if (order.getClientId() == null || !order.getClientId().equals(principal.getId())) {
                throw new AccessDeniedException("Access denied: You do not own Order #" + order.getId());
            }
            return;
        }

        throw new AccessDeniedException("Unauthorized role for Order #" + order.getId());
    }

    /**
     * Resolves the immutable template binary DOCX content for an order.
     * Option A Mandate: Historical reports are bound to their version snapshot and never affected
     * by subsequent template edits, archiving, or deletions.
     */
    public byte[] resolveOrderTemplateBytes(Order order, Template fallbackTemplate) {
        if (order != null && order.getTemplateVersionId() != null) {
            java.util.Optional<com.provaluer.model.TemplateVersion> versionOpt = templateVersionRepository.findById(order.getTemplateVersionId());
            if (versionOpt.isPresent() && versionOpt.get().getTemplateContent() != null && versionOpt.get().getTemplateContent().length > 0) {
                return versionOpt.get().getTemplateContent();
            }
        }
        if (order != null && order.getTemplateId() != null && order.getTemplateVersion() != null) {
            java.util.Optional<com.provaluer.model.TemplateVersion> versionOpt = templateVersionRepository.findByTemplateIdAndVersion(order.getTemplateId(), order.getTemplateVersion());
            if (versionOpt.isPresent() && versionOpt.get().getTemplateContent() != null && versionOpt.get().getTemplateContent().length > 0) {
                return versionOpt.get().getTemplateContent();
            }
        }
        if (fallbackTemplate != null && fallbackTemplate.getTemplateContent() != null && fallbackTemplate.getTemplateContent().length > 0) {
            return fallbackTemplate.getTemplateContent();
        }
        if (order != null && order.getTemplateId() != null) {
            return templateRepository.findById(order.getTemplateId())
                    .map(Template::getTemplateContent)
                    .orElse(null);
        }
        return null;
    }

    /**
     * GET /api/v1/orders/{id}/document-workspace
     * Pure, instantaneous workspace data endpoint returning documentDom, placeholders, values, and sections.
     * Completely decoupled from PDF and visual image preview generation.
     */
    @Transactional
    public DocumentWorkspaceResponse getDocumentWorkspace(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "VIEW");

        Long templateId = order.getTemplateId();
        if (templateId == null) {
            // Find active template as default fallback
            List<Template> activeTemplates = templateRepository.findAllByIsActive("Y");
            if (!activeTemplates.isEmpty()) {
                Template fallback = activeTemplates.get(0);
                templateId = fallback.getId();
                order.setTemplateId(templateId);
            } else {
                throw new IllegalStateException("No active valuation template available for this order");
            }
        }
        final Long effectiveTemplateId = templateId;

        Template template = templateRepository.findById(effectiveTemplateId)
                .orElse(null);

        // 1. Template Version Snapshot Resolution (Option A Mandate):
        //    Historical reports are permanently bound to their immutable version snapshot.
        byte[] docxBytes = resolveOrderTemplateBytes(order, template);
        if (docxBytes == null || docxBytes.length == 0) {
            throw new IllegalStateException("Template has no binary document content for order #" + orderId);
        }

        if (order.getTemplateVersion() == null && template != null) {
            order.setTemplateVersion(template.getVersion());
        }
        if (order.getTemplateVersionId() == null) {
            List<com.provaluer.model.TemplateVersion> versions = templateVersionRepository.findAllByTemplateIdOrderByVersionDesc(effectiveTemplateId);
            for (com.provaluer.model.TemplateVersion v : versions) {
                if (order.getTemplateVersion() != null && v.getVersion() == order.getTemplateVersion()) {
                    order.setTemplateVersionId(v.getId());
                    break;
                }
            }
            if (order.getTemplateVersionId() == null && !versions.isEmpty()) {
                order.setTemplateVersionId(versions.get(0).getId());
            }
            orderRepository.save(order);
        }

        // 2. DOM Snapshot Management (Option A Mandate):
        //    Once created, an order's DOM snapshot is irrevocable and NEVER invalidated by subsequent template updates.
        if (order.getDocumentDomSnapshot() == null || order.getDocumentDomSnapshot().trim().isEmpty()) {
            try {
                JsonNode domNode = docxStructureParser.parseDocumentStructure(docxBytes);
                order.setDocumentDomSnapshot(domNode.toString());
                orderRepository.save(order);
            } catch (Exception e) {
                log.warn("Failed to generate document DOM snapshot on the fly: {}", e.getMessage());
            }
        }

        // 2. Pure lightweight visual preview stub (decoupled from workspace data loading)
        VisualPreviewResponse visualPreview = new VisualPreviewResponse(
                effectiveTemplateId,
                0,
                new VisualPreviewResponse.PageDimensions(595, 842, 0.707),
                Collections.emptyList()
        );

        // 3. Assemble Consolidated Values Map
        Map<String, String> valuesMap = getConsolidatedValues(orderId);

        // Auto-populate default fields if absent
        if (!valuesMap.containsKey("CLIENT_NAME") && order.getClientName() != null) {
            valuesMap.put("CLIENT_NAME", order.getClientName());
        }
        if (!valuesMap.containsKey("BANK_NAME") && order.getBankName() != null) {
            valuesMap.put("BANK_NAME", order.getBankName());
        }
        if (!valuesMap.containsKey("BRANCH_NAME") && order.getBranchName() != null) {
            valuesMap.put("BRANCH_NAME", order.getBranchName());
        }

        // 4. Determine Read-Only Status
        boolean isSpaOrAdmin = principal.getAuthorities().stream().anyMatch(
                a -> a.getAuthority().equals("ROLE_SPA") || a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
        boolean readOnly = false;
        boolean isLockedOrFinalized = "FINAL_DELIVERY".equalsIgnoreCase(order.getStatus())
                || "SPA_CONFIRMED".equalsIgnoreCase(order.getStatus())
                || "FINALIZED".equalsIgnoreCase(order.getValuationStatus())
                || "LOCKED".equalsIgnoreCase(order.getValuationStatus());

        if (isLockedOrFinalized && !isSpaOrAdmin) {
            readOnly = true;
        } else if ("FINAL_DELIVERY".equalsIgnoreCase(order.getStatus())) {
            readOnly = true;
        }

        // 5. Hydrate semantic Document DOM for Table-Driven Workspace
        JsonNode domNode = null;
        if (order.getDocumentDomSnapshot() != null && !order.getDocumentDomSnapshot().trim().isEmpty()) {
            try {
                domNode = objectMapper.readTree(order.getDocumentDomSnapshot());
            } catch (Exception e) {
                log.warn("Failed to parse documentDomSnapshot JSON for order {}: {}", orderId, e.getMessage());
            }
        }
        if (domNode == null && template.getDocumentDom() != null && !template.getDocumentDom().trim().isEmpty()) {
            try {
                domNode = objectMapper.readTree(template.getDocumentDom());
            } catch (Exception e) {
                log.warn("Failed to parse template documentDom JSON for template {}: {}", templateId, e.getMessage());
            }
        }

        // Apply Hierarchical Text Overrides: SPA Order Override > Super Admin Template Override > Dictionary Baseline
        Map<String, String> effectiveOverrides = getEffectiveTextOverrides(order, effectiveTemplateId);
        if (domNode != null && !effectiveOverrides.isEmpty()) {
            domNode = applyTextOverridesToDom(domNode, effectiveOverrides);
        }

        // Self-Healing Migration: Normalize stale COMPOSITE_PROPERTY_TABLE snapshots
        if (domNode != null) {
            boolean snapshotModified = normalizeCompositeTableSnapshots(domNode, orderId);
            if (snapshotModified && order.getDocumentDomSnapshot() != null) {
                order.setDocumentDomSnapshot(domNode.toString());
                orderRepository.save(order);
            }
        }

        return new DocumentWorkspaceResponse(
                order.getId(),
                order.getStatus(),
                order.getReportNumber(),
                visualPreview,
                valuesMap,
                readOnly,
                domNode
        );
    }

    /**
     * SPA Order-level text override persistence.
     */
    @Transactional
    public Map<String, Object> saveOrderTextOverrides(Long orderId, Map<String, String> overrides, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "APPROVE");

        try {
            String json = objectMapper.writeValueAsString(overrides != null ? overrides : Collections.emptyMap());
            order.setFieldMappingSnapshot(json);
            order.setUpdatedAt(LocalDateTime.now());
            orderRepository.save(order);
            log.info("SPA user #{} saved {} order-level text overrides for order #{}", principal.getId(), overrides != null ? overrides.size() : 0, orderId);
        } catch (Exception e) {
            log.error("Failed to serialize order text overrides for order #{}: {}", orderId, e.getMessage());
            throw new RuntimeException("Failed to save text overrides: " + e.getMessage());
        }

        return Map.of("orderId", orderId, "status", "SUCCESS", "overridesCount", overrides != null ? overrides.size() : 0);
    }

    public Map<String, String> getEffectiveTextOverrides(Order order, Long templateId) {
        Map<String, String> result = new LinkedHashMap<>();

        // 1. Template Question Dictionary baseline
        try {
            List<TemplateQuestion> questions = templateQuestionRepository.findAll();
            for (TemplateQuestion tq : questions) {
                if (tq.getQuestionText() != null && !tq.getQuestionText().trim().isEmpty()) {
                    result.put(tq.getPlaceholderKey().toUpperCase(), tq.getQuestionText().trim());
                }
            }
        } catch (Exception e) {
            log.warn("Could not query template_questions_dictionary: {}", e.getMessage());
        }

        // 2. Super Admin Template-level Override (DocumentStudioConfig.customLabels)
        if (templateId != null) {
            try {
                Optional<DocumentStudioConfig> studioConfigOpt = studioConfigRepository.findByTemplateId(templateId);
                if (studioConfigOpt.isPresent()) {
                    String customLabelsJson = studioConfigOpt.get().getCustomLabels();
                    if (customLabelsJson != null && !customLabelsJson.trim().isEmpty()) {
                        JsonNode root = objectMapper.readTree(customLabelsJson);
                        if (root.isObject()) {
                            Iterator<Map.Entry<String, JsonNode>> fields = root.fields();
                            while (fields.hasNext()) {
                                Map.Entry<String, JsonNode> field = fields.next();
                                String k = field.getKey().toUpperCase().trim();
                                JsonNode v = field.getValue();
                                String text = v.isObject() && v.has("label") ? v.get("label").asText() : v.asText();
                                if (text != null && !text.trim().isEmpty()) {
                                    result.put(k, text.trim());
                                }
                            }
                        }
                    }
                }
            } catch (Exception e) {
                log.warn("Could not read studio customLabels for template {}: {}", templateId, e.getMessage());
            }
        }

        // 3. SPA Order-level Override (Order.fieldMappingSnapshot)
        if (order != null && order.getFieldMappingSnapshot() != null && !order.getFieldMappingSnapshot().trim().isEmpty()) {
            try {
                JsonNode root = objectMapper.readTree(order.getFieldMappingSnapshot());
                if (root.isObject()) {
                    Iterator<Map.Entry<String, JsonNode>> fields = root.fields();
                    while (fields.hasNext()) {
                        Map.Entry<String, JsonNode> field = fields.next();
                        String k = field.getKey().toUpperCase().trim();
                        JsonNode v = field.getValue();
                        String text = v.isObject() && v.has("label") ? v.get("label").asText() : v.asText();
                        if (text != null && !text.trim().isEmpty()) {
                            result.put(k, text.trim()); // SPA overrides template & dictionary!
                        }
                    }
                }
            } catch (Exception e) {
                log.warn("Could not parse SPA order text overrides for order {}: {}", order.getId(), e.getMessage());
            }
        }

        return result;
    }

    public JsonNode applyTextOverridesToDom(JsonNode domNode, Map<String, String> overrides) {
        if (domNode == null || overrides == null || overrides.isEmpty()) return domNode;
        try {
            com.fasterxml.jackson.databind.node.ObjectNode root = (com.fasterxml.jackson.databind.node.ObjectNode) domNode;

            // 1. Update placeholdersSummary
            if (root.has("placeholdersSummary")) {
                com.fasterxml.jackson.databind.node.ArrayNode summaryArray = (com.fasterxml.jackson.databind.node.ArrayNode) root.get("placeholdersSummary");
                for (JsonNode itemNode : summaryArray) {
                    if (itemNode.isObject()) {
                        com.fasterxml.jackson.databind.node.ObjectNode item = (com.fasterxml.jackson.databind.node.ObjectNode) itemNode;
                        String key = item.path("key").asText().toUpperCase();
                        if (overrides.containsKey(key)) {
                            String newText = overrides.get(key);
                            item.put("questionText", newText);
                            item.put("label", newText);
                        }
                    }
                }
            }

            // 2. Update Table Rows / Q&A placeholderBindings and Question Cells
            if (root.has("sections")) {
                for (JsonNode sectionNode : root.get("sections")) {
                    if (sectionNode.has("elements")) {
                        for (JsonNode elemNode : sectionNode.get("elements")) {
                            if ("TABLE".equalsIgnoreCase(elemNode.path("type").asText()) && elemNode.has("rows")) {
                                for (JsonNode rowNode : elemNode.get("rows")) {
                                    if (rowNode.has("cells")) {
                                        for (JsonNode cellNode : rowNode.get("cells")) {
                                            if (cellNode.has("placeholderBindings")) {
                                                for (JsonNode bindingNode : cellNode.get("placeholderBindings")) {
                                                    if (bindingNode.isObject()) {
                                                        com.fasterxml.jackson.databind.node.ObjectNode b = (com.fasterxml.jackson.databind.node.ObjectNode) bindingNode;
                                                        String k = b.path("key").asText().toUpperCase();
                                                        if (overrides.containsKey(k)) {
                                                            b.put("questionText", overrides.get(k));
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.warn("Failed to apply text overrides to DOM: {}", e.getMessage());
        }
        return domNode;
    }

    /**
     * POST /api/v1/orders/{id}/save-document-values
     */
    @Transactional
    public Map<String, String> saveDocumentValues(Long orderId, SaveDocumentValuesRequest request, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "SAVE");

        if (request != null && request.getValues() != null) {
            Map<String, String> expandedInputs = new HashMap<>(request.getValues());

            // Phase 4B: Value Normalization Engine & Dual Value Model storage
            for (Map.Entry<String, String> entry : request.getValues().entrySet()) {
                String k = entry.getKey();
                String v = entry.getValue();
                if (v != null && !v.startsWith("data:image")) {
                    if (com.provaluer.util.ValueNormalizationEngine.isSupported(k)) {
                        try {
                            com.provaluer.util.ValueNormalizationEngine.DualValueResult dual = 
                                    com.provaluer.util.ValueNormalizationEngine.createDualValueResult(k, v);
                            expandedInputs.putAll(dual.getValuesToStore());
                        } catch (Exception ignored) {
                            // Non-numeric or invalid entries remain in raw format
                        }
                    }
                }
            }

            Map<String, String> existingValues = getConsolidatedValues(orderId);
            existingValues.putAll(expandedInputs);

            // 1. Update orders.input_values JSON column
            try {
                // Filter out large base64 strings from jsonb column to keep record light
                Map<String, String> textValuesOnly = new HashMap<>();
                for (Map.Entry<String, String> entry : existingValues.entrySet()) {
                    if (entry.getValue() != null && !entry.getValue().startsWith("data:image")) {
                        textValuesOnly.put(entry.getKey(), entry.getValue());
                    }
                }
                order.setInputValues(objectMapper.writeValueAsString(textValuesOnly));
            } catch (Exception e) {
                log.warn("Failed to serialize input values JSON: {}", e.getMessage());
            }
            orderRepository.save(order);

            // 2. Persist to order_inputs table for hydration & image binary persistence
            for (Map.Entry<String, String> entry : expandedInputs.entrySet()) {
                saveOrUpdateInput(orderId, entry.getKey(), entry.getValue());
            }
        }

        return Map.of("status", "SAVED");
    }

    /**
     * POST /api/v1/orders/{id}/submit-to-spa
     */
    @Transactional
    public Map<String, String> submitToSpa(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "SUBMIT_TO_SPA");

        boolean wasAlreadyInSpaGate = "SPA_GATE".equalsIgnoreCase(order.getStatus());
        order.setStatus("SPA_GATE");
        order.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(order);

        // Audit Logging for submission / resubmission
        String actionType = wasAlreadyInSpaGate ? "PA_RESUBMITTED" : "PA_SUBMITTED";
        String description = wasAlreadyInSpaGate
                ? "PA resubmitted updated report draft to SPA review queue"
                : "PA submitted report draft to SPA review queue";
        try {
            Long actorId = principal != null ? principal.getId() : null;
            String actorEmail = principal != null ? principal.getEmail() : "PA";
            auditLogService.log(
                    actorId,
                    actorEmail,
                    "ROLE_PA",
                    actionType,
                    "ORDER",
                    String.valueOf(orderId),
                    description
            );
        } catch (Exception e) {
            log.warn("Failed to create audit log for order #{}: {}", orderId, e.getMessage());
        }

        return Map.of("status", "SPA_GATE");
    }

    /**
     * POST /api/v1/orders/{id}/spa-approve
     */
    @Transactional
    public Map<String, Object> spaApprove(Long orderId, SpaApproveDocumentRequest request, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "APPROVE");

        // 1. Save modified values if provided
        if (request != null && request.getModifiedValues() != null) {
            for (Map.Entry<String, String> entry : request.getModifiedValues().entrySet()) {
                saveOrUpdateInput(orderId, entry.getKey(), entry.getValue());
            }
        }

        if (request != null && request.getFinalValue() != null) {
            order.setFinalValue(request.getFinalValue());
        }

        // 2. Pricing and balance calculations
        BigDecimal chargedFee = pricingService.calculateFee(order.getPurpose(), order.getEstimatedValue(), order.getFinalValue());
        order.setFeeCharged(chargedFee);
        order.setBalanceDue(BigDecimal.ZERO);

        // 3. Hydrate Original DOCX and Generate Final PDF
        Long templateId = order.getTemplateId();
        if (templateId != null) {
            Template template = templateRepository.findById(templateId).orElse(null);
            byte[] tplBytes = resolveOrderTemplateBytes(order, template);
            if (tplBytes != null && tplBytes.length > 0) {
                try {
                    Map<String, String> inputsMap = getConsolidatedValues(orderId);
                    Map<String, byte[]> imagesMap = new HashMap<>();
                    List<OrderInput> inputsList = orderInputRepository.findAllByOrderId(orderId);
                    for (OrderInput input : inputsList) {
                        String key = input.getFieldKey().toUpperCase();
                        String val = input.getFieldValue();
                        if ((key.contains("DATE_") || key.contains("_DATE") || key.equals("DATE")) && (val == null || val.trim().isEmpty())) {
                            inputsMap.put(key, java.time.LocalDate.now().format(DateTimeFormatter.ofPattern("dd-MM-yyyy")));
                        }
                        if (input.getImageValue() != null) {
                            imagesMap.put(key, input.getImageValue());
                        }
                    }

                    // Hydrate DOCX
                    byte[] docxBytes = docxTemplateEngine.generateReport(tplBytes, inputsMap, imagesMap);
                    
                    // Stamp digital signature and convert to PDF
                    String signerName = principal != null ? principal.getUsername() : "Senior Property Analyst (SPA)";
                    String timestamp = LocalDateTime.now().toString();
                    byte[] signedDocxBytes = docxTemplateEngine.stampDigitalSignature(docxBytes, signerName, timestamp);
                    byte[] pdfBytes = docxTemplateEngine.convertDocxToPdf(signedDocxBytes);

                    // Save as final documents
                    User uploader = principal != null ? userRepository.findById(principal.getId()).orElse(null) : null;
                    if (uploader != null) {
                        saveOrderDocument(order, "FINAL_DOCX", "Report_" + orderId + ".docx", signedDocxBytes, uploader);
                        saveOrderDocument(order, "FINAL_SIGNED_PDF", "Report_" + orderId + ".pdf", pdfBytes, uploader);
                    }
                } catch (Exception e) {
                    log.error("Failed to compile final report during SPA approval: {}", e.getMessage(), e);
                }
            }
        }

        order.setStatus("SPA_CONFIRMED");
        orderRepository.save(order);

        Map<String, Object> result = new HashMap<>();
        result.put("status", "SPA_CONFIRMED");
        result.put("finalValue", order.getFinalValue());
        result.put("feeCharged", order.getFeeCharged());
        return result;
    }

    /**
     * POST /api/v1/orders/{id}/compile-live-preview
     * TASK 4: Reuses cached preview if document values and template are unchanged.
     * Only regenerates and re-renders when values or template actually change.
     */
    @Transactional
    public VisualPreviewResponse compileLivePreview(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "VIEW");

        Long templateId = order.getTemplateId();
        if (templateId == null) {
            throw new IllegalStateException("Order has no assigned template");
        }

        Template template = templateRepository.findById(templateId).orElse(null);
        byte[] tplBytes = resolveOrderTemplateBytes(order, template);
        if (tplBytes == null || tplBytes.length == 0) {
            throw new IllegalStateException("Template has no binary document content for live preview of order #" + orderId);
        }

        Map<String, String> inputsMap = getConsolidatedValues(orderId);
        Map<String, byte[]> imagesMap = new HashMap<>();
        List<OrderInput> inputsList = orderInputRepository.findAllByOrderId(orderId);
        for (OrderInput input : inputsList) {
            if (input.getImageValue() != null) {
                imagesMap.put(input.getFieldKey().toUpperCase(), input.getImageValue());
            }
        }

        int effectiveVersion = order.getTemplateVersion() != null ? order.getTemplateVersion() : (template != null ? template.getVersion() : 1);
        String contentHash = computePreviewContentHash(templateId, effectiveVersion, inputsMap, imagesMap);

        // 1. In-memory Cache Check
        CachedOrderPreview cached = orderPreviewCache.get(orderId);
        if (cached != null && cached.contentHash.equals(contentHash)) {
            log.info("Serving in-memory cached live preview for order #{} (hash: {})", orderId, contentHash);
            return cached.response;
        }

        // 2. Disk Cache Check
        Path hashCacheDir = Paths.get("storage/preview-cache", "order_" + orderId + "_hash_" + contentHash);
        if (Files.isDirectory(hashCacheDir) && previewGenerator.isCacheValid(hashCacheDir)) {
            DocxPreviewGenerator.PreviewMetadata cachedMeta = previewGenerator.loadMetadataFromCache(templateId, hashCacheDir);
            if (cachedMeta != null) {
                List<VisualPreviewResponse.VisualPage> pages = new ArrayList<>();
                for (int i = 0; i < cachedMeta.getTotalPages(); i++) {
                    pages.add(new VisualPreviewResponse.VisualPage(
                            i,
                            "/api/v1/orders/" + orderId + "/live-preview/" + contentHash + "/pages/" + i + ".png",
                            Collections.emptyList()
                    ));
                }
                VisualPreviewResponse cachedResponse = new VisualPreviewResponse(
                        templateId,
                        contentHash,
                        cachedMeta.getTotalPages(),
                        new VisualPreviewResponse.PageDimensions(cachedMeta.getWidthPt(), cachedMeta.getHeightPt(), cachedMeta.getAspectRatio()),
                        pages
                );
                orderPreviewCache.put(orderId, new CachedOrderPreview(contentHash, cachedResponse));
                log.info("Serving disk-cached live preview for order #{} (hash: {})", orderId, contentHash);
                return cachedResponse;
            }
        }

        // 3. Cache Miss: Perform DOCX hydration, PDF conversion, and image rendering
        byte[] hydratedDocx;
        try {
            hydratedDocx = docxTemplateEngine.generateReport(tplBytes, inputsMap, imagesMap);
        } catch (Exception e) {
            log.error("Failed to hydrate template DOCX for live preview: {}", e.getMessage(), e);
            throw new IllegalStateException("Failed to generate live preview report: " + e.getMessage(), e);
        }
        byte[] pdfBytes = previewGenerator.convertDocxToPdf(templateId, hydratedDocx);

        try {
            Files.createDirectories(hashCacheDir);
        } catch (Exception e) {
            log.error("Failed to create live preview cache directory: {}", e.getMessage());
        }

        DocxPreviewGenerator.PreviewMetadata metadata = previewGenerator.renderPdfToImages(templateId, pdfBytes, hashCacheDir);

        List<VisualPreviewResponse.VisualPage> pages = new ArrayList<>();
        for (int i = 0; i < metadata.getTotalPages(); i++) {
            pages.add(new VisualPreviewResponse.VisualPage(
                    i,
                    "/api/v1/orders/" + orderId + "/live-preview/" + contentHash + "/pages/" + i + ".png",
                    Collections.emptyList()
            ));
        }

        VisualPreviewResponse generatedResponse = new VisualPreviewResponse(
                templateId,
                contentHash,
                metadata.getTotalPages(),
                new VisualPreviewResponse.PageDimensions(metadata.getWidthPt(), metadata.getHeightPt(), metadata.getAspectRatio()),
                pages
        );

        orderPreviewCache.put(orderId, new CachedOrderPreview(contentHash, generatedResponse));
        return generatedResponse;
    }

    /**
     * GET /api/v1/orders/{id}/live-preview/{previewSessionId}/pages/{pageIndex}.png
     */
    public byte[] getLivePreviewSessionPageImage(Long orderId, String previewSessionId, int pageIndex) {
        Path imagePath = Paths.get("storage/preview-cache", "order_" + orderId + "_hash_" + previewSessionId, "page_" + pageIndex + ".png");
        if (!Files.exists(imagePath)) {
            imagePath = Paths.get("storage/preview-cache", "order_" + orderId + "_live_" + previewSessionId, "page_" + pageIndex + ".png");
        }
        if (!Files.exists(imagePath)) {
            // Fallback check to unversioned live directory if present
            Path fallbackPath = Paths.get("storage/preview-cache", "order_" + orderId + "_live", "page_" + pageIndex + ".png");
            if (Files.exists(fallbackPath)) {
                imagePath = fallbackPath;
            } else {
                throw new NoSuchElementException("Live preview image not found for order #" + orderId + " session " + previewSessionId + " page " + pageIndex);
            }
        }
        try {
            return Files.readAllBytes(imagePath);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to read live page image: " + e.getMessage(), e);
        }
    }

    /**
     * Backward-compatible fallback for unversioned live page image endpoint.
     */
    public byte[] getLivePageImage(Long orderId, int pageIndex) {
        Path imagePath = Paths.get("storage/preview-cache", "order_" + orderId + "_live", "page_" + pageIndex + ".png");
        if (!Files.exists(imagePath)) {
            throw new NoSuchElementException("Live preview image not found for order #" + orderId + " page " + pageIndex);
        }
        try {
            return Files.readAllBytes(imagePath);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to read live page image: " + e.getMessage(), e);
        }
    }

    private void saveOrderDocument(Order order, String category, String filename, byte[] content, User uploader) {
        List<OrderDocument> existingDocs = orderDocumentRepository.findAllByOrderId(order.getId());
        OrderDocument doc = existingDocs.stream()
                .filter(d -> category.equalsIgnoreCase(d.getCategory()))
                .findFirst()
                .orElseGet(() -> {
                    OrderDocument newDoc = new OrderDocument();
                    newDoc.setOrder(order);
                    newDoc.setCategory(category);
                    newDoc.setUploadedBy(uploader);
                    return newDoc;
                });

        doc.setFilename(filename);
        doc.setFileContent(content);
        orderDocumentRepository.save(doc);
    }

    public Map<String, String> getConsolidatedValues(Long orderId) {
        Map<String, String> map = new HashMap<>();
        List<OrderInput> inputs = orderInputRepository.findAllByOrderId(orderId);
        for (OrderInput input : inputs) {
            if (input.getImageValue() != null) {
                String base64Data = "data:image/png;base64," + Base64.getEncoder().encodeToString(input.getImageValue());
                map.put(input.getFieldKey(), base64Data);
            } else {
                map.put(input.getFieldKey(), input.getFieldValue());
            }
        }

        // Merge Valuation Engine Placeholders as fallback / bundle computation
        try {
            com.provaluer.dto.ValuationBundleResponse valBundle = valuationEngineService.getValuationBundle(orderId);
            if (valBundle != null && valBundle.getPlaceholders() != null) {
                for (Map.Entry<String, String> entry : valBundle.getPlaceholders().entrySet()) {
                    String k = entry.getKey();
                    String v = entry.getValue();
                    String existing = map.get(k);

                    boolean isExistingEmptyOrZero = (existing == null || existing.trim().isEmpty()
                            || existing.trim().equals("0") || existing.trim().equals("0.0") || existing.trim().equals("0.00")
                            || existing.trim().equals("₹ 0") || existing.trim().equals("₹ 0.00") || existing.trim().equals("INR 0")
                            || existing.trim().equalsIgnoreCase("Rupees Zero Only") || existing.trim().equalsIgnoreCase("Zero"));

                    if (!map.containsKey(k) || isExistingEmptyOrZero) {
                        if (v != null && !v.trim().isEmpty()) {
                            map.put(k, v);
                        } else if (!map.containsKey(k)) {
                            map.put(k, "");
                        }
                    }
                }

                // Serialized RAW items for Dynamic DOCX repeating tables
                if (valBundle.getLandItems() != null && !valBundle.getLandItems().isEmpty()) {
                    map.put("RAW_LAND_ITEMS_JSON", objectMapper.writeValueAsString(valBundle.getLandItems()));
                }
                if (valBundle.getBuildingItems() != null && !valBundle.getBuildingItems().isEmpty()) {
                    map.put("RAW_BUILDING_ITEMS_JSON", objectMapper.writeValueAsString(valBundle.getBuildingItems()));
                }
                if (valBundle.getComparableSales() != null && !valBundle.getComparableSales().isEmpty()) {
                    map.put("RAW_COMPARABLES_JSON", objectMapper.writeValueAsString(valBundle.getComparableSales()));
                }
                if (valBundle.getCompositeItems() != null && !valBundle.getCompositeItems().isEmpty()) {
                    map.put("RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(valBundle.getCompositeItems()));
                }
            }
        } catch (Exception e) {
            log.warn("Could not merge valuation bundle into consolidated values for order #{}: {}", orderId, e.getMessage());
        }

        return map;
    }

    private void saveOrUpdateInput(Long orderId, String key, String value) {
        Optional<OrderInput> existing = orderInputRepository.findByOrderIdAndFieldKey(orderId, key);
        OrderInput field = existing.orElseGet(() -> new OrderInput(orderId, key, ""));

        if (value != null && value.startsWith("data:image/") && value.contains(";base64,")) {
            try {
                String base64Data = value.substring(value.indexOf(";base64,") + 8);
                byte[] bytes = Base64.getDecoder().decode(base64Data);
                field.setImageValue(bytes);
                field.setFieldValue("[IMAGE]");
            } catch (Exception e) {
                field.setFieldValue(value);
            }
        } else {
            field.setFieldValue(value != null ? value : "");
            field.setImageValue(null);
        }
        orderInputRepository.save(field);
    }

    /**
     * POST /api/v1/admin/dom-snapshot-audit
     *
     * Audits every order's documentDomSnapshot against its template version.
     * Stale or missing snapshots are rebuilt from the live DOCX binary.
     * Returns per-order audit rows with version information and image placeholder verification.
     */
    @Transactional
    public Map<String, Object> auditAndRebuildDomSnapshots() {
        List<Order> allOrders = orderRepository.findAll();
        List<Map<String, Object>> rows = new ArrayList<>();

        // Image keys to verify
        List<String> IMAGE_KEYS = List.of(
                "IMG_FRONT_PAGE",
                "IMG_PIC1", "IMG_PIC2", "IMG_PIC3", "IMG_PIC4",
                "IMG_PIC5", "IMG_PIC6", "IMG_PIC7", "IMG_PIC8"
        );

        int rebuiltCount = 0;

        // Cache templates fetched during this run
        Map<Long, Template> templateCache = new LinkedHashMap<>();

        for (Order order : allOrders) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("orderId", order.getId());
            row.put("reportNumber", order.getReportNumber());
            row.put("status", order.getStatus());

            Long tplId = order.getTemplateId();
            if (tplId == null) {
                // Fall back to any active template
                List<Template> active = templateRepository.findAllByIsActive("Y");
                if (!active.isEmpty()) {
                    tplId = active.get(0).getId();
                    order.setTemplateId(tplId);
                }
            }

            if (tplId == null) {
                row.put("templateId", null);
                row.put("templateVersion", null);
                row.put("snapshotVersion", order.getTemplateVersion());
                row.put("action", "SKIPPED – no template assigned");
                rows.add(row);
                continue;
            }

            Template template = templateCache.computeIfAbsent(tplId, id ->
                    templateRepository.findById(id).orElse(null));

            if (template == null || template.getTemplateContent() == null || template.getTemplateContent().length == 0) {
                row.put("templateId", tplId);
                row.put("templateVersion", null);
                row.put("snapshotVersion", order.getTemplateVersion());
                row.put("action", "SKIPPED – template has no binary content");
                rows.add(row);
                continue;
            }

            int currentTemplateVersion = template.getVersion();
            Integer snapshotVersion = order.getTemplateVersion();

            row.put("templateId", tplId);
            row.put("templateVersion", currentTemplateVersion);
            row.put("snapshotVersion", snapshotVersion);

            boolean snapshotMissing = order.getDocumentDomSnapshot() == null
                    || order.getDocumentDomSnapshot().trim().isEmpty();
            boolean versionMismatch = snapshotVersion == null || !snapshotVersion.equals(currentTemplateVersion);
            boolean needsRebuild = snapshotMissing || versionMismatch;

            row.put("snapshotMissing", snapshotMissing);
            row.put("versionMismatch", versionMismatch);

            if (needsRebuild) {
                try {
                    JsonNode domNode = docxStructureParser.parseDocumentStructure(template.getTemplateContent());
                    String domJson = domNode.toString();

                    order.setDocumentDomSnapshot(domJson);
                    order.setTemplateVersion(currentTemplateVersion);
                    orderRepository.save(order);

                    // Also update template-level cached DOM
                    template.setDocumentDom(domJson);
                    template.setPlaceholderRegistry(docxStructureParser.generatePlaceholderRegistry(domNode));
                    templateCache.put(tplId, template); // keep in-memory cache updated

                    // Verify image placeholders
                    Map<String, Boolean> imgPresence = new LinkedHashMap<>();
                    for (String key : IMAGE_KEYS) {
                        imgPresence.put(key, domJson.contains("\"" + key + "\""));
                    }
                    long foundCount = imgPresence.values().stream().filter(v -> v).count();

                    row.put("action", "REBUILT");
                    row.put("imagePlaceholders", imgPresence);
                    row.put("imageKeysFound", foundCount + "/" + IMAGE_KEYS.size());
                    rebuiltCount++;
                } catch (Exception e) {
                    row.put("action", "ERROR – " + e.getMessage());
                    row.put("imagePlaceholders", Collections.emptyMap());
                }
            } else {
                // Already up to date – just verify what's in the existing snapshot
                String domJson = order.getDocumentDomSnapshot();
                Map<String, Boolean> imgPresence = new LinkedHashMap<>();
                for (String key : IMAGE_KEYS) {
                    imgPresence.put(key, domJson.contains("\"" + key + "\""));
                }
                long foundCount = imgPresence.values().stream().filter(v -> v).count();

                row.put("action", "OK – snapshot current");
                row.put("imagePlaceholders", imgPresence);
                row.put("imageKeysFound", foundCount + "/" + IMAGE_KEYS.size());
            }

            rows.add(row);
        }

        // Flush updated templates to DB in one pass
        templateCache.values().forEach(t -> {
            if (t.getDocumentDom() != null) templateRepository.save(t);
        });

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("totalOrders", allOrders.size());
        result.put("rebuiltCount", rebuiltCount);
        result.put("orders", rows);
        return result;
    }

    private static boolean isCompositeTableKey(String key) {
        if (key == null) return false;
        String clean = key.replaceAll("<<", "").replaceAll(">>", "").trim().toUpperCase();
        return clean.equals("COMPOSITE_PROPERTY_TABLE")
                || clean.equals("DYNAMIC_COMPOSITE_PROPERTY_TABLE")
                || clean.equals("COMPOSITE_TABLE");
    }

    private boolean normalizeCompositeTableSnapshots(JsonNode rootNode, Long orderId) {
        if (rootNode == null) return false;
        boolean modified = false;

        List<com.fasterxml.jackson.databind.node.ObjectNode> nodesToExamine = new ArrayList<>();
        collectAllObjectNodes(rootNode, nodesToExamine);

        for (com.fasterxml.jackson.databind.node.ObjectNode node : nodesToExamine) {
            String key = null;
            if (node.has("key") && !node.get("key").isNull()) {
                key = node.get("key").asText();
            } else if (node.has("placeholderKey") && !node.get("placeholderKey").isNull()) {
                key = node.get("placeholderKey").asText();
            }

            if (isCompositeTableKey(key)) {
                // Normalize fieldType property (used in table cell placeholderBindings)
                if (node.has("fieldType")) {
                    String currentFieldType = node.get("fieldType").asText();
                    if (!"DYNAMIC_COMPOSITE_PROPERTY_TABLE".equalsIgnoreCase(currentFieldType)) {
                        node.put("fieldType", "DYNAMIC_COMPOSITE_PROPERTY_TABLE");
                        modified = true;
                        log.info(
                                "Self-healed composite table snapshot. OrderId={}, OldType={}, NewType={}",
                                orderId,
                                currentFieldType,
                                "DYNAMIC_COMPOSITE_PROPERTY_TABLE"
                        );
                    }
                }

                // Normalize type property (used in placeholdersSummary items)
                if (node.has("type")) {
                    String currentType = node.get("type").asText();
                    if (!"DYNAMIC_COMPOSITE_PROPERTY_TABLE".equalsIgnoreCase(currentType)) {
                        node.put("type", "DYNAMIC_COMPOSITE_PROPERTY_TABLE");
                        modified = true;
                        log.info(
                                "Self-healed composite table snapshot. OrderId={}, OldType={}, NewType={}",
                                orderId,
                                currentType,
                                "DYNAMIC_COMPOSITE_PROPERTY_TABLE"
                        );
                    }
                }
            }
        }

        return modified;
    }

    private void collectAllObjectNodes(JsonNode current, List<com.fasterxml.jackson.databind.node.ObjectNode> list) {
        if (current == null) return;
        if (current.isObject()) {
            list.add((com.fasterxml.jackson.databind.node.ObjectNode) current);
            Iterator<JsonNode> elements = current.elements();
            while (elements.hasNext()) {
                collectAllObjectNodes(elements.next(), list);
            }
        } else if (current.isArray()) {
            for (JsonNode child : current) {
                collectAllObjectNodes(child, list);
            }
        }
    }
}

