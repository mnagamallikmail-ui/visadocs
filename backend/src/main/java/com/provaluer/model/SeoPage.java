package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "seo_pages")
public class SeoPage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 500)
    private String url;

    @Column(nullable = false)
    private String slug;

    @Column(nullable = false)
    private String title;

    @Column(name = "published_at", nullable = false)
    private LocalDateTime publishedAt = LocalDateTime.now();

    @Column(nullable = false)
    private Boolean indexed = false;

    @Column(name = "index_date")
    private LocalDateTime indexDate;

    @Column(nullable = false, length = 50)
    private String status = "PUBLISHED";

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public SeoPage() {}

    public SeoPage(String url, String slug, String title, LocalDateTime publishedAt, Boolean indexed, LocalDateTime indexDate, String status) {
        this.url = url;
        this.slug = slug;
        this.title = title;
        this.publishedAt = publishedAt != null ? publishedAt : LocalDateTime.now();
        this.indexed = indexed != null ? indexed : false;
        this.indexDate = indexDate;
        this.status = status != null ? status : "PUBLISHED";
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public LocalDateTime getPublishedAt() { return publishedAt; }
    public void setPublishedAt(LocalDateTime publishedAt) { this.publishedAt = publishedAt; }

    public Boolean getIndexed() { return indexed; }
    public void setIndexed(Boolean indexed) { this.indexed = indexed; }

    public LocalDateTime getIndexDate() { return indexDate; }
    public void setIndexDate(LocalDateTime indexDate) { this.indexDate = indexDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
