package com.provaluer.dto;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Map;

public class SpaApproveDocumentRequest implements Serializable {
    private static final long serialVersionUID = 1L;

    private BigDecimal finalValue;
    private Map<String, String> modifiedValues;

    public SpaApproveDocumentRequest() {}

    public SpaApproveDocumentRequest(BigDecimal finalValue, Map<String, String> modifiedValues) {
        this.finalValue = finalValue;
        this.modifiedValues = modifiedValues;
    }

    public BigDecimal getFinalValue() { return finalValue; }
    public void setFinalValue(BigDecimal finalValue) { this.finalValue = finalValue; }

    public Map<String, String> getModifiedValues() { return modifiedValues; }
    public void setModifiedValues(Map<String, String> modifiedValues) { this.modifiedValues = modifiedValues; }
}
