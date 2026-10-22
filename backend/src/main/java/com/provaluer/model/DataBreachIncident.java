package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * DPDP Act 2023 - Section 8(6) Data Breach Registry
 * Tracks suspected or confirmed data breach incidents, root causes, severity, and containment status.
 */
@Entity
@Table(name = "data_breach_registry")
public class DataBreachIncident {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "incident_id", nullable = false, unique = true, length = 64)
    private String incidentId;

    @Column(name = "discovery_time", nullable = false)
    private LocalDateTime discoveryTime;

    @Column(name = "severity", nullable = false, length = 32)
    private String severity = "MEDIUM"; // LOW, MEDIUM, HIGH, CRITICAL

    @Column(name = "status", nullable = false, length = 32)
    private String status = "OPEN"; // OPEN, UNDER_INVESTIGATION, CONTAINED, NOTIFIED, CLOSED

    @Column(name = "root_cause", columnDefinition = "TEXT")
    private String rootCause;

    @Column(name = "impact_assessment", columnDefinition = "TEXT")
    private String impactAssessment;

    @Column(name = "number_affected", nullable = false)
    private int numberAffected = 0;

    @Column(name = "containment_status", length = 64)
    private String containmentStatus = "UNDER_ANALYSIS";

    @Column(name = "closure_notes", columnDefinition = "TEXT")
    private String closureNotes;

    @Column(name = "data_impacted", columnDefinition = "TEXT")
    private String dataImpacted;

    @Column(name = "systems_impacted", columnDefinition = "TEXT")
    private String systemsImpacted;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public DataBreachIncident() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getIncidentId() { return incidentId; }
    public void setIncidentId(String incidentId) { this.incidentId = incidentId; }

    public LocalDateTime getDiscoveryTime() { return discoveryTime; }
    public void setDiscoveryTime(LocalDateTime discoveryTime) { this.discoveryTime = discoveryTime; }

    public String getSeverity() { return severity; }
    public void setSeverity(String severity) { this.severity = severity; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getRootCause() { return rootCause; }
    public void setRootCause(String rootCause) { this.rootCause = rootCause; }

    public String getImpactAssessment() { return impactAssessment; }
    public void setImpactAssessment(String impactAssessment) { this.impactAssessment = impactAssessment; }

    public int getNumberAffected() { return numberAffected; }
    public void setNumberAffected(int numberAffected) { this.numberAffected = numberAffected; }

    public String getContainmentStatus() { return containmentStatus; }
    public void setContainmentStatus(String containmentStatus) { this.containmentStatus = containmentStatus; }

    public String getClosureNotes() { return closureNotes; }
    public void setClosureNotes(String closureNotes) { this.closureNotes = closureNotes; }

    public String getDataImpacted() { return dataImpacted; }
    public void setDataImpacted(String dataImpacted) { this.dataImpacted = dataImpacted; }

    public String getSystemsImpacted() { return systemsImpacted; }
    public void setSystemsImpacted(String systemsImpacted) { this.systemsImpacted = systemsImpacted; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
