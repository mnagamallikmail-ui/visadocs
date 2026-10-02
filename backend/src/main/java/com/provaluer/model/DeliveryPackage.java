package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "delivery_packages")
public class DeliveryPackage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false, unique = true)
    private Long orderId;

    @Basic(fetch = FetchType.LAZY)
    @Column(name = "encrypted_pdf_content")
    private byte[] encryptedPdfContent;

    @Column(name = "encrypted_pdf_hash", length = 64)
    private String encryptedPdfHash;

    @Column(name = "manifest_json", columnDefinition = "TEXT")
    private String manifestJson;

    @Basic(fetch = FetchType.LAZY)
    @Column(name = "compliance_cert_pdf")
    private byte[] complianceCertPdf;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public DeliveryPackage() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public byte[] getEncryptedPdfContent() { return encryptedPdfContent; }
    public void setEncryptedPdfContent(byte[] encryptedPdfContent) { this.encryptedPdfContent = encryptedPdfContent; }

    public String getEncryptedPdfHash() { return encryptedPdfHash; }
    public void setEncryptedPdfHash(String encryptedPdfHash) { this.encryptedPdfHash = encryptedPdfHash; }

    public String getManifestJson() { return manifestJson; }
    public void setManifestJson(String manifestJson) { this.manifestJson = manifestJson; }

    public byte[] getComplianceCertPdf() { return complianceCertPdf; }
    public void setComplianceCertPdf(byte[] complianceCertPdf) { this.complianceCertPdf = complianceCertPdf; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
