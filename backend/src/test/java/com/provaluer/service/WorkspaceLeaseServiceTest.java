package com.provaluer.service;

import com.provaluer.model.Order;
import com.provaluer.model.User;
import com.provaluer.model.UserRole;
import com.provaluer.model.WorkspaceLeaseAudit;
import com.provaluer.model.WorkspaceSession;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.repository.WorkspaceLeaseAuditRepository;
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
import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class WorkspaceLeaseServiceTest {

    @Mock
    private WorkspaceSessionRepository workspaceSessionRepository;

    @Mock
    private WorkspaceLeaseAuditRepository leaseAuditRepository;

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private RealtimePushService realtimePushService;

    @InjectMocks
    private WorkspaceLeaseService workspaceLeaseService;

    private User primaryUser;
    private User secondaryUser;
    private User superAdminUser;
    private Order order;
    private WorkspaceSession existingLease;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(workspaceLeaseService, "leaseTtlSeconds", 300);
        ReflectionTestUtils.setField(workspaceLeaseService, "takeoverAutosaveDeadlineMs", 200L);

        primaryUser = new User();
        primaryUser.setId(101L);
        primaryUser.setUsername("primary_valuer");
        primaryUser.setRole(UserRole.PA);

        secondaryUser = new User();
        secondaryUser.setId(102L);
        secondaryUser.setUsername("secondary_viewer");
        secondaryUser.setRole(UserRole.PA);

        superAdminUser = new User();
        superAdminUser.setId(999L);
        superAdminUser.setUsername("superadmin");
        superAdminUser.setRole(UserRole.SUPER_ADMIN);

        order = new Order();
        order.setId(5001L);
        order.setStatus("ASSIGNED");
        order.setWorkspaceRevision(5);

        existingLease = new WorkspaceSession(
                order,
                primaryUser,
                "sess-user-1",
                "tab-user-1-a",
                "Machine-1",
                "Chrome Desktop",
                "192.168.1.10"
        );
        existingLease.setLastHeartbeat(LocalDateTime.now());
        existingLease.setLastActivity(LocalDateTime.now());
    }

    @Test
    @DisplayName("Acquire lease on open order should grant ACTIVE_EDITOR role with 300s TTL")
    void testAcquireLock_New() {
        when(orderRepository.findById(5001L)).thenReturn(Optional.of(order));
        when(userRepository.findById(101L)).thenReturn(Optional.of(primaryUser));
        when(workspaceSessionRepository.findByOrderId(5001L)).thenReturn(Optional.empty());
        when(workspaceSessionRepository.save(any(WorkspaceSession.class))).thenAnswer(i -> i.getArgument(0));

        Map<String, Object> result = workspaceLeaseService.acquireLock(
                5001L, 101L, "sess-user-1", "tab-user-1-a", "Machine-1", "Desktop", "192.168.1.10"
        );

        assertNotNull(result);
        assertEquals("ACTIVE_EDITOR", result.get("role"));
        assertEquals(300, result.get("leaseTtlSeconds"));
        assertEquals("sess-user-1", result.get("sessionId"));
        assertEquals("tab-user-1-a", result.get("tabSessionId"));

        verify(workspaceSessionRepository, times(1)).save(any(WorkspaceSession.class));
        verify(leaseAuditRepository, times(1)).save(any(WorkspaceLeaseAudit.class));
    }

    @Test
    @DisplayName("Secondary user accessing active report should get READ_ONLY_VIEWER role (Rule 2)")
    void testAcquireLock_SecondaryViewerReadOnly() {
        when(orderRepository.findById(5001L)).thenReturn(Optional.of(order));
        when(userRepository.findById(102L)).thenReturn(Optional.of(secondaryUser));
        when(workspaceSessionRepository.findByOrderId(5001L)).thenReturn(Optional.of(existingLease));

        Map<String, Object> result = workspaceLeaseService.acquireLock(
                5001L, 102L, "sess-user-2", "tab-user-2-a", "Machine-2", "Desktop", "192.168.1.20"
        );

        assertNotNull(result);
        assertEquals("READ_ONLY_VIEWER", result.get("role"));
        assertNotNull(result.get("activeEditor"));
    }

    @Test
    @DisplayName("Expired lease (> 300s without heartbeat) should be evicted and reacquired cleanly")
    void testAcquireLock_ExpiredLeaseEviction() {
        existingLease.setLastHeartbeat(LocalDateTime.now().minusSeconds(350)); // Expired > 300s
        when(orderRepository.findById(5001L)).thenReturn(Optional.of(order));
        when(userRepository.findById(102L)).thenReturn(Optional.of(secondaryUser));
        when(workspaceSessionRepository.findByOrderId(5001L)).thenReturn(Optional.of(existingLease));
        when(workspaceSessionRepository.save(any(WorkspaceSession.class))).thenAnswer(i -> i.getArgument(0));

        Map<String, Object> result = workspaceLeaseService.acquireLock(
                5001L, 102L, "sess-user-2", "tab-user-2-a", "Machine-2", "Desktop", "192.168.1.20"
        );

        assertEquals("ACTIVE_EDITOR", result.get("role"));
        assertEquals("sess-user-2", result.get("sessionId"));
    }

    @Test
    @DisplayName("Same user opening new tab should prompt SAME_USER_SECONDARY_TAB")
    void testAcquireLock_SameUserNewTab() {
        when(orderRepository.findById(5001L)).thenReturn(Optional.of(order));
        when(userRepository.findById(101L)).thenReturn(Optional.of(primaryUser));
        when(workspaceSessionRepository.findByOrderId(5001L)).thenReturn(Optional.of(existingLease));

        Map<String, Object> result = workspaceLeaseService.acquireLock(
                5001L, 101L, "sess-user-1", "tab-user-1-b", "Machine-1", "Desktop", "192.168.1.10"
        );

        assertEquals("SAME_USER_SECONDARY_TAB", result.get("role"));
        assertEquals("tab-user-1-a", result.get("activeTabSessionId"));
        assertTrue((Boolean) result.get("canSwitchTab"));
    }

    @Test
    @DisplayName("Switch active tab should transfer lease to new tab and notify old tab via SSE")
    void testSwitchTab() {
        when(workspaceSessionRepository.findByOrderId(5001L)).thenReturn(Optional.of(existingLease));
        when(workspaceSessionRepository.switchTabSession(5001L, 101L, "tab-user-1-b")).thenReturn(1);

        Map<String, Object> result = workspaceLeaseService.switchTab(
                5001L, 101L, "sess-user-1", "tab-user-1-b"
        );

        assertEquals("TAB_SWITCHED", result.get("status"));
        assertEquals("ACTIVE_EDITOR", result.get("role"));
        assertEquals("tab-user-1-b", result.get("tabSessionId"));

        // Verify notification was sent to old tab
        verify(realtimePushService, times(1)).broadcastLeaseLost(eq("sess-user-1"), eq(5001L), eq("TAB_SWITCH"), any());
    }

    @Test
    @DisplayName("Isolated Heartbeat: Updates ONLY workspace_sessions without touching Order entity")
    void testRenewHeartbeat_Isolated() {
        when(workspaceSessionRepository.renewHeartbeat(5001L, "sess-user-1")).thenReturn(1);

        Map<String, Object> result = workspaceLeaseService.renewHeartbeat(5001L, "sess-user-1");

        assertNotNull(result);
        assertEquals("ACTIVE", result.get("status"));
        assertNotNull(result.get("serverTime"));

        // Verify Order repository was NEVER touched
        verify(orderRepository, never()).save(any(Order.class));
        verify(orderRepository, never()).findById(anyLong());
        verify(workspaceSessionRepository, times(1)).renewHeartbeat(5001L, "sess-user-1");
    }

    @Test
    @DisplayName("Admin Takeover: Pushes SSE pre-flight forced autosave, terminates lease, and transfers to Admin")
    void testTakeoverLease() {
        when(userRepository.findById(999L)).thenReturn(Optional.of(superAdminUser));
        when(workspaceSessionRepository.findByOrderId(5001L)).thenReturn(Optional.of(existingLease));
        when(workspaceSessionRepository.takeoverLease(eq(5001L), eq(999L), eq("sess-admin-1"), eq("tab-admin-1"),
                anyString(), anyString(), anyString())).thenReturn(1);

        Map<String, Object> result = workspaceLeaseService.takeoverLease(
                5001L, 999L, "sess-admin-1", "tab-admin-1", "Admin-Machine", "Desktop", "127.0.0.1"
        );

        assertNotNull(result);
        assertEquals("TAKEOVER_SUCCESS", result.get("status"));
        assertEquals("ACTIVE_EDITOR", result.get("role"));
        assertEquals("sess-admin-1", result.get("sessionId"));

        // Verify forced autosave SSE broadcast was sent before lease transfer
        verify(realtimePushService, times(1)).broadcastForceAutosave(eq("sess-user-1"), eq(5001L), eq(200L), eq("superadmin"));
        verify(realtimePushService, times(1)).broadcastLeaseLost(eq("sess-user-1"), eq(5001L), eq("ADMIN_TAKEOVER"), eq("superadmin"));
        verify(leaseAuditRepository, times(1)).save(any(WorkspaceLeaseAudit.class));
    }

    @Test
    @DisplayName("Release lease sets status to RELEASED and cascades audit event")
    void testReleaseLock() {
        when(workspaceSessionRepository.releaseLease(5001L, "sess-user-1")).thenReturn(1);
        when(workspaceSessionRepository.findByOrderId(5001L)).thenReturn(Optional.of(existingLease));

        workspaceLeaseService.releaseLock(5001L, "sess-user-1");

        verify(workspaceSessionRepository, times(1)).releaseLease(5001L, "sess-user-1");
        verify(leaseAuditRepository, times(1)).save(any(WorkspaceLeaseAudit.class));
    }
}
