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
        List<Order> assignedOrders = orderRepository.findAllByStatus("ASSIGNED");

        for (Order order : assignedOrders) {
            if (order.getPaId() == null || order.getClaimedAt() == null) continue;

            // Calculate business hours elapsed since the file was claimed
            double businessHoursElapsed = slaService.getRemainingBusinessHours(order.getClaimedAt(), now);

            if (businessHoursElapsed >= 6.0) {
                // Check active heartbeat telemetry (within last 45 seconds to accommodate 30s intervals)
                boolean isUserActive = order.getLastHeartbeat() != null &&
                        order.getLastHeartbeat().isAfter(now.minusSeconds(45));

                if (isUserActive) {
                    // Extend the session by pushing claimed_at forward to maintain lock
                    order.setClaimedAt(now.minusMinutes(330)); // Resets elapsed to 5.5 hours to check again in 30 mins
                    orderRepository.save(order);
                } else {
                    // Session expired due to inactivity -> recycle file to global pool
                    Long expiredPaId = order.getPaId();
                    order.setPaId(null);
                    order.setClaimedAt(null);
                    order.setLastHeartbeat(null);
                    order.setStatus("PAID_INTAKE");
                    orderRepository.save(order);

                    // Update PA performance logs
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
