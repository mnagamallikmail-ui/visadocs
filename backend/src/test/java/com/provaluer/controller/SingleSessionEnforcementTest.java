package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.controller.AuthController.LoginRequest;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.model.UserSession;
import com.provaluer.repository.UserRepository;
import com.provaluer.repository.UserSessionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class SingleSessionEnforcementTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private UserRepository userRepository;
    @Autowired private UserSessionRepository userSessionRepository;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private ObjectMapper objectMapper;

    private User testUser;
    private final String rawPassword = "Password123!";

    @BeforeEach
    void setUp() {
        userSessionRepository.deleteAll();
        Optional<User> existing = userRepository.findByUsernameIgnoreCase("session_client");
        if (existing.isPresent()) {
            testUser = existing.get();
            testUser.setPassword(passwordEncoder.encode(rawPassword));
            testUser = userRepository.save(testUser);
        } else {
            testUser = new User(
                    "session_client",
                    "session_client@visadocs.online",
                    passwordEncoder.encode(rawPassword),
                    UserRole.CLIENT,
                    "9876543210",
                    "v1.0"
            );
            testUser.setFullName("Session Test Client");
            testUser = userRepository.save(testUser);
        }
    }

    @Test
    @DisplayName("Single Active Session Enforcement: 409 on duplicate login, Force login evicts old session, Old token rejected with 401")
    void testSingleActiveSessionWorkflow() throws Exception {
        // 1. Device 1 logs in successfully -> HTTP 200
        LoginRequest req1 = new LoginRequest();
        req1.setUsername(testUser.getUsername());
        req1.setPassword(rawPassword);
        req1.setDeviceInfo("Chrome on Windows 11");
        req1.setPlatformInfo("Windows Desktop");

        MvcResult login1Result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req1)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andReturn();

        Map<?, ?> resp1 = objectMapper.readValue(login1Result.getResponse().getContentAsString(), Map.class);
        String token1 = resp1.get("token").toString();

        // Verify active session exists in DB
        Optional<UserSession> session1Opt = userSessionRepository.findByUserIdAndIsActiveTrue(testUser.getId());
        assertTrue(session1Opt.isPresent());
        assertEquals("Chrome on Windows 11", session1Opt.get().getDeviceInfo());

        // Device 1 accesses authenticated endpoint -> HTTP 200
        mockMvc.perform(get("/api/v1/orders/client")
                        .header("Authorization", "Bearer " + token1))
                .andExpect(status().isOk());

        // 2. Device 2 attempts login without forceLogin -> HTTP 409 Conflict with SESSION_ALREADY_ACTIVE
        LoginRequest req2 = new LoginRequest();
        req2.setUsername(testUser.getUsername());
        req2.setPassword(rawPassword);
        req2.setDeviceInfo("Safari on iPhone 15");
        req2.setPlatformInfo("iOS Mobile");
        req2.setForceLogin(false);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req2)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("SESSION_ALREADY_ACTIVE"))
                .andExpect(jsonPath("$.deviceName").value("Chrome on Windows 11"))
                .andExpect(jsonPath("$.location").value("India"))
                .andExpect(jsonPath("$.loginTime").isNotEmpty());

        // 3. User chooses 'LOG OUT OTHER SESSION & CONTINUE' (forceLogin = true) -> HTTP 200
        Thread.sleep(1100); // Ensure second login gets a new JWT issuedAt timestamp
        req2.setForceLogin(true);

        MvcResult login2Result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req2)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andReturn();

        Map<?, ?> resp2 = objectMapper.readValue(login2Result.getResponse().getContentAsString(), Map.class);
        String token2 = resp2.get("token").toString();

        // 4. Verify DB: Session 1 is terminated and Session 2 is active
        UserSession activeSession = userSessionRepository.findByUserIdAndIsActiveTrue(testUser.getId()).orElseThrow();
        assertEquals("Safari on iPhone 15", activeSession.getDeviceInfo());

        UserSession oldSession = userSessionRepository.findById(session1Opt.get().getId()).orElseThrow();
        assertFalse(oldSession.getIsActive());
        assertEquals("NEW_DEVICE_ACTIVATION", oldSession.getTerminationReason());

        // 5. Device 1 tries to use token1 -> Server returns HTTP 401 Unauthorized!
        mockMvc.perform(get("/api/v1/orders/client")
                        .header("Authorization", "Bearer " + token1))
                .andExpect(status().isUnauthorized());

        // 6. Device 2 uses token2 -> Server returns HTTP 200 OK!
        mockMvc.perform(get("/api/v1/orders/client")
                        .header("Authorization", "Bearer " + token2))
                .andExpect(status().isOk());
    }
}
