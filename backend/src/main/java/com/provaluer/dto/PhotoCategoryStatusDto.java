package com.provaluer.dto;

public class PhotoCategoryStatusDto {

    private String category;
    private String displayName;
    private boolean mandatory;
    private int minRequired;
    private long currentCount;
    private boolean satisfied;

    public PhotoCategoryStatusDto() {}

    public PhotoCategoryStatusDto(String category, String displayName, boolean mandatory, int minRequired, long currentCount) {
        this.category = category;
        this.displayName = displayName;
        this.mandatory = mandatory;
        this.minRequired = minRequired;
        this.currentCount = currentCount;
        this.satisfied = currentCount >= minRequired;
    }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getDisplayName() { return displayName; }
    public void setDisplayName(String displayName) { this.displayName = displayName; }

    public boolean isMandatory() { return mandatory; }
    public void setMandatory(boolean mandatory) { this.mandatory = mandatory; }

    public int getMinRequired() { return minRequired; }
    public void setMinRequired(int minRequired) { this.minRequired = minRequired; }

    public long getCurrentCount() { return currentCount; }
    public void setCurrentCount(long currentCount) { this.currentCount = currentCount; }

    public boolean isSatisfied() { return satisfied; }
    public void setSatisfied(boolean satisfied) { this.satisfied = satisfied; }
}
