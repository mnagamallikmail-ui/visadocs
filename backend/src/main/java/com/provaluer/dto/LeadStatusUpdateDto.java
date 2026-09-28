package com.provaluer.dto;

public class LeadStatusUpdateDto {
    private String status;
    private String note;

    public LeadStatusUpdateDto() {}

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
