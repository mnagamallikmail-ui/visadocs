package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String username;

    @Column(unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;

    @Convert(converter = com.provaluer.security.encryption.AesGcmEncryptionConverter.class)
    @Column(name = "full_name", length = 1024)
    private String fullName;

    @Convert(converter = com.provaluer.security.encryption.AesGcmEncryptionConverter.class)
    @Column(name = "mobile_number", length = 1024)
    private String mobileNumber;

    @Column(name = "email_hash", length = 128)
    private String emailHash;

    @Column(name = "mfa_enabled", nullable = false)
    private boolean mfaEnabled = false;

    @Column(name = "mfa_secret")
    private String mfaSecret;

    @Column(name = "mfa_recovery_codes", columnDefinition = "TEXT")
    private String mfaRecoveryCodes;

    @Column(name = "failed_login_attempts", nullable = false)
    private int failedLoginAttempts = 0;

    @Column(name = "lockout_until")
    private LocalDateTime lockoutUntil;

    @Column(name = "accepted_tc_version")
    private String acceptedTcVersion;

    @Column(name = "is_locked", nullable = false)
    private boolean locked = false;

    @Column(name = "is_deleted", nullable = false)
    private boolean deleted = false;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "dpdp_consent_given", nullable = false)
    private boolean dpdpConsentGiven = false;

    @Column(name = "dpdp_consent_version", length = 32)
    private String dpdpConsentVersion;

    @Column(name = "dpdp_consent_timestamp")
    private LocalDateTime dpdpConsentTimestamp;

    @PrePersist
    public void prePersist() {
        if ((username == null || username.trim().isEmpty()) && email != null && !email.trim().isEmpty()) {
            username = email.contains("@") ? email.substring(0, email.indexOf('@')) : email;
        } else if (username == null || username.trim().isEmpty()) {
            username = "user_" + System.currentTimeMillis();
        }
        if (email != null) {
            this.emailHash = com.provaluer.security.encryption.AesGcmEncryptionConverter.computeBlindIndex(this.email);
        }
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = LocalDateTime.now();
        }
    }

    @PreUpdate
    public void preUpdate() {
        if (email != null) {
            this.emailHash = com.provaluer.security.encryption.AesGcmEncryptionConverter.computeBlindIndex(this.email);
        }
        updatedAt = LocalDateTime.now();
    }

    public User() {}

    public User(String username, String email, String password, UserRole role, String mobileNumber, String acceptedTcVersion) {
        this.username = username;
        this.email = email;
        this.password = password;
        this.role = role;
        this.mobileNumber = mobileNumber;
        this.acceptedTcVersion = acceptedTcVersion;
        if (email != null) {
            this.emailHash = com.provaluer.security.encryption.AesGcmEncryptionConverter.computeBlindIndex(email);
        }
    }

    public User(String email, String password, UserRole role, String mobileNumber, String acceptedTcVersion) {
        this(email != null && email.contains("@") ? email.substring(0, email.indexOf('@')) : email,
             email, password, role, mobileNumber, acceptedTcVersion);
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) {
        this.email = email;
        if (email != null) {
            this.emailHash = com.provaluer.security.encryption.AesGcmEncryptionConverter.computeBlindIndex(email);
        }
    }
    public String getEmailHash() { return emailHash; }
    public void setEmailHash(String emailHash) { this.emailHash = emailHash; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public UserRole getRole() { return role; }
    public void setRole(UserRole role) { this.role = role; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getMobileNumber() { return mobileNumber; }
    public void setMobileNumber(String mobileNumber) { this.mobileNumber = mobileNumber; }
    public String getAcceptedTcVersion() { return acceptedTcVersion; }
    public void setAcceptedTcVersion(String acceptedTcVersion) { this.acceptedTcVersion = acceptedTcVersion; }
    public boolean isLocked() { return locked; }
    public void setLocked(boolean locked) { this.locked = locked; }
    public boolean isDeleted() { return deleted; }
    public void setDeleted(boolean deleted) { this.deleted = deleted; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public boolean isMfaEnabled() { return mfaEnabled; }
    public void setMfaEnabled(boolean mfaEnabled) { this.mfaEnabled = mfaEnabled; }
    public String getMfaSecret() { return mfaSecret; }
    public void setMfaSecret(String mfaSecret) { this.mfaSecret = mfaSecret; }
    public String getMfaRecoveryCodes() { return mfaRecoveryCodes; }
    public void setMfaRecoveryCodes(String mfaRecoveryCodes) { this.mfaRecoveryCodes = mfaRecoveryCodes; }
    public int getFailedLoginAttempts() { return failedLoginAttempts; }
    public void setFailedLoginAttempts(int failedLoginAttempts) { this.failedLoginAttempts = failedLoginAttempts; }
    public LocalDateTime getLockoutUntil() { return lockoutUntil; }
    public void setLockoutUntil(LocalDateTime lockoutUntil) { this.lockoutUntil = lockoutUntil; }

    public boolean isDpdpConsentGiven() { return dpdpConsentGiven; }
    public void setDpdpConsentGiven(boolean dpdpConsentGiven) { this.dpdpConsentGiven = dpdpConsentGiven; }

    public String getDpdpConsentVersion() { return dpdpConsentVersion; }
    public void setDpdpConsentVersion(String dpdpConsentVersion) { this.dpdpConsentVersion = dpdpConsentVersion; }

    public LocalDateTime getDpdpConsentTimestamp() { return dpdpConsentTimestamp; }
    public void setDpdpConsentTimestamp(LocalDateTime dpdpConsentTimestamp) { this.dpdpConsentTimestamp = dpdpConsentTimestamp; }
}
