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
            if (order.getPaId() != null && order.getPaId().equals(principal.getId())) {
                return;
            }
            throw new AccessDeniedException("Access denied: You are not the assigned Property Analyst for Order #" + order.getId());
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
                .orElseThrow(() -> new NoSuchElementException("Template not found with ID: " + effectiveTemplateId));

        byte[] docxBytes = template.getTemplateContent();
        if (docxBytes == null || docxBytes.length == 0) {
            throw new IllegalStateException("Template has no binary document content");
        }

        // 1. Dom Snapshot Management:
        //    If the template has been updated (version changed), invalidate the stale cached snapshot
        //    and force a re-parse from the live DOCX binary. This ensures new placeholders (e.g.
        //    image placeholders like IMG_FRONT_PAGE, IMG_PIC3) are always reflected in the workspace.
        boolean templateVersionChanged = order.getTemplateVersion() != null
                && !order.getTemplateVersion().equals(template.getVersion());
        if (templateVersionChanged) {
            log.info("Template version changed for order #{}: v{} -> v{}. Invalidating stale documentDomSnapshot.",
                    orderId, order.getTemplateVersion(), template.getVersion());
            order.setDocumentDomSnapshot(null);
            order.setTemplateVersion(template.getVersion());
        }
        if (order.getTemplateVersion() == null) {
            order.setTemplateVersion(template.getVersion());
        }
        if (order.getDocumentDomSnapshot() == null) {
            try {
                // Always re-parse from live DOCX binary (not the stale template.documentDom column)
                // so that any new placeholders added to the DOCX are captured.
                JsonNode domNode = docxStructureParser.parseDocumentStructure(docxBytes);
                order.setDocumentDomSnapshot(domNode.toString());
                template.setDocumentDom(domNode.toString());
                template.setPlaceholderRegistry(docxStructureParser.generatePlaceholderRegistry(domNode));
                templateRepository.save(template);
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
        if ("FINAL_DELIVERY".equals(order.getStatus())) {
            readOnly = true;
        } else if ("SPA_CONFIRMED".equals(order.getStatus()) && !isSpaOrAdmin) {
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
            Map<String, String> existingValues = getConsolidatedValues(orderId);
            existingValues.putAll(request.getValues());

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
            for (Map.Entry<String, String> entry : request.getValues().entrySet()) {
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

        order.setStatus("SPA_GATE");
        orderRepository.save(order);

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
            if (template != null && template.getTemplateContent() != null) {
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
                    byte[] docxBytes = docxTemplateEngine.generateReport(template.getTemplateContent(), inputsMap, imagesMap);
                    
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

        Template template = templateRepository.findById(templateId)
                .orElseThrow(() -> new NoSuchElementException("Template not found with ID: " + templateId));

        Map<String, String> inputsMap = getConsolidatedValues(orderId);
        Map<String, byte[]> imagesMap = new HashMap<>();
        List<OrderInput> inputsList = orderInputRepository.findAllByOrderId(orderId);
        for (OrderInput input : inputsList) {
            if (input.getImageValue() != null) {
                imagesMap.put(input.getFieldKey().toUpperCase(), input.getImageValue());
            }
        }

        int effectiveVersion = order.getTemplateVersion() != null ? order.getTemplateVersion() : template.getVersion();
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
            hydratedDocx = docxTemplateEngine.generateReport(template.getTemplateContent(), inputsMap, imagesMap);
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
                    if (!map.containsKey(k) || map.get(k) == null || map.get(k).trim().isEmpty()) {
                        if (v != null && !v.trim().isEmpty()) {
                            map.put(k, v);
                        } else {
                            map.put(k, "");
                        }
                    }
                }

                // Serialized RAW items for Dynamic DOCX repeating tables
                if (valBundle.getLandItems() != null) {
                    map.put("RAW_LAND_ITEMS_JSON", objectMapper.writeValueAsString(valBundle.getLandItems()));
                }
                if (valBundle.getBuildingItems() != null) {
                    map.put("RAW_BUILDING_ITEMS_JSON", objectMapper.writeValueAsString(valBundle.getBuildingItems()));
                }
                if (valBundle.getComparableSales() != null) {
                    map.put("RAW_COMPARABLES_JSON", objectMapper.writeValueAsString(valBundle.getComparableSales()));
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
}

