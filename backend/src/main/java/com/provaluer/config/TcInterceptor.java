package com.provaluer.config;

import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.SystemSettingRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.UserDetailsImpl;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import java.util.Objects;

@Component
public class TcInterceptor implements HandlerInterceptor {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SystemSettingRepository systemSettingRepository;

    @Override
    public boolean preHandle(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull Object handler) throws Exception {
        String path = request.getRequestURI();
        if (path.startsWith("/api/v1/auth") || path.startsWith("/swagger-ui") || path.startsWith("/v3/api-docs")) {
            return true;
        }

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated() && auth.getPrincipal() instanceof UserDetailsImpl) {
            UserDetailsImpl principal = (UserDetailsImpl) auth.getPrincipal();
            User user = userRepository.findById(Objects.requireNonNull(principal.getId())).orElse(null);

            if (user == null) return true;

            // SUPER_ADMIN and SPA/PA bypass T&C enforcement — only CLIENT is gated
            if (user.getRole() == UserRole.SUPER_ADMIN || user.getRole() == UserRole.ADMIN
                    || user.getRole() == UserRole.SPA || user.getRole() == UserRole.PA) {
                return true;
            }

            // Enforce T&C for CLIENT role only
            if (user.getRole() == UserRole.CLIENT) {
                String activeVersion = systemSettingRepository.findById("tc_version")
                        .map(s -> s.getSettingValue())
                        .orElse("v1.0");
                String userAccepted = user.getAcceptedTcVersion();
                if (userAccepted == null || !userAccepted.equals(activeVersion)) {
                    response.setStatus(451);
                    response.setContentType("application/json");
                    response.getWriter().write("{\"error\": \"TERMS_AND_CONDITIONS_REQUIRED\", \"activeVersion\": \"" + activeVersion + "\"}");
                    return false;
                }
            }
        }
        return true;
    }
}
