package com.provaluer.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

/**
 * Entity maintaining monotonic, gap-free, atomic sequence counters
 * per month prefix (e.g., 'PV-2610-').
 */
@Entity
@Table(name = "report_sequences")
public class ReportSequence {

    @Id
    @Column(name = "prefix", length = 32, nullable = false)
    private String prefix;

    @Column(name = "last_sequence", nullable = false)
    private Long lastSequence;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public ReportSequence() {}

    public ReportSequence(String prefix, Long lastSequence) {
        this.prefix = prefix;
        this.lastSequence = lastSequence;
        this.updatedAt = LocalDateTime.now();
    }

    public String getPrefix() {
        return prefix;
    }

    public void setPrefix(String prefix) {
        this.prefix = prefix;
    }

    public Long getLastSequence() {
        return lastSequence;
    }

    public void setLastSequence(Long lastSequence) {
        this.lastSequence = lastSequence;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
