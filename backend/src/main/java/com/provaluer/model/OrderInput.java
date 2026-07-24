package com.provaluer.model;

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
}
