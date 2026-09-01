package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.PlaceholderCatalogItemDTO;
import com.provaluer.dto.SaveValuationRequest;
import com.provaluer.dto.ValuationBundleResponse;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.util.IndianCurrencyToWords;
import com.provaluer.util.IndianNumberFormatter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class ValuationEngineService {

    private static final Logger log = LoggerFactory.getLogger(ValuationEngineService.class);

    @Autowired
    private ValuationDataRepository valuationDataRepository;

    @Autowired
    private ValuationLandItemRepository landItemRepository;

    @Autowired
    private ValuationBuildingItemRepository buildingItemRepository;

    @Autowired
    private ValuationComparableSaleRepository comparableSaleRepository;

    @Autowired
    private ValuationSnapshotRepository snapshotRepository;

    @Autowired
    private ValuationAuditLogRepository auditLogRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private SystemSettingRepository systemSettingRepository;

    @Autowired
    private ValuationCalculationFormulaService formulaService;

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    /**
     * Retrieves or creates default ValuationData and child items for an order.
     */
    @Transactional
    public ValuationBundleResponse getValuationBundle(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));

        ValuationData data = valuationDataRepository.findByOrderId(orderId)
                .orElseGet(() -> initializeDefaultValuationData(order));

        List<ValuationLandItem> landItems = landItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
        List<ValuationBuildingItem> buildingItems = buildingItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
        List<ValuationComparableSale> comparables = comparableSaleRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
        List<ValuationSnapshot> snapshots = snapshotRepository.findByOrderIdOrderByVersionNumberDesc(orderId);

        // Always ensure live formula calculation
        formulaService.calculateSummary(data, landItems, buildingItems);

        Map<String, String> placeholders = generatePlaceholders(order, data, landItems, buildingItems, comparables);
        boolean isLocked = "LOCKED".equalsIgnoreCase(data.getValuationStatus()) || "LOCKED".equalsIgnoreCase(order.getValuationStatus());

        return new ValuationBundleResponse(data, landItems, buildingItems, comparables, snapshots, placeholders, isLocked);
    }

    private ValuationData initializeDefaultValuationData(Order order) {
        ValuationData data = new ValuationData(order.getId());

        // Load master default percentages if configured
        try {
            systemSettingRepository.findById("val_realizable_percentage")
                    .ifPresent(s -> data.setRealizablePercentage(new BigDecimal(s.getSettingValue())));
            systemSettingRepository.findById("val_distress_percentage")
                    .ifPresent(s -> data.setDistressSalePercentage(new BigDecimal(s.getSettingValue())));
            systemSettingRepository.findById("val_salvage_percentage")
                    .ifPresent(s -> data.setDefaultSalvagePercentage(new BigDecimal(s.getSettingValue())));
        } catch (Exception e) {
            log.warn("Failed to load default valuation settings: {}", e.getMessage());
        }

        if (order.getEstimatedValue() != null && order.getEstimatedValue().signum() > 0) {
            data.setFairValue(order.getEstimatedValue());
            data.setRealizableValue(order.getEstimatedValue().multiply(data.getRealizablePercentage()).divide(BigDecimal.valueOf(100)));
            data.setDistressSaleValue(order.getEstimatedValue().multiply(data.getDistressSalePercentage()).divide(BigDecimal.valueOf(100)));
        }

        return valuationDataRepository.save(data);
    }

    /**
     * Saves or recalculates valuation items, updates totals, logs audit changes.
     */
    @Transactional
    public ValuationBundleResponse saveValuation(Long orderId, SaveValuationRequest request, UserDetailsImpl user, String source) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new NoSuchElementException("Order not found with ID: " + orderId));

        ValuationData data = valuationDataRepository.findByOrderId(orderId)
                .orElseGet(() -> new ValuationData(orderId));

        if ("LOCKED".equalsIgnoreCase(data.getValuationStatus())) {
            throw new IllegalStateException("Valuation is LOCKED. Super Admin unlock required before editing.");
        }

        // Record Old Values for Audit Log
        BigDecimal oldFairValue = data.getFairValue();
        BigDecimal oldRealizableValue = data.getRealizableValue();
        BigDecimal oldDistressValue = data.getDistressSaleValue();
        BigDecimal oldGovtValue = data.getGovernmentValue() != null ? data.getGovernmentValue() : BigDecimal.ZERO;

        if (request.getLandRealizablePercentage() != null) {
            data.setLandRealizablePercentage(request.getLandRealizablePercentage());
        } else if (request.getRealizablePercentage() != null) {
            data.setLandRealizablePercentage(request.getRealizablePercentage());
            data.setRealizablePercentage(request.getRealizablePercentage());
        }
        if (request.getBuildingRealizablePercentage() != null) {
            data.setBuildingRealizablePercentage(request.getBuildingRealizablePercentage());
        } else if (request.getRealizablePercentage() != null) {
            data.setBuildingRealizablePercentage(request.getRealizablePercentage());
            data.setRealizablePercentage(request.getRealizablePercentage());
        }

        if (request.getLandDistressPercentage() != null) {
            data.setLandDistressPercentage(request.getLandDistressPercentage());
        } else if (request.getDistressSalePercentage() != null) {
            data.setLandDistressPercentage(request.getDistressSalePercentage());
            data.setDistressSalePercentage(request.getDistressSalePercentage());
        }
        if (request.getBuildingDistressPercentage() != null) {
            data.setBuildingDistressPercentage(request.getBuildingDistressPercentage());
        } else if (request.getDistressSalePercentage() != null) {
            data.setBuildingDistressPercentage(request.getDistressSalePercentage());
            data.setDistressSalePercentage(request.getDistressSalePercentage());
        }

        if (request.getDefaultSalvagePercentage() != null) {
            data.setDefaultSalvagePercentage(request.getDefaultSalvagePercentage());
        }
        if (request.getGovernmentValue() != null) {
            data.setGovernmentValue(request.getGovernmentValue());
        }

        // 1. Replace Land Items
        if (request.getLandItems() != null) {
            landItemRepository.deleteByOrderId(orderId);
            int orderIdx = 1;
            for (ValuationLandItem item : request.getLandItems()) {
                item.setId(null);
                item.setOrderId(orderId);
                item.setSortOrder(orderIdx++);
                formulaService.calculateLandItem(item);
                landItemRepository.save(item);
            }
        }

        // 2. Replace Building Items
        if (request.getBuildingItems() != null) {
            buildingItemRepository.deleteByOrderId(orderId);
            int orderIdx = 1;
            for (ValuationBuildingItem item : request.getBuildingItems()) {
                item.setId(null);
                item.setOrderId(orderId);
                item.setSortOrder(orderIdx++);
                if (item.getSalvagePercentage() == null) {
                    item.setSalvagePercentage(data.getDefaultSalvagePercentage());
                }
                formulaService.calculateBuildingItem(item);
                buildingItemRepository.save(item);
            }
        }

        // 3. Replace Comparable Sales
        if (request.getComparableSales() != null) {
            comparableSaleRepository.deleteByOrderId(orderId);
            int orderIdx = 1;
            for (ValuationComparableSale item : request.getComparableSales()) {
                item.setId(null);
                item.setOrderId(orderId);
                item.setSortOrder(orderIdx++);
                comparableSaleRepository.save(item);
            }
        }

        List<ValuationLandItem> landItems = landItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
        List<ValuationBuildingItem> buildingItems = buildingItemRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);
        List<ValuationComparableSale> comparables = comparableSaleRepository.findByOrderIdOrderBySortOrderAscIdAsc(orderId);

        // 4. Run calculation summary
        formulaService.calculateSummary(data, landItems, buildingItems);
        data.setUpdatedAt(LocalDateTime.now());
        valuationDataRepository.save(data);

        // 5. Update Order Final Value & Estimated Value
        order.setFinalValue(data.getFairValue());
        if (order.getEstimatedValue() == null || order.getEstimatedValue().signum() == 0) {
            order.setEstimatedValue(data.getFairValue());
        }
        orderRepository.save(order);

        // 6. Audit Log
        Long userId = user != null ? user.getId() : null;
        if (oldFairValue != null && oldFairValue.compareTo(data.getFairValue()) != 0) {
            auditLogRepository.save(new ValuationAuditLog(
                    orderId, "fair_value", oldFairValue.toString(), data.getFairValue().toString(),
                    source != null ? source : "manual_edit", request.getReason(), userId
            ));
        }
        if (oldRealizableValue != null && oldRealizableValue.compareTo(data.getRealizableValue()) != 0) {
            auditLogRepository.save(new ValuationAuditLog(
                    orderId, "realizable_value", oldRealizableValue.toString(), data.getRealizableValue().toString(),
                    source != null ? source : "manual_edit", request.getReason(), userId
            ));
        }
        if (oldDistressValue != null && oldDistressValue.compareTo(data.getDistressSaleValue()) != 0) {
            auditLogRepository.save(new ValuationAuditLog(
                    orderId, "distress_sale_value", oldDistressValue.toString(), data.getDistressSaleValue().toString(),
                    source != null ? source : "manual_edit", request.getReason(), userId
            ));
        }
        if (oldGovtValue != null && oldGovtValue.compareTo(data.getGovernmentValue()) != 0) {
            auditLogRepository.save(new ValuationAuditLog(
                    orderId, "government_value", oldGovtValue.toString(), data.getGovernmentValue().toString(),
                    source != null ? source : "manual_edit", request.getReason(), userId
            ));
        }

        Map<String, String> placeholders = generatePlaceholders(order, data, landItems, buildingItems, comparables);
        List<ValuationSnapshot> snapshots = snapshotRepository.findByOrderIdOrderByVersionNumberDesc(orderId);

        return new ValuationBundleResponse(data, landItems, buildingItems, comparables, snapshots, placeholders, false);
    }

    /**
     * Finalizes report valuation, freezes numbers, and captures immutable snapshot.
     */
    @Transactional
    public ValuationBundleResponse finalizeValuation(Long orderId, UserDetailsImpl user, String versionNotes, byte[] docxBytes, byte[] pdfBytes) {
        ValuationBundleResponse bundle = getValuationBundle(orderId);
        ValuationData data = bundle.getValuationData();

        data.setValuationStatus("FINALIZED");
        int nextVersion = data.getCurrentVersion() + 1;
        data.setCurrentVersion(nextVersion);
        data.setUpdatedAt(LocalDateTime.now());
        valuationDataRepository.save(data);

        Order order = orderRepository.findById(orderId).orElseThrow();
        order.setValuationStatus("FINALIZED");
        orderRepository.save(order);

        // Create Immutable Snapshot
        createSnapshot(order, data, bundle.getLandItems(), bundle.getBuildingItems(), bundle.getComparableSales(),
                bundle.getPlaceholders(), "REPORT_FINALIZED", nextVersion, versionNotes, user, docxBytes, pdfBytes);

        auditLogRepository.save(new ValuationAuditLog(
                orderId, "valuation_status", "DRAFT", "FINALIZED", "manual_edit", versionNotes != null ? versionNotes : "Valuation Finalized v" + nextVersion, user != null ? user.getId() : null
        ));

        return getValuationBundle(orderId);
    }

    /**
     * Locks valuation (completely immutable).
     */
    @Transactional
    public ValuationBundleResponse lockValuation(Long orderId, UserDetailsImpl user) {
        ValuationBundleResponse bundle = getValuationBundle(orderId);
        ValuationData data = bundle.getValuationData();

        data.setValuationStatus("LOCKED");
        data.setUpdatedAt(LocalDateTime.now());
        valuationDataRepository.save(data);

        Order order = orderRepository.findById(orderId).orElseThrow();
        order.setValuationStatus("LOCKED");
        orderRepository.save(order);

        auditLogRepository.save(new ValuationAuditLog(
                orderId, "valuation_status", "FINALIZED", "LOCKED", "manual_edit", "Valuation Locked", user != null ? user.getId() : null
        ));

        return getValuationBundle(orderId);
    }

    /**
     * Super Admin unlock permission.
     */
    @Transactional
    public ValuationBundleResponse unlockValuation(Long orderId, UserDetailsImpl user, String reason) {
        if (user == null || user.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_SUPER_ADMIN"))) {
            throw new AccessDeniedException("Only SUPER_ADMIN can unlock a locked valuation.");
        }

        ValuationBundleResponse bundle = getValuationBundle(orderId);
        ValuationData data = bundle.getValuationData();

        String oldStatus = data.getValuationStatus();
        data.setValuationStatus("DRAFT");
        data.setUpdatedAt(LocalDateTime.now());
        valuationDataRepository.save(data);

        Order order = orderRepository.findById(orderId).orElseThrow();
        order.setValuationStatus("DRAFT");
        orderRepository.save(order);

        auditLogRepository.save(new ValuationAuditLog(
                orderId, "valuation_status", oldStatus, "DRAFT", "restore", reason != null ? reason : "Super Admin unlocked report", user.getId()
        ));

        return getValuationBundle(orderId);
    }

    private void createSnapshot(Order order, ValuationData data, List<ValuationLandItem> landItems,
                                List<ValuationBuildingItem> buildingItems, List<ValuationComparableSale> comparables,
                                Map<String, String> placeholders, String trigger, int versionNumber, String notes,
                                UserDetailsImpl user, byte[] docxBytes, byte[] pdfBytes) {
        try {
            Map<String, Object> snapshotMap = new HashMap<>();
            snapshotMap.put("valuationData", data);
            snapshotMap.put("landItems", landItems);
            snapshotMap.put("buildingItems", buildingItems);
            snapshotMap.put("comparableSales", comparables);
            snapshotMap.put("placeholders", placeholders);
            snapshotMap.put("order", Map.of(
                    "id", order.getId(),
                    "reportNumber", order.getReportNumber() != null ? order.getReportNumber() : "",
                    "clientName", order.getClientName() != null ? order.getClientName() : "",
                    "bankName", order.getBankName() != null ? order.getBankName() : "",
                    "branchName", order.getBranchName() != null ? order.getBranchName() : ""
            ));

            String json = objectMapper.writeValueAsString(snapshotMap);
            String snapshotHash = computeSha256(json.getBytes(StandardCharsets.UTF_8));
            String documentHash = (pdfBytes != null && pdfBytes.length > 0) ? computeSha256(pdfBytes) :
                    ((docxBytes != null && docxBytes.length > 0) ? computeSha256(docxBytes) : snapshotHash);

            ValuationSnapshot snapshot = new ValuationSnapshot();
            snapshot.setOrderId(order.getId());
            snapshot.setVersionNumber(versionNumber);
            snapshot.setSnapshotTrigger(trigger);
            snapshot.setSnapshotHash(snapshotHash);
            snapshot.setDocumentHash(documentHash);
            snapshot.setSnapshotData(json);
            snapshot.setDocxContent(docxBytes);
            snapshot.setPdfContent(pdfBytes);
            snapshot.setVersionNotes(notes);
            snapshot.setCreatedBy(user != null ? user.getId() : null);

            snapshotRepository.save(snapshot);
            log.info("Created immutable snapshot v{} for order #{} [trigger: {}]", versionNumber, order.getId(), trigger);
        } catch (Exception e) {
            log.error("Failed to create snapshot for order #{}: {}", order.getId(), e.getMessage());
        }
    }

    private String computeSha256(byte[] data) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(data);
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            return UUID.randomUUID().toString().replace("-", "");
        }
    }

    /**
     * Generates all canonical placeholders with Indian numbers and words format.
     */
    public Map<String, String> generatePlaceholders(Order order, ValuationData data,
                                                    List<ValuationLandItem> landItems,
                                                    List<ValuationBuildingItem> buildingItems,
                                                    List<ValuationComparableSale> comparables) {
        Map<String, String> map = new LinkedHashMap<>();

        // Property Metadata
        map.put("report_no", order.getReportNumber() != null ? order.getReportNumber() : "PV-" + order.getId());
        map.put("report_version", "v" + data.getCurrentVersion());
        map.put("valuation_status", data.getValuationStatus());
        map.put("report_date", LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd-MM-yyyy")));
        map.put("valuation_date", LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd-MM-yyyy")));
        map.put("inspection_date", LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd-MM-yyyy")));
        map.put("owner_name", order.getClientName() != null ? order.getClientName() : "");
        map.put("client_name", order.getClientName() != null ? order.getClientName() : "");
        map.put("bank_name", order.getBankName() != null ? order.getBankName() : "");
        map.put("branch_name", order.getBranchName() != null ? order.getBranchName() : "");
        map.put("property_type", order.getPropertyCategory() != null ? order.getPropertyCategory() : "Commercial Property");
        map.put("property_address", "");

        // Land Values
        map.put("total_land_value", IndianNumberFormatter.format(data.getTotalLandValue()));
        map.put("total_land_value_words", IndianCurrencyToWords.convertToWords(data.getTotalLandValue()));
        BigDecimal sayLand = data.getSayLandValue() != null && data.getSayLandValue().compareTo(BigDecimal.ZERO) > 0
                ? data.getSayLandValue()
                : computeSayValue(data.getTotalLandValue());
        map.put("say_land_value", IndianNumberFormatter.format(sayLand));
        map.put("say_land_value_words", IndianCurrencyToWords.convertToWords(sayLand));

        // Building Values
        map.put("total_replacement_cost", IndianNumberFormatter.format(data.getTotalReplacementCost()));
        map.put("total_replacement_cost_words", IndianCurrencyToWords.convertToWords(data.getTotalReplacementCost()));
        map.put("total_depreciation_amount", IndianNumberFormatter.format(data.getTotalDepreciationAmount()));
        map.put("total_depreciation_amount_words", IndianCurrencyToWords.convertToWords(data.getTotalDepreciationAmount()));
        map.put("total_salvage_value", IndianNumberFormatter.format(data.getTotalSalvageValue()));
        map.put("total_salvage_value_words", IndianCurrencyToWords.convertToWords(data.getTotalSalvageValue()));
        map.put("total_building_value", IndianNumberFormatter.format(data.getTotalBuildingValue()));
        map.put("total_building_value_words", IndianCurrencyToWords.convertToWords(data.getTotalBuildingValue()));
        BigDecimal sayBldg = data.getSayBuildingValue() != null && data.getSayBuildingValue().compareTo(BigDecimal.ZERO) > 0
                ? data.getSayBuildingValue()
                : computeSayValue(data.getTotalBuildingValue());
        map.put("say_building_value", IndianNumberFormatter.format(sayBldg));
        map.put("say_building_value_words", IndianCurrencyToWords.convertToWords(sayBldg));

        // Valuation Summary
        BigDecimal fairVal = sayLand.add(sayBldg);
        map.put("fair_value", IndianNumberFormatter.format(fairVal));
        map.put("fair_value_words", IndianCurrencyToWords.convertToWords(fairVal));

        // Separate Realizable
        BigDecimal landRealPct = data.getLandRealizablePercentage() != null ? data.getLandRealizablePercentage() : new BigDecimal("85.00");
        BigDecimal bldgRealPct = data.getBuildingRealizablePercentage() != null ? data.getBuildingRealizablePercentage() : new BigDecimal("85.00");
        BigDecimal landRealVal = data.getLandRealizableValue() != null && data.getLandRealizableValue().compareTo(BigDecimal.ZERO) > 0
                ? data.getLandRealizableValue()
                : sayLand.multiply(landRealPct).divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
        BigDecimal bldgRealVal = data.getBuildingRealizableValue() != null && data.getBuildingRealizableValue().compareTo(BigDecimal.ZERO) > 0
                ? data.getBuildingRealizableValue()
                : sayBldg.multiply(bldgRealPct).divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
        BigDecimal totalRealVal = landRealVal.add(bldgRealVal);

        map.put("land_realizable_percentage", landRealPct + "%");
        map.put("land_realizable_value", IndianNumberFormatter.format(landRealVal));
        map.put("land_realizable_value_words", IndianCurrencyToWords.convertToWords(landRealVal));
        map.put("building_realizable_percentage", bldgRealPct + "%");
        map.put("building_realizable_value", IndianNumberFormatter.format(bldgRealVal));
        map.put("building_realizable_value_words", IndianCurrencyToWords.convertToWords(bldgRealVal));
        map.put("realizable_percentage", landRealPct + "%");
        map.put("realizable_value", IndianNumberFormatter.format(totalRealVal));
        map.put("realizable_value_words", IndianCurrencyToWords.convertToWords(totalRealVal));

        // Separate Distress
        BigDecimal landDistPct = data.getLandDistressPercentage() != null ? data.getLandDistressPercentage() : new BigDecimal("75.00");
        BigDecimal bldgDistPct = data.getBuildingDistressPercentage() != null ? data.getBuildingDistressPercentage() : new BigDecimal("75.00");
        BigDecimal landDistVal = data.getLandDistressValue() != null && data.getLandDistressValue().compareTo(BigDecimal.ZERO) > 0
                ? data.getLandDistressValue()
                : sayLand.multiply(landDistPct).divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
        BigDecimal bldgDistVal = data.getBuildingDistressValue() != null && data.getBuildingDistressValue().compareTo(BigDecimal.ZERO) > 0
                ? data.getBuildingDistressValue()
                : sayBldg.multiply(bldgDistPct).divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
        BigDecimal totalDistVal = landDistVal.add(bldgDistVal);

        map.put("land_distress_percentage", landDistPct + "%");
        map.put("land_distress_value", IndianNumberFormatter.format(landDistVal));
        map.put("land_distress_value_words", IndianCurrencyToWords.convertToWords(landDistVal));
        map.put("building_distress_percentage", bldgDistPct + "%");
        map.put("building_distress_value", IndianNumberFormatter.format(bldgDistVal));
        map.put("building_distress_value_words", IndianCurrencyToWords.convertToWords(bldgDistVal));
        map.put("distress_sale_percentage", landDistPct + "%");
        map.put("distress_sale_value", IndianNumberFormatter.format(totalDistVal));
        map.put("distress_sale_value_words", IndianCurrencyToWords.convertToWords(totalDistVal));

        // Insurable Value (Business Rule: Insurable Value = Total Replacement Cost of Buildings)
        BigDecimal insurableVal = (data.getInsurableValue() != null && data.getInsurableValue().signum() > 0)
                ? data.getInsurableValue()
                : (data.getTotalReplacementCost() != null ? data.getTotalReplacementCost() : BigDecimal.ZERO);
        map.put("insurable_value", IndianNumberFormatter.format(insurableVal));
        map.put("insurable_value_words", IndianCurrencyToWords.convertToWords(insurableVal));

        // Government Value (Independent Guideline / Statutory Value)
        BigDecimal landGovt = data.getLandGovernmentValue() != null && data.getLandGovernmentValue().compareTo(BigDecimal.ZERO) > 0
                ? data.getLandGovernmentValue()
                : formulaService.calculateLandGovernmentValue(landItems, new BigDecimal("5500"));
        BigDecimal bldgGovt = data.getBuildingGovernmentValue() != null && data.getBuildingGovernmentValue().compareTo(BigDecimal.ZERO) > 0
                ? data.getBuildingGovernmentValue()
                : formulaService.calculateBuildingGovernmentValue(buildingItems, new BigDecimal("2400"), new BigDecimal("1900"));
        BigDecimal totalGovt = (data.getGovernmentValue() != null && data.getGovernmentValue().compareTo(BigDecimal.ZERO) > 0)
                ? data.getGovernmentValue()
                : landGovt.add(bldgGovt);

        map.put("land_government_value", IndianNumberFormatter.format(landGovt));
        map.put("land_government_value_words", IndianCurrencyToWords.convertToWords(landGovt));
        map.put("building_government_value", IndianNumberFormatter.format(bldgGovt));
        map.put("building_government_value_words", IndianCurrencyToWords.convertToWords(bldgGovt));
        map.put("government_value", IndianNumberFormatter.format(totalGovt));
        map.put("government_value_words", IndianCurrencyToWords.convertToWords(totalGovt));

        // Say Value
        BigDecimal sayVal = computeSayValue(fairVal);
        map.put("say_value", IndianNumberFormatter.format(sayVal));
        map.put("say_value_words", IndianCurrencyToWords.convertToWords(sayVal));

        // Backward compatibility for single land / building placeholders
        if (landItems != null && !landItems.isEmpty()) {
            ValuationLandItem firstLand = landItems.get(0);
            map.put("land_area", firstLand.getEnteredArea() + " " + firstLand.getEnteredUnit());
            map.put("land_rate", IndianNumberFormatter.format(firstLand.getRate()));
            map.put("land_value", IndianNumberFormatter.format(firstLand.getValue()));
            map.put("land_value_words", IndianCurrencyToWords.convertToWords(firstLand.getValue()));
        } else {
            map.put("land_area", "0 Sq.Ft");
            map.put("land_rate", "0");
            map.put("land_value", "0");
            map.put("land_value_words", "Rupees Zero Only");
        }

        if (buildingItems != null && !buildingItems.isEmpty()) {
            ValuationBuildingItem firstBldg = buildingItems.get(0);
            map.put("building_type", firstBldg.getBuildingType());
            map.put("building_area", firstBldg.getEnteredArea() + " " + firstBldg.getEnteredUnit());
            map.put("replacement_rate", IndianNumberFormatter.format(firstBldg.getReplacementRate()));
            map.put("replacement_cost", IndianNumberFormatter.format(firstBldg.getReplacementCost()));
            map.put("replacement_cost_words", IndianCurrencyToWords.convertToWords(firstBldg.getReplacementCost()));
            map.put("building_age", firstBldg.getBuildingAge().toString() + " Years");
            map.put("building_useful_life", firstBldg.getBuildingUsefulLife() + " Years");
            map.put("depreciation_percent", firstBldg.getDepreciationPercentage().toString() + "%");
            map.put("depreciation_amount", IndianNumberFormatter.format(firstBldg.getDepreciationAmount()));
            map.put("depreciation_amount_words", IndianCurrencyToWords.convertToWords(firstBldg.getDepreciationAmount()));
            map.put("building_value", IndianNumberFormatter.format(firstBldg.getBuildingValue()));
            map.put("building_value_words", IndianCurrencyToWords.convertToWords(firstBldg.getBuildingValue()));
        }

        // Add uppercase alias keys for flexible template authoring (e.g. <<FAIR_VALUE>>)
        Map<String, String> uppercaseAliases = new HashMap<>();
        for (Map.Entry<String, String> e : map.entrySet()) {
            uppercaseAliases.put(e.getKey().toUpperCase(), e.getValue());
        }
        map.putAll(uppercaseAliases);

        return map;
    }

    /**
     * Searchable placeholder catalog across 7 functional groups.
     */
    public List<PlaceholderCatalogItemDTO> getPlaceholderCatalog() {
        List<PlaceholderCatalogItemDTO> catalog = new ArrayList<>();

        // Property
        catalog.add(new PlaceholderCatalogItemDTO("<<report_no>>", "Report Identification Number", "PV-2026-0042", "Property", "Auto-generated report number"));
        catalog.add(new PlaceholderCatalogItemDTO("<<report_version>>", "Report Revision Version", "v1", "Property", "Increments on finalization and revisions"));
        catalog.add(new PlaceholderCatalogItemDTO("<<valuation_status>>", "Valuation Lifecycle Status", "FINALIZED", "Property", "DRAFT, FINALIZED, LOCKED"));
        catalog.add(new PlaceholderCatalogItemDTO("<<report_date>>", "Date of Report Generation", "31-08-2026", "Property", "Current system date"));
        catalog.add(new PlaceholderCatalogItemDTO("<<valuation_date>>", "Effective Valuation Date", "31-08-2026", "Property", "Valuation appraisal date"));
        catalog.add(new PlaceholderCatalogItemDTO("<<inspection_date>>", "Physical Site Inspection Date", "30-08-2026", "Property", "Date inspection was conducted"));
        catalog.add(new PlaceholderCatalogItemDTO("<<owner_name>>", "Property Owner / Borrower Name", "M/s Apex Global Ltd", "Property", "Primary property title holder"));
        catalog.add(new PlaceholderCatalogItemDTO("<<client_name>>", "Client Name", "State Bank of India", "Property", "Client / Institution"));
        catalog.add(new PlaceholderCatalogItemDTO("<<bank_name>>", "Lending Bank Name", "HDFC Bank", "Property", "Banking partner"));
        catalog.add(new PlaceholderCatalogItemDTO("<<branch_name>>", "Bank Branch Name", "Commercial Center Branch", "Property", "Branch location"));
        catalog.add(new PlaceholderCatalogItemDTO("<<property_type>>", "Property Type Category", "Commercial Building", "Property", "Property classification"));

        // Land
        catalog.add(new PlaceholderCatalogItemDTO("<<total_land_value>>", "Total Land Value (Indian Format)", "85,50,000", "Land", "Sum of all land parcels"));
        catalog.add(new PlaceholderCatalogItemDTO("<<total_land_value_words>>", "Total Land Value in Banking Words", "Rupees Eighty Five Lakh Fifty Thousand Only", "Land", "Official banking currency format"));

        // Building
        catalog.add(new PlaceholderCatalogItemDTO("<<total_replacement_cost>>", "Total Building Replacement Cost", "1,20,00,000", "Building", "Gross reproduction cost"));
        catalog.add(new PlaceholderCatalogItemDTO("<<total_replacement_cost_words>>", "Replacement Cost in Words", "Rupees One Crore Twenty Lakh Only", "Building", "Words format"));
        catalog.add(new PlaceholderCatalogItemDTO("<<total_depreciation_amount>>", "Total Depreciation Amount", "18,00,000", "Building", "Depreciation with 10% salvage retention"));
        catalog.add(new PlaceholderCatalogItemDTO("<<total_depreciation_amount_words>>", "Depreciation in Words", "Rupees Eighteen Lakh Only", "Building", "Words format"));
        catalog.add(new PlaceholderCatalogItemDTO("<<total_salvage_value>>", "Total Salvage Value Floor", "12,00,000", "Building", "10% salvage floor"));
        catalog.add(new PlaceholderCatalogItemDTO("<<total_building_value>>", "Total Depreciated Building Value", "1,02,00,000", "Building", "Sum of all building structures"));
        catalog.add(new PlaceholderCatalogItemDTO("<<total_building_value_words>>", "Building Value in Words", "Rupees One Crore Two Lakh Only", "Building", "Words format"));

        // Valuation Summary & Certificates
        catalog.add(new PlaceholderCatalogItemDTO("<<fair_value>>", "Total Fair Market Value", "1,87,50,000", "Valuation", "Total Land Value + Total Building Value"));
        catalog.add(new PlaceholderCatalogItemDTO("<<fair_value_words>>", "Fair Market Value in Words", "Rupees One Crore Eighty Seven Lakh Fifty Thousand Only", "Valuation", "Certified banking wording"));
        catalog.add(new PlaceholderCatalogItemDTO("<<realizable_percentage>>", "Realizable Percentage", "85%", "Valuation", "Default 85%, editable"));
        catalog.add(new PlaceholderCatalogItemDTO("<<realizable_value>>", "Realizable Sale Value", "1,59,37,500", "Valuation", "Fair Value * Realizable %"));
        catalog.add(new PlaceholderCatalogItemDTO("<<realizable_value_words>>", "Realizable Value in Words", "Rupees One Crore Fifty Nine Lakh Thirty Seven Thousand Five Hundred Only", "Valuation", "Certified wording"));
        catalog.add(new PlaceholderCatalogItemDTO("<<distress_sale_percentage>>", "Distress Sale Percentage", "75%", "Valuation", "Default 75%, editable"));
        catalog.add(new PlaceholderCatalogItemDTO("<<distress_sale_value>>", "Distress Sale Value", "1,40,62,500", "Valuation", "Fair Value * Distress %"));
        catalog.add(new PlaceholderCatalogItemDTO("<<distress_sale_value_words>>", "Distress Sale Value in Words", "Rupees One Crore Forty Lakh Sixty Two Thousand Five Hundred Only", "Valuation", "Certified wording"));
        catalog.add(new PlaceholderCatalogItemDTO("<<insurable_value>>", "Insurable Value (Total Building Replacement Cost)", "1,20,00,000", "Valuation", "Total Building Replacement Cost (excl. land)"));
        catalog.add(new PlaceholderCatalogItemDTO("<<insurable_value_words>>", "Insurable Value in Words", "Rupees One Crore Twenty Lakh Only", "Valuation", "Certified words format"));
        catalog.add(new PlaceholderCatalogItemDTO("<<government_value>>", "Government / Guideline Value", "95,00,000", "Valuation", "Statutory or guideline rate value"));
        catalog.add(new PlaceholderCatalogItemDTO("<<government_value_words>>", "Government Value in Words", "Rupees Ninety Five Lakh Only", "Valuation", "Certified words format"));
        catalog.add(new PlaceholderCatalogItemDTO("<<say_value>>", "Say Value (Rounded Fair Value)", "1,88,00,000", "Valuation", "Presentation Say Value rounded to nearest Lakh if >= 1 Crore"));
        catalog.add(new PlaceholderCatalogItemDTO("<<say_value_words>>", "Say Value in Words", "Rupees One Crore Eighty Eight Lakh Only", "Valuation", "Certified words for Say Value"));

        // Dynamic Tables
        catalog.add(new PlaceholderCatalogItemDTO("<<LAND_TABLE>>", "Dynamic Land Parcels Table", "Generated Land Table", "Dynamic Tables", "Auto-expands all parcels with survey numbers and totals"));
        catalog.add(new PlaceholderCatalogItemDTO("<<BUILDING_TABLE>>", "Dynamic Building Breakdown Table", "Generated Building Table", "Dynamic Tables", "Auto-expands structures, rates, depreciation & totals"));
        catalog.add(new PlaceholderCatalogItemDTO("<<PROPERTY_VALUE_TABLE>>", "Dynamic Property Value Component Table", "Generated Property Value Table", "Dynamic Tables", "Renders Value of Land, Value of Building, Total, Say"));
        catalog.add(new PlaceholderCatalogItemDTO("<<VALUATION_SUMMARY_TABLE>>", "Dynamic Valuation Summary Table", "Generated Summary Table", "Dynamic Tables", "Complete financial breakdown table"));
        catalog.add(new PlaceholderCatalogItemDTO("<<COMPARABLES_TABLE>>", "Market Comparable Sales Table", "Generated Comparables Table", "Dynamic Tables", "Comparable transactions matrix"));

        return catalog;
    }

    /**
     * Presentation Say Value: Rounded Fair Value to nearest Lakh when Fair Value >= 1 Crore.
     */
    public static BigDecimal computeSayValue(BigDecimal fairValue) {
        if (fairValue == null) {
            return BigDecimal.ZERO;
        }
        BigDecimal oneCrore = new BigDecimal("10000000");
        BigDecimal oneLakh = new BigDecimal("100000");
        if (fairValue.compareTo(oneCrore) >= 0) {
            BigDecimal roundedInLakhs = fairValue.divide(oneLakh, 0, java.math.RoundingMode.HALF_UP);
            return roundedInLakhs.multiply(oneLakh).setScale(2, java.math.RoundingMode.HALF_UP);
        } else {
            return fairValue.setScale(2, java.math.RoundingMode.HALF_UP);
        }
    }
}
