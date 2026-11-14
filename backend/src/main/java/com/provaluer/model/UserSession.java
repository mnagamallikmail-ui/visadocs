package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.Objects;

@Entity
@Table(name = "user_sessions", indexes = {
    @Index(name = "idx_user_sessions_user_active", columnList = "user_id, is_active"),
    @Index(name = "idx_user_sessions_session_id", columnList = "session_id")
})
public class UserSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "session_id", nullable = false, unique = true, length = 64)
    private String sessionId;

    @Column(name = "session_token_hash", nullable = false, length = 64)
    private String sessionTokenHash;

    @Column(name = "refresh_token_hash", nullable = false, length = 64)
    private String refreshTokenHash;

    @Column(name = "device_info", nullable = false, length = 255)
    private String deviceInfo;

    @Column(name = "platform_info", length = 100)
    private String platformInfo;

    @Column(name = "approximate_location", length = 100)
    private String approximateLocation;

    @Column(name = "ip_address", nullable = false, length = 50)
    private String ipAddress;

    @Column(name = "last_activity", nullable = false)
    private LocalDateTime lastActivity = LocalDateTime.now();

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "challenge_status", nullable = false, length = 30)
    private String challengeStatus = "NONE"; // NONE, PENDING_CHALLENGE, CHALLENGE_REJECTED

    @Column(name = "challenge_target_session", length = 64)
    private String challengeTargetSession;

    @Column(name = "challenge_expiry")
    private LocalDateTime challengeExpiry;

    @Column(name = "terminated_at")
    private LocalDateTime terminatedAt;

    @Column(name = "termination_reason", length = 255)
    private String terminationReason;

    public UserSession() {}

    public UserSession(User user, String sessionId, String sessionTokenHash, String refreshTokenHash,
                       String deviceInfo, String platformInfo, String approximateLocation, String ipAddress) {
        this.user = user;
        this.sessionId = sessionId;
        this.sessionTokenHash = sessionTokenHash;
        this.refreshTokenHash = refreshTokenHash;
        this.deviceInfo = deviceInfo;
        this.platformInfo = platformInfo;
        this.approximateLocation = approximateLocation;
        this.ipAddress = ipAddress;
        this.lastActivity = LocalDateTime.now();
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        this.isActive = true;
        this.challengeStatus = "NONE";
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public String getSessionTokenHash() { return sessionTokenHash; }
    public void setSessionTokenHash(String sessionTokenHash) { this.sessionTokenHash = sessionTokenHash; }

    public String getRefreshTokenHash() { return refreshTokenHash; }
    public void setRefreshTokenHash(String refreshTokenHash) { this.refreshTokenHash = refreshTokenHash; }

    public String getDeviceInfo() { return deviceInfo; }
    public void setDeviceInfo(String deviceInfo) { this.deviceInfo = deviceInfo; }

    public String getPlatformInfo() { return platformInfo; }
    public void setPlatformInfo(String platformInfo) { this.platformInfo = platformInfo; }

    public String getApproximateLocation() { return approximateLocation; }
    public void setApproximateLocation(String approximateLocation) { this.approximateLocation = approximateLocation; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public LocalDateTime getLastActivity() { return lastActivity; }
    public void setLastActivity(LocalDateTime lastActivity) { this.lastActivity = lastActivity; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean active) { isActive = active; }

    public String getChallengeStatus() { return challengeStatus; }
    public void setChallengeStatus(String challengeStatus) { this.challengeStatus = challengeStatus; }

    public String getChallengeTargetSession() { return challengeTargetSession; }
    public void setChallengeTargetSession(String challengeTargetSession) { this.challengeTargetSession = challengeTargetSession; }

    public LocalDateTime getChallengeExpiry() { return challengeExpiry; }
    public void setChallengeExpiry(LocalDateTime challengeExpiry) { this.challengeExpiry = challengeExpiry; }

    public LocalDateTime getTerminatedAt() { return terminatedAt; }
    public void setTerminatedAt(LocalDateTime terminatedAt) { this.terminatedAt = terminatedAt; }

    public String getTerminationReason() { return terminationReason; }
    public void setTerminationReason(String terminationReason) { this.terminationReason = terminationReason; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof UserSession)) return false;
        UserSession that = (UserSession) o;
        return Objects.equals(sessionId, that.sessionId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(sessionId);
    }
}

