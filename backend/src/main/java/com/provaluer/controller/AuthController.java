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
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);
        
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
        User user = userRepository.findById(userDetails.getId()).orElseThrow();

        return ResponseEntity.ok(new JwtResponse(jwt, 
                                                 userDetails.getId(), 
                                                 userDetails.getUsername(), 
                                                 user.getRole().name(),
                                                 user.getFullName(),
                                                 user.getMobileNumber(),
                                                 user.getAcceptedTcVersion()));
    }

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody RegisterRequest signUpRequest) {
        if (userRepository.findByEmailIgnoreCase(signUpRequest.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Error: Email is already in use!");
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
            signUpRequest.getEmail(),
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
        private String email;
        private String password;
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    public static class RegisterRequest {
        private String email;
        private String password;
        private String role;
        private String mobileNumber;
        private String fullName;
        private String acceptedTcVersion;
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
        private String email;
        private String role;
        private String fullName;
        private String mobileNumber;
        private String acceptedTcVersion;

        public JwtResponse(String accessToken, Long id, String email, String role, String fullName, String mobileNumber, String acceptedTcVersion) {
            this.token = accessToken;
            this.id = id;
            this.email = email;
            this.role = role;
            this.fullName = fullName;
            this.mobileNumber = mobileNumber;
            this.acceptedTcVersion = acceptedTcVersion;
        }

        public String getToken() { return token; }
        public Long getId() { return id; }
        public String getEmail() { return email; }
        public String getRole() { return role; }
        public String getFullName() { return fullName; }
        public String getMobileNumber() { return mobileNumber; }
        public String getAcceptedTcVersion() { return acceptedTcVersion; }
    }
}
