package com.provaluer.repository;

import com.provaluer.model.PerformanceLedger;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PerformanceLedgerRepository extends JpaRepository<PerformanceLedger, Long> {
    void deleteByEmployeeId(Long employeeId);
}
