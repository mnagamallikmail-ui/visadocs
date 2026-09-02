package com.provaluer.service;

import com.provaluer.model.SystemSetting;
import com.provaluer.repository.SystemSettingRepository;
import com.provaluer.security.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

@Service
public class FeatureFlagService {

    public static final String FLAG_DOCUMENT_STUDIO = "feature_flag_document_studio";
    public static final String PILOT_USERS_KEY = "document_studio_pilot_users";

    public static final String MODE_DISABLED = "DISABLED";
    public static final String MODE_SUPER_ADMIN_ONLY = "SUPER_ADMIN_ONLY";
    public static final String MODE_PILOT_USERS = "PILOT_USERS";
    public static final String MODE_ENABLED = "ENABLED";

    @Autowired
    private SystemSettingRepository systemSettingRepository;

    /**
     * Retrieves the current feature flag configuration mode from system_settings.
     * Defaults to 'DISABLED' if missing or blank.
     */
    public String getStudioFlagValue() {
        return systemSettingRepository.findById(FLAG_DOCUMENT_STUDIO)
                .map(SystemSetting::getSettingValue)
                .filter(val -> val != null && !val.trim().isEmpty())
                .map(String::trim)
                .map(String::toUpperCase)
                .orElse(MODE_DISABLED);
    }

    /**
     * Evaluates whether Document Studio is accessible for the specified authenticated UserDetailsImpl.
     */
    public boolean isStudioEnabled(UserDetailsImpl user) {
        if (user == null) {
            return false;
        }

        String mode = getStudioFlagValue();

        switch (mode) {
            case MODE_ENABLED:
                return true;

            case MODE_SUPER_ADMIN_ONLY:
                return hasAdminAuthority(user);

            case MODE_PILOT_USERS:
                if (hasAdminAuthority(user)) {
                    return true;
                }
                return isUserInPilotList(user.getUsername()) || isUserInPilotList(user.getEmail());

            case MODE_DISABLED:
            default:
                return false;
        }
    }

    /**
     * Evaluates whether Document Studio is accessible for the given Spring Security Authentication.
     */
    public boolean isStudioEnabled(Authentication auth) {
        if (auth == null || !auth.isAuthenticated() || auth.getPrincipal() == null) {
            return false;
        }

        Object principal = auth.getPrincipal();
        if (principal instanceof UserDetailsImpl userDetails) {
            return isStudioEnabled(userDetails);
        }

        // Fallback for custom or anonymous principals: check authorities
        String mode = getStudioFlagValue();
        if (MODE_ENABLED.equals(mode)) {
            return true;
        }

        boolean isAdmin = auth.getAuthorities() != null && auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch(a -> "ROLE_SUPER_ADMIN".equals(a) || "ROLE_ADMIN".equals(a));

        if (isAdmin && (MODE_SUPER_ADMIN_ONLY.equals(mode) || MODE_PILOT_USERS.equals(mode))) {
            return true;
        }

        if (MODE_PILOT_USERS.equals(mode)) {
            return isUserInPilotList(auth.getName());
        }

        return false;
    }

    private boolean hasAdminAuthority(UserDetailsImpl user) {
        if (user.getAuthorities() == null) {
            return false;
        }
        return user.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .anyMatch(auth -> "ROLE_SUPER_ADMIN".equals(auth) || "ROLE_ADMIN".equals(auth));
    }

    private boolean isUserInPilotList(String userEmail) {
        if (userEmail == null || userEmail.trim().isEmpty()) {
            return false;
        }

        Optional<SystemSetting> settingOpt = systemSettingRepository.findById(PILOT_USERS_KEY);
        if (settingOpt.isEmpty() || settingOpt.get().getSettingValue() == null) {
            return false;
        }

        String pilotListRaw = settingOpt.get().getSettingValue();
        if (pilotListRaw.trim().isEmpty()) {
            return false;
        }

        String normalizedEmail = userEmail.trim().toLowerCase();
        List<String> pilotEmails = Arrays.stream(pilotListRaw.split(","))
                .map(String::trim)
                .filter(e -> !e.isEmpty())
                .map(String::toLowerCase)
                .toList();

        return pilotEmails.contains(normalizedEmail);
    }
}
