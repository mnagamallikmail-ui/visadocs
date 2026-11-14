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
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
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
        ReflectionTestUtils.setField(authSessionService, "sessionChallengeTimeoutSeconds", 30);

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
    @DisplayName("Initiate login challenge should set pending challenge and push SSE to Device A")
    void testInitiateLoginChallenge() {
        when(userSessionRepository.save(any(UserSession.class))).thenReturn(activeSession);

        Map<String, Object> challengeResult = authSessionService.initiateLoginChallenge(
                testUser,
                activeSession,
                "sess-new-456",
                "Mozilla Firefox - MacOS",
                "Desktop",
                "Delhi, India",
                "192.168.1.50"
        );

        assertNotNull(challengeResult);
        assertEquals("CHALLENGE_REQUIRED", challengeResult.get("status"));
        assertEquals("sess-existing-123", challengeResult.get("challengeSessionId"));
        assertEquals("Google Chrome - Windows", challengeResult.get("activeDevice"));
        assertEquals(30, challengeResult.get("expiresInSeconds"));

        // Verify SSE broadcast was dispatched to activeSession
        verify(realtimePushService, times(1)).broadcastLoginChallenge(eq("sess-existing-123"), anyMap());
        verify(userSessionRepository, times(1)).save(activeSession);
        assertEquals("PENDING_CHALLENGE", activeSession.getChallengeStatus());
        assertEquals("sess-new-456", activeSession.getChallengeTargetSession());
        assertNotNull(activeSession.getChallengeExpiry());
    }

    @Test
    @DisplayName("Respond to challenge: KEEP should reject new login and preserve active session")
    void testRespondToChallenge_Keep() {
        when(userSessionRepository.findBySessionId("sess-existing-123")).thenReturn(Optional.of(activeSession));
        when(userSessionRepository.save(any(UserSession.class))).thenReturn(activeSession);

        Map<String, Object> response = authSessionService.respondToChallenge("sess-existing-123", "KEEP", 101L);

        assertEquals("CHALLENGE_REJECTED", response.get("status"));
        assertEquals("CHALLENGE_REJECTED", activeSession.getChallengeStatus());
        assertNull(activeSession.getChallengeTargetSession());
        assertNull(activeSession.getChallengeExpiry());
        assertTrue(activeSession.getIsActive());
        verify(userSessionRepository, times(1)).save(activeSession);
    }

    @Test
    @DisplayName("Respond to challenge: ALLOW should evict Device A and cascade release workspace leases")
    void testRespondToChallenge_Allow() {
        when(userSessionRepository.findBySessionId("sess-existing-123")).thenReturn(Optional.of(activeSession));

        Map<String, Object> response = authSessionService.respondToChallenge("sess-existing-123", "ALLOW", 101L);

        assertEquals("SESSION_TRANSFERRED", response.get("status"));
        assertFalse(activeSession.getIsActive());
        assertEquals("USER_PERMITTED_NEW_DEVICE", activeSession.getTerminationReason());

        // Verify cascade workspace lease release and SSE eviction
        verify(workspaceSessionRepository, times(1)).releaseAllActiveLeases(eq(101L), eq("sess-existing-123"));
        verify(realtimePushService, times(1)).broadcastSessionEviction(eq("sess-existing-123"), anyMap());
        verify(realtimePushService, times(1)).removeEmitter(eq("sess-existing-123"));
    }

    @Test
    @DisplayName("Check challenge status should auto-evict on 30s timeout expiration")
    void testCheckChallengeStatus_TimeoutExpiry() {
        activeSession.setChallengeExpiry(LocalDateTime.now().minusSeconds(5)); // Expired 5 seconds ago
        when(userSessionRepository.findBySessionId("sess-existing-123")).thenReturn(Optional.of(activeSession));

        String status = authSessionService.checkChallengeStatus("sess-existing-123");

        assertEquals("APPROVED_BY_TIMEOUT", status);
        assertFalse(activeSession.getIsActive());
        assertEquals("CHALLENGE_TIMEOUT_EXPIRED", activeSession.getTerminationReason());
        verify(workspaceSessionRepository, times(1)).releaseAllActiveLeases(eq(101L), eq("sess-existing-123"));
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

