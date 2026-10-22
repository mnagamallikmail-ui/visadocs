package com.provaluer.model;

import com.provaluer.security.encryption.AesGcmEncryptionConverter;
import jakarta.persistence.*;

@Entity
@Table(name = "order_inputs")
public class OrderInput {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "field_key", nullable = false)
    private String fieldKey;

    @Column(name = "field_value", nullable = false, columnDefinition = "TEXT")
    private String fieldValue;

    @Column(name = "image_value", columnDefinition = "BYTEA")
    private byte[] imageValue;

    @Version
    @Column(name = "version", nullable = false)
    private Long version = 0L;

    public static boolean isSensitiveKey(String key) {
        if (key == null) return false;
        String k = key.toUpperCase();
        return k.contains("PAN") ||
               k.contains("AADHAAR") ||
               k.contains("ADHAAR") ||
               k.contains("PASSPORT") ||
               k.contains("BANK_ACCOUNT") ||
               k.contains("ACCOUNT_NUMBER") ||
               k.contains("BANK_ACC") ||
               k.contains("NET_WORTH") ||
               k.contains("FINANCIAL") ||
               k.contains("LOAN_ACCOUNT") ||
               k.contains("LOAN_ACC") ||
               k.contains("LOAN_DETAIL") ||
               k.contains("LOAN_DETAILS") ||
               k.contains("DRIVING_LICENCE") ||
               k.contains("DRIVING_LICENSE") ||
               k.contains("UTR");
    }

    @PrePersist
    @PreUpdate
    public void prePersistOrUpdate() {
        if (isSensitiveKey(fieldKey) && fieldValue != null && !fieldValue.startsWith("ENC_GCM:")) {
            this.fieldValue = AesGcmEncryptionConverter.encryptString(this.fieldValue);
        }
    }

    @PostPersist
    @PostUpdate
    @PostLoad
    public void postLoadOrPersist() {
        if (this.fieldValue != null && this.fieldValue.startsWith("ENC_GCM:")) {
            this.fieldValue = AesGcmEncryptionConverter.decryptString(this.fieldValue);
        }
    }

    public OrderInput() {}

    public OrderInput(Long orderId, String fieldKey, String fieldValue) {
        this.orderId = orderId;
        this.fieldKey = fieldKey;
        this.fieldValue = fieldValue;
    }

    public OrderInput(Long orderId, String fieldKey, String fieldValue, byte[] imageValue) {
        this.orderId = orderId;
        this.fieldKey = fieldKey;
        this.fieldValue = fieldValue;
        this.imageValue = imageValue;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getFieldKey() { return fieldKey; }
    public void setFieldKey(String fieldKey) { this.fieldKey = fieldKey; }

    public String getFieldValue() { return fieldValue; }
    public void setFieldValue(String fieldValue) { this.fieldValue = fieldValue; }

    public byte[] getImageValue() { return imageValue; }
    public void setImageValue(byte[] imageValue) { this.imageValue = imageValue; }

    public Long getVersion() { return version; }
    public void setVersion(Long version) { this.version = version; }
}
