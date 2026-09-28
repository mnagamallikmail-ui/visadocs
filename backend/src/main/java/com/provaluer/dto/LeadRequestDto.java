package com.provaluer.dto;

public class LeadRequestDto {
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
    private String preferredChannel = "EMAIL";
    private int documentCount = 0;

    public LeadRequestDto() {}

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

    public int getDocumentCount() { return documentCount; }
    public void setDocumentCount(int documentCount) { this.documentCount = documentCount; }
}
