package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * DPDP Act 2023 - Section 12 Deletion Certificate
 * Legally binding audit certificate proving irreversible erasure / cryptographic shredding
 * of personal data following a verified erasure request or statutory retention expiry.
 */
@Entity
@Table(name = "deletion_certificates")
public class DeletionCertificate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "certificate_number", nullable = false, unique = true, length = 128)
    private String certificateNumber;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "user_identifier", nullable = false)
    private String userIdentifier;

    @Column(name = "records_deleted", nullable = false)
    private int recordsDeleted = 0;

    @Column(name = "completion_time", nullable = false)
    private LocalDateTime completionTime = LocalDateTime.now();

    @Column(name = "officer", nullable = false, length = 100)
    private String officer;

    @Column(name = "hash_signature", nullable = false)
    private String hashSignature;

    @Column(name = "certificate_details", columnDefinition = "TEXT")
    private String certificateDetails;

    public DeletionCertificate() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCertificateNumber() { return certificateNumber; }
    public void setCertificateNumber(String certificateNumber) { this.certificateNumber = certificateNumber; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getUserIdentifier() { return userIdentifier; }
    public void setUserIdentifier(String userIdentifier) { this.userIdentifier = userIdentifier; }

    public int getRecordsDeleted() { return recordsDeleted; }
    public void setRecordsDeleted(int recordsDeleted) { this.recordsDeleted = recordsDeleted; }

    public LocalDateTime getCompletionTime() { return completionTime; }
    public void setCompletionTime(LocalDateTime completionTime) { this.completionTime = completionTime; }

    public String getOfficer() { return officer; }
    public void setOfficer(String officer) { this.officer = officer; }

    public String getHashSignature() { return hashSignature; }
    public void setHashSignature(String hashSignature) { this.hashSignature = hashSignature; }

    public String getCertificateDetails() { return certificateDetails; }
    public void setCertificateDetails(String certificateDetails) { this.certificateDetails = certificateDetails; }
}
