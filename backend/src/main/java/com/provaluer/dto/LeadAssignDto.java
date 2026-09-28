package com.provaluer.dto;

public class LeadAssignDto {
    private Long valuerId;
    private String assignerName;

    public LeadAssignDto() {}

    public Long getValuerId() { return valuerId; }
    public void setValuerId(Long valuerId) { this.valuerId = valuerId; }

    public String getAssignerName() { return assignerName; }
    public void setAssignerName(String assignerName) { this.assignerName = assignerName; }
}
