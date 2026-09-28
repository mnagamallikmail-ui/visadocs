package com.provaluer.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "lead_activity_log")
public class LeadActivityLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lead_id", nullable = false)
    @JsonIgnore
    private ValuationLead lead;

    @Column(nullable = false, length = 100)
    private String action; // STATUS_CHANGED, ASSIGNED, QUOTE_SENT, VIEWED

    @Column(columnDefinition = "TEXT")
    private String details;

    @Column(name = "actor_name")
    private String actorName;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public LeadActivityLog() {}

    public LeadActivityLog(ValuationLead lead, String action, String details, String actorName) {
        this.lead = lead;
        this.action = action;
        this.details = details;
        this.actorName = actorName;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public ValuationLead getLead() { return lead; }
    public void setLead(ValuationLead lead) { this.lead = lead; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public String getActorName() { return actorName; }
    public void setActorName(String actorName) { this.actorName = actorName; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
