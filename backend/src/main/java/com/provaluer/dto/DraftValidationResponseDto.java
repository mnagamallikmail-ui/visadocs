package com.provaluer.dto;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class DraftValidationResponseDto {
    private Long orderId;
    private boolean valid;
    private boolean canSubmit;
    private List<String> missingFields = new ArrayList<>();
    private List<String> missingPhotos = new ArrayList<>();
    private List<String> calculationErrors = new ArrayList<>();
    private List<String> placeholderErrors = new ArrayList<>();
    private String message;
    private LocalDateTime validationTimestamp;

    public DraftValidationResponseDto() {}

    public Long getOrderId() {
        return orderId;
    }

    public void setOrderId(Long orderId) {
        this.orderId = orderId;
    }

    public boolean isValid() {
        return valid;
    }

    public void setValid(boolean valid) {
        this.valid = valid;
    }

    public boolean isCanSubmit() {
        return canSubmit;
    }

    public void setCanSubmit(boolean canSubmit) {
        this.canSubmit = canSubmit;
    }

    public List<String> getMissingFields() {
        return missingFields;
    }

    public void setMissingFields(List<String> missingFields) {
        this.missingFields = missingFields;
    }

    public List<String> getMissingPhotos() {
        return missingPhotos;
    }

    public void setMissingPhotos(List<String> missingPhotos) {
        this.missingPhotos = missingPhotos;
    }

    public List<String> getCalculationErrors() {
        return calculationErrors;
    }

    public void setCalculationErrors(List<String> calculationErrors) {
        this.calculationErrors = calculationErrors;
    }

    public List<String> getPlaceholderErrors() {
        return placeholderErrors;
    }

    public void setPlaceholderErrors(List<String> placeholderErrors) {
        this.placeholderErrors = placeholderErrors;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public LocalDateTime getValidationTimestamp() {
        return validationTimestamp;
    }

    public void setValidationTimestamp(LocalDateTime validationTimestamp) {
        this.validationTimestamp = validationTimestamp;
    }

    public int getErrorCount() {
        return (missingFields != null ? missingFields.size() : 0)
                + (missingPhotos != null ? missingPhotos.size() : 0)
                + (calculationErrors != null ? calculationErrors.size() : 0)
                + (placeholderErrors != null ? placeholderErrors.size() : 0);
    }
}
