package com.provaluer.service;

import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.model.UserSession;
import com.provaluer.repository.UserSessionRepository;
import com.provaluer.repository.WorkspaceSessionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class AuthSessionServiceTest {

    @Mock
    private UserSessionRepository userSessionRepository;

    @Mock
    private WorkspaceSessionRepository workspaceSessionRepository;

    @Mock
    private RealtimePushService realtimePushService;

    @Mock
    private AuditLogService auditLogService;

    @InjectMocks
    private AuthSessionService authSessionService;

    private User testUser;
    private UserSession activeSession;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setId(101L);
        testUser.setUsername("testvaluer");
        testUser.setEmail("valuer@provaluer.com");
        testUser.setRole(UserRole.PA);

        activeSession = new UserSession(
                testUser,
                "sess-existing-123",
                AuthSessionService.hashToken("jwt-123"),
                AuthSessionService.hashToken("refresh-123"),
                "Google Chrome - Windows",
                "Desktop",
                "Mumbai, India",
                "192.168.1.10"
        );
    }

    @Test
    @DisplayName("HashToken should produce deterministic SHA-256 hex string")
    void testHashToken() {
        String token = "sample-jwt-token-string";
        String hash1 = AuthSessionService.hashToken(token);
        String hash2 = AuthSessionService.hashToken(token);

        assertNotNull(hash1);
        assertEquals(64, hash1.length());
        assertEquals(hash1, hash2);
        assertNotEquals(token, hash1);
    }

    @Test
    @DisplayName("GetActiveSession returns existing active session")
    void testGetActiveSession() {
        when(userSessionRepository.findAllByUserIdAndIsActiveTrue(101L)).thenReturn(List.of(activeSession));

        Optional<UserSession> result = authSessionService.getActiveSession(101L);

        assertTrue(result.isPresent());
        assertEquals("sess-existing-123", result.get().getSessionId());
    }

    @Test
    @DisplayName("Create and activate session should terminate previous active sessions")
    void testCreateAndActivateSession() {
        when(userSessionRepository.findAllByUserIdAndIsActiveTrue(101L)).thenReturn(List.of(activeSession));
        when(userSessionRepository.save(any(UserSession.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UserSession newSession = authSessionService.createAndActivateSession(
                testUser,
                "sess-new-789",
                "jwt-token-new",
                "refresh-token-new",
                "Safari - iPad",
                "Tablet",
                "Bengaluru, India",
                "10.0.0.5"
        );

        assertNotNull(newSession);
        assertEquals("sess-new-789", newSession.getSessionId());
        assertTrue(newSession.getIsActive());

        // Verify old session was evicted
        assertFalse(activeSession.getIsActive());
        assertEquals("NEW_DEVICE_ACTIVATION", activeSession.getTerminationReason());
        verify(workspaceSessionRepository, times(1)).releaseAllActiveLeases(eq(101L), eq("sess-existing-123"));
    }

    @Test
    @DisplayName("User explicit logout should mark session inactive and cascade release leases")
    void testLogout() {
        when(userSessionRepository.findBySessionId("sess-existing-123")).thenReturn(Optional.of(activeSession));

        authSessionService.logout("sess-existing-123");

        assertFalse(activeSession.getIsActive());
        assertEquals("USER_LOGOUT", activeSession.getTerminationReason());
        assertNotNull(activeSession.getTerminatedAt());

        verify(workspaceSessionRepository, times(1)).releaseAllActiveLeases(eq(101L), eq("sess-existing-123"));
        verify(realtimePushService, times(1)).removeEmitter(eq("sess-existing-123"));
    }
}

