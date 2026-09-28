package com.provaluer.dto;

import com.provaluer.model.ValuationLead;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

public class LeadResponseDto {
    private Long id;
    private String referenceCode;
    private String serviceVertical;
    private String mandatePurpose;
    private String assetName;
    private String assetLocation;
    private String valueBracket;
    private String urgencySla;
    private String contactName;
    private String contactRole;
    private String companyName;
    private String contactEmail;
    private String contactPhone;
    private String preferredChannel;
    private int leadScore;
    private String intentLevel;
    private String status;
    private Long assignedValuerId;
    private LocalDateTime createdAt;
    private List<DocumentDto> documents;
    private List<QuotationDto> quotations;

    public static class DocumentDto {
        public Long id;
        public String fileName;
        public String fileType;
        public Long fileSizeBytes;
        public String storagePath;
        public LocalDateTime uploadedAt;
    }

    public static class QuotationDto {
        public Long id;
        public String quoteNumber;
        public java.math.BigDecimal estimatedFee;
        public java.math.BigDecimal taxAmount;
        public java.math.BigDecimal totalFee;
        public int turnaroundDays;
        public String scopeOfWork;
        public boolean isAccepted;
        public LocalDateTime createdAt;
    }

    public LeadResponseDto() {}

    public static LeadResponseDto fromEntity(ValuationLead lead) {
        LeadResponseDto dto = new LeadResponseDto();
        dto.setId(lead.getId());
        dto.setReferenceCode(lead.getReferenceCode());
        dto.setServiceVertical(lead.getServiceVertical());
        dto.setMandatePurpose(lead.getMandatePurpose());
        dto.setAssetName(lead.getAssetName());
        dto.setAssetLocation(lead.getAssetLocation());
        dto.setValueBracket(lead.getValueBracket());
        dto.setUrgencySla(lead.getUrgencySla());
        dto.setContactName(lead.getContactName());
        dto.setContactRole(lead.getContactRole());
        dto.setCompanyName(lead.getCompanyName());
        dto.setContactEmail(lead.getContactEmail());
        dto.setContactPhone(lead.getContactPhone());
        dto.setPreferredChannel(lead.getPreferredChannel());
        dto.setLeadScore(lead.getLeadScore());
        dto.setIntentLevel(lead.getIntentLevel());
        dto.setStatus(lead.getStatus());
        dto.setAssignedValuerId(lead.getAssignedValuerId());
        dto.setCreatedAt(lead.getCreatedAt());

        if (lead.getDocuments() != null) {
            dto.setDocuments(lead.getDocuments().stream().map(doc -> {
                DocumentDto d = new DocumentDto();
                d.id = doc.getId();
                d.fileName = doc.getFileName();
                d.fileType = doc.getFileType();
                d.fileSizeBytes = doc.getFileSizeBytes();
                d.storagePath = doc.getStoragePath();
                d.uploadedAt = doc.getUploadedAt();
                return d;
            }).collect(Collectors.toList()));
        }

        if (lead.getQuotations() != null) {
            dto.setQuotations(lead.getQuotations().stream().map(q -> {
                QuotationDto qd = new QuotationDto();
                qd.id = q.getId();
                qd.quoteNumber = q.getQuoteNumber();
                qd.estimatedFee = q.getEstimatedFee();
                qd.taxAmount = q.getTaxAmount();
                qd.totalFee = q.getTotalFee();
                qd.turnaroundDays = q.getTurnaroundDays();
                qd.scopeOfWork = q.getScopeOfWork();
                qd.isAccepted = q.isAccepted();
                qd.createdAt = q.getCreatedAt();
                return qd;
            }).collect(Collectors.toList()));
        }

        return dto;
    }

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
    public List<DocumentDto> getDocuments() { return documents; }
    public void setDocuments(List<DocumentDto> documents) { this.documents = documents; }
    public List<QuotationDto> getQuotations() { return quotations; }
    public void setQuotations(List<QuotationDto> quotations) { this.quotations = quotations; }
}
