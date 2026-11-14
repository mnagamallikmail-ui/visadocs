package com.provaluer.controller;

import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.model.UserSession;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.JwtUtils;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.AuditLogService;
import com.provaluer.service.AuthSessionService;
import com.provaluer.service.MfaService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder encoder;

    @Autowired
    private JwtUtils jwtUtils;

    @Autowired
    private AuditLogService auditLogService;

    @Autowired
    private MfaService mfaService;

    @Autowired
    private AuthSessionService authSessionService;

    @org.springframework.beans.factory.annotation.Value("${app.mfa.enforcement-enabled:${MFA_ENFORCEMENT_ENABLED:false}}")
    private boolean mfaEnforcementEnabled;

    private static final java.util.Map<String, Long> mfaChallengeStore = new java.util.concurrent.ConcurrentHashMap<>();

    private String getClientIp(HttpServletRequest request) {
        if (request == null) return "127.0.0.1";
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.isBlank()) {
            return xf.split(",")[0].trim();
        }
        return request.getRemoteAddr() != null ? request.getRemoteAddr() : "127.0.0.1";
    }

    private String getDeviceInfo(LoginRequest req, HttpServletRequest request) {
        if (req != null && req.getDeviceInfo() != null && !req.getDeviceInfo().isBlank()) {
            return req.getDeviceInfo().trim();
        }
        if (request == null) return "Web Browser";
        String ua = request.getHeader("User-Agent");
        if (ua == null || ua.isBlank()) return "Web Browser";
        if (ua.contains("Edg/")) return "Microsoft Edge";
        if (ua.contains("Chrome/")) return "Google Chrome";
        if (ua.contains("Firefox/")) return "Mozilla Firefox";
        if (ua.contains("Safari/") && !ua.contains("Chrome")) return "Apple Safari";
        return "Web Browser";
    }

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@RequestBody LoginRequest loginRequest, HttpServletRequest request) {
        String loginIdentifier = loginRequest.getUsername() != null && !loginRequest.getUsername().isBlank()
                ? loginRequest.getUsername().trim()
                : (loginRequest.getEmail() != null ? loginRequest.getEmail().trim() : "");

        // 1. Account Lockout Verification
        Optional<User> existingUserOpt = userRepository.findByUsernameIgnoreCase(loginIdentifier)
                .or(() -> userRepository.findByEmailLookup(loginIdentifier));

        if (existingUserOpt.isPresent()) {
            User existing = existingUserOpt.get();
            if (existing.getLockoutUntil() != null && existing.getLockoutUntil().isAfter(java.time.LocalDateTime.now())) {
                return ResponseEntity.status(423).body(java.util.Map.of(
                        "error", "Account locked due to consecutive failed authentication attempts.",
                        "lockoutUntil", existing.getLockoutUntil().toString()
                ));
            }
        }

        Authentication authentication;
        try {
            authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginIdentifier, loginRequest.getPassword()));
        } catch (BadCredentialsException e) {
            if (existingUserOpt.isPresent()) {
                User u = existingUserOpt.get();
                int attempts = u.getFailedLoginAttempts() + 1;
                u.setFailedLoginAttempts(attempts);
                if (attempts >= 5) {
                    u.setLockoutUntil(java.time.LocalDateTime.now().plusMinutes(15));
                    userRepository.save(u);
                    return ResponseEntity.status(423).body(java.util.Map.of(
                            "error", "Account has been locked for 15 minutes due to 5 consecutive failed login attempts."
                    ));
                }
                userRepository.save(u);
            }
            return ResponseEntity.status(401).body(java.util.Map.of("error", "Invalid username or password"));
        }

        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        User user = userRepository.findById(userDetails.getId()).orElseThrow();

        // Reset failed login attempts on successful credentials
        user.setFailedLoginAttempts(0);
        user.setLockoutUntil(null);
        userRepository.save(user);

        // 2. Multi-Factor Authentication Challenge for Privileged Roles (ADMIN, SUPER_ADMIN, PA, SPA)
        boolean isPrivileged = user.getRole() == UserRole.ADMIN || user.getRole() == UserRole.SUPER_ADMIN
                || user.getRole() == UserRole.PA || user.getRole() == UserRole.SPA;

        if (mfaEnforcementEnabled && (user.isMfaEnabled() || isPrivileged)) {
            if (user.getMfaSecret() == null || user.getMfaSecret().isBlank()) {
                // Initial MFA Setup required for privileged user
                MfaService.MfaSetupPackage setup = mfaService.generateMfaSetup(user.getUsername(), user.getEmail());
                String setupToken = java.util.UUID.randomUUID().toString();
                mfaChallengeStore.put(setupToken, user.getId());

                return ResponseEntity.ok(java.util.Map.of(
                        "mfaSetupRequired", true,
                        "setupToken", setupToken,
                        "secretKey", setup.getSecretKey(),
                        "otpAuthUri", setup.getOtpAuthUri(),
                        "recoveryCodes", setup.getRecoveryCodes(),
                        "message", "Statutory Security Mandate: Multi-Factor Authentication (MFA) setup required for privileged role."
                ));
            }

            String mfaToken = "MFA-" + java.util.UUID.randomUUID().toString();
            mfaChallengeStore.put(mfaToken, user.getId());

            return ResponseEntity.ok(java.util.Map.of(
                    "mfaRequired", true,
                    "mfaToken", mfaToken,
                    "username", user.getUsername(),
                    "message", "MFA Verification Required. Enter 6-digit TOTP code from authenticator app."
            ));
        }

        // 3. Single Active Login Session Check
        Optional<UserSession> activeSessionOpt = authSessionService.getActiveSession(user.getId());
        if (activeSessionOpt.isPresent() && !loginRequest.isForceLogin()) {
            UserSession activeSession = activeSessionOpt.get();
            String challengeStatus = authSessionService.checkChallengeStatus(activeSession.getSessionId());
            if (!"APPROVED".equals(challengeStatus) && !"APPROVED_BY_TIMEOUT".equals(challengeStatus)) {
                String proposedSessionId = java.util.UUID.randomUUID().toString();
                String deviceInfo = getDeviceInfo(loginRequest, request);
                String platformInfo = loginRequest.getPlatformInfo() != null ? loginRequest.getPlatformInfo() : "Web";
                String ip = getClientIp(request);

                java.util.Map<String, Object> challengePayload = authSessionService.initiateLoginChallenge(
                        user, activeSession, proposedSessionId, deviceInfo, platformInfo, "India", ip
                );
                return ResponseEntity.status(org.springframework.http.HttpStatus.CONFLICT).body(challengePayload);
            }
        }

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);
        String refreshToken = jwtUtils.generateRefreshToken(user.getUsername());
        String sessionId = java.util.UUID.randomUUID().toString();
        String deviceInfo = getDeviceInfo(loginRequest, request);
        String platformInfo = loginRequest.getPlatformInfo() != null ? loginRequest.getPlatformInfo() : "Web";
        String ip = getClientIp(request);

        authSessionService.createAndActivateSession(user, sessionId, jwt, refreshToken, deviceInfo, platformInfo, "India", ip);
        
        try {
            auditLogService.log(user.getId(), user.getEmail() != null ? user.getEmail() : user.getUsername(),
                    user.getRole().name(), "USER_LOGIN_SUCCESS", "USER", String.valueOf(user.getId()),
                    null, null, "User successfully logged in on " + deviceInfo);
        } catch (Exception ignored) {}

        return ResponseEntity.ok(new JwtResponse(jwt, 
                                                 refreshToken,
                                                 sessionId,
                                                 userDetails.getId(), 
                                                 user.getUsername(),
                                                 user.getEmail(), 
                                                 user.getRole().name(),
                                                 user.getFullName(),
                                                 user.getMobileNumber(),
                                                 user.getAcceptedTcVersion()));
    }

    @PostMapping("/mfa/verify")
    public ResponseEntity<?> verifyMfaAndAuthenticate(@RequestBody MfaVerifyRequest req, HttpServletRequest request) {
        if (req.getMfaToken() == null || req.getCode() == null) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "mfaToken and code are required"));
        }

        Long userId = mfaChallengeStore.get(req.getMfaToken());
        if (userId == null) {
            return ResponseEntity.status(401).body(java.util.Map.of("error", "Invalid or expired MFA session challenge"));
        }

        User user = userRepository.findById(userId).orElseThrow();
        boolean validTotp = mfaService.verifyTotp(user.getMfaSecret(), req.getCode());
        boolean validRecovery = false;

        if (!validTotp && user.getMfaRecoveryCodes() != null) {
            StringBuilder remainingCodes = new StringBuilder(user.getMfaRecoveryCodes());
            validRecovery = mfaService.verifyAndConsumeRecoveryCode(req.getCode(), remainingCodes);
            if (validRecovery) {
                user.setMfaRecoveryCodes(remainingCodes.toString());
                userRepository.save(user);
            }
        }

        if (!validTotp && !validRecovery) {
            return ResponseEntity.status(401).body(java.util.Map.of("error", "Invalid 6-digit TOTP or recovery code"));
        }

        // MFA Successful: Remove token, activate session, and issue JWT
        mfaChallengeStore.remove(req.getMfaToken());

        UserDetailsImpl userDetails = UserDetailsImpl.build(user);
        Authentication auth = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
        String jwt = jwtUtils.generateJwtToken(auth);
        String refreshToken = jwtUtils.generateRefreshToken(user.getUsername());
        String sessionId = java.util.UUID.randomUUID().toString();
        String deviceInfo = getDeviceInfo(null, request);
        String ip = getClientIp(request);

        authSessionService.createAndActivateSession(user, sessionId, jwt, refreshToken, deviceInfo, "Web", "India", ip);

        return ResponseEntity.ok(new JwtResponse(jwt, 
                                                 refreshToken,
                                                 sessionId,
                                                 user.getId(), 
                                                 user.getUsername(),
                                                 user.getEmail(), 
                                                 user.getRole().name(),
                                                 user.getFullName(),
                                                 user.getMobileNumber(),
                                                 user.getAcceptedTcVersion()));
    }

    @PostMapping("/mfa/confirm-setup")
    public ResponseEntity<?> confirmMfaSetup(@RequestBody MfaSetupConfirmRequest req, HttpServletRequest request) {
        Long userId = mfaChallengeStore.get(req.getSetupToken());
        if (userId == null) {
            return ResponseEntity.status(401).body(java.util.Map.of("error", "Invalid or expired setup token"));
        }

        boolean valid = mfaService.verifyTotp(req.getSecretKey(), req.getVerificationCode());
        if (!valid) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "Invalid verification code for secret key"));
        }

        User user = userRepository.findById(userId).orElseThrow();
        user.setMfaSecret(req.getSecretKey());
        user.setMfaEnabled(true);
        if (req.getRecoveryCodes() != null) {
            user.setMfaRecoveryCodes(String.join(",", req.getRecoveryCodes()));
        }
        userRepository.save(user);

        mfaChallengeStore.remove(req.getSetupToken());

        UserDetailsImpl userDetails = UserDetailsImpl.build(user);
        Authentication auth = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
        String jwt = jwtUtils.generateJwtToken(auth);
        String refreshToken = jwtUtils.generateRefreshToken(user.getUsername());
        String sessionId = java.util.UUID.randomUUID().toString();
        String deviceInfo = getDeviceInfo(null, request);
        String ip = getClientIp(request);

        authSessionService.createAndActivateSession(user, sessionId, jwt, refreshToken, deviceInfo, "Web", "India", ip);

        return ResponseEntity.ok(new JwtResponse(jwt, 
                                                 refreshToken,
                                                 sessionId,
                                                 user.getId(), 
                                                 user.getUsername(),
                                                 user.getEmail(), 
                                                 user.getRole().name(),
                                                 user.getFullName(),
                                                 user.getMobileNumber(),
                                                 user.getAcceptedTcVersion()));
    }

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody RegisterRequest signUpRequest) {
        // Enforce DPDP Statutory Consent at Registration
        if (!signUpRequest.isDpdpConsentGiven()) {
            return ResponseEntity.badRequest().body("DPDP Act 2023 Error: Affirmative statutory consent under Section 6 is mandatory to register.");
        }

        if (signUpRequest.getPassword() == null || signUpRequest.getPassword().length() < 8) {
            return ResponseEntity.badRequest().body("Security Policy Error: Password must be at least 8 characters long.");
        }

        String rawUsername = signUpRequest.getUsername();
        if (rawUsername == null || rawUsername.trim().isEmpty()) {
            if (signUpRequest.getEmail() != null && signUpRequest.getEmail().contains("@")) {
                rawUsername = signUpRequest.getEmail().split("@")[0].trim().toLowerCase();
            } else {
                return ResponseEntity.badRequest().body("Error: Username is required!");
            }
        }
        String username = rawUsername.trim().toLowerCase();

        if (userRepository.existsByUsernameIgnoreCase(username)) {
            return ResponseEntity.badRequest().body("Error: Username is already in use!");
        }

        if (signUpRequest.getEmail() != null && !signUpRequest.getEmail().trim().isEmpty()) {
            if (userRepository.findByEmailLookup(signUpRequest.getEmail().trim()).isPresent()) {
                return ResponseEntity.badRequest().body("Error: Email is already in use!");
            }
        }

        UserRole userRole = UserRole.CLIENT;

        User user = new User(
            username,
            signUpRequest.getEmail() != null ? signUpRequest.getEmail().trim() : null,
            encoder.encode(signUpRequest.getPassword()),
            userRole,
            signUpRequest.getMobileNumber(),
            signUpRequest.getAcceptedTcVersion() != null ? signUpRequest.getAcceptedTcVersion() : "v1.0"
        );
        user.setFullName(signUpRequest.getFullName());
        user.setDpdpConsentGiven(true);
        user.setDpdpConsentVersion("DPDP-NOTICE-V2.0");
        user.setDpdpConsentTimestamp(java.time.LocalDateTime.now());

        User savedUser = userRepository.save(user);

        try {
            auditLogService.log(savedUser.getId(), savedUser.getEmail() != null ? savedUser.getEmail() : savedUser.getUsername(),
                    "CLIENT", "USER_REGISTERED", "USER", String.valueOf(savedUser.getId()),
                    null, "CLIENT", "New user self-registered with CLIENT role and recorded statutory DPDP consent");
        } catch (Exception ignored) {}

        return ResponseEntity.ok("User registered successfully!");
    }

    @PostMapping("/accept-tc")
    public ResponseEntity<?> acceptTermsAndConditions(@RequestBody TcAcceptRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetailsImpl) {
            UserDetailsImpl principal = (UserDetailsImpl) auth.getPrincipal();
            Optional<User> userOpt = userRepository.findById(principal.getId());
            if (userOpt.isPresent()) {
                User user = userOpt.get();
                user.setAcceptedTcVersion(request.getVersion());
                userRepository.save(user);
                return ResponseEntity.ok("Terms & Conditions version " + request.getVersion() + " accepted successfully!");
            }
        }
        return ResponseEntity.status(401).body("Unauthorized");
    }

    @PostMapping("/challenge/respond")
    public ResponseEntity<?> respondToChallenge(@RequestBody ChallengeRespondRequest req) {
        if (req.getChallengeSessionId() == null || req.getDecision() == null) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "challengeSessionId and decision are required"));
        }
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !(auth.getPrincipal() instanceof UserDetailsImpl)) {
            return ResponseEntity.status(401).body(java.util.Map.of("error", "Authentication required"));
        }
        UserDetailsImpl principal = (UserDetailsImpl) auth.getPrincipal();
        try {
            java.util.Map<String, Object> result = authSessionService.respondToChallenge(
                    req.getChallengeSessionId(), req.getDecision(), principal.getId()
            );
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/challenge/status")
    public ResponseEntity<?> checkChallengeStatus(@RequestParam("id") String challengeSessionId) {
        if (challengeSessionId == null || challengeSessionId.isBlank()) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "challengeSessionId parameter 'id' is required"));
        }
        String status = authSessionService.checkChallengeStatus(challengeSessionId);
        return ResponseEntity.ok(java.util.Map.of(
                "challengeSessionId", challengeSessionId,
                "status", status
        ));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestBody(required = false) java.util.Map<String, String> payload,
                                    @RequestHeader(value = "X-Session-ID", required = false) String sessionHeader) {
        String sessionId = sessionHeader;
        if ((sessionId == null || sessionId.isBlank()) && payload != null) {
            sessionId = payload.get("sessionId");
        }
        if (sessionId != null && !sessionId.isBlank()) {
            authSessionService.logout(sessionId);
        }
        SecurityContextHolder.clearContext();
        return ResponseEntity.ok(java.util.Map.of("message", "Logged out successfully"));
    }

    @PostMapping({"/refresh", "/refresh-token"})
    public ResponseEntity<?> refreshToken(@RequestBody RefreshTokenRequest req) {
        if (req.getRefreshToken() == null || req.getRefreshToken().isBlank()) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", "Refresh token is required"));
        }
        if (!jwtUtils.validateJwtToken(req.getRefreshToken())) {
            return ResponseEntity.status(401).body(java.util.Map.of("error", "Invalid or expired refresh token"));
        }

        String username = jwtUtils.getUserNameFromJwtToken(req.getRefreshToken());
        if (!userRepository.existsByUsernameIgnoreCase(username)) {
            throw new BadCredentialsException("User not found");
        }

        if (req.getSessionId() != null && !req.getSessionId().isBlank()) {
            boolean sessionActive = authSessionService.validateAndTouchSession(req.getSessionId());
            if (!sessionActive) {
                return ResponseEntity.status(401).body(java.util.Map.of("error", "Session has been evicted or expired. Re-authentication required."));
            }
        }

        String newJwt = jwtUtils.generateTokenFromUsername(username);
        String newRefreshToken = jwtUtils.generateRefreshToken(username);

        return ResponseEntity.ok(java.util.Map.of(
                "token", newJwt,
                "refreshToken", newRefreshToken,
                "sessionId", req.getSessionId() != null ? req.getSessionId() : ""
        ));
    }

    // DTO Classes
    public static class LoginRequest {
        private String username;
        private String email;
        private String password;
        private String deviceInfo;
        private String platformInfo;
        private boolean forceLogin;
        private String challengeSessionId;

        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getDeviceInfo() { return deviceInfo; }
        public void setDeviceInfo(String deviceInfo) { this.deviceInfo = deviceInfo; }
        public String getPlatformInfo() { return platformInfo; }
        public void setPlatformInfo(String platformInfo) { this.platformInfo = platformInfo; }
        public boolean isForceLogin() { return forceLogin; }
        public void setForceLogin(boolean forceLogin) { this.forceLogin = forceLogin; }
        public String getChallengeSessionId() { return challengeSessionId; }
        public void setChallengeSessionId(String challengeSessionId) { this.challengeSessionId = challengeSessionId; }
    }

    public static class ChallengeRespondRequest {
        private String challengeSessionId;
        private String decision;

        public String getChallengeSessionId() { return challengeSessionId; }
        public void setChallengeSessionId(String challengeSessionId) { this.challengeSessionId = challengeSessionId; }
        public String getDecision() { return decision; }
        public void setDecision(String decision) { this.decision = decision; }
    }

    public static class RefreshTokenRequest {
        private String refreshToken;
        private String sessionId;

        public String getRefreshToken() { return refreshToken; }
        public void setRefreshToken(String refreshToken) { this.refreshToken = refreshToken; }
        public String getSessionId() { return sessionId; }
        public void setSessionId(String sessionId) { this.sessionId = sessionId; }
    }

    public static class RegisterRequest {
        private String username;
        private String email;
        private String password;
        private String role;
        private String mobileNumber;
        private String fullName;
        private String acceptedTcVersion;
        private boolean dpdpConsentGiven;

        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }
        public String getMobileNumber() { return mobileNumber; }
        public void setMobileNumber(String mobileNumber) { this.mobileNumber = mobileNumber; }
        public String getFullName() { return fullName; }
        public void setFullName(String fullName) { this.fullName = fullName; }
        public String getAcceptedTcVersion() { return acceptedTcVersion; }
        public void setAcceptedTcVersion(String acceptedTcVersion) { this.acceptedTcVersion = acceptedTcVersion; }
        public boolean isDpdpConsentGiven() { return dpdpConsentGiven; }
        public void setDpdpConsentGiven(boolean dpdpConsentGiven) { this.dpdpConsentGiven = dpdpConsentGiven; }
    }

    public static class MfaVerifyRequest {
        private String mfaToken;
        private String code;

        public String getMfaToken() { return mfaToken; }
        public void setMfaToken(String mfaToken) { this.mfaToken = mfaToken; }
        public String getCode() { return code; }
        public void setCode(String code) { this.code = code; }
    }

    public static class MfaSetupConfirmRequest {
        private String setupToken;
        private String secretKey;
        private String verificationCode;
        private java.util.List<String> recoveryCodes;

        public String getSetupToken() { return setupToken; }
        public void setSetupToken(String setupToken) { this.setupToken = setupToken; }
        public String getSecretKey() { return secretKey; }
        public void setSecretKey(String secretKey) { this.secretKey = secretKey; }
        public String getVerificationCode() { return verificationCode; }
        public void setVerificationCode(String verificationCode) { this.verificationCode = verificationCode; }
        public java.util.List<String> getRecoveryCodes() { return recoveryCodes; }
        public void setRecoveryCodes(java.util.List<String> recoveryCodes) { this.recoveryCodes = recoveryCodes; }
    }

    public static class TcAcceptRequest {
        private String version;
        public String getVersion() { return version; }
        public void setVersion(String version) { this.version = version; }
    }

    public static class JwtResponse {
        private String token;
        private String refreshToken;
        private String sessionId;
        private Long id;
        private String username;
        private String email;
        private String role;
        private String fullName;
        private String mobileNumber;
        private String acceptedTcVersion;

        public JwtResponse() {}

        public JwtResponse(String accessToken, Long id, String username, String email, String role, String fullName, String mobileNumber, String acceptedTcVersion) {
            this(accessToken, null, null, id, username, email, role, fullName, mobileNumber, acceptedTcVersion);
        }

        public JwtResponse(String accessToken, Long id, String email, String role, String fullName, String mobileNumber, String acceptedTcVersion) {
            this(accessToken, null, null, id, email != null && email.contains("@") ? email.substring(0, email.indexOf('@')) : email,
                 email, role, fullName, mobileNumber, acceptedTcVersion);
        }

        public JwtResponse(String accessToken, String refreshToken, String sessionId, Long id, String username, String email, String role, String fullName, String mobileNumber, String acceptedTcVersion) {
            this.token = accessToken;
            this.refreshToken = refreshToken;
            this.sessionId = sessionId;
            this.id = id;
            this.username = username;
            this.email = email;
            this.role = role;
            this.fullName = fullName;
            this.mobileNumber = mobileNumber;
            this.acceptedTcVersion = acceptedTcVersion;
        }

        public String getToken() { return token; }
        public String getRefreshToken() { return refreshToken; }
        public String getSessionId() { return sessionId; }
        public Long getId() { return id; }
        public String getUsername() { return username; }
        public String getEmail() { return email; }
        public String getRole() { return role; }
        public String getFullName() { return fullName; }
        public String getMobileNumber() { return mobileNumber; }
        public String getAcceptedTcVersion() { return acceptedTcVersion; }
    }
}
