package com.provaluer.scheduler;

import com.provaluer.controller.SuperAdminController;
import com.provaluer.model.Order;
import com.provaluer.model.PerformanceLedger;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.PerformanceLedgerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.springframework.security.test.context.support.WithMockUser;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
@WithMockUser(username = "superadmin@provaluer.com", roles = {"SUPER_ADMIN"})
public class SlaCronSchedulerAbandonmentRecoveryTest {

    @Autowired
    private SlaCronScheduler slaCronScheduler;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private PerformanceLedgerRepository performanceLedgerRepository;

    @Autowired
    private SuperAdminController superAdminController;

    private Long testPaId = 888L;
    private Long newPaId = 999L;

    @BeforeEach
    void setup() {
        PerformanceLedger ledger = new PerformanceLedger();
        ledger.setEmployeeId(testPaId);
        ledger.setActiveAllocations(2);
        ledger.setSlaTimeouts(0);
        ledger.setFilesCompleted(5);
        performanceLedgerRepository.save(ledger);

        PerformanceLedger newLedger = new PerformanceLedger();
        newLedger.setEmployeeId(newPaId);
        newLedger.setActiveAllocations(0);
        newLedger.setSlaTimeouts(0);
        newLedger.setFilesCompleted(2);
        performanceLedgerRepository.save(newLedger);
    }

    private Order createTestOrder(String status, LocalDateTime claimedAt, LocalDateTime lastHeartbeat) {
        Order order = new Order();
        order.setClientId(1L);
        order.setPurpose("Visa");
        order.setPropertyCategory("Commercial");
        order.setStatus(status);
        order.setPaId(testPaId);
        order.setClaimedAt(claimedAt);
        order.setLastHeartbeat(lastHeartbeat);
        order.setEstimatedValue(BigDecimal.valueOf(1000000));
        order.setFeeCharged(BigDecimal.valueOf(5000));
        order.setCreatedAt(claimedAt != null ? claimedAt : LocalDateTime.now());
        order.setUpdatedAt(claimedAt != null ? claimedAt : LocalDateTime.now());
        return orderRepository.save(order);
    }

    @Test
    @DisplayName("Scenario A: ASSIGNED + No activity -> Recovers to PAID_INTAKE in common pool")
    @Transactional
    public void testScenarioA_AssignedNoActivity_RecoversToPaidIntake() {
        LocalDateTime now = LocalDateTime.now();
        // Claimed 2 days ago, stale heartbeat 2 hours ago (>45s)
        Order order = createTestOrder("ASSIGNED", now.minusDays(2), now.minusHours(2));

        slaCronScheduler.checkAnalystSessionLocks();

        Order recovered = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("PAID_INTAKE", recovered.getStatus(), "Abandoned ASSIGNED order must return to PAID_INTAKE");
        assertNull(recovered.getPaId(), "paId must be cleared so any analyst can claim it");
        assertNull(recovered.getClaimedAt(), "claimedAt must be cleared");
        assertNull(recovered.getLastHeartbeat(), "lastHeartbeat must be cleared");
        assertNotNull(recovered.getPauseReason());
        assertTrue(recovered.getPauseReason().contains("Recycled to pool"));

        // Verify ledger penalty
        PerformanceLedger ledger = performanceLedgerRepository.findById(testPaId).orElseThrow();
        assertEquals(1, ledger.getActiveAllocations());
        assertEquals(1, ledger.getSlaTimeouts());
    }

    @Test
    @DisplayName("Scenario B: WORKSPACE_READY + Browser closed -> Recovers to PAID_INTAKE in common pool")
    @Transactional
    public void testScenarioB_WorkspaceReadyBrowserClosed_RecoversToPaidIntake() {
        LocalDateTime now = LocalDateTime.now();
        // Claimed 1 day ago, analyst opened workspace but closed browser -> lastHeartbeat stale
        Order order = createTestOrder("WORKSPACE_READY", now.minusDays(1), now.minusHours(1));

        slaCronScheduler.checkAnalystSessionLocks();

        Order recovered = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("PAID_INTAKE", recovered.getStatus(), "Abandoned WORKSPACE_READY order must return to PAID_INTAKE");
        assertNull(recovered.getPaId(), "paId must be null to allow re-claiming");
        assertNull(recovered.getClaimedAt());
        assertNull(recovered.getLastHeartbeat());
        assertTrue(recovered.getPauseReason().contains("WORKSPACE_READY"));
    }

