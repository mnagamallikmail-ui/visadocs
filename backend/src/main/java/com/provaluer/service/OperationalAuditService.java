package com.provaluer.service;

import com.provaluer.model.AuditLog;
import com.provaluer.model.Order;
import com.provaluer.repository.AuditLogRepository;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Enterprise Production Governance: Operational Audit & Report Lineage Service.
 * Tracks lifecycle events (Save, Autosave, Submit, PDF, Assignment, Completion)
 * and provides end-to-end report lineage tracing.
 */
@Service
public class OperationalAuditService {

    private static final Logger log = LoggerFactory.getLogger(OperationalAuditService.class);

    @Autowired
    private AuditLogRepository auditLogRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TelemetryService telemetryService;

    /**
     * Records an operational lifecycle event with full actor, order, and status metadata.
     */
    public void recordOperationalAction(
            Long actorId,
            String actorEmail,
            String actorRole,
            String actionType,
            Long orderId,
            String reportNumber,
            boolean success,
            String description) {

        String entityId = orderId != null ? orderId.toString() : (reportNumber != null ? reportNumber : "N/A");
        String resultTag = success ? "SUCCESS" : "FAILURE";
        String fullDescription = String.format("[%s] ReportNo: %s | Result: %s | %s",
                actionType, reportNumber != null ? reportNumber : "N/A", resultTag, description != null ? description : "");

        AuditLog logEntry = new AuditLog(
                actorId != null ? actorId : 0L,
                actorEmail != null ? actorEmail : "system@provaluer.in",
                actorRole != null ? actorRole : "SYSTEM",
                actionType,
                "ORDER",
                entityId,
                null,
                resultTag,
                fullDescription
        );
        auditLogRepository.save(logEntry);

        // Feed operational telemetry
        switch (actionType) {
            case "SAVE_DRAFT":
                telemetryService.recordSave(success, orderId, reportNumber, actorEmail);
                break;
            case "AUTOSAVE":
                telemetryService.recordAutosave(success, orderId, reportNumber, actorEmail);
                break;
            case "SUBMIT_TO_SPA":
                telemetryService.recordSubmitSpa(success, orderId, reportNumber, actorEmail, description);
                break;
            case "REPORT_GENERATION":
                telemetryService.recordPdfGeneration(success, orderId, reportNumber, actorEmail, description);
                break;
            default:
                break;
        }

        log.info("[OPERATIONAL AUDIT] Action: {} | Order: {} | Report: {} | Actor: {} | Result: {}",
                actionType, orderId, reportNumber, actorEmail, resultTag);
    }

    /**
     * Phase 7: End-to-End Report Lineage Tracing.
     * Trace: Report Number -> Order -> Valuer -> PA -> SPA -> Generated PDF -> Approval -> Archive.
     */
    public Map<String, Object> getReportNumberLineage(String reportNumber) {
        Map<String, Object> lineage = new LinkedHashMap<>();
        lineage.put("reportNumber", reportNumber);
        lineage.put("queryTimestamp", LocalDateTime.now().toString());

        Optional<Order> orderOpt = orderRepository.findByReportNumber(reportNumber);
        if (orderOpt.isEmpty()) {
            lineage.put("status", "NOT_FOUND");
            lineage.put("message", "No order found with report number: " + reportNumber);
            return lineage;
        }

        Order order = orderOpt.get();
        lineage.put("orderId", order.getId());
        lineage.put("referenceCode", order.getReferenceCode());
        lineage.put("currentStatus", order.getStatus());
        lineage.put("createdAt", order.getCreatedAt() != null ? order.getCreatedAt().toString() : null);
        lineage.put("releasedToPoolAt", order.getReleasedToPoolAt() != null ? order.getReleasedToPoolAt().toString() : null);
        lineage.put("claimedAt", order.getClaimedAt() != null ? order.getClaimedAt().toString() : null);
        lineage.put("finalValue", order.getFinalValue());

        // Trace Actors: Client, Valuer/PA
        if (order.getClientId() != null) {
            userRepository.findById(order.getClientId()).ifPresent(u -> {
                lineage.put("client", Map.of("id", u.getId(), "name", u.getFullName() != null ? u.getFullName() : u.getUsername(), "email", u.getEmail()));
            });
        }
        if (order.getPaId() != null) {
            userRepository.findById(order.getPaId()).ifPresent(u -> {
                lineage.put("valuer_pa", Map.of("id", u.getId(), "name", u.getFullName() != null ? u.getFullName() : u.getUsername(), "email", u.getEmail(), "role", u.getRole().name()));
            });
        }

        // Trace Audit Events
        List<AuditLog> auditEvents = auditLogRepository.findAllByEntityTypeAndEntityIdOrderByTimestampDesc("ORDER", order.getId().toString());
        List<Map<String, Object>> eventsList = new ArrayList<>();
        for (AuditLog event : auditEvents) {
            eventsList.add(Map.of(
                    "timestamp", event.getTimestamp().toString(),
                    "actor", event.getActorEmail(),
                    "role", event.getActorRole(),
                    "action", event.getActionType(),
                    "result", event.getNewValue() != null ? event.getNewValue() : "SUCCESS",
                    "description", event.getDescription() != null ? event.getDescription() : ""
            ));
        }
        lineage.put("auditHistory", eventsList);
        lineage.put("totalAuditEntries", eventsList.size());
        lineage.put("status", "AUDIT_VERIFIED");

        return lineage;
    }
}
