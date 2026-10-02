package com.provaluer.dto;

public class AcknowledgeDeliveryRequest {
    private String action; // VIEWED, DOWNLOADED, ACCEPTED, CLARIFICATION_REQUESTED
    private String clarificationType;
    private String clarificationNotes;
    private String acceptanceDeclaration;

    public AcknowledgeDeliveryRequest() {}

    public AcknowledgeDeliveryRequest(String action, String clarificationType, String clarificationNotes, String acceptanceDeclaration) {
        this.action = action;
        this.clarificationType = clarificationType;
        this.clarificationNotes = clarificationNotes;
        this.acceptanceDeclaration = acceptanceDeclaration;
    }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getClarificationType() { return clarificationType; }
    public void setClarificationType(String clarificationType) { this.clarificationType = clarificationType; }

    public String getClarificationNotes() { return clarificationNotes; }
    public void setClarificationNotes(String clarificationNotes) { this.clarificationNotes = clarificationNotes; }

    public String getAcceptanceDeclaration() { return acceptanceDeclaration; }
    public void setAcceptanceDeclaration(String acceptanceDeclaration) { this.acceptanceDeclaration = acceptanceDeclaration; }
}
