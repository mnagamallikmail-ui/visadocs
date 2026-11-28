package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "website_visits")
public class WebsiteVisit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "page_path", nullable = false, length = 500)
    private String pagePath = "/";

    @Column(name = "country", nullable = false, length = 100)
    private String country = "Unknown";

    @Column(name = "state", nullable = false, length = 100)
    private String state = "Unknown";

    @Column(name = "city", nullable = false, length = 100)
    private String city = "Unknown";

    @Column(name = "device", nullable = false, length = 50)
    private String device = "Desktop";

    @Column(name = "browser", nullable = false, length = 100)
    private String browser = "Unknown";

    @Column(name = "referrer", length = 500)
    private String referrer;

    @Column(name = "visited_at", nullable = false)
    private LocalDateTime visitedAt;

    @PrePersist
    public void prePersist() {
        if (visitedAt == null) {
            visitedAt = LocalDateTime.now();
        }
        if (pagePath == null || pagePath.isBlank()) {
            pagePath = "/";
        }
        if (country == null || country.isBlank()) {
            country = "Unknown";
        }
        if (state == null || state.isBlank()) {
            state = "Unknown";
        }
        if (city == null || city.isBlank()) {
            city = "Unknown";
        }
        if (device == null || device.isBlank()) {
            device = "Desktop";
        }
        if (browser == null || browser.isBlank()) {
            browser = "Unknown";
        }
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getPagePath() { return pagePath; }
    public void setPagePath(String pagePath) { this.pagePath = pagePath; }

    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }

    public String getState() { return state; }
    public void setState(String state) { this.state = state; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getDevice() { return device; }
    public void setDevice(String device) { this.device = device; }

    public String getBrowser() { return browser; }
    public void setBrowser(String browser) { this.browser = browser; }

    public String getReferrer() { return referrer; }
    public void setReferrer(String referrer) { this.referrer = referrer; }

    public LocalDateTime getVisitedAt() { return visitedAt; }
    public void setVisitedAt(LocalDateTime visitedAt) { this.visitedAt = visitedAt; }
}

