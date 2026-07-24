package com.provaluer.model;

public enum UserRole {
    CLIENT,
    PA,
    SPA,
    SUPER_ADMIN,
    ADMIN  // Legacy alias — maps to SUPER_ADMIN authority in Spring Security
}
