package com.provaluer.service;

import com.provaluer.dto.SaveDocumentValuesRequest;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class DocumentWorkspaceEnterpriseServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private OrderInputRepository orderInputRepository;

    @Mock
    private TemplateRepository templateRepository;

    @Mock
    private AuditLogRepository auditLogRepository;

    @Mock
    private PerformanceLedgerRepository performanceLedgerRepository;

    @Mock
    private OrderRevisionHistoryRepository orderRevisionHistoryRepository;

    @Mock
    private WorkspaceSessionRepository workspaceSessionRepository;

    @Mock
    private RealtimePushService realtimePushService;

    @Mock
    private PricingService pricingService;

    @Mock
    private AuditLogService auditLogService;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private DocumentWorkspaceService documentWorkspaceService;

    private User primaryUser;
    private User secondaryUser;
    private UserDetailsImpl primaryPrincipal;
    private UserDetailsImpl secondaryPrincipal;
    private Order order;
    private WorkspaceSession activeLease;

    @BeforeEach
    void setUp() {
        primaryUser = new User();
        primaryUser.setId(101L);
        primaryUser.setUsername("primary_valuer");
        primaryUser.setEmail("valuer@provaluer.com");
        primaryUser.setRole(UserRole.PA);
        primaryPrincipal = UserDetailsImpl.build(primaryUser);

        secondaryUser = new User();
        secondaryUser.setId(102L);
        secondaryUser.setUsername("secondary_spa");
        secondaryUser.setEmail("spa@provaluer.com");
        secondaryUser.setRole(UserRole.SPA);
        secondaryPrincipal = UserDetailsImpl.build(secondaryUser);

        order = new Order();
        order.setId(6001L);
        order.setPaId(101L);
        order.setStatus("ASSIGNED");
        order.setWorkspaceRevision(3);
        order.setDocumentDomSnapshot("{\"type\":\"doc\",\"content\":[]}");

        activeLease = new WorkspaceSession(
                order,
                primaryUser,
                "sess-101",
                "tab-101-a",
                "Machine-1",
                "Desktop",
                "192.168.1.10"
        );
    }

    @Test
    @DisplayName("Save with active lease: increments statutory revision, creates immutable history, and saves")
    void testSaveDocumentValues_SuccessWithLease() {
        when(orderRepository.findById(6001L)).thenReturn(Optional.of(order));
        when(workspaceSessionRepository.findByOrderId(6001L)).thenReturn(Optional.of(activeLease));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArgument(0));
        when(userRepository.findById(101L)).thenReturn(Optional.of(primaryUser));

        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        req.setValues(Map.of("PROPERTY_ADDRESS", "123 MG Road"));
        req.setWorkspaceRevision(3);
        req.setSessionId("sess-101");
        req.setTabSessionId("tab-101-a");

        Map<String, String> result = documentWorkspaceService.saveDocumentValues(6001L, req, primaryPrincipal);

        assertNotNull(result);
        // Verify statutory monotonic revision increment
        assertEquals(4, order.getWorkspaceRevision());
        assertNotNull(order.getUpdatedAt());

        // Verify statutory audit snapshot was created in order_revision_history
        verify(orderRevisionHistoryRepository, times(1)).save(argThat(h ->
                h.getOrder().getId().equals(6001L) &&
                h.getRevisionNumber() == 4 &&
                "primary_valuer".equals(h.getSavedByUsername())
        ));

        // Verify lease activity was touched
        verify(workspaceSessionRepository, times(1)).touchActivity(eq(6001L), eq("sess-101"));

        // Verify Order was saved
        verify(orderRepository, atLeastOnce()).save(order);
    }

    @Test
    @DisplayName("Save by secondary user when order is locked by primary: throws 403 Forbidden without modifying Order")
    void testSaveDocumentValues_UnauthorizedSecondaryViewerRejected() {
        when(orderRepository.findById(6001L)).thenReturn(Optional.of(order));
        when(workspaceSessionRepository.findByOrderId(6001L)).thenReturn(Optional.of(activeLease));

        SaveDocumentValuesRequest req = new SaveDocumentValuesRequest();
        req.setValues(Map.of("PROPERTY_ADDRESS", "Tampered Address"));
        req.setSessionId("sess-102");
        req.setTabSessionId("tab-102-a");

        ResponseStatusException ex = assertThrows(ResponseStatusException.class, () ->
                documentWorkspaceService.saveDocumentValues(6001L, req, secondaryPrincipal)
        );

        assertEquals(403, ex.getStatusCode().value());
        String reason = ex.getReason();
        assertNotNull(reason);
        assertTrue(reason.contains("Read-Only mode: Order is currently locked"));

        // Verify Order was NEVER modified or saved
        verify(orderRepository, never()).save(any(Order.class));
        verify(orderRevisionHistoryRepository, never()).save(any(OrderRevisionHistory.class));
    }
}
