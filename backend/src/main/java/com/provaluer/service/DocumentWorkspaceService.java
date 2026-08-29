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

    private final ObjectMapper objectMapper = new ObjectMapper();

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
            if (order.getPaId() == null || !order.getPaId().equals(principal.getId())) {
                throw new AccessDeniedException("Access denied: You are not the assigned Property Analyst for Order #" + order.getId());
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
     * GET /api/v1/orders/{id}/document-workspace
     * Generates or retrieves the complete document workspace payload with visual preview & values.
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

        // 1. Legacy / Migration Support: Ensure documentDomSnapshot and templateVersion are populated
        if (order.getTemplateVersion() == null) {
            order.setTemplateVersion(template.getVersion());
        }
        if (order.getDocumentDomSnapshot() == null) {
            try {
                if (template.getDocumentDom() != null && !template.getDocumentDom().trim().isEmpty()) {
                    order.setDocumentDomSnapshot(template.getDocumentDom());
                } else {
                    JsonNode domNode = docxStructureParser.parseDocumentStructure(docxBytes);
                    order.setDocumentDomSnapshot(domNode.toString());
                    template.setDocumentDom(domNode.toString());
                    template.setPlaceholderRegistry(docxStructureParser.generatePlaceholderRegistry(domNode));
                    templateRepository.save(template);
                }
                orderRepository.save(order);
            } catch (Exception e) {
                log.warn("Failed to generate document DOM snapshot on the fly: {}", e.getMessage());
            }
        }

        // 2. Generate / Retrieve Visual Preview Layout & Disk-Cached Coordinates with Version Isolation
        int effectiveVersion = order.getTemplateVersion() != null ? order.getTemplateVersion() : template.getVersion();
        DocxPreviewGenerator.PreviewMetadata metadata = previewGenerator.generatePreview(templateId, effectiveVersion, docxBytes, false);
        byte[] pdfBytes = previewGenerator.convertDocxToPdf(templateId, docxBytes);

        // TASK 2: Load coordinates from disk cache if present; extract and cache only if absent
        Map<Integer, List<VisualPreviewResponse.VisualPlaceholder>> coordinatesMap =
                coordinateExtractor.getOrExtractCoordinates(effectiveTemplateId, effectiveVersion, pdfBytes);

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

        VisualPreviewResponse visualPreview = new VisualPreviewResponse(
                templateId,
                metadata.getTotalPages(),
                dims,
                pages
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

        return new DocumentWorkspaceResponse(
                order.getId(),
                order.getStatus(),
                order.getReportNumber(),
                visualPreview,
                valuesMap,
                readOnly
        );
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
                    List<OrderInput> inputsList = orderInputRepository.findAllByOrderId(orderId);
                    Map<String, String> inputsMap = new HashMap<>();
                    Map<String, byte[]> imagesMap = new HashMap<>();
                    for (OrderInput input : inputsList) {
                        String key = input.getFieldKey().toUpperCase();
                        String val = input.getFieldValue();
                        if ((key.contains("DATE_") || key.contains("_DATE") || key.equals("DATE")) && (val == null || val.trim().isEmpty())) {
                            val = java.time.LocalDate.now().format(DateTimeFormatter.ofPattern("dd-MM-yyyy"));
                        }
                        inputsMap.put(key, val);
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
     * TASK 3: Generates a unique timestamped session nonce to prevent cache collisions and browser stale cache issues.
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

        byte[] hydratedDocx;
        try {
            hydratedDocx = docxTemplateEngine.generateReport(template.getTemplateContent(), inputsMap, imagesMap);
        } catch (Exception e) {
            log.error("Failed to hydrate template DOCX for live preview: {}", e.getMessage(), e);
            throw new IllegalStateException("Failed to generate live preview report: " + e.getMessage(), e);
        }
        byte[] pdfBytes = previewGenerator.convertDocxToPdf(templateId, hydratedDocx);

        // TASK 3: Unique previewSessionId per compilation request
        String previewSessionId = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmssSSS"));
        Path liveCacheDir = Paths.get("storage/preview-cache", "order_" + orderId + "_live_" + previewSessionId);
        try {
            Files.createDirectories(liveCacheDir);
        } catch (Exception e) {
            log.error("Failed to create live preview cache directory: {}", e.getMessage());
        }

        DocxPreviewGenerator.PreviewMetadata metadata = previewGenerator.renderPdfToImages(templateId, pdfBytes, liveCacheDir);

        List<VisualPreviewResponse.VisualPage> pages = new ArrayList<>();
        for (int i = 0; i < metadata.getTotalPages(); i++) {
            pages.add(new VisualPreviewResponse.VisualPage(
                    i,
                    "/api/v1/orders/" + orderId + "/live-preview/" + previewSessionId + "/pages/" + i + ".png",
                    Collections.emptyList()
            ));
        }

        return new VisualPreviewResponse(
                templateId,
                previewSessionId,
                metadata.getTotalPages(),
                new VisualPreviewResponse.PageDimensions(metadata.getWidthPt(), metadata.getHeightPt(), metadata.getAspectRatio()),
                pages
        );
    }

    /**
     * GET /api/v1/orders/{id}/live-preview/{previewSessionId}/pages/{pageIndex}.png
     */
    public byte[] getLivePreviewSessionPageImage(Long orderId, String previewSessionId, int pageIndex) {
        Path imagePath = Paths.get("storage/preview-cache", "order_" + orderId + "_live_" + previewSessionId, "page_" + pageIndex + ".png");
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

    private Map<String, String> getConsolidatedValues(Long orderId) {
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
}
