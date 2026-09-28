package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "valuation_leads")
public class ValuationLead {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "reference_code", nullable = false, unique = true, length = 32)
    private String referenceCode;

    @Column(name = "service_vertical", nullable = false, length = 50)
    private String serviceVertical;

    @Column(name = "mandate_purpose", nullable = false, length = 100)
    private String mandatePurpose;

    @Column(name = "asset_name", nullable = false)
    private String assetName;

    @Column(name = "asset_location")
    private String assetLocation;

    @Column(name = "value_bracket", nullable = false, length = 50)
    private String valueBracket;

    @Column(name = "urgency_sla", nullable = false, length = 50)
    private String urgencySla;

    @Column(name = "contact_name", nullable = false)
    private String contactName;

    @Column(name = "contact_role", length = 100)
    private String contactRole;

    @Column(name = "company_name")
    private String companyName;

    @Column(name = "contact_email", nullable = false)
    private String contactEmail;

    @Column(name = "contact_phone", nullable = false, length = 50)
    private String contactPhone;

    @Column(name = "preferred_channel", length = 50)
    private String preferredChannel = "EMAIL";

    @Column(name = "lead_score", nullable = false)
    private int leadScore = 0;

    @Column(name = "intent_level", nullable = false, length = 20)
    private String intentLevel = "MEDIUM"; // LOW, MEDIUM, HIGH, CRITICAL

    @Column(nullable = false, length = 50)
    private String status = "NEW"; // NEW, QUALIFIED, QUOTED, WON, LOST

    @Column(name = "assigned_valuer_id")
    private Long assignedValuerId;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @OneToMany(mappedBy = "lead", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<LeadDocument> documents = new ArrayList<>();

    @OneToMany(mappedBy = "lead", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<LeadNote> notes = new ArrayList<>();

    @OneToMany(mappedBy = "lead", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<LeadQuotation> quotations = new ArrayList<>();

    @OneToMany(mappedBy = "lead", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<LeadActivityLog> activityLogs = new ArrayList<>();

    public ValuationLead() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getReferenceCode() { return referenceCode; }
    public void setReferenceCode(String referenceCode) { this.referenceCode = referenceCode; }

    public String getServiceVertical() { return serviceVertical; }
    public void setServiceVertical(String serviceVertical) { this.serviceVertical = serviceVertical; }

    public String getMandatePurpose() { return mandatePurpose; }
    public void setMandatePurpose(String mandatePurpose) { this.mandatePurpose = mandatePurpose; }

    public String getAssetName() { return assetName; }
    public void setAssetName(String assetName) { this.assetName = assetName; }

    public String getAssetLocation() { return assetLocation; }
    public void setAssetLocation(String assetLocation) { this.assetLocation = assetLocation; }

    public String getValueBracket() { return valueBracket; }
    public void setValueBracket(String valueBracket) { this.valueBracket = valueBracket; }

    public String getUrgencySla() { return urgencySla; }
    public void setUrgencySla(String urgencySla) { this.urgencySla = urgencySla; }

    public String getContactName() { return contactName; }
    public void setContactName(String contactName) { this.contactName = contactName; }

    public String getContactRole() { return contactRole; }
    public void setContactRole(String contactRole) { this.contactRole = contactRole; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getContactEmail() { return contactEmail; }
    public void setContactEmail(String contactEmail) { this.contactEmail = contactEmail; }

    public String getContactPhone() { return contactPhone; }
    public void setContactPhone(String contactPhone) { this.contactPhone = contactPhone; }

    public String getPreferredChannel() { return preferredChannel; }
    public void setPreferredChannel(String preferredChannel) { this.preferredChannel = preferredChannel; }

    public int getLeadScore() { return leadScore; }
    public void setLeadScore(int leadScore) { this.leadScore = leadScore; }

    public String getIntentLevel() { return intentLevel; }
    public void setIntentLevel(String intentLevel) { this.intentLevel = intentLevel; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Long getAssignedValuerId() { return assignedValuerId; }
    public void setAssignedValuerId(Long assignedValuerId) { this.assignedValuerId = assignedValuerId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public List<LeadDocument> getDocuments() { return documents; }
    public void setDocuments(List<LeadDocument> documents) { this.documents = documents; }

    public List<LeadNote> getNotes() { return notes; }
    public void setNotes(List<LeadNote> notes) { this.notes = notes; }

    public List<LeadQuotation> getQuotations() { return quotations; }
    public void setQuotations(List<LeadQuotation> quotations) { this.quotations = quotations; }

    public List<LeadActivityLog> getActivityLogs() { return activityLogs; }
    public void setActivityLogs(List<LeadActivityLog> activityLogs) { this.activityLogs = activityLogs; }
}
