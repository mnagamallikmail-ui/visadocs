package com.provaluer.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.http.HttpMethod;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.Arrays;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {
    @Autowired
    private UserDetailsServiceImpl userDetailsService;

    @Autowired
    private AuthEntryPointJwt unauthorizedHandler;

    @Autowired
    private JwtUtils jwtUtils;

    @Bean
    public AuthTokenFilter authenticationJwtTokenFilter() {
        // Explicit constructor injection ensures jwtUtils and userDetailsService
        // are never null — both are fully wired by the time SecurityConfig is processed.
        return new AuthTokenFilter(jwtUtils, userDetailsService);
    }

    /**
     * Prevent Spring Boot from auto-registering AuthTokenFilter in the servlet container.
     * AuthTokenFilter is a @Bean, so Spring Boot's FilterRegistrationAutoConfiguration would
     * register it as a standalone servlet filter AND Spring Security adds it via addFilterBefore —
     * two registrations of the same OncePerRequestFilter. OncePerRequestFilter marks the request
     * as FILTERED on first execution; the second attempt silently skips, leaving the
     * SecurityContextHolder empty on whichever run comes second → 401 on all protected endpoints.
     */
    @Bean
    public FilterRegistrationBean<AuthTokenFilter> authTokenFilterRegistration() {
        FilterRegistrationBean<AuthTokenFilter> registration =
                new FilterRegistrationBean<>(authenticationJwtTokenFilter());
        registration.setEnabled(false); // Only run inside Spring Security's filter chain
        return registration;
    }

    @Bean
    public DaoAuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService);
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authConfig) throws Exception {
        return authConfig.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .exceptionHandling(exception -> exception.authenticationEntryPoint(unauthorizedHandler))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> 
                auth.requestMatchers("/api/v1/auth/**").permitAll()
                    // P0-1: Strictly allow ONLY POST requests for public commercial lead intake and document uploads
                    .requestMatchers(HttpMethod.POST, "/api/leads").permitAll()
                    .requestMatchers(HttpMethod.POST, "/api/leads/*/upload").permitAll()
                    // All other lead operations (listing, dossier inspection, quote generation, status transitions) require ADMIN
                    .requestMatchers("/api/leads/**").hasAnyRole("ADMIN", "SUPER_ADMIN")
                    .requestMatchers("/swagger-ui/**", "/v3/api-docs/**", "/error").permitAll()
                    .anyRequest().authenticated()
            );

        http.authenticationProvider(authenticationProvider());
        http.addFilterBefore(authenticationJwtTokenFilter(), UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        // P1-5: Hardened CORS - remove wildcards, permit only verified production, admin, and dev origins
        configuration.setAllowedOrigins(Arrays.asList(
            "https://www.provaluer.in",
            "https://provaluer.in",
            "https://admin.provaluer.in",
            "http://localhost:3000",
            "http://localhost:8080",
            "http://localhost:5000",
            "http://localhost:5173",
            "http://127.0.0.1:3000",
            "http://127.0.0.1:8080"
        ));
        configuration.setAllowCredentials(true);
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "Accept", "X-Requested-With"));
        configuration.setExposedHeaders(Arrays.asList("Authorization"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
