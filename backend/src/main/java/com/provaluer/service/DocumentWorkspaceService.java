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
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.provaluer.dto.BindTemplateRequest;
import com.provaluer.dto.DraftValidationResponseDto;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

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
    private ValuationCompositeItemRepository compositeItemRepository;

    @Autowired
    private ValuationLandItemRepository landItemRepository;

    @Autowired
    private ValuationBuildingItemRepository buildingItemRepository;

    @Autowired
    private ValuationDataRepository valuationDataRepository;

    @Autowired
    private ValuationCalculationFormulaService formulaService;

    @Autowired
    private DocxPreviewGenerator previewGenerator;

    @Autowired
    private DocxStructureParser docxStructureParser;

    @Autowired
    private DocxTemplateEngine docxTemplateEngine;

    @Autowired
    private PricingService pricingService;

    @Autowired
    private AuditLogService auditLogService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private DocumentStudioConfigRepository studioConfigRepository;

    @Autowired
    private TemplateQuestionRepository templateQuestionRepository;

    @Autowired
    private ValuationEngineService valuationEngineService;

    @Autowired
    private ValuationSnapshotRepository valuationSnapshotRepository;

    @Autowired
    private ValuationAuditLogRepository valuationAuditLogRepository;


    @Autowired
    private TelegramNotificationService telegramNotificationService;

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

        if ((order.isArchivalLocked() || "CLOSED".equalsIgnoreCase(order.getStatus())) && !"VIEW".equalsIgnoreCase(action)) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.LOCKED,
                    "Order #" + order.getId() + " is permanently CLOSED and archived under 10-year statutory lock. Modifications are strictly forbidden."
            );
        }

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
            if ("VIEW".equalsIgnoreCase(action)) {
                return;
            }

            // Strict Locking Rule:
            // PA becomes READ ONLY when in SPA_GATE, SPA_CONFIRMED, FINAL_DELIVERY, FINALIZED, or LOCKED
            boolean isLockedOrFinalized = "SPA_GATE".equalsIgnoreCase(order.getStatus())
                    || "SPA_CONFIRMED".equalsIgnoreCase(order.getStatus())
                    || "FINAL_DELIVERY".equalsIgnoreCase(order.getStatus())
                    || "FINALIZED".equalsIgnoreCase(order.getValuationStatus())
                    || "LOCKED".equalsIgnoreCase(order.getValuationStatus());

            if (isLockedOrFinalized && ("SAVE".equalsIgnoreCase(action) || "SUBMIT_TO_SPA".equalsIgnoreCase(action))) {
                throw new AccessDeniedException("Report is in " + order.getStatus() + " and is READ ONLY for Property Analyst");
            }

            return;
        }

        // SPA Validation: May inspect, live-preview, and review orders. Read-Only during drafting.
        if (isSpa) {
            if ("SAVE".equalsIgnoreCase(action) && ("WORKSPACE_READY".equalsIgnoreCase(order.getStatus()) || "DRAFTING".equalsIgnoreCase(order.getStatus()))) {
                throw new AccessDeniedException("SPA has read-only access during Property Analyst drafting phase");
            }
            return;
        }

        // Client Validation: Clients do not have access to Document Workspace
        if (isClient) {
            throw new AccessDeniedException("Clients do not have access to Document Workspace");
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

    private boolean isSuperAdminOrAdmin(UserDetailsImpl principal) {
        if (principal == null || principal.getAuthorities() == null) return false;
        return principal.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_SUPER_ADMIN") || a.getAuthority().equals("ROLE_ADMIN"));
    }

    private String getPrincipalRole(UserDetailsImpl principal) {
        if (principal == null || principal.getAuthorities() == null || principal.getAuthorities().isEmpty()) {
            return "SYSTEM";
        }
        return principal.getAuthorities().iterator().next().getAuthority().replace("ROLE_", "");
    }

    /**
     * SPRINT 6: Initialize Document Workspace.
     * Transitions status: INSPECTION_COMPLETED → WORKSPACE_READY.
     * 1. Resolves template
     * 2. Locks template version permanently
     * 3. Generates DOM snapshot
     * 4. Generates field mapping snapshot
     * 5. Imports inspection & order/client/quote data
     * 6. Imports and binds photo evidence
     * 7. Transitions status to WORKSPACE_READY
     * 8. Records comprehensive audit entries
     */
    @Transactional
    public DocumentWorkspaceResponse initializeWorkspace(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "VIEW");

        // 1. Resolve template
        Long templateId = order.getTemplateId();
        Template template = null;
        if (templateId != null) {
            template = templateRepository.findById(templateId).orElse(null);
        }
        if (template == null) {
            List<Template> activeTemplates = templateRepository.findAllByIsActive("Y");
            if (!activeTemplates.isEmpty()) {
                template = activeTemplates.get(0);
                templateId = template.getId();
                order.setTemplateId(templateId);
            } else {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No active valuation template available in the system.");
            }
        }
        final Long effectiveTemplateId = templateId;

        // 2. Lock template version permanently
        if (order.getTemplateVersion() == null && template != null) {
            order.setTemplateVersion(template.getVersion());
        }
        if (order.getTemplateVersionId() == null) {
            List<TemplateVersion> versions = templateVersionRepository.findAllByTemplateIdOrderByVersionDesc(effectiveTemplateId);
            for (TemplateVersion v : versions) {
                if (order.getTemplateVersion() != null && v.getVersion() == order.getTemplateVersion()) {
                    order.setTemplateVersionId(v.getId());
                    break;
                }
            }
            if (order.getTemplateVersionId() == null && !versions.isEmpty()) {
                order.setTemplateVersionId(versions.get(0).getId());
            } else if (order.getTemplateVersionId() == null && template != null) {
                TemplateVersion fallbackVer = new TemplateVersion();
                fallbackVer.setTemplateId(template.getId());
                fallbackVer.setVersion(order.getTemplateVersion() != null && order.getTemplateVersion() > 0 ? order.getTemplateVersion() : 1);
                fallbackVer.setName(template.getName() != null ? template.getName() : "Template v1");
                fallbackVer.setTemplateContent(template.getTemplateContent() != null ? template.getTemplateContent() : new byte[]{1, 2, 3});
                fallbackVer.setFieldMapping(template.getFieldMapping() != null ? template.getFieldMapping() : "{}");
                fallbackVer.setDocumentDom(template.getDocumentDom() != null ? template.getDocumentDom() : "{\"sections\":[]}");
                fallbackVer.setPlaceholderRegistry(template.getPlaceholderRegistry());
                fallbackVer.setStatus("ACTIVE");
                fallbackVer.setCreatedAt(LocalDateTime.now());
                fallbackVer.setCreatedBy(principal != null ? principal.getId() : null);
                fallbackVer = templateVersionRepository.save(fallbackVer);
                order.setTemplateVersionId(fallbackVer.getId());
            }
        }

        // 3. Generate field mapping snapshot
        if (order.getFieldMappingSnapshot() == null || order.getFieldMappingSnapshot().trim().isEmpty()) {
            order.setFieldMappingSnapshot(template != null && template.getFieldMapping() != null ? template.getFieldMapping() : "{}");
        }

        // 4. Generate DOM snapshot
        byte[] docxBytes = resolveOrderTemplateBytes(order, template);
        if (order.getDocumentDomSnapshot() == null || order.getDocumentDomSnapshot().trim().isEmpty()) {
            if (template != null && template.getDocumentDom() != null && !template.getDocumentDom().trim().isEmpty()) {
                order.setDocumentDomSnapshot(template.getDocumentDom());
            } else if (docxBytes != null && docxBytes.length > 0) {
                try {
                    Map<String, String> typeOverrides = template != null ? TemplateProcessingService.extractTypeOverrides(template) : Collections.emptyMap();
                    JsonNode domNode = docxStructureParser.parseDocumentStructure(docxBytes, typeOverrides);
                    docxStructureParser.applyTypeOverridesToDom(domNode, typeOverrides);
                    order.setDocumentDomSnapshot(domNode.toString());
                } catch (Exception e) {
                    log.warn("Failed to generate document DOM snapshot on the fly: {}", e.getMessage());
                }
            }
        }
        if (order.getDocumentDomSnapshot() == null || order.getDocumentDomSnapshot().trim().isEmpty()) {
            order.setDocumentDomSnapshot("{\"sections\":[]}");
        }

        // 5. Assemble and import inspection, client, order, and quote details
        Map<String, String> inputsMap = new HashMap<>(getConsolidatedValues(orderId));

        if (order.getReferenceCode() != null) inputsMap.put("ORDER_REF_NO", order.getReferenceCode());
        if (order.getReportNumber() != null) inputsMap.put("REPORT_NUMBER", order.getReportNumber());
        if (order.getPurpose() != null) inputsMap.put("PURPOSE_OF_VALUATION", order.getPurpose());
        if (order.getPropertyCategory() != null) inputsMap.put("PROPERTY_CATEGORY", order.getPropertyCategory());
        if (order.getClientName() != null) inputsMap.put("CLIENT_NAME", order.getClientName());
        if (order.getBankName() != null) inputsMap.put("BANK_NAME", order.getBankName());
        if (order.getBranchName() != null) inputsMap.put("BRANCH_NAME", order.getBranchName());

        if (order.getQuoteNumber() != null) inputsMap.put("QUOTE_NUMBER", order.getQuoteNumber());
        if (order.getQuoteAmount() != null) inputsMap.put("QUOTE_AMOUNT", order.getQuoteAmount().toPlainString());
        if (order.getQuoteTax() != null) inputsMap.put("QUOTE_TAX", order.getQuoteTax().toPlainString());
        if (order.getQuoteTotal() != null) inputsMap.put("QUOTE_TOTAL", order.getQuoteTotal().toPlainString());
        if (order.getQuoteTurnaround() != null) inputsMap.put("QUOTE_TURNAROUND", order.getQuoteTurnaround());



        // Update orders.input_values JSONB
        try {
            Map<String, String> textOnly = new HashMap<>();
            for (Map.Entry<String, String> e : inputsMap.entrySet()) {
                if (e.getValue() != null && !e.getValue().startsWith("data:image")) {
                    textOnly.put(e.getKey(), e.getValue());
                }
            }
            order.setInputValues(objectMapper.writeValueAsString(textOnly));
        } catch (Exception ignored) {}

        // Valuer / PA Details
        if (order.getPaId() != null) {
            userRepository.findById(order.getPaId()).ifPresent(pa -> {
                String paName = pa.getFullName() != null && !pa.getFullName().trim().isEmpty() ? pa.getFullName() : pa.getUsername();
                inputsMap.put("VALUER_NAME", paName);
                inputsMap.put("PA_NAME", paName);
                if (pa.getMobileNumber() != null) inputsMap.put("VALUER_PHONE", pa.getMobileNumber());
                if (pa.getEmail() != null) inputsMap.put("VALUER_EMAIL", pa.getEmail());
            });
        }

        // Save imported text fields
        for (Map.Entry<String, String> entry : inputsMap.entrySet()) {
            saveOrUpdateInput(orderId, entry.getKey(), entry.getValue());
        }

        // Update orders.input_values JSONB
        try {
            Map<String, String> textOnly = new HashMap<>();
            for (Map.Entry<String, String> e : inputsMap.entrySet()) {
                if (e.getValue() != null && !e.getValue().startsWith("data:image")) {
                    textOnly.put(e.getKey(), e.getValue());
                }
            }
            order.setInputValues(objectMapper.writeValueAsString(textOnly));
        } catch (Exception ignored) {}

        // 6. Transition status: ASSIGNED → WORKSPACE_READY
        String previousStatus = order.getStatus();
        if ("ASSIGNED".equalsIgnoreCase(order.getStatus()) || "INSPECTION_COMPLETED".equalsIgnoreCase(order.getStatus())) {
            order.setStatus("WORKSPACE_READY");
        }
        order.setUpdatedAt(LocalDateTime.now());
        Order savedOrder = orderRepository.save(order);

        // 7. Audit Logging
        Long actorId = principal != null ? principal.getId() : null;
        String actorEmail = principal != null ? principal.getEmail() : "SYSTEM";
        String actorRole = getPrincipalRole(principal);

        auditLogService.log(actorId, actorEmail, actorRole, "WORKSPACE_INITIALIZED", "ORDER",
                String.valueOf(orderId), previousStatus, savedOrder.getStatus(), "Workspace initialized");
        auditLogService.log(actorId, actorEmail, actorRole, "TEMPLATE_BOUND", "ORDER",
                String.valueOf(orderId), "Template #" + (template != null ? template.getId() : effectiveTemplateId) + " v" + (template != null ? template.getVersion() : order.getTemplateVersion()) + " locked (Version ID: " + order.getTemplateVersionId() + ")");

        return getDocumentWorkspace(orderId, principal);
    }

    /**
     * SPRINT 6: Bind template to order.
     * Locks template version permanently, records DOM and field mapping snapshots.
     */
    @Transactional
    public Map<String, Object> bindTemplate(Long orderId, BindTemplateRequest req, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "SAVE");

        Long requestedTemplateId = req != null && req.getTemplateId() != null ? req.getTemplateId() : order.getTemplateId();
        if (requestedTemplateId == null) {
            List<Template> activeTemplates = templateRepository.findAllByIsActive("Y");
            if (!activeTemplates.isEmpty()) {
                requestedTemplateId = activeTemplates.get(0).getId();
            } else {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "No active template available to bind");
            }
        }

        final Long targetTemplateId = requestedTemplateId;
        Template template = templateRepository.findById(targetTemplateId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Template not found: " + targetTemplateId));

        // Lock template version
        order.setTemplateId(template.getId());
        order.setTemplateVersion(template.getVersion());

        List<TemplateVersion> versions = templateVersionRepository.findAllByTemplateIdOrderByVersionDesc(template.getId());
        TemplateVersion matched = versions.stream()
                .filter(v -> v.getVersion() == template.getVersion())
                .findFirst()
                .orElse(!versions.isEmpty() ? versions.get(0) : null);

        if (matched != null) {
            order.setTemplateVersionId(matched.getId());
        } else {
            TemplateVersion fallbackVer = new TemplateVersion();
            fallbackVer.setTemplateId(template.getId());
            fallbackVer.setVersion(template.getVersion() > 0 ? template.getVersion() : 1);
            fallbackVer.setName(template.getName() != null ? template.getName() : "Template v1");
            fallbackVer.setTemplateContent(template.getTemplateContent() != null ? template.getTemplateContent() : new byte[]{1, 2, 3});
            fallbackVer.setFieldMapping(template.getFieldMapping() != null ? template.getFieldMapping() : "{}");
            fallbackVer.setDocumentDom(template.getDocumentDom() != null ? template.getDocumentDom() : "{\"sections\":[]}");
            fallbackVer.setPlaceholderRegistry(template.getPlaceholderRegistry());
            fallbackVer.setStatus("ACTIVE");
            fallbackVer.setCreatedAt(LocalDateTime.now());
            fallbackVer.setCreatedBy(principal != null ? principal.getId() : null);
            fallbackVer = templateVersionRepository.save(fallbackVer);
            order.setTemplateVersionId(fallbackVer.getId());
        }

        order.setFieldMappingSnapshot(template.getFieldMapping() != null ? template.getFieldMapping() : "{}");

        boolean forceRebuild = req != null && Boolean.TRUE.equals(req.getForceSnapshotRebuild());
        if (forceRebuild || order.getDocumentDomSnapshot() == null || order.getDocumentDomSnapshot().trim().isEmpty()) {
            if (template.getDocumentDom() != null && !template.getDocumentDom().trim().isEmpty()) {
                order.setDocumentDomSnapshot(template.getDocumentDom());
            } else {
                byte[] docxBytes = resolveOrderTemplateBytes(order, template);
                if (docxBytes != null && docxBytes.length > 0) {
                    try {
                        Map<String, String> typeOverrides = TemplateProcessingService.extractTypeOverrides(template);
                        JsonNode domNode = docxStructureParser.parseDocumentStructure(docxBytes, typeOverrides);
                        docxStructureParser.applyTypeOverridesToDom(domNode, typeOverrides);
                        order.setDocumentDomSnapshot(domNode.toString());
                    } catch (Exception e) {
                        log.warn("Failed to generate document DOM snapshot during bind-template: {}", e.getMessage());
                    }
                }
            }
        }
        if (order.getDocumentDomSnapshot() == null || order.getDocumentDomSnapshot().trim().isEmpty()) {
            order.setDocumentDomSnapshot("{\"sections\":[]}");
        }

        order.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(order);

        // Audit log
        auditLogService.log(
                principal != null ? principal.getId() : null,
                principal != null ? principal.getEmail() : "PA",
                getPrincipalRole(principal),
                "TEMPLATE_BOUND",
                "ORDER",
                String.valueOf(orderId),
                String.format("Template #%d (Version %d, VersionID: %s) bound to Order %s",
                        template.getId(), template.getVersion(), String.valueOf(order.getTemplateVersionId()), order.getReferenceCode())
        );

        Map<String, Object> resp = new HashMap<>();
        resp.put("orderId", orderId);
        resp.put("templateId", template.getId());
        resp.put("templateVersion", order.getTemplateVersion());
        resp.put("templateVersionId", order.getTemplateVersionId());
        resp.put("status", order.getStatus());
        return resp;
    }

    /**
     * SPRINT 6: Draft Pre-submission Validation Engine.
     * Evaluates mandatory fields, mandatory photos, formula calculations, and image placeholders.
     */
    @Transactional(readOnly = true)
    public DraftValidationResponseDto validateDraft(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "VIEW");

        List<String> missingFields = new ArrayList<>();
        List<String> missingPhotos = new ArrayList<>();
        List<String> calculationErrors = new ArrayList<>();
        List<String> placeholderErrors = new ArrayList<>();

        Map<String, String> consolidatedValues = getConsolidatedValues(orderId);

        // 1. Mandatory Fields
        String[] coreMandatory = {"CLIENT_NAME", "PROPERTY_ADDRESS", "PURPOSE_OF_VALUATION", "INSPECTION_DATE", "VALUER_NAME"};
        for (String k : coreMandatory) {
            String val = consolidatedValues.get(k);
            if (val == null || val.trim().isEmpty()) {
                missingFields.add(k);
            }
        }

        if (order.getDocumentDomSnapshot() != null) {
            try {
                JsonNode dom = objectMapper.readTree(order.getDocumentDomSnapshot());
                if (dom.has("placeholdersSummary")) {
                    for (JsonNode ph : dom.get("placeholdersSummary")) {
                        if (ph.path("isMandatory").asBoolean(false) || ph.path("mandatory").asBoolean(false)) {
                            String key = ph.path("key").asText().toUpperCase();
                            String val = consolidatedValues.get(key);
                            if ((val == null || val.trim().isEmpty()) && !missingFields.contains(key)) {
                                missingFields.add(key);
                            }
                        }
                    }
                }
            } catch (Exception ignored) {}
        }



        // 3. Formula & Valuation Calculation
        BigDecimal estVal = order.getEstimatedValue();
        BigDecimal finVal = order.getFinalValue();
        if ((estVal == null || estVal.compareTo(BigDecimal.ZERO) <= 0) && (finVal == null || finVal.compareTo(BigDecimal.ZERO) <= 0)) {
            String totalValStr = consolidatedValues.get("FINAL_VALUATION_AMOUNT");
            if (totalValStr == null || totalValStr.trim().isEmpty()) {
                totalValStr = consolidatedValues.get("TOTAL_VALUATION");
            }
            if (totalValStr == null || totalValStr.trim().isEmpty()) {
                totalValStr = consolidatedValues.get("FAIR_MARKET_VALUE");
            }
            if (totalValStr == null || totalValStr.trim().isEmpty()) {
                calculationErrors.add("Final valuation amount must be greater than zero.");
            }
        }

        // 4. Placeholder & Unresolved Syntax Validation
        for (Map.Entry<String, String> e : consolidatedValues.entrySet()) {
            String v = e.getValue();
            if (v != null && (v.contains("{{") || v.contains("}}") || v.contains("<<") || v.contains(">>"))) {
                placeholderErrors.add("Unresolved placeholder syntax detected in field " + e.getKey());
            }
        }

        // 5. Image Placeholder Validation
        boolean hasFrontPhoto = orderInputRepository.findAllByOrderId(orderId).stream()
                .anyMatch(i -> ("IMG_FRONT_PAGE".equalsIgnoreCase(i.getFieldKey())
                        || "IMG_COVER_PAGE".equalsIgnoreCase(i.getFieldKey())
                        || "IMG_FRONT_ELEVATION".equalsIgnoreCase(i.getFieldKey()))
                        && i.getImageValue() != null && i.getImageValue().length > 0);
        if (!hasFrontPhoto) {
            missingPhotos.add("FRONT_ELEVATION image binary missing in workspace");
        }

        boolean valid = missingFields.isEmpty() && missingPhotos.isEmpty() && calculationErrors.isEmpty() && placeholderErrors.isEmpty();
        String msg = valid ? "Draft is valid and ready for SPA submission." : "Draft validation failed with issues.";

        DraftValidationResponseDto resp = new DraftValidationResponseDto();
        resp.setOrderId(orderId);
        resp.setValid(valid);
        resp.setCanSubmit(valid);
        resp.setMissingFields(missingFields);
        resp.setMissingPhotos(missingPhotos);
        resp.setCalculationErrors(calculationErrors);
        resp.setPlaceholderErrors(placeholderErrors);
        resp.setMessage(msg);
        resp.setValidationTimestamp(LocalDateTime.now());
        return resp;
    }

    /**
     * GET /api/v1/orders/{id}/document-workspace
     * Pure, instantaneous workspace data endpoint returning documentDom, placeholders, values, and sections.
     * Completely decoupled from PDF and visual image preview generation.
     */
    @Transactional
    public DocumentWorkspaceResponse getDocumentWorkspace(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "VIEW");

        // Auto-initialization:
        if ("ASSIGNED".equalsIgnoreCase(order.getStatus()) || "INSPECTION_COMPLETED".equalsIgnoreCase(order.getStatus())) {
            return initializeWorkspace(orderId, principal);
        }

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
            if (template != null && template.getDocumentDom() != null && !template.getDocumentDom().trim().isEmpty()) {
                order.setDocumentDomSnapshot(template.getDocumentDom());
                orderRepository.save(order);
            } else {
                try {
                    Map<String, String> typeOverrides = TemplateProcessingService.extractTypeOverrides(template);
                    JsonNode domNode = docxStructureParser.parseDocumentStructure(docxBytes, typeOverrides);
                    docxStructureParser.applyTypeOverridesToDom(domNode, typeOverrides);
                    order.setDocumentDomSnapshot(domNode.toString());
                    orderRepository.save(order);
                } catch (Exception e) {
                    log.warn("Failed to generate document DOM snapshot on the fly: {}", e.getMessage());
                }
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
        if (domNode == null && template != null && template.getDocumentDom() != null && !template.getDocumentDom().trim().isEmpty()) {
            try {
                domNode = objectMapper.readTree(template.getDocumentDom());
            } catch (Exception e) {
                log.warn("Failed to parse template documentDom JSON for template {}: {}", templateId, e.getMessage());
            }
        }

        // Apply Hierarchical Field Type Overrides: Registry / Template / Order snapshot
        Map<String, String> typeOverrides = TemplateProcessingService.extractTypeOverrides(template);
        if (domNode != null && !typeOverrides.isEmpty()) {
            docxStructureParser.applyTypeOverridesToDom(domNode, typeOverrides);
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
                domNode,
                order.getWorkspaceRevision() != null ? order.getWorkspaceRevision() : 1
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

        // FIX 1 & FIX 3 & FIX 5: Concurrency Conflict Detection & Workspace Revision Governance
        Integer expectedRev = order.getWorkspaceRevision() != null ? order.getWorkspaceRevision() : 1;
        if (request != null && request.getWorkspaceRevision() != null) {
            if (!request.getWorkspaceRevision().equals(expectedRev)) {
                try {
                    auditLogService.log(
                            principal != null ? principal.getId() : null,
                            principal != null ? principal.getEmail() : "SYSTEM",
                            getPrincipalRole(principal),
                            "WORKSPACE_CONFLICT_REJECTED",
                            "ORDER",
                            String.valueOf(orderId),
                            "rev:" + expectedRev,
                            "submitted_rev:" + request.getWorkspaceRevision(),
                            "Save rejected due to revision mismatch. Workspace updated elsewhere. Current revision: "
                                    + expectedRev + ", Submitted revision: " + request.getWorkspaceRevision()
                    );
                } catch (Exception e) {
                    log.warn("Failed to audit conflict event: {}", e.getMessage());
                }
                throw new ResponseStatusException(HttpStatus.CONFLICT,
                        "Workspace updated elsewhere (Server revision: " + expectedRev
                        + ", Submitted revision: " + request.getWorkspaceRevision() + "). Refresh required.");
            }
        }

        // SPRINT 6: Transition WORKSPACE_READY → DRAFTING upon first save
        if ("WORKSPACE_READY".equalsIgnoreCase(order.getStatus())) {
            order.setStatus("DRAFTING");
            order.setUpdatedAt(LocalDateTime.now());
            orderRepository.save(order);
        }

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

            boolean tablesModified = false;

            if (expandedInputs.containsKey("RAW_LAND_ITEMS_JSON")) {
                String landJson = expandedInputs.get("RAW_LAND_ITEMS_JSON");
                if (landJson != null && !landJson.trim().isEmpty() && !landJson.equals("[]")) {
                    try {
                        List<ValuationLandItem> items = objectMapper.readValue(
                                landJson,
                                objectMapper.getTypeFactory().constructCollectionType(List.class, ValuationLandItem.class)
                        );
                        if (items != null && landItemRepository != null) {
                            reconcileLandItems(orderId, items);
                            tablesModified = true;
                        }
                    } catch (Exception e) {
                        log.warn("Failed to sync landItemRepository from saveDocumentValues: {}", e.getMessage());
                    }
                }
            }

            if (expandedInputs.containsKey("RAW_BUILDING_ITEMS_JSON")) {
                String bldgJson = expandedInputs.get("RAW_BUILDING_ITEMS_JSON");
                if (bldgJson != null && !bldgJson.trim().isEmpty() && !bldgJson.equals("[]")) {
                    try {
                        List<ValuationBuildingItem> items = objectMapper.readValue(
                                bldgJson,
                                objectMapper.getTypeFactory().constructCollectionType(List.class, ValuationBuildingItem.class)
                        );
                        if (items != null && buildingItemRepository != null) {
                            reconcileBuildingItems(orderId, items);
                            tablesModified = true;
                        }
                    } catch (Exception e) {
                        log.warn("Failed to sync buildingItemRepository from saveDocumentValues: {}", e.getMessage());
                    }
                }
            }

            if (expandedInputs.containsKey("RAW_COMPOSITE_ITEMS_JSON")) {
                String compJson = expandedInputs.get("RAW_COMPOSITE_ITEMS_JSON");
                if (compJson != null && !compJson.trim().isEmpty() && !compJson.equals("[]")) {
                    try {
                        List<ValuationCompositeItem> items = objectMapper.readValue(
                                compJson,
                                objectMapper.getTypeFactory().constructCollectionType(List.class, ValuationCompositeItem.class)
                        );
                        if (items != null && compositeItemRepository != null) {
                            reconcileCompositeItems(orderId, items);
                            tablesModified = true;
                        }
                    } catch (Exception e) {
                        log.warn("Failed to sync compositeItemRepository from saveDocumentValues: {}", e.getMessage());
                    }
                }
            } else if (expandedInputs.containsKey("SALEABLE_AREA_NUMERIC") || expandedInputs.containsKey("SALEABLE_AREA")) {
                String saleableArea = expandedInputs.get("SALEABLE_AREA_NUMERIC");
                if (saleableArea == null || saleableArea.trim().isEmpty()) {
                    saleableArea = expandedInputs.get("SALEABLE_AREA");
                }
                if (saleableArea != null && !saleableArea.trim().isEmpty() && compositeItemRepository != null) {
                    String cleanNum = saleableArea.replaceAll("[^0-9.]", "").trim();
                    if (!cleanNum.isEmpty()) {
                        try {
                            BigDecimal qty = new BigDecimal(cleanNum);
                            if (qty.compareTo(BigDecimal.ZERO) > 0) {
                                List<ValuationCompositeItem> compList = compositeItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
                                for (ValuationCompositeItem itm : compList) {
                                    if ("MAIN_UNIT".equalsIgnoreCase(itm.getItemCategory())) {
                                        itm.setQuantity(qty);
                                        compositeItemRepository.save(itm);
                                        tablesModified = true;
                                        break;
                                    }
                                }
                            }
                        } catch (Exception ignored) {}
                    }
                }
            }

            if (expandedInputs.containsKey("COMPOSITE_GOVERNMENT_RATE")
                    || expandedInputs.containsKey("composite_government_rate")
                    || expandedInputs.containsKey("COMPOSITE_GOVT_RATE")) {
                String compGovtRate = expandedInputs.get("COMPOSITE_GOVERNMENT_RATE");
                if (compGovtRate == null || compGovtRate.trim().isEmpty()) {
                    compGovtRate = expandedInputs.get("composite_government_rate");
                }
                if (compGovtRate == null || compGovtRate.trim().isEmpty()) {
                    compGovtRate = expandedInputs.get("COMPOSITE_GOVT_RATE");
                }
                if (compGovtRate != null && !compGovtRate.trim().isEmpty()) {
                    String cleanNum = compGovtRate.replaceAll("[^0-9.]", "").trim();
                    if (!cleanNum.isEmpty()) {
                        try {
                            BigDecimal rateBd = new BigDecimal(cleanNum);
                            ValuationData vData = valuationDataRepository != null ?
                                    valuationDataRepository.findByOrderId(orderId).orElse(null) : null;
                            if (vData != null) {
                                vData.setCompositeGovernmentRate(rateBd);
                                valuationDataRepository.save(vData);
                                tablesModified = true;
                            }
                        } catch (Exception ignored) {}
                    }
                }
            }

            // If tables were updated, recalculate summary totals and synchronize order_inputs to match repository state
            if (tablesModified && valuationDataRepository != null && formulaService != null && valuationEngineService != null) {
                try {
                    ValuationData valData = valuationDataRepository.findByOrderId(orderId)
                            .orElseGet(() -> valuationEngineService.initializeDefaultValuationData(order));

                    if (expandedInputs.containsKey("COMPOSITE_GOVERNMENT_RATE")
                            || expandedInputs.containsKey("composite_government_rate")
                            || expandedInputs.containsKey("COMPOSITE_GOVT_RATE")) {
                        String compGovtRate = expandedInputs.get("COMPOSITE_GOVERNMENT_RATE");
                        if (compGovtRate == null || compGovtRate.trim().isEmpty()) {
                            compGovtRate = expandedInputs.get("composite_government_rate");
                        }
                        if (compGovtRate == null || compGovtRate.trim().isEmpty()) {
                            compGovtRate = expandedInputs.get("COMPOSITE_GOVT_RATE");
                        }
                        if (compGovtRate != null && !compGovtRate.trim().isEmpty()) {
                            String cleanNum = compGovtRate.replaceAll("[^0-9.]", "").trim();
                            if (!cleanNum.isEmpty()) {
                                try {
                                    valData.setCompositeGovernmentRate(new BigDecimal(cleanNum));
                                } catch (Exception ignored) {}
                            }
                        }
                    }

                    List<ValuationLandItem> landItems = landItemRepository != null ?
                            landItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId) : List.of();
                    List<ValuationBuildingItem> buildingItems = buildingItemRepository != null ?
                            buildingItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId) : List.of();
                    List<ValuationCompositeItem> compositeItems = compositeItemRepository != null ?
                            compositeItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId) : List.of();

                    boolean isComp = (compositeItems != null && !compositeItems.isEmpty())
                            || "COMPOSITE_RATE".equalsIgnoreCase(valData.getValuationMethodology())
                            || "COMPOSITE".equalsIgnoreCase(valData.getValuationMethodology());

                    if (isComp) {
                        valData.setValuationMethodology("COMPOSITE_RATE");
                        formulaService.calculateCompositeSummary(valData, compositeItems);
                    } else {
                        formulaService.calculateSummary(valData, landItems, buildingItems);
                    }

                    valData.setUpdatedAt(LocalDateTime.now());
                    valuationDataRepository.save(valData);

                    order.setFinalValue(valData.getFairValue());
                    if (order.getEstimatedValue() == null || order.getEstimatedValue().signum() == 0) {
                        order.setEstimatedValue(valData.getFairValue());
                    }

                    // Single source of truth: synchronize calculated totals to order_inputs
                    Map<String, String> calculatedPlaceholders = valuationEngineService.generatePlaceholders(
                            order, valData, landItems, buildingItems, List.of(), compositeItems
                    );
                    for (Map.Entry<String, String> entry : calculatedPlaceholders.entrySet()) {
                        saveOrUpdateInput(orderId, entry.getKey(), entry.getValue());
                        existingValues.put(entry.getKey(), entry.getValue());
                    }

                    Map<String, String> textOnly = new HashMap<>();
                    for (Map.Entry<String, String> entry : existingValues.entrySet()) {
                        if (entry.getValue() != null && !entry.getValue().startsWith("data:image")) {
                            textOnly.put(entry.getKey(), entry.getValue());
                        }
                    }
                    order.setInputValues(objectMapper.writeValueAsString(textOnly));
                    orderRepository.save(order);
                } catch (Exception e) {
                    log.warn("Failed to synchronize ValuationData totals from saveDocumentValues: {}", e.getMessage());
                }
            }
        }

        // FIX 1: Increment workspace revision on successful save
        order.setWorkspaceRevision(expectedRev + 1);
        order.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(order);

        // SPRINT 6 & FIX 9: Audit log for saved draft values with revision governance
        try {
            Long actorId = principal != null ? principal.getId() : null;
            String actorEmail = principal != null ? principal.getEmail() : "PA";
            String actorRole = getPrincipalRole(principal);
            auditLogService.log(
                    actorId,
                    actorEmail,
                    actorRole,
                    "DRAFT_SAVED",
                    "ORDER",
                    String.valueOf(orderId),
                    "rev:" + expectedRev,
                    "rev:" + order.getWorkspaceRevision(),
                    "Saved workspace draft input values (keys: " + (request != null && request.getValues() != null ? request.getValues().size() : 0) + ") at revision " + order.getWorkspaceRevision()
            );
        } catch (Exception e) {
            log.warn("Failed to log DRAFT_SAVED for order #{}: {}", orderId, e.getMessage());
        }

        Map<String, String> result = new HashMap<>();
        result.put("status", "SAVED");
        result.put("workspaceRevision", String.valueOf(order.getWorkspaceRevision()));
        return result;
    }

    /**
     * SPRINT 6: POST /api/v1/orders/{id}/submit-to-spa
     * Advances order status from DRAFTING to SPA_GATE after validating all mandatory gates.
     */
    @Transactional
    public Map<String, String> submitToSpa(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found with ID: " + orderId));

        validateOrderAccess(order, principal, "SUBMIT_TO_SPA");

        boolean isAdmin = isSuperAdminOrAdmin(principal);
        if (!isAdmin) {
            if (order.getPaId() == null || !order.getPaId().equals(principal.getId())) {
                throw new AccessDeniedException("Access denied: You are not the assigned Property Analyst for Order #" + order.getId());
            }
        }

        if (!"DRAFTING".equalsIgnoreCase(order.getStatus()) &&
            !"WORKSPACE_READY".equalsIgnoreCase(order.getStatus()) &&
            !"ASSIGNED".equalsIgnoreCase(order.getStatus()) &&
            !"ACTION_NEEDED".equalsIgnoreCase(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Order must be in DRAFTING, WORKSPACE_READY, ASSIGNED, or ACTION_NEEDED status to submit to SPA. Current status: " + order.getStatus());
        }

        DraftValidationResponseDto validation = validateDraft(orderId, principal);
        if (!validation.isValid()) {
            List<String> allErrors = new ArrayList<>();
            allErrors.addAll(validation.getMissingFields());
            allErrors.addAll(validation.getMissingPhotos());
            allErrors.addAll(validation.getCalculationErrors());
            allErrors.addAll(validation.getPlaceholderErrors());
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Draft validation failed. Incomplete draft: " + String.join("; ", allErrors));
        }

        String previousStatus = order.getStatus();
        order.setStatus("SPA_GATE");
        order.setValuationStatus("SUBMITTED");
        order.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(order);

        // Audit Logging for submission
        String actorRole = getPrincipalRole(principal);
        auditLogService.log(
                principal != null ? principal.getId() : null,
                principal != null ? principal.getEmail() : "PA",
                actorRole,
                "PA_SUBMITTED",
                "ORDER",
                String.valueOf(orderId),
                previousStatus,
                "SPA_GATE",
                "PA submitted report draft to SPA review queue"
        );

        // Telegram Notification
        telegramNotificationService.sendSpaReviewSubmissionNotification(
                order.getReferenceCode(),
                order.getReportNumber(),
                order.getClientName(),
                principal != null ? principal.getUsername() : "Assigned PA"
        );

        Map<String, String> resp = new HashMap<>();
        resp.put("orderId", String.valueOf(orderId));
        resp.put("previousStatus", previousStatus);
        resp.put("status", "SPA_GATE");
        resp.put("valuationStatus", "SUBMITTED");
        resp.put("message", "Report draft successfully submitted to SPA review gate.");
        return resp;
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
                    if (imagesMap.containsKey("IMG_COVER_PAGE") && !imagesMap.containsKey("IMG_FRONT_PAGE")) {
                        imagesMap.put("IMG_FRONT_PAGE", imagesMap.get("IMG_COVER_PAGE"));
                    } else if (imagesMap.containsKey("IMG_FRONT_PAGE") && !imagesMap.containsKey("IMG_COVER_PAGE")) {
                        imagesMap.put("IMG_COVER_PAGE", imagesMap.get("IMG_FRONT_PAGE"));
                    }
                    if (imagesMap.containsKey("COVER_IMAGE") && !imagesMap.containsKey("IMG_COVER_PAGE")) {
                        imagesMap.put("IMG_COVER_PAGE", imagesMap.get("COVER_IMAGE"));
                    }

                    // Hydrate DOCX
                    byte[] docxBytes = docxTemplateEngine.generateReport(tplBytes, inputsMap, imagesMap);
                    
                    // Stamp digital signature and convert to PDF
                    String signerName = principal != null ? principal.getUsername() : "Senior Property Analyst (SPA)";
                    String timestamp = LocalDateTime.now().toString();
                    byte[] signedDocxBytes = docxTemplateEngine.stampDigitalSignature(docxBytes, signerName, timestamp);
                    byte[] pdfBytes = docxTemplateEngine.convertDocxToPdf(signedDocxBytes);

                    // Option A Revision Governance:
                    // Revision 0 = Original generation
                    // Revision 1 = First recompilation
                    // Revision 2 = Second recompilation
                    // Revision numbers must never decrease, never be reused, never be overwritten.
                    // Always use: MAX(existing revision) + 1.
                    List<ValuationSnapshot> existingSnapshots = valuationSnapshotRepository.findByOrderIdOrderByVersionNumberDesc(orderId);
                    int nextRevision;
                    if (existingSnapshots.isEmpty()) {
                        nextRevision = 0;
                    } else {
                        int maxRev = existingSnapshots.stream().mapToInt(ValuationSnapshot::getVersionNumber).max().orElse(-1);
                        nextRevision = Math.max(maxRev + 1, order.getRevisionCount() + 1);
                    }
                    order.setRevisionCount(nextRevision);

                    // Save as final documents
                    User uploader = principal != null ? userRepository.findById(principal.getId()).orElse(null) : null;
                    if (uploader != null) {
                        saveOrderDocument(order, "FINAL_DOCX", "Report_" + orderId + ".docx", signedDocxBytes, uploader);
                        saveOrderDocument(order, "FINAL_SIGNED_PDF", "Report_" + orderId + ".pdf", pdfBytes, uploader);
                    }

                    // Create immutable ValuationSnapshot record (Option A Mandate: never overwrite history)
                    ValuationSnapshot snapshot = new ValuationSnapshot();
                    snapshot.setOrderId(order.getId());
                    snapshot.setVersionNumber(nextRevision);
                    snapshot.setSnapshotTrigger(nextRevision == 0 ? "REPORT_GENERATED" : "REPORT_RECOMPILED");
                    snapshot.setDocxContent(signedDocxBytes);
                    snapshot.setPdfContent(pdfBytes);
                    String snapHash = computePreviewContentHash(templateId, nextRevision, inputsMap, Collections.emptyMap());
                    snapshot.setSnapshotHash(snapHash);
                    snapshot.setDocumentHash(snapHash);

                    Map<String, Object> snapshotDataMap = new HashMap<>();
                    snapshotDataMap.put("orderId", orderId);
                    snapshotDataMap.put("reportNumber", order.getReportNumber());
                    snapshotDataMap.put("revisionNumber", nextRevision);
                    snapshotDataMap.put("previousRevision", nextRevision > 0 ? (nextRevision - 1) : null);
                    snapshotDataMap.put("currentRevision", nextRevision);
                    snapshotDataMap.put("compiledBy", principal != null ? principal.getUsername() : "SPA");
                    snapshotDataMap.put("compiledAt", LocalDateTime.now().toString());
                    snapshotDataMap.put("reasonForRevision", nextRevision == 0 ? "Original generation" : "Report revision and recompilation");
                    snapshotDataMap.put("inputs", inputsMap);

                    snapshot.setSnapshotData(objectMapper.writeValueAsString(snapshotDataMap));
                    snapshot.setVersionNotes(nextRevision == 0 ? "Original generation" : ("Revision " + nextRevision + " - Recompiled"));
                    snapshot.setCreatedBy(principal != null ? principal.getId() : null);
                    snapshot.setCreatedAt(LocalDateTime.now());
                    valuationSnapshotRepository.save(snapshot);
                    log.info("Saved revision {} snapshot for order #{} [trigger: {}]", nextRevision, orderId, snapshot.getSnapshotTrigger());

                    // Audit Trail Requirements
                    try {
                        valuationAuditLogRepository.save(new ValuationAuditLog(
                                orderId,
                                "report_revision",
                                String.valueOf(nextRevision > 0 ? nextRevision - 1 : 0),
                                String.valueOf(nextRevision),
                                "RECOMPILE",
                                nextRevision == 0 ? "Original generation" : ("Revision " + nextRevision + " recompilation"),
                                principal != null ? principal.getId() : null
                        ));
                    } catch (Exception e) {
                        log.warn("Failed to save valuation audit log for order #{}: {}", orderId, e.getMessage());
                    }
                } catch (Throwable e) {
                    log.error("Failed to compile final report during SPA approval: {}", e.getMessage(), e);
                }
            }
        }

        // Lifecycle Governance: DO NOT revert FINAL_DELIVERY back to SPA_GATE or SPA_CONFIRMED.
        // Keep FINAL_DELIVERY as historical truth.
        if (!"FINAL_DELIVERY".equalsIgnoreCase(order.getStatus())) {
            order.setStatus("SPA_CONFIRMED");
        }
        orderRepository.save(order);

        Map<String, Object> result = new HashMap<>();
        result.put("status", order.getStatus());
        result.put("revisionNumber", order.getRevisionCount());
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
        if (imagesMap.containsKey("IMG_COVER_PAGE") && !imagesMap.containsKey("IMG_FRONT_PAGE")) {
            imagesMap.put("IMG_FRONT_PAGE", imagesMap.get("IMG_COVER_PAGE"));
        } else if (imagesMap.containsKey("IMG_FRONT_PAGE") && !imagesMap.containsKey("IMG_COVER_PAGE")) {
            imagesMap.put("IMG_COVER_PAGE", imagesMap.get("IMG_FRONT_PAGE"));
        }
        if (imagesMap.containsKey("COVER_IMAGE") && !imagesMap.containsKey("IMG_COVER_PAGE")) {
            imagesMap.put("IMG_COVER_PAGE", imagesMap.get("COVER_IMAGE"));
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

        // Ensure bidirectional alias coverage for cover page / front page images
        if (map.containsKey("IMG_COVER_PAGE") && (!map.containsKey("IMG_FRONT_PAGE") || map.get("IMG_FRONT_PAGE").isEmpty())) {
            map.put("IMG_FRONT_PAGE", map.get("IMG_COVER_PAGE"));
        } else if (map.containsKey("IMG_FRONT_PAGE") && (!map.containsKey("IMG_COVER_PAGE") || map.get("IMG_COVER_PAGE").isEmpty())) {
            map.put("IMG_COVER_PAGE", map.get("IMG_FRONT_PAGE"));
        }
        if (map.containsKey("COVER_IMAGE") && (!map.containsKey("IMG_COVER_PAGE") || map.get("IMG_COVER_PAGE").isEmpty())) {
            map.put("IMG_COVER_PAGE", map.get("COVER_IMAGE"));
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
                    String existingComp = map.get("RAW_COMPOSITE_ITEMS_JSON");
                    boolean shouldOverride = true;
                    if (existingComp != null && !existingComp.trim().isEmpty() && !existingComp.equals("[]")) {
                        boolean bundleHasPositiveQty = valBundle.getCompositeItems().stream()
                                .anyMatch(i -> i.getQuantity() != null && i.getQuantity().compareTo(BigDecimal.ZERO) > 0);
                        if (!bundleHasPositiveQty) {
                            shouldOverride = false;
                        }
                    }
                    if (shouldOverride) {
                        map.put("RAW_COMPOSITE_ITEMS_JSON", objectMapper.writeValueAsString(valBundle.getCompositeItems()));
                    }
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

        if (value != null && (value.startsWith("data:image/") || (value.length() > 200 && !value.contains(" ") && !value.contains("\n")))) {
            try {
                String base64Data = value;
                if (base64Data.contains(";base64,")) {
                    base64Data = base64Data.substring(base64Data.indexOf(";base64,") + 8);
                }
                byte[] bytes = Base64.getDecoder().decode(base64Data.replaceAll("\\s+", ""));
                bytes = com.provaluer.util.ImageOptimizationUtil.compressAndResizeImage(bytes);
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
     * FIX 7: Dynamic Table Safety - Row-level reconciliation for Land Items.
     * Prevents destructive deleteByOrderId() pattern and preserves row identity.
     */
    private void reconcileLandItems(Long orderId, List<ValuationLandItem> incomingItems) {
        List<ValuationLandItem> existingItems = landItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
        Map<Long, ValuationLandItem> existingById = existingItems.stream()
                .filter(i -> i.getId() != null)
                .collect(Collectors.toMap(ValuationLandItem::getId, Function.identity(), (a, b) -> a));

        Set<Long> processedIds = new HashSet<>();
        int sort = 1;

        for (ValuationLandItem incoming : incomingItems) {
            ValuationLandItem target;
            if (incoming.getId() != null && existingById.containsKey(incoming.getId())) {
                target = existingById.get(incoming.getId());
                target.setDescription(incoming.getDescription());
                target.setSurveyNo(incoming.getSurveyNo());
                target.setEnteredArea(incoming.getEnteredArea());
                target.setEnteredUnit(incoming.getEnteredUnit());
                target.setStandardAreaSqft(incoming.getStandardAreaSqft());
                target.setRate(incoming.getRate());
                target.setValue(incoming.getValue());
                target.setSortOrder(sort++);
                processedIds.add(target.getId());
            } else {
                target = incoming;
                target.setId(null);
                target.setOrderId(orderId);
                target.setSortOrder(sort++);
            }
            if (formulaService != null) {
                formulaService.calculateLandItem(target);
            }
            ValuationLandItem saved = landItemRepository.save(target);
            if (saved.getId() != null) {
                processedIds.add(saved.getId());
            }
        }

        for (ValuationLandItem existing : existingItems) {
            if (!processedIds.contains(existing.getId())) {
                landItemRepository.delete(existing);
            }
        }
    }

    /**
     * FIX 7: Dynamic Table Safety - Row-level reconciliation for Building Items.
     * Prevents destructive deleteByOrderId() pattern and preserves row identity.
     */
    private void reconcileBuildingItems(Long orderId, List<ValuationBuildingItem> incomingItems) {
        List<ValuationBuildingItem> existingItems = buildingItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
        Map<Long, ValuationBuildingItem> existingById = existingItems.stream()
                .filter(i -> i.getId() != null)
                .collect(Collectors.toMap(ValuationBuildingItem::getId, Function.identity(), (a, b) -> a));

        ValuationData vData = valuationDataRepository != null ?
                valuationDataRepository.findByOrderId(orderId).orElse(null) : null;
        BigDecimal defaultSalvage = vData != null ? vData.getDefaultSalvagePercentage() : new BigDecimal("10.00");

        Set<Long> processedIds = new HashSet<>();
        int sort = 1;

        for (ValuationBuildingItem incoming : incomingItems) {
            ValuationBuildingItem target;
            if (incoming.getId() != null && existingById.containsKey(incoming.getId())) {
                target = existingById.get(incoming.getId());
                target.setDescription(incoming.getDescription());
                target.setStructureType(incoming.getStructureType());
                target.setBuildingType(incoming.getBuildingType());
                target.setBuildingAge(incoming.getBuildingAge());
                target.setBuildingUsefulLife(incoming.getBuildingUsefulLife());
                target.setDepreciationPercentage(incoming.getDepreciationPercentage());
                target.setEnteredArea(incoming.getEnteredArea());
                target.setEnteredUnit(incoming.getEnteredUnit());
                target.setStandardAreaSqft(incoming.getStandardAreaSqft());
                target.setReplacementRate(incoming.getReplacementRate());
                target.setReplacementCost(incoming.getReplacementCost());
                target.setDepreciationAmount(incoming.getDepreciationAmount());
                target.setBuildingValue(incoming.getBuildingValue());
                target.setSalvagePercentage(incoming.getSalvagePercentage() != null ? incoming.getSalvagePercentage() : defaultSalvage);
                target.setSortOrder(sort++);
                processedIds.add(target.getId());
            } else {
                target = incoming;
                target.setId(null);
                target.setOrderId(orderId);
                target.setSortOrder(sort++);
                if (target.getSalvagePercentage() == null) {
                    target.setSalvagePercentage(defaultSalvage);
                }
            }
            if (formulaService != null) {
                formulaService.calculateBuildingItem(target);
            }
            ValuationBuildingItem saved = buildingItemRepository.save(target);
            if (saved.getId() != null) {
                processedIds.add(saved.getId());
            }
        }

        for (ValuationBuildingItem existing : existingItems) {
            if (!processedIds.contains(existing.getId())) {
                buildingItemRepository.delete(existing);
            }
        }
    }

    /**
     * FIX 7: Dynamic Table Safety - Row-level reconciliation for Composite Items.
     * Prevents destructive deleteByOrderId() pattern and preserves row identity.
     */
    private void reconcileCompositeItems(Long orderId, List<ValuationCompositeItem> incomingItems) {
        List<ValuationCompositeItem> existingItems = compositeItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
        Map<Long, ValuationCompositeItem> existingById = existingItems.stream()
                .filter(i -> i.getId() != null)
                .collect(Collectors.toMap(ValuationCompositeItem::getId, Function.identity(), (a, b) -> a));

        Set<Long> processedIds = new HashSet<>();
        int sort = 1;

        for (ValuationCompositeItem incoming : incomingItems) {
            ValuationCompositeItem target;
            if (incoming.getId() != null && existingById.containsKey(incoming.getId())) {
                target = existingById.get(incoming.getId());
                target.setItemCategory(incoming.getItemCategory() != null ? incoming.getItemCategory() : "OTHER");
                target.setDescription(incoming.getDescription());
                target.setEnteredUnit(incoming.getEnteredUnit());
                target.setQuantity(incoming.getQuantity());
                target.setRate(incoming.getRate());
                target.setAmount(incoming.getAmount());
                target.setConstructionCost(incoming.getConstructionCost());
                target.setBuildingAge(incoming.getBuildingAge());
                target.setTotalLife(incoming.getTotalLife());
                target.setDepreciationMode(incoming.getDepreciationMode());
                target.setDepreciationAmount(incoming.getDepreciationAmount());
                target.setIsInsurable(incoming.getIsInsurable());
                target.setSortOrder(sort++);
                processedIds.add(target.getId());
            } else {
                target = incoming;
                target.setId(null);
                target.setOrderId(orderId);
                target.setSortOrder(sort++);
                if (target.getItemCategory() == null) {
                    target.setItemCategory("OTHER");
                }
            }
            if (formulaService != null) {
                formulaService.calculateCompositeItem(target);
            }
            ValuationCompositeItem saved = compositeItemRepository.save(target);
            if (saved.getId() != null) {
                processedIds.add(saved.getId());
            }
        }

        for (ValuationCompositeItem existing : existingItems) {
            if (!processedIds.contains(existing.getId())) {
                compositeItemRepository.delete(existing);
            }
        }
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
                    Map<String, String> typeOverrides = TemplateProcessingService.extractTypeOverrides(template);
                    JsonNode domNode = docxStructureParser.parseDocumentStructure(template.getTemplateContent(), typeOverrides);
                    docxStructureParser.applyTypeOverridesToDom(domNode, typeOverrides);
                    String domJson = domNode.toString();

                    order.setDocumentDomSnapshot(domJson);
                    order.setTemplateVersion(currentTemplateVersion);
                    orderRepository.save(order);

                    // Also update template-level cached DOM
                    template.setDocumentDom(domJson);
                    template.setPlaceholderRegistry(docxStructureParser.generatePlaceholderRegistry(domNode, typeOverrides));
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

    /**
     * Option A Governance: Returns all revision history snapshots for an order.
     */
    public List<Map<String, Object>> getOrderRevisions(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));
        validateOrderAccess(order, principal, "VIEW");

        List<ValuationSnapshot> snapshots = valuationSnapshotRepository.findByOrderIdOrderByVersionNumberDesc(orderId);
        List<Map<String, Object>> list = new ArrayList<>();
        for (ValuationSnapshot snap : snapshots) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", snap.getId());
            map.put("orderId", snap.getOrderId());
            map.put("revisionNumber", snap.getVersionNumber());
            map.put("trigger", snap.getSnapshotTrigger());
            map.put("versionNotes", snap.getVersionNotes());
            map.put("createdAt", snap.getCreatedAt());
            map.put("createdBy", snap.getCreatedBy());
            map.put("hasDocx", snap.getDocxContent() != null && snap.getDocxContent().length > 0);
            map.put("hasPdf", snap.getPdfContent() != null && snap.getPdfContent().length > 0);

            if (snap.getSnapshotData() != null) {
                try {
                    JsonNode dataNode = objectMapper.readTree(snap.getSnapshotData());
                    if (dataNode.has("compiledBy")) map.put("compiledBy", dataNode.get("compiledBy").asText());
                    if (dataNode.has("compiledAt")) map.put("compiledAt", dataNode.get("compiledAt").asText());
                    if (dataNode.has("previousRevision")) map.put("previousRevision", dataNode.get("previousRevision").asText());
                    if (dataNode.has("currentRevision")) map.put("currentRevision", dataNode.get("currentRevision").asText());
                    if (dataNode.has("reasonForRevision")) map.put("reasonForRevision", dataNode.get("reasonForRevision").asText());
                } catch (Exception ignored) {}
            }
            list.add(map);
        }
        return list;
    }

    /**
     * Option A Governance: Returns historical revision DOCX or PDF bytes without modifying historical truth.
     */
    public byte[] getRevisionDocumentBytes(Long orderId, int revisionNumber, String type, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));
        validateOrderAccess(order, principal, "VIEW");

        ValuationSnapshot snap = valuationSnapshotRepository.findByOrderIdAndVersionNumber(orderId, revisionNumber)
                .orElseThrow(() -> new NoSuchElementException("Revision " + revisionNumber + " not found for order #" + orderId));

        if ("pdf".equalsIgnoreCase(type)) {
            if (snap.getPdfContent() == null || snap.getPdfContent().length == 0) {
                throw new NoSuchElementException("PDF content not available for revision " + revisionNumber);
            }
            return snap.getPdfContent();
        } else if ("docx".equalsIgnoreCase(type)) {
            if (snap.getDocxContent() == null || snap.getDocxContent().length == 0) {
                throw new NoSuchElementException("DOCX content not available for revision " + revisionNumber);
            }
            return snap.getDocxContent();
        }
        throw new IllegalArgumentException("Unsupported document type: " + type);
    }
}

