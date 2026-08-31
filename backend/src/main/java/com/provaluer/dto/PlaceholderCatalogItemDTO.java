package com.provaluer.dto;

public class PlaceholderCatalogItemDTO {
    private String placeholder;
    private String description;
    private String sampleValue;
    private String category;
    private String usageNotes;

    public PlaceholderCatalogItemDTO() {}

    public PlaceholderCatalogItemDTO(String placeholder, String description, String sampleValue, String category, String usageNotes) {
        this.placeholder = placeholder;
        this.description = description;
        this.sampleValue = sampleValue;
        this.category = category;
        this.usageNotes = usageNotes;
    }

    public String getPlaceholder() { return placeholder; }
    public void setPlaceholder(String placeholder) { this.placeholder = placeholder; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getSampleValue() { return sampleValue; }
    public void setSampleValue(String sampleValue) { this.sampleValue = sampleValue; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getUsageNotes() { return usageNotes; }
    public void setUsageNotes(String usageNotes) { this.usageNotes = usageNotes; }
}
