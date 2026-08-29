package com.provaluer.dto;

import java.io.Serializable;
import java.util.Map;

public class SaveDocumentValuesRequest implements Serializable {
    private static final long serialVersionUID = 1L;

    private Map<String, String> values;

    public SaveDocumentValuesRequest() {}

    public SaveDocumentValuesRequest(Map<String, String> values) {
        this.values = values;
    }

    public Map<String, String> getValues() { return values; }
    public void setValues(Map<String, String> values) { this.values = values; }
}
