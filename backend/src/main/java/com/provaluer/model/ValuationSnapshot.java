package com.provaluer.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "valuation_snapshots")
public class ValuationSnapshot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "version_number", nullable = false)
    private int versionNumber = 1;

    @Column(name = "snapshot_trigger", nullable = false)
    private String snapshotTrigger; // REPORT_GENERATED, REPORT_FINALIZED, REPORT_LOCKED, REPORT_RECALCULATED, REPORT_REVISED

    @Column(name = "snapshot_hash", length = 64, nullable = false)
    private String snapshotHash;

    @Column(name = "document_hash", length = 64)
    private String documentHash;

    @Column(name = "snapshot_data", columnDefinition = "TEXT", nullable = false)
    private String snapshotData;

    @JsonIgnore
    @Basic(fetch = FetchType.LAZY)
    @Column(name = "docx_content")
    private byte[] docxContent;

    @JsonIgnore
    @Basic(fetch = FetchType.LAZY)
    @Column(name = "pdf_content")
    private byte[] pdfContent;

    @Column(name = "version_notes", length = 500)
    private String versionNotes;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "created_by")
    private Long createdBy;

    public ValuationSnapshot() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public int getVersionNumber() { return versionNumber; }
    public void setVersionNumber(int versionNumber) { this.versionNumber = versionNumber; }

    public String getSnapshotTrigger() { return snapshotTrigger; }
    public void setSnapshotTrigger(String snapshotTrigger) { this.snapshotTrigger = snapshotTrigger; }

    public String getSnapshotHash() { return snapshotHash; }
    public void setSnapshotHash(String snapshotHash) { this.snapshotHash = snapshotHash; }

    public String getDocumentHash() { return documentHash; }
    public void setDocumentHash(String documentHash) { this.documentHash = documentHash; }

    public String getSnapshotData() { return snapshotData; }
    public void setSnapshotData(String snapshotData) { this.snapshotData = snapshotData; }

    public byte[] getDocxContent() { return docxContent; }
    public void setDocxContent(byte[] docxContent) { this.docxContent = docxContent; }

    public byte[] getPdfContent() { return pdfContent; }
    public void setPdfContent(byte[] pdfContent) { this.pdfContent = pdfContent; }

    public String getVersionNotes() { return versionNotes; }
    public void setVersionNotes(String versionNotes) { this.versionNotes = versionNotes; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public Long getCreatedBy() { return createdBy; }
    public void setCreatedBy(Long createdBy) { this.createdBy = createdBy; }
}
