package com.provaluer.repository;

import com.provaluer.model.WorkspaceSyncEvent;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface WorkspaceSyncEventRepository extends JpaRepository<WorkspaceSyncEvent, Long> {

    @Query("SELECT e FROM WorkspaceSyncEvent e WHERE e.order.id = :orderId ORDER BY e.createdAt DESC")
    List<WorkspaceSyncEvent> findAllByOrderIdOrderByCreatedAtDesc(@Param("orderId") Long orderId);

    @Query("SELECT e FROM WorkspaceSyncEvent e WHERE e.order.id = :orderId ORDER BY e.createdAt DESC")
    Page<WorkspaceSyncEvent> findAllByOrderIdOrderByCreatedAtDesc(@Param("orderId") Long orderId, Pageable pageable);

    @Query("SELECT e FROM WorkspaceSyncEvent e WHERE e.sessionId = :sessionId ORDER BY e.createdAt DESC")
    List<WorkspaceSyncEvent> findAllBySessionIdOrderByCreatedAtDesc(@Param("sessionId") String sessionId);

    @Query("SELECT COUNT(e) FROM WorkspaceSyncEvent e WHERE e.syncStatus = 'PENDING'")
    long countPendingEvents();

    @Modifying
    @Query(value = "DELETE FROM workspace_sync_events WHERE created_at < (NOW() - INTERVAL '90 days')", nativeQuery = true)
    int purgeOldEvents();
}

