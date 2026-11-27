package com.provaluer.util;

import com.provaluer.security.UserDetailsImpl;

/**
 * Canonical authority hierarchy for report field governance:
 * ADMIN / SUPER_ADMIN (3) > SPA (2) > PA (1) > SYSTEM (0).
 */
public final class AuthorityGovernance {

    public static final int RANK_SYSTEM = 0;
    public static final int RANK_PA = 1;
    public static final int RANK_SPA = 2;
    public static final int RANK_ADMIN = 3;

    private AuthorityGovernance() {}

    public static int resolveRank(UserDetailsImpl principal) {
        if (principal == null || principal.getAuthorities() == null) {
            return RANK_SYSTEM;
        }
        boolean isAdmin = principal.getAuthorities().stream()
                .anyMatch(a -> "ROLE_SUPER_ADMIN".equals(a.getAuthority()) || "ROLE_ADMIN".equals(a.getAuthority()));
        if (isAdmin) return RANK_ADMIN;

        boolean isSpa = principal.getAuthorities().stream()
                .anyMatch(a -> "ROLE_SPA".equals(a.getAuthority()));
        if (isSpa) return RANK_SPA;

        boolean isPa = principal.getAuthorities().stream()
                .anyMatch(a -> "ROLE_PA".equals(a.getAuthority()));
        if (isPa) return RANK_PA;

        return RANK_SYSTEM;
    }

    public static String resolveRoleLabel(int rank) {
        switch (rank) {
            case RANK_ADMIN: return "ADMIN";
            case RANK_SPA: return "SPA";
            case RANK_PA: return "PA";
            default: return "SYSTEM";
        }
    }

    public static String resolveUserDisplay(UserDetailsImpl principal) {
        if (principal == null) return "SYSTEM";
        if (principal.getUsername() != null && !principal.getUsername().isBlank()) {
            return principal.getUsername();
        }
        if (principal.getEmail() != null && !principal.getEmail().isBlank()) {
            return principal.getEmail();
        }
        return principal.getId() != null ? "user#" + principal.getId() : "SYSTEM";
    }

    public static String canonicalKey(String key) {
        return key == null ? "" : key.trim().toUpperCase();
    }
}

