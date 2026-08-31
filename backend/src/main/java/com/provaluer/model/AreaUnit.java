package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "area_units")
public class AreaUnit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "unit_name", unique = true, nullable = false)
    private String unitName;

    @Column(name = "conversion_factor_sqft", precision = 19, scale = 6, nullable = false)
    private BigDecimal conversionFactorSqft;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public AreaUnit() {}

    public AreaUnit(String unitName, BigDecimal conversionFactorSqft, boolean isActive) {
        this.unitName = unitName;
        this.conversionFactorSqft = conversionFactorSqft;
        this.isActive = isActive;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUnitName() { return unitName; }
    public void setUnitName(String unitName) { this.unitName = unitName; }

    public BigDecimal getConversionFactorSqft() { return conversionFactorSqft; }
    public void setConversionFactorSqft(BigDecimal conversionFactorSqft) { this.conversionFactorSqft = conversionFactorSqft; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
