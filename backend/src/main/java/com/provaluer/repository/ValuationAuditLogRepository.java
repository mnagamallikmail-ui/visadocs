package com.provaluer.repository;

import com.provaluer.model.ValuationAuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ValuationAuditLogRepository extends JpaRepository<ValuationAuditLog, Long> {
    List<ValuationAuditLog> findByOrderIdOrderByChangedAtDesc(Long orderId);
}
