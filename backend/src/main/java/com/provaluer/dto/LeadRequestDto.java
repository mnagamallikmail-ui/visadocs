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
    private boolean consentGiven = false;
    private boolean isMinor = false;
    private String guardianName;
    private String guardianRelationship;
    private String guardianEmail;
    private String guardianPhone;
    private boolean guardianConsentGiven = false;
    private String noticeVersion = "DPDP-NOTICE-V2.0";
    private String uploadToken;

    public LeadRequestDto() {}

    public boolean isConsentGiven() { return consentGiven; }
    public void setConsentGiven(boolean consentGiven) { this.consentGiven = consentGiven; }

    public boolean isMinor() { return isMinor; }
    public void setMinor(boolean minor) { isMinor = minor; }

    public String getGuardianName() { return guardianName; }
    public void setGuardianName(String guardianName) { this.guardianName = guardianName; }

    public String getGuardianRelationship() { return guardianRelationship; }
    public void setGuardianRelationship(String guardianRelationship) { this.guardianRelationship = guardianRelationship; }

    public String getGuardianEmail() { return guardianEmail; }
    public void setGuardianEmail(String guardianEmail) { this.guardianEmail = guardianEmail; }

    public String getGuardianPhone() { return guardianPhone; }
    public void setGuardianPhone(String guardianPhone) { this.guardianPhone = guardianPhone; }

    public boolean isGuardianConsentGiven() { return guardianConsentGiven; }
    public void setGuardianConsentGiven(boolean guardianConsentGiven) { this.guardianConsentGiven = guardianConsentGiven; }

    public String getNoticeVersion() { return noticeVersion; }
    public void setNoticeVersion(String noticeVersion) { this.noticeVersion = noticeVersion; }

    public String getUploadToken() { return uploadToken; }
    public void setUploadToken(String uploadToken) { this.uploadToken = uploadToken; }

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
