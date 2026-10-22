package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "retention_execution_log")
public class RetentionExecutionLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "execution_timestamp", nullable = false)
    private LocalDateTime executionTimestamp = LocalDateTime.now();

    @Column(name = "entities_scanned", nullable = false)
    private int entitiesScanned = 0;

    @Column(name = "entities_archived", nullable = false)
    private int entitiesArchived = 0;

    @Column(name = "entities_purged", nullable = false)
    private int entitiesPurged = 0;

    @Column(name = "status", nullable = false, length = 32)
    private String status = "SUCCESS";

    @Column(name = "summary", columnDefinition = "TEXT")
    private String summary;

    public RetentionExecutionLog() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public LocalDateTime getExecutionTimestamp() { return executionTimestamp; }
    public void setExecutionTimestamp(LocalDateTime executionTimestamp) { this.executionTimestamp = executionTimestamp; }

    public int getEntitiesScanned() { return entitiesScanned; }
    public void setEntitiesScanned(int entitiesScanned) { this.entitiesScanned = entitiesScanned; }

    public int getEntitiesArchived() { return entitiesArchived; }
    public void setEntitiesArchived(int entitiesArchived) { this.entitiesArchived = entitiesArchived; }

    public int getEntitiesPurged() { return entitiesPurged; }
    public void setEntitiesPurged(int entitiesPurged) { this.entitiesPurged = entitiesPurged; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getSummary() { return summary; }
    public void setSummary(String summary) { this.summary = summary; }
}
