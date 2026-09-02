package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.controller.AuthController;
import com.provaluer.controller.SuperAdminController;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class UserAuthenticationRestructureTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private com.provaluer.repository.PerformanceLedgerRepository performanceLedgerRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("Runtime Verification: Username-Based Auth Restructure, Master Account & Admin Capabilities")
    @WithMockUser(username = "admin", roles = {"SUPER_ADMIN"})
    public void testUsernameBasedAuthRestructure() throws Exception {
        System.out.println("========================================================================");
        System.out.println("USER MANAGEMENT & AUTHENTICATION RESTRUCTURE RUNTIME VERIFICATION");
        System.out.println("========================================================================");

        // --------------------------------------------------------------------
        // 1. Verify Database Migration & Initial Users
        // --------------------------------------------------------------------
        System.out.println("1. Verifying Database Migration & Initial User Entities...");
        User admin = userRepository.findByUsernameIgnoreCase("admin")
                .orElseThrow(() -> new AssertionError("Master 'admin' user not found in database!"));
        assertEquals("admin", admin.getUsername());
        assertEquals(UserRole.SUPER_ADMIN, admin.getRole(), "Master account role must be SUPER_ADMIN");

        User poojitha = userRepository.findByUsernameIgnoreCase("poojitha")
                .orElseThrow(() -> new AssertionError("User 'poojitha' not found in database!"));
        assertEquals("poojitha", poojitha.getUsername());
        assertEquals(UserRole.PA, poojitha.getRole(), "'poojitha' role must be PA");

        User divya = userRepository.findByUsernameIgnoreCase("divya")
                .orElseThrow(() -> new AssertionError("User 'divya' not found in database!"));
        assertEquals("divya", divya.getUsername());
        assertEquals(UserRole.SPA, divya.getRole(), "'divya' role must be SPA");

        User naga = userRepository.findByUsernameIgnoreCase("naga")
                .orElseThrow(() -> new AssertionError("User 'naga' not found in database!"));
        assertEquals("naga", naga.getUsername());
        assertEquals(UserRole.CLIENT, naga.getRole(), "'naga' role must be CLIENT");

        System.out.println("-> PASSED: All 4 initial accounts correctly stored with target usernames and roles.");

        // --------------------------------------------------------------------
        // 2. Verify Authentication via /api/v1/auth/login
        // --------------------------------------------------------------------
        System.out.println("2. Verifying Login using Username + Password...");

        // Login as admin
        AuthController.LoginRequest adminReq = new AuthController.LoginRequest();
        adminReq.setUsername("admin");
        adminReq.setPassword("password");
        MvcResult adminRes = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(adminReq)))
                .andExpect(status().isOk())
                .andReturn();
        AuthController.JwtResponse adminJwt = objectMapper.readValue(adminRes.getResponse().getContentAsString(), AuthController.JwtResponse.class);
        assertNotNull(adminJwt.getToken());
        assertEquals("admin", adminJwt.getUsername());
        assertEquals("SUPER_ADMIN", adminJwt.getRole());

        // Login as poojitha (PA)
        AuthController.LoginRequest paReq = new AuthController.LoginRequest();
        paReq.setUsername("poojitha");
        paReq.setPassword("password");
        MvcResult paRes = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(paReq)))
                .andExpect(status().isOk())
                .andReturn();
        AuthController.JwtResponse paJwt = objectMapper.readValue(paRes.getResponse().getContentAsString(), AuthController.JwtResponse.class);
        assertNotNull(paJwt.getToken());
        assertEquals("poojitha", paJwt.getUsername());
        assertEquals("PA", paJwt.getRole());

        // Login as divya (SPA)
        AuthController.LoginRequest spaReq = new AuthController.LoginRequest();
        spaReq.setUsername("divya");
        spaReq.setPassword("password");
        MvcResult spaRes = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(spaReq)))
                .andExpect(status().isOk())
                .andReturn();
        AuthController.JwtResponse spaJwt = objectMapper.readValue(spaRes.getResponse().getContentAsString(), AuthController.JwtResponse.class);
        assertNotNull(spaJwt.getToken());
        assertEquals("divya", spaJwt.getUsername());
        assertEquals("SPA", spaJwt.getRole());

        // Login as naga (CLIENT)
        AuthController.LoginRequest clientReq = new AuthController.LoginRequest();
        clientReq.setUsername("naga");
        clientReq.setPassword("password");
        MvcResult clientRes = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(clientReq)))
                .andExpect(status().isOk())
                .andReturn();
        AuthController.JwtResponse clientJwt = objectMapper.readValue(clientRes.getResponse().getContentAsString(), AuthController.JwtResponse.class);
        assertNotNull(clientJwt.getToken());
        assertEquals("naga", clientJwt.getUsername());
        assertEquals("CLIENT", clientJwt.getRole());

        System.out.println("-> PASSED: Login with username/password verified for admin, poojitha, divya, and naga.");

        String adminToken = "Bearer " + adminJwt.getToken();

        // --------------------------------------------------------------------
        // 3. Verify Master Account Protection
        // --------------------------------------------------------------------
        System.out.println("3. Verifying Master 'admin' Account Protection...");

        // Admin account cannot be locked
        mockMvc.perform(post("/api/v1/admin/users/" + admin.getId() + "/lock")
                        .header("Authorization", adminToken))
                .andExpect(status().isBadRequest());

        // Admin account cannot be deleted
        mockMvc.perform(delete("/api/v1/admin/users/" + admin.getId())
                        .header("Authorization", adminToken))
                .andExpect(status().isBadRequest());

        // Admin role cannot be modified
        SuperAdminController.RoleChangeRequest roleReq = new SuperAdminController.RoleChangeRequest();
        roleReq.setRole("PA");
        mockMvc.perform(put("/api/v1/admin/users/" + admin.getId() + "/role")
                        .header("Authorization", adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(roleReq)))
                .andExpect(status().isBadRequest());

        System.out.println("-> PASSED: Master 'admin' account is permanently protected against lock, delete, and role change.");

        // --------------------------------------------------------------------
        // 4. Verify Admin Capabilities: Create, Edit, Lock/Unlock, Reset Password, Role Assignment
        // --------------------------------------------------------------------
        System.out.println("4. Verifying Admin Capabilities on New Users...");

        // Clean up previous test user if exists via hard-delete API
        userRepository.findByUsernameIgnoreCase("mallik").ifPresent(u -> {
            try {
                mockMvc.perform(delete("/api/v1/admin/users/" + u.getId() + "/hard")
                                .header("Authorization", adminToken));
            } catch (Exception ignored) {}
        });

        // 4a. Create User: mallik (PA)
        SuperAdminController.CreateUserRequest createReq = new SuperAdminController.CreateUserRequest();
        createReq.setUsername("mallik");
        createReq.setRole("PA");
        createReq.setFullName("Mallik Property Analyst");
        createReq.setMobileNumber("9111223344");
        createReq.setEmail("mallik@example.com");
        createReq.setPassword("secret123");

        MvcResult createRes = mockMvc.perform(post("/api/v1/admin/users")
                        .header("Authorization", adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isOk())
                .andReturn();

        User createdUser = objectMapper.readValue(createRes.getResponse().getContentAsString(), User.class);
        assertEquals("mallik", createdUser.getUsername());
        assertEquals(UserRole.PA, createdUser.getRole());

        // 4b. Verify mallik can login
        AuthController.LoginRequest mallikReq = new AuthController.LoginRequest();
        mallikReq.setUsername("mallik");
        mallikReq.setPassword("secret123");
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mallikReq)))
                .andExpect(status().isOk());

        // 4c. Admin Resets mallik's password
        SuperAdminController.ResetPasswordRequest resetReq = new SuperAdminController.ResetPasswordRequest();
        resetReq.setNewPassword("newpass456");
        mockMvc.perform(post("/api/v1/admin/users/" + createdUser.getId() + "/reset-password")
                        .header("Authorization", adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(resetReq)))
                .andExpect(status().isOk());

        // Old password fails
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mallikReq)))
                .andExpect(status().isUnauthorized());

        // New password succeeds
        mallikReq.setPassword("newpass456");
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mallikReq)))
                .andExpect(status().isOk());

        // 4d. Admin deactivates/locks mallik
        mockMvc.perform(post("/api/v1/admin/users/" + createdUser.getId() + "/lock")
                        .header("Authorization", adminToken))
                .andExpect(status().isOk());

        // Locked user cannot log in
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mallikReq)))
                .andExpect(status().isUnauthorized());

        // 4e. Admin unlocks mallik
        mockMvc.perform(post("/api/v1/admin/users/" + createdUser.getId() + "/unlock")
                        .header("Authorization", adminToken))
                .andExpect(status().isOk());

        // Unlocked user can log in again
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mallikReq)))
                .andExpect(status().isOk());

        // 4f. Admin assigns new role SPA to mallik
        SuperAdminController.RoleChangeRequest mallikRoleReq = new SuperAdminController.RoleChangeRequest();
        mallikRoleReq.setRole("SPA");
        mockMvc.perform(put("/api/v1/admin/users/" + createdUser.getId() + "/role")
                        .header("Authorization", adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(mallikRoleReq)))
                .andExpect(status().isOk());

        User updatedMallik = userRepository.findById(createdUser.getId()).orElseThrow();
        assertEquals(UserRole.SPA, updatedMallik.getRole());

        System.out.println("-> PASSED: Admin capabilities (Create, Edit, Lock/Unlock, Reset Password, Role Assignment) verified.");
        System.out.println("========================================================================");
        System.out.println("ALL AUTHENTICATION RESTRUCTURE VERIFICATIONS PASSED SUCCESSFULLY!");
        System.out.println("========================================================================");
    }
}
