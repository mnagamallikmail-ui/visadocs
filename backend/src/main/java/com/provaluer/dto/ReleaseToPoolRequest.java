package com.provaluer.dto;

/**
 * SPRINT 4: Request body for POST /api/v1/orders/{id}/release-to-pool.
 */
public class ReleaseToPoolRequest {

    private String intakeNotes;

    public String getIntakeNotes() { return intakeNotes; }
    public void setIntakeNotes(String intakeNotes) { this.intakeNotes = intakeNotes; }
}
