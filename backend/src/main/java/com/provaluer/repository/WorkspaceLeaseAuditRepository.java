package com.provaluer.repository;

import com.provaluer.model.WorkspaceLeaseAudit;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WorkspaceLeaseAuditRepository extends JpaRepository<WorkspaceLeaseAudit, Long> {

    List<WorkspaceLeaseAudit> findAllByOrderIdOrderByTimestampDesc(Long orderId);

    Page<WorkspaceLeaseAudit> findAllByOrderIdOrderByTimestampDesc(Long orderId, Pageable pageable);

    List<WorkspaceLeaseAudit> findTop20ByOrderByTimestampDesc();
}

