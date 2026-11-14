package com.provaluer.repository;

import com.provaluer.model.UserSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserSessionRepository extends JpaRepository<UserSession, Long> {

    Optional<UserSession> findBySessionId(String sessionId);

    Optional<UserSession> findByUserIdAndIsActiveTrue(Long userId);

    List<UserSession> findAllByUserIdAndIsActiveTrue(Long userId);

    @Query("SELECT s FROM UserSession s WHERE s.sessionId = :sessionId AND s.isActive = true")
    Optional<UserSession> findActiveBySessionId(@Param("sessionId") String sessionId);

    @Modifying
    @Query(value = "UPDATE user_sessions SET is_active = false, terminated_at = NOW(), termination_reason = :reason " +
           "WHERE user_id = :userId AND is_active = true", nativeQuery = true)
    int terminateActiveSessionsForUser(@Param("userId") Long userId, @Param("reason") String reason);

    @Modifying
    @Query(value = "UPDATE user_sessions SET is_active = false, terminated_at = NOW(), termination_reason = :reason " +
           "WHERE session_id = :sessionId AND is_active = true", nativeQuery = true)
    int terminateSession(@Param("sessionId") String sessionId, @Param("reason") String reason);

    @Modifying
    @Query(value = "UPDATE user_sessions SET last_activity = NOW() WHERE session_id = :sessionId AND is_active = true", nativeQuery = true)
    int touchActivity(@Param("sessionId") String sessionId);

    @Modifying
    @Query(value = "UPDATE user_sessions SET challenge_status = :status, challenge_target_session = :targetSession, " +
           "challenge_expiry = :expiry WHERE session_id = :sessionId", nativeQuery = true)
    int updateChallenge(@Param("sessionId") String sessionId,
                        @Param("status") String status,
                        @Param("targetSession") String targetSession,
                        @Param("expiry") LocalDateTime expiry);

    @Query("SELECT COUNT(s) FROM UserSession s WHERE s.isActive = true")
    long countActiveSessions();

    @Query("SELECT COUNT(DISTINCT s.user.id) FROM UserSession s WHERE s.isActive = true")
    long countActiveUsers();
}

