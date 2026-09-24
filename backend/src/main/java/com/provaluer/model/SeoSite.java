package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "seo_sites")
public class SeoSite {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String domain;

    @Column(name = "gsc_property_id")
    private String gscPropertyId;

    @Column(name = "bing_site_id")
    private String bingSiteId;

    @Column(nullable = false)
    private Boolean verified = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public SeoSite() {}

    public SeoSite(String domain, String gscPropertyId, String bingSiteId, Boolean verified) {
        this.domain = domain;
        this.gscPropertyId = gscPropertyId;
        this.bingSiteId = bingSiteId;
        this.verified = verified;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getDomain() { return domain; }
    public void setDomain(String domain) { this.domain = domain; }

    public String getGscPropertyId() { return gscPropertyId; }
    public void setGscPropertyId(String gscPropertyId) { this.gscPropertyId = gscPropertyId; }

    public String getBingSiteId() { return bingSiteId; }
    public void setBingSiteId(String bingSiteId) { this.bingSiteId = bingSiteId; }

    public Boolean getVerified() { return verified; }
    public void setVerified(Boolean verified) { this.verified = verified; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
