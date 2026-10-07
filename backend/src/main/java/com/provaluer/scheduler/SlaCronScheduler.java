package com.provaluer.scheduler;

import com.provaluer.model.Order;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.PerformanceLedgerRepository;
import com.provaluer.service.SlaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Component
public class SlaCronScheduler {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private PerformanceLedgerRepository performanceLedgerRepository;

    @Autowired
    private SlaService slaService;

    /**
     * Executes every minute to sweep active analyst sessions and SLA deadlines.
     */
    @Scheduled(fixedRate = 60000)
    @Transactional
    public void checkAnalystSessionLocks() {
        LocalDateTime now = LocalDateTime.now();
        List<Order> activeOrders = orderRepository.findAllByStatusIn(
                List.of("ASSIGNED", "WORKSPACE_READY", "DRAFTING", "ACTION_NEEDED")
        );

        for (Order order : activeOrders) {
            String status = order.getStatus();

            // Escalation check for orders in ACTION_NEEDED
            if ("ACTION_NEEDED".equalsIgnoreCase(status)) {
                if (order.getSlaExpiryTime() != null && now.isAfter(order.getSlaExpiryTime())) {
                    if (order.getPauseReason() == null || !order.getPauseReason().contains("Escalated to Super Admin")) {
                        order.setPauseReason("Critical SLA timeout in ACTION_NEEDED. Escalated to Super Admin.");
                        order.setUpdatedAt(now);
                        orderRepository.save(order);
                    }
                }
                continue;
            }

            LocalDateTime referenceTime = order.getClaimedAt() != null
                    ? order.getClaimedAt()
                    : (order.getUpdatedAt() != null ? order.getUpdatedAt() : order.getCreatedAt());

            if (referenceTime == null) continue;

            // Calculate business hours elapsed since the file was claimed/updated
            double businessHoursElapsed = slaService.getRemainingBusinessHours(referenceTime, now);

            if (businessHoursElapsed >= 6.0) {
                // Check active heartbeat telemetry (within last 45 seconds to accommodate 30s intervals)
                boolean isUserActive = order.getLastHeartbeat() != null &&
                        order.getLastHeartbeat().isAfter(now.minusSeconds(45));

                if (isUserActive) {
                    // Extend the session by pushing claimed_at forward to maintain lock
                    order.setClaimedAt(now.minusMinutes(330)); // Resets elapsed to 5.5 hours to check again in 30 mins
                    orderRepository.save(order);
                } else {
                    // Session expired due to inactivity -> perform state-specific recovery
                    Long expiredPaId = order.getPaId();

                    if ("ASSIGNED".equalsIgnoreCase(status) || "WORKSPACE_READY".equalsIgnoreCase(status)) {
                        // ASSIGNED or WORKSPACE_READY -> PAID_INTAKE (recycle file to global pool)
                        order.setPaId(null);
                        order.setClaimedAt(null);
                        order.setLastHeartbeat(null);
                        order.setStatus("PAID_INTAKE");
                        order.setPauseReason("Analyst abandoned session in " + status + ". Recycled to pool.");
                        order.setUpdatedAt(now);
                        orderRepository.save(order);
                    } else if ("DRAFTING".equalsIgnoreCase(status)) {
                        // DRAFTING -> ACTION_NEEDED (authored work preserved 100%, awaiting reassignment)
                        order.setPrePauseStatus("DRAFTING");
                        order.setPaused(true);
                        order.setStatus("ACTION_NEEDED");
                        order.setPauseReason("Analyst abandoned drafting session. Authored work preserved; awaiting reassignment.");
                        order.setUpdatedAt(now);
                        orderRepository.save(order);
                    }

                    // Update PA performance logs if PA was assigned
                    if (expiredPaId != null) {
                        performanceLedgerRepository.findById(expiredPaId).ifPresent(ledger -> {
                            ledger.setActiveAllocations(Math.max(0, ledger.getActiveAllocations() - 1));
                            ledger.setSlaTimeouts(ledger.getSlaTimeouts() + 1);
                            performanceLedgerRepository.save(ledger);
                        });
                    }
                }
            }
        }
    }
}
