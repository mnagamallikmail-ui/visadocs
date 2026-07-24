package com.provaluer.repository;

import com.provaluer.model.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {
    List<AuditLog> findAllByActorIdOrderByTimestampDesc(Long actorId);
    List<AuditLog> findAllByEntityTypeAndEntityIdOrderByTimestampDesc(String entityType, String entityId);
    Page<AuditLog> findAllByOrderByTimestampDesc(Pageable pageable);
    List<AuditLog> findTop50ByOrderByTimestampDesc();
    void deleteByActorId(Long actorId);
}
