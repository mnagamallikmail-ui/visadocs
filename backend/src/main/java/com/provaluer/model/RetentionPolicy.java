package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "retention_policies")
public class RetentionPolicy {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "entity_type", nullable = false, unique = true, length = 64)
    private String entityType;

    @Column(name = "retention_days", nullable = false)
    private int retentionDays;

    @Column(name = "legal_basis", nullable = false)
    private String legalBasis;

    @Column(name = "archive_strategy", nullable = false, length = 64)
    private String archiveStrategy = "ARCHIVE_THEN_PURGE";

    @Column(name = "purge_strategy", nullable = false, length = 64)
    private String purgeStrategy = "CRYPTO_SHRED";

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public RetentionPolicy() {}

    public RetentionPolicy(String entityType, int retentionDays, String legalBasis, String archiveStrategy, String purgeStrategy) {
        this.entityType = entityType;
        this.retentionDays = retentionDays;
        this.legalBasis = legalBasis;
        this.archiveStrategy = archiveStrategy;
        this.purgeStrategy = purgeStrategy;
        this.isActive = true;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getEntityType() { return entityType; }
    public void setEntityType(String entityType) { this.entityType = entityType; }

    public int getRetentionDays() { return retentionDays; }
    public void setRetentionDays(int retentionDays) { this.retentionDays = retentionDays; }

    public String getLegalBasis() { return legalBasis; }
    public void setLegalBasis(String legalBasis) { this.legalBasis = legalBasis; }

    public String getArchiveStrategy() { return archiveStrategy; }
    public void setArchiveStrategy(String archiveStrategy) { this.archiveStrategy = archiveStrategy; }

    public String getPurgeStrategy() { return purgeStrategy; }
    public void setPurgeStrategy(String purgeStrategy) { this.purgeStrategy = purgeStrategy; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
