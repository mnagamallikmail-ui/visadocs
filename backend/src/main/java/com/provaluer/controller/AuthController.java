package com.provaluer.controller;

import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.JwtUtils;
import com.provaluer.security.UserDetailsImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

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

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@RequestBody LoginRequest loginRequest) {
        String loginIdentifier = loginRequest.getUsername() != null && !loginRequest.getUsername().isBlank()
                ? loginRequest.getUsername().trim()
                : (loginRequest.getEmail() != null ? loginRequest.getEmail().trim() : "");

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginIdentifier, loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);
        
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        User user = userRepository.findById(userDetails.getId()).orElseThrow();

        return ResponseEntity.ok(new JwtResponse(jwt, 
                                                 userDetails.getId(), 
                                                 user.getUsername(),
                                                 user.getEmail(), 
                                                 user.getRole().name(),
                                                 user.getFullName(),
                                                 user.getMobileNumber(),
                                                 user.getAcceptedTcVersion()));
    }

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody RegisterRequest signUpRequest) {
        String rawUsername = signUpRequest.getUsername();
        if (rawUsername == null || rawUsername.trim().isEmpty()) {
            // If username not explicitly provided, generate from email if present
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
            if (userRepository.findByEmailIgnoreCase(signUpRequest.getEmail().trim()).isPresent()) {
                return ResponseEntity.badRequest().body("Error: Email is already in use!");
            }
        }

        // Create new user's account
        UserRole userRole = UserRole.CLIENT;
        if (signUpRequest.getRole() != null) {
            try {
                userRole = UserRole.valueOf(signUpRequest.getRole().toUpperCase());
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body("Error: Invalid role specified.");
            }
        }

        User user = new User(
            username,
            signUpRequest.getEmail() != null ? signUpRequest.getEmail().trim() : null,
            encoder.encode(signUpRequest.getPassword()),
            userRole,
            signUpRequest.getMobileNumber(),
            signUpRequest.getAcceptedTcVersion() != null ? signUpRequest.getAcceptedTcVersion() : "v1.0"
        );
        user.setFullName(signUpRequest.getFullName());

        userRepository.save(user);
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

    // DTO Classes
    public static class LoginRequest {
        private String username;
        private String email;
        private String password;

        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    public static class RegisterRequest {
        private String username;
        private String email;
        private String password;
        private String role;
        private String mobileNumber;
        private String fullName;
        private String acceptedTcVersion;

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
    }

    public static class TcAcceptRequest {
        private String version;
        public String getVersion() { return version; }
        public void setVersion(String version) { this.version = version; }
    }

    public static class JwtResponse {
        private String token;
        private Long id;
        private String username;
        private String email;
        private String role;
        private String fullName;
        private String mobileNumber;
        private String acceptedTcVersion;

        public JwtResponse() {}

        public JwtResponse(String accessToken, Long id, String username, String email, String role, String fullName, String mobileNumber, String acceptedTcVersion) {
            this.token = accessToken;
            this.id = id;
            this.username = username;
            this.email = email;
            this.role = role;
            this.fullName = fullName;
            this.mobileNumber = mobileNumber;
            this.acceptedTcVersion = acceptedTcVersion;
        }

        public JwtResponse(String accessToken, Long id, String email, String role, String fullName, String mobileNumber, String acceptedTcVersion) {
            this(accessToken, id, email != null && email.contains("@") ? email.substring(0, email.indexOf('@')) : email,
                 email, role, fullName, mobileNumber, acceptedTcVersion);
        }

        public String getToken() { return token; }
        public Long getId() { return id; }
        public String getUsername() { return username; }
        public String getEmail() { return email; }
        public String getRole() { return role; }
        public String getFullName() { return fullName; }
        public String getMobileNumber() { return mobileNumber; }
        public String getAcceptedTcVersion() { return acceptedTcVersion; }
    }
}
