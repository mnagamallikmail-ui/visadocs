package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "building_types")
public class BuildingType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", unique = true, nullable = false)
    private String name;

    @Column(name = "default_useful_life", nullable = false)
    private int defaultUsefulLife;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public BuildingType() {}

    public BuildingType(String name, int defaultUsefulLife, boolean isActive) {
        this.name = name;
        this.defaultUsefulLife = defaultUsefulLife;
        this.isActive = isActive;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public int getDefaultUsefulLife() { return defaultUsefulLife; }
    public void setDefaultUsefulLife(int defaultUsefulLife) { this.defaultUsefulLife = defaultUsefulLife; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