    @Test
    @DisplayName("Scenario C: DRAFTING + No heartbeat 7 days -> Preserves authored data and transitions to ACTION_NEEDED")
    @Transactional
    public void testScenarioC_DraftingNoHeartbeat7Days_PreservesAuthoredDataAndTransitionsToActionNeeded() {
        LocalDateTime now = LocalDateTime.now();
        Order order = createTestOrder("DRAFTING", now.minusDays(7), now.minusDays(7));
        
        // Populate critical authored data
        String testInputs = "{\"fair_market_value\":8500000,\"land_rate\":4500,\"builtup_area\":1800}";
        String testDom = "{\"dom\":\"<div class='valuation-grid'>Calculations intact</div>\"}";
        order.setInputValues(testInputs);
        order.setDocumentDomSnapshot(testDom);
        order = orderRepository.save(order);

        slaCronScheduler.checkAnalystSessionLocks();

        Order recovered = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("ACTION_NEEDED", recovered.getStatus(), "Abandoned DRAFTING order must transition to ACTION_NEEDED");
        assertTrue(recovered.isPaused(), "Order must be flagged as paused");
        
        // DATA PROTECTION VERIFICATION (FIX 7): Under no circumstance delete workspace data
        assertEquals(testInputs, recovered.getInputValues(), "CRITICAL: Authored inputs must NEVER be deleted upon recovery");
        assertEquals(testDom, recovered.getDocumentDomSnapshot(), "CRITICAL: Document DOM snapshot must NEVER be deleted upon recovery");
        assertTrue(recovered.getPauseReason().contains("Authored work preserved"));
    }

    @Test
    @DisplayName("Scenario D: Admin can reassign abandoned order without SQL and restore to active drafting")
    @Transactional
    public void testScenarioD_AdminReassignsStaleOrderWithoutSql() {
        LocalDateTime now = LocalDateTime.now();
        Order order = createTestOrder("ACTION_NEEDED", now.minusDays(3), now.minusDays(3));
        order.setInputValues("{\"property_type\":\"Commercial\",\"value\":12000000}");
        order = orderRepository.save(order);

        // Admin reassigns via API
        SuperAdminController.ReassignRequest req = new SuperAdminController.ReassignRequest();
        req.setNewPaId(newPaId);

        superAdminController.reassignOrder(order.getId(), req);

        Order reassigned = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals(newPaId, reassigned.getPaId(), "New PA must be assigned to order");
        assertEquals("DRAFTING", reassigned.getStatus(), "Order with existing authored work must resume in DRAFTING");
        assertFalse(reassigned.isPaused(), "Paused state must be cleared upon reassignment");
        assertNotNull(reassigned.getLastHeartbeat(), "Telemetry heartbeat must be refreshed");
        assertEquals("{\"property_type\":\"Commercial\",\"value\":12000000}", reassigned.getInputValues(), "Authored work preserved");
    }

    @Test
    @DisplayName("Heartbeat Governance: Active heartbeat extends session lock and avoids recovery")
    @Transactional
    public void testHeartbeatGovernance_ActiveHeartbeatExtendsSession() {
        LocalDateTime now = LocalDateTime.now();
        // Claimed 8 business hours ago, but analyst is actively heartbeating (10s ago)
        Order order = createTestOrder("WORKSPACE_READY", now.minusHours(8), now.minusSeconds(10));

        slaCronScheduler.checkAnalystSessionLocks();

        Order activeOrder = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("WORKSPACE_READY", activeOrder.getStatus(), "Active analyst session must NOT be terminated");
        assertEquals(testPaId, activeOrder.getPaId(), "Ownership must NOT be revoked while heartbeating actively");
    }

    @Test
    @DisplayName("Escalation Visibility: ACTION_NEEDED order with breached SLA triggers escalation event")
    @Transactional
    public void testActionNeededEscalationVisibility() {
        LocalDateTime now = LocalDateTime.now();
        Order order = createTestOrder("ACTION_NEEDED", now.minusDays(5), null);
        order.setSlaExpiryTime(now.minusHours(2)); // Breached SLA
        order = orderRepository.save(order);

        slaCronScheduler.checkAnalystSessionLocks();

        Order escalated = orderRepository.findById(order.getId()).orElseThrow();
        assertNotNull(escalated.getPauseReason());
        assertTrue(escalated.getPauseReason().contains("Escalated to Super Admin"), "Must set escalation note for dashboard visibility");
    }

    @Test
    @DisplayName("Admin Force Recovery Endpoint: Recovers WORKSPACE_READY and DRAFTING states safely")
    @Transactional
    public void testAdminForceRecoveryEndpoint() {
        LocalDateTime now = LocalDateTime.now();
        Order order1 = createTestOrder("WORKSPACE_READY", now.minusHours(1), null);
        superAdminController.forceRecovery(order1.getId());
        Order rec1 = orderRepository.findById(order1.getId()).orElseThrow();
        assertEquals("PAID_INTAKE", rec1.getStatus());
        assertNull(rec1.getPaId());

        Order order2 = createTestOrder("DRAFTING", now.minusHours(1), null);
        order2.setInputValues("{\"draft\":\"data\"}");
        order2 = orderRepository.save(order2);
        superAdminController.forceRecovery(order2.getId());
        Order rec2 = orderRepository.findById(order2.getId()).orElseThrow();
        assertEquals("ACTION_NEEDED", rec2.getStatus());
        assertEquals("{\"draft\":\"data\"}", rec2.getInputValues());
    }
}
