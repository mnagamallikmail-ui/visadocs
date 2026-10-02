package com.provaluer.dto;

public class CloseOrderRequest {
    private String closeNotes;
    private boolean forceClose = false;

    public CloseOrderRequest() {}

    public CloseOrderRequest(String closeNotes, boolean forceClose) {
        this.closeNotes = closeNotes;
        this.forceClose = forceClose;
    }

    public String getCloseNotes() { return closeNotes; }
    public void setCloseNotes(String closeNotes) { this.closeNotes = closeNotes; }

    public boolean isForceClose() { return forceClose; }
    public void setForceClose(boolean forceClose) { this.forceClose = forceClose; }
}
