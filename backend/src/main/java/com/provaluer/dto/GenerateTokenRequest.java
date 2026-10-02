package com.provaluer.dto;

public class GenerateTokenRequest {
    private String fileType; // REPORT_PDF, INVOICE_PDF, MANIFEST, REPORT_DOCX

    public GenerateTokenRequest() {}

    public GenerateTokenRequest(String fileType) {
        this.fileType = fileType;
    }

    public String getFileType() { return fileType; }
    public void setFileType(String fileType) { this.fileType = fileType; }
}
