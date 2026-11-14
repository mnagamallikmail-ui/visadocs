package com.provaluer.repository;

import com.provaluer.model.WorkspaceSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WorkspaceSessionRepository extends JpaRepository<WorkspaceSession, Long> {

    @Query("SELECT ws FROM WorkspaceSession ws WHERE ws.order.id = :orderId")
    Optional<WorkspaceSession> findByOrderId(@Param("orderId") Long orderId);

    @Query("SELECT ws FROM WorkspaceSession ws JOIN FETCH ws.user WHERE ws.order.id = :orderId")
    Optional<WorkspaceSession> findByOrderIdWithUser(@Param("orderId") Long orderId);

    @Query("SELECT ws FROM WorkspaceSession ws WHERE ws.order.id = :orderId AND ws.lockStatus = :lockStatus")
    Optional<WorkspaceSession> findByOrderIdAndLockStatus(@Param("orderId") Long orderId, @Param("lockStatus") String lockStatus);

    @Query("SELECT ws FROM WorkspaceSession ws WHERE ws.order.id = :orderId AND ws.sessionId = :sessionId AND ws.lockStatus = 'ACTIVE'")
    Optional<WorkspaceSession> findActiveByOrderAndSession(@Param("orderId") Long orderId, @Param("sessionId") String sessionId);

    @Query("SELECT ws FROM WorkspaceSession ws WHERE ws.order.id = :orderId AND ws.sessionId = :sessionId AND ws.tabSessionId = :tabSessionId AND ws.lockStatus = 'ACTIVE'")
    Optional<WorkspaceSession> findActiveByOrderAndSessionAndTab(@Param("orderId") Long orderId,
                                                                 @Param("sessionId") String sessionId,
                                                                 @Param("tabSessionId") String tabSessionId);

    // Isolated Non-Entity Heartbeat Update (Execution < 1ms, 0 Order version touch)
    @Modifying
    @Query(value = "UPDATE workspace_sessions SET last_heartbeat = NOW() " +
                   "WHERE order_id = :orderId AND session_id = :sessionId AND lock_status = 'ACTIVE'",
           nativeQuery = true)
    int renewHeartbeat(@Param("orderId") Long orderId, @Param("sessionId") String sessionId);

    // Touch both last_activity and last_heartbeat on save
    @Modifying
    @Query(value = "UPDATE workspace_sessions SET last_activity = NOW(), last_heartbeat = NOW() " +
                   "WHERE order_id = :orderId AND session_id = :sessionId AND lock_status = 'ACTIVE'",
           nativeQuery = true)
    int touchActivity(@Param("orderId") Long orderId, @Param("sessionId") String sessionId);

    // Same-user multi-tab switch (swaps tab_session_id smoothly)
    @Modifying
    @Query(value = "UPDATE workspace_sessions SET tab_session_id = :newTabSessionId, last_activity = NOW(), last_heartbeat = NOW() " +
                   "WHERE order_id = :orderId AND user_id = :userId AND lock_status = 'ACTIVE'",
           nativeQuery = true)
    int switchTabSession(@Param("orderId") Long orderId, @Param("userId") Long userId, @Param("newTabSessionId") String newTabSessionId);

    // Admin Break-Glass Takeover atomic reassignment
    @Modifying
    @Query(value = "UPDATE workspace_sessions SET user_id = :newUserId, session_id = :newSessionId, tab_session_id = :newTabSessionId, " +
                   "machine_name = :machineName, platform_info = :platformInfo, ip_address = :ipAddress, " +
                   "acquired_at = NOW(), last_heartbeat = NOW(), last_activity = NOW(), lock_status = 'ACTIVE' " +
                   "WHERE order_id = :orderId",
           nativeQuery = true)
    int takeoverLease(@Param("orderId") Long orderId,
                      @Param("newUserId") Long newUserId,
                      @Param("newSessionId") String newSessionId,
                      @Param("newTabSessionId") String newTabSessionId,
                      @Param("machineName") String machineName,
                      @Param("platformInfo") String platformInfo,
                      @Param("ipAddress") String ipAddress);

    // Release specific workspace lock
    @Modifying
    @Query(value = "UPDATE workspace_sessions SET lock_status = 'RELEASED' " +
                   "WHERE order_id = :orderId AND session_id = :sessionId AND lock_status = 'ACTIVE'",
           nativeQuery = true)
    int releaseLease(@Param("orderId") Long orderId, @Param("sessionId") String sessionId);

    // Cascade release all active leases owned by a user session (on logout or session eviction)
    @Modifying
    @Query(value = "UPDATE workspace_sessions SET lock_status = 'RELEASED' " +
                   "WHERE user_id = :userId AND session_id = :sessionId AND lock_status = 'ACTIVE'",
           nativeQuery = true)
    int releaseAllActiveLeases(@Param("userId") Long userId, @Param("sessionId") String sessionId);

    // Evict expired leases (> 300 seconds without heartbeat)
    @Modifying
    @Query(value = "UPDATE workspace_sessions SET lock_status = 'EXPIRED' " +
                   "WHERE lock_status = 'ACTIVE' AND last_heartbeat < (NOW() - INTERVAL '300 seconds')",
           nativeQuery = true)
    int expireStaleLeases();

    @Query(value = "SELECT COUNT(*) FROM workspace_sessions WHERE lock_status = 'ACTIVE' AND last_heartbeat >= (NOW() - INTERVAL '300 seconds')", nativeQuery = true)
    long countActiveEditors();

    @Query("SELECT ws FROM WorkspaceSession ws JOIN FETCH ws.user JOIN FETCH ws.order WHERE ws.lockStatus = 'ACTIVE'")
    List<WorkspaceSession> findAllActiveWithDetails();
}

