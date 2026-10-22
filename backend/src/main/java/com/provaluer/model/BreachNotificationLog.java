package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * DPDP Act 2023 - Section 8(6) Breach Notification Log
 * Logs statutory notifications sent to the Data Protection Board of India (DPBI) and affected Data Principals.
 */
@Entity
@Table(name = "breach_notification_log")
public class BreachNotificationLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "incident_id", nullable = false, length = 64)
    private String incidentId;

    @Column(name = "notification_type", nullable = false, length = 64)
    private String notificationType; // DPBI_BOARD_NOTICE, PRINCIPAL_NOTICE, INTERNAL_INCIDENT_REPORT

    @Column(name = "recipient", nullable = false)
    private String recipient;

    @Column(name = "discovery_timestamp", nullable = false)
    private LocalDateTime discoveryTimestamp;

    @Column(name = "notification_timestamp", nullable = false)
    private LocalDateTime notificationTimestamp = LocalDateTime.now();

    @Column(name = "sending_officer", nullable = false, length = 100)
    private String sendingOfficer;

    @Column(name = "evidence_package", columnDefinition = "TEXT")
    private String evidencePackage;

    @Column(name = "delivery_status", nullable = false, length = 32)
    private String deliveryStatus = "DISPATCHED";

    @Column(name = "content_payload", nullable = false, columnDefinition = "TEXT")
    private String contentPayload;

    public BreachNotificationLog() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getIncidentId() { return incidentId; }
    public void setIncidentId(String incidentId) { this.incidentId = incidentId; }

    public String getNotificationType() { return notificationType; }
    public void setNotificationType(String notificationType) { this.notificationType = notificationType; }

    public String getRecipient() { return recipient; }
    public void setRecipient(String recipient) { this.recipient = recipient; }

    public LocalDateTime getDiscoveryTimestamp() { return discoveryTimestamp; }
    public void setDiscoveryTimestamp(LocalDateTime discoveryTimestamp) { this.discoveryTimestamp = discoveryTimestamp; }

    public LocalDateTime getNotificationTimestamp() { return notificationTimestamp; }
    public void setNotificationTimestamp(LocalDateTime notificationTimestamp) { this.notificationTimestamp = notificationTimestamp; }

    public String getSendingOfficer() { return sendingOfficer; }
    public void setSendingOfficer(String sendingOfficer) { this.sendingOfficer = sendingOfficer; }

    public String getEvidencePackage() { return evidencePackage; }
    public void setEvidencePackage(String evidencePackage) { this.evidencePackage = evidencePackage; }

    public String getDeliveryStatus() { return deliveryStatus; }
    public void setDeliveryStatus(String deliveryStatus) { this.deliveryStatus = deliveryStatus; }

    public String getContentPayload() { return contentPayload; }
    public void setContentPayload(String contentPayload) { this.contentPayload = contentPayload; }
}
