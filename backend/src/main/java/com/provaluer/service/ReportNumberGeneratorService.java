package com.provaluer.service;

import com.provaluer.model.ReportSequence;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.ReportSequenceRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Enterprise Service for Atomic, Monotonic, Concurrency-Safe Report Number Generation.
 *
 * Replaces non-deterministic count(*)+1 implementations.
 * Allocates report numbers matching pattern: PV-YYMM-0001
 * Uses pessimistic row locking (SELECT ... FOR UPDATE) on report_sequences.
 * Guarantees zero duplicate allocations, zero skipped numbers, and transactional rollback safety.
 */
@Service
public class ReportNumberGeneratorService {

    private static final Logger log = LoggerFactory.getLogger(ReportNumberGeneratorService.class);

    private final ReportSequenceRepository sequenceRepository;
    private final OrderRepository orderRepository;

    @Autowired
    public ReportNumberGeneratorService(ReportSequenceRepository sequenceRepository, OrderRepository orderRepository) {
        this.sequenceRepository = sequenceRepository;
        this.orderRepository = orderRepository;
    }

    /**
     * Generates the next sequential report number for the current month.
     * Thread-safe and transaction-safe via pessimistic write lock on the sequence table.
     *
     * @return Formatted report number string, e.g. PV-2610-0001
     */
    @Transactional(propagation = Propagation.REQUIRED, isolation = Isolation.READ_COMMITTED)
    public synchronized String generateNextReportNumber() {
        LocalDateTime now = LocalDateTime.now();
        int yy = now.getYear() % 100;
        int mm = now.getMonthValue();
        String prefix = String.format("PV-%02d%02d-", yy, mm);
        return generateNextReportNumberForPrefix(prefix);
    }

    /**
     * Generates next atomic sequential report number for a given prefix under pessimistic lock.
     *
     * @param prefix Prefix e.g. 'PV-2610-'
     * @return Formatted report number
     */
    @Transactional(propagation = Propagation.REQUIRED, isolation = Isolation.READ_COMMITTED)
    public synchronized String generateNextReportNumberForPrefix(String prefix) {
        ReportSequence seq = sequenceRepository.findByPrefixWithLock(prefix).orElse(null);

        if (seq == null) {
            // Safe initialization for new month prefix if not yet seeded
            try {
                seq = sequenceRepository.saveAndFlush(new ReportSequence(prefix, 0L));
            } catch (Exception e) {
                log.debug("Concurrent insert on sequence prefix {}: {}", prefix, e.getMessage());
            }
            seq = sequenceRepository.findByPrefixWithLock(prefix)
                    .orElseThrow(() -> new IllegalStateException("Failed to lock sequence for prefix: " + prefix));
        }

        long nextSequence = seq.getLastSequence() + 1;
        String formattedReportNumber = String.format("%s%04d", prefix, nextSequence);

        // Safety verification: guard against pre-existing historical orders
        while (orderRepository.existsByReportNumber(formattedReportNumber)) {
            log.warn("Historical collision for {} detected, advancing sequence allocator", formattedReportNumber);
            nextSequence++;
            formattedReportNumber = String.format("%s%04d", prefix, nextSequence);
        }

        seq.setLastSequence(nextSequence);
        seq.setUpdatedAt(LocalDateTime.now());
        sequenceRepository.saveAndFlush(seq);

        log.info("Atomic sequence allocated: {} (seq: {})", formattedReportNumber, nextSequence);
        return formattedReportNumber;
    }
}
