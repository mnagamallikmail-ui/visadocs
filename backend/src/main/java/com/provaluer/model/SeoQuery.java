package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "seo_queries", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"page_id", "query", "source", "date"})
})
public class SeoQuery {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "page_id", nullable = false)
    private SeoPage page;

    @Column(nullable = false, length = 500)
    private String query;

    @Column(nullable = false, length = 50)
    private String source; // 'GSC', 'BING'

    @Column(nullable = false)
    private LocalDate date;

    @Column(nullable = false)
    private Integer impressions = 0;

    @Column(nullable = false)
    private Integer clicks = 0;

    @Column(nullable = false, precision = 6, scale = 4)
    private BigDecimal ctr = BigDecimal.ZERO;

    @Column(name = "avg_position", nullable = false, precision = 6, scale = 2)
    private BigDecimal avgPosition = BigDecimal.ZERO;

    @Column(length = 10)
    private String country = "IND";

    @Column(length = 50)
    private String device = "DESKTOP";

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public SeoQuery() {}

    public SeoQuery(SeoPage page, String query, String source, LocalDate date, Integer impressions, Integer clicks, BigDecimal ctr, BigDecimal avgPosition, String country, String device) {
        this.page = page;
        this.query = query;
        this.source = source;
        this.date = date;
        this.impressions = impressions != null ? impressions : 0;
        this.clicks = clicks != null ? clicks : 0;
        this.ctr = ctr != null ? ctr : BigDecimal.ZERO;
        this.avgPosition = avgPosition != null ? avgPosition : BigDecimal.ZERO;
        this.country = country != null ? country : "IND";
        this.device = device != null ? device : "DESKTOP";
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public SeoPage getPage() { return page; }
    public void setPage(SeoPage page) { this.page = page; }

    public String getQuery() { return query; }
    public void setQuery(String query) { this.query = query; }

    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }

    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }

    public Integer getImpressions() { return impressions; }
    public void setImpressions(Integer impressions) { this.impressions = impressions; }

    public Integer getClicks() { return clicks; }
    public void setClicks(Integer clicks) { this.clicks = clicks; }

    public BigDecimal getCtr() { return ctr; }
    public void setCtr(BigDecimal ctr) { this.ctr = ctr; }

    public BigDecimal getAvgPosition() { return avgPosition; }
    public void setAvgPosition(BigDecimal avgPosition) { this.avgPosition = avgPosition; }

    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }

    public String getDevice() { return device; }
    public void setDevice(String device) { this.device = device; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
