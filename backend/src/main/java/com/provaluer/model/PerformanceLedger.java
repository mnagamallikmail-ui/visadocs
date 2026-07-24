package com.provaluer.model;

import jakarta.persistence.*;

@Entity
@Table(name = "performance_ledger")
public class PerformanceLedger {
    @Id
    @Column(name = "employee_id")
    private Long employeeId;

    @Column(name = "active_allocations", nullable = false)
    private int activeAllocations = 0;

    @Column(name = "files_completed", nullable = false)
    private int filesCompleted = 0;

    @Column(name = "sla_timeouts", nullable = false)
    private int slaTimeouts = 0;

    @Column(name = "freeze_counts", nullable = false)
    private int freezeCounts = 0;

    public PerformanceLedger() {}

    public PerformanceLedger(Long employeeId) {
        this.employeeId = employeeId;
    }

    public Long getEmployeeId() { return employeeId; }
    public void setEmployeeId(Long employeeId) { this.employeeId = employeeId; }

    public int getActiveAllocations() { return activeAllocations; }
    public void setActiveAllocations(int activeAllocations) { this.activeAllocations = activeAllocations; }

    public int getFilesCompleted() { return filesCompleted; }
    public void setFilesCompleted(int filesCompleted) { this.filesCompleted = filesCompleted; }

    public int getSlaTimeouts() { return slaTimeouts; }
    public void setSlaTimeouts(int slaTimeouts) { this.slaTimeouts = slaTimeouts; }

    public int getFreezeCounts() { return freezeCounts; }
    public void setFreezeCounts(int freezeCounts) { this.freezeCounts = freezeCounts; }
}
