package com.provaluer.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

public class AuthTokenFilter extends OncePerRequestFilter {
    private static final Logger logger = LoggerFactory.getLogger(AuthTokenFilter.class);

    private final JwtUtils jwtUtils;
    private final UserDetailsServiceImpl userDetailsService;
    private final com.provaluer.repository.UserSessionRepository userSessionRepository;

    // Explicit constructor injection — avoids @Autowired field injection timing issues
    // when this filter is instantiated via new AuthTokenFilter() inside a @Bean factory method.
    public AuthTokenFilter(JwtUtils jwtUtils, UserDetailsServiceImpl userDetailsService,
                           com.provaluer.repository.UserSessionRepository userSessionRepository) {
        this.jwtUtils = jwtUtils;
        this.userDetailsService = userDetailsService;
        this.userSessionRepository = userSessionRepository;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String jwt = parseJwt(request);
            if (jwt != null && jwtUtils.validateJwtToken(jwt)) {
                String username = jwtUtils.getUserNameFromJwtToken(jwt);
                UserDetails userDetails = userDetailsService.loadUserByUsername(username);

                // Mirror DaoAuthenticationProvider's DefaultUserDetailsChecker:
                // a valid JWT is not enough — the account must also be in good standing.
                if (!userDetails.isEnabled() || !userDetails.isAccountNonLocked()
                        || !userDetails.isAccountNonExpired() || !userDetails.isCredentialsNonExpired()) {
                    logger.warn("[AuthTokenFilter] Rejected valid JWT for account with bad status: {}", username);
                } else {
                    // Authoritative Single-Session Check: verify session is active and not displaced
                    if (userSessionRepository != null) {
                        String tokenHash = com.provaluer.service.AuthSessionService.hashToken(jwt);
                        boolean isDisplaced = false;

                        java.util.Optional<com.provaluer.model.UserSession> sessionOpt = 
                                userSessionRepository.findTopBySessionTokenHashOrderByIdDesc(tokenHash);
                        if (sessionOpt.isPresent()) {
                            if (!Boolean.TRUE.equals(sessionOpt.get().getIsActive())) {
                                isDisplaced = true;
                            }
                        } else if (userDetails instanceof UserDetailsImpl) {
                            Long userId = ((UserDetailsImpl) userDetails).getId();
                            java.util.Optional<com.provaluer.model.UserSession> activeForUser = 
                                    userSessionRepository.findByUserIdAndIsActiveTrue(userId);
                            if (activeForUser.isPresent() && !tokenHash.equals(activeForUser.get().getSessionTokenHash())) {
                                isDisplaced = true;
                            }
                        }

                        if (isDisplaced) {
                            logger.warn("[AuthTokenFilter] Displaced or terminated session for user {}. Rejecting request.", username);
                            // Proceed without setting SecurityContext -> Spring Security will return 401
                            filterChain.doFilter(request, response);
                            return;
                        }
                    }

                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    logger.debug("[AuthTokenFilter] Authenticated user: {}", username);
                }
            }
        } catch (Exception e) {
            logger.error("[AuthTokenFilter] Cannot set user authentication: {}", e.getMessage(), e);
        }
        filterChain.doFilter(request, response);
    }

    private String parseJwt(HttpServletRequest request) {
        String headerAuth = request.getHeader("Authorization");
        if (StringUtils.hasText(headerAuth) && headerAuth.startsWith("Bearer ")) {
            return headerAuth.substring(7);
        }
        String paramToken = request.getParameter("token");
        if (StringUtils.hasText(paramToken)) {
            return paramToken;
        }
        return null;
    }
}
