package com.provaluer.dto;

import java.io.Serializable;

/**
 * Data Transfer Object for creating or updating Document Studio visual configuration.
 */
public class SaveStudioConfigRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    private String customLabels;
    private String tableConfigs;

    public SaveStudioConfigRequest() {}

    public SaveStudioConfigRequest(String customLabels, String tableConfigs) {
        this.customLabels = customLabels;
        this.tableConfigs = tableConfigs;
    }

    public String getCustomLabels() {
        return customLabels;
    }

    public void setCustomLabels(String customLabels) {
        this.customLabels = customLabels;
    }

    public String getTableConfigs() {
        return tableConfigs;
    }

    public void setTableConfigs(String tableConfigs) {
        this.tableConfigs = tableConfigs;
    }
}
