package com.provaluer.model;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Canonical Single Source of Truth for Order Statuses across ProValuer.
 */
public final class OrderStatus {

    private OrderStatus() {}

    // Intake & Quote
    public static final String DRAFT = "DRAFT";
    public static final String QUOTE_PENDING = "QUOTE_PENDING";
    public static final String QUOTE_PROVIDED = "QUOTE_PROVIDED";

    // Payment Lifecycle
    public static final String PAYMENT_SUBMITTED = "PAYMENT_SUBMITTED";
    public static final String PAYMENT_VERIFIED = "PAYMENT_VERIFIED";
    public static final String PAYMENT_REJECTED = "PAYMENT_REJECTED";
    public static final String PAID_INTAKE = "PAID_INTAKE";

    // Valuation Workspace & Drafting
    public static final String ASSIGNED = "ASSIGNED";
    public static final String WORKSPACE_READY = "WORKSPACE_READY";
    public static final String DRAFTING = "DRAFTING";
    public static final String ACTION_NEEDED = "ACTION_NEEDED";

    // SPA Review & Quality Gate
    public static final String SPA_REVIEW = "SPA_REVIEW";
    public static final String SPA_GATE = "SPA_GATE";
    public static final String SPA_CONFIRMED = "SPA_CONFIRMED";

    // Delivery & Client Lifecycle
    public static final String ON_HOLD_PAYMENT_PENDING = "ON_HOLD_PAYMENT_PENDING";
    public static final String DELIVERY_READY = "DELIVERY_READY";
    public static final String FINAL_DELIVERY = "FINAL_DELIVERY";
    public static final String CLIENT_DOWNLOADED = "CLIENT_DOWNLOADED";
    public static final String DELIVERY_DISPUTED = "DELIVERY_DISPUTED";
    public static final String CLOSED = "CLOSED";

    // Sets of states
    public static final Set<String> DELIVERY_STATES = Collections.unmodifiableSet(new HashSet<>(Arrays.asList(
            FINAL_DELIVERY,
            CLIENT_DOWNLOADED,
            CLOSED
    )));

    public static final Set<String> OPEN_KPI_STATES = Collections.unmodifiableSet(new HashSet<>(Arrays.asList(
            PAID_INTAKE,
            ASSIGNED,
            WORKSPACE_READY,
            DRAFTING,
            ACTION_NEEDED,
            SPA_REVIEW,
            SPA_GATE,
            SPA_CONFIRMED,
            PAYMENT_REJECTED,
            ON_HOLD_PAYMENT_PENDING,
            DELIVERY_READY
    )));

    /**
     * Checks if the given status allows client and staff downloading of the certified report.
     */
    public static boolean isDownloadAllowed(String status) {
        if (status == null) return false;
        String s = status.trim().toUpperCase();
        return DELIVERY_STATES.contains(s);
    }

    /**
     * Checks if the given status represents a completed / delivered report.
     */
    public static boolean isCompleted(String status) {
        if (status == null) return false;
        String s = status.trim().toUpperCase();
        return DELIVERY_STATES.contains(s);
    }

    /**
     * Checks if the order is considered open / active in production pipelines.
     */
    public static boolean isOpen(String status) {
        if (status == null) return false;
        String s = status.trim().toUpperCase();
        return OPEN_KPI_STATES.contains(s);
    }
}
