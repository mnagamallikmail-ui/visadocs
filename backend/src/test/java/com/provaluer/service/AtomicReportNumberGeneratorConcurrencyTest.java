package com.provaluer.service;

import com.provaluer.model.ReportSequence;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.ReportSequenceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class AtomicReportNumberGeneratorConcurrencyTest {

    @Autowired
    private ReportNumberGeneratorService generatorService;

    @Autowired
    private ReportSequenceRepository sequenceRepository;

    @Autowired
    OrderRepository orderRepository;

    @BeforeEach
    void setup() {
        sequenceRepository.deleteAll();
    }

    private void runConcurrencyTest(int threadCount, String prefix) throws InterruptedException, ExecutionException {
        // Initialize prefix sequence at 0
        sequenceRepository.saveAndFlush(new ReportSequence(prefix, 0L));

        ExecutorService executor = Executors.newFixedThreadPool(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);
        List<Future<String>> futures = new ArrayList<>();

        for (int i = 0; i < threadCount; i++) {
            futures.add(executor.submit(() -> {
                startLatch.await(); // ensure all threads fire concurrently
                return generatorService.generateNextReportNumberForPrefix(prefix);
            }));
        }

        startLatch.countDown(); // unblock all threads simultaneously

        List<String> results = new ArrayList<>();
        for (Future<String> future : futures) {
            results.add(future.get());
        }

        executor.shutdown();
        assertTrue(executor.awaitTermination(15, TimeUnit.SECONDS));

        // 1. Verify no duplicate report numbers
        Set<String> uniqueResults = new HashSet<>(results);
        assertEquals(threadCount, uniqueResults.size(),
                "Duplicate report numbers detected! Total results: " + results.size() + ", Unique: " + uniqueResults.size());

        // 2. Verify all numbers start with prefix and match format
        for (String repNo : results) {
            assertTrue(repNo.startsWith(prefix), "Report number does not start with prefix: " + repNo);
            assertTrue(repNo.matches("^" + prefix + "\\d{4}$"), "Report number does not match pattern: " + repNo);
        }

        // 3. Extract numeric sequence values and verify no skipped sequences / gaps
        List<Integer> sequences = results.stream()
                .map(s -> Integer.parseInt(s.substring(prefix.length())))
                .sorted()
                .collect(Collectors.toList());

        for (int i = 0; i < threadCount; i++) {
            int expectedSeq = i + 1;
            assertEquals(expectedSeq, sequences.get(i),
                    "Gap/skip detected! Expected sequence " + expectedSeq + " but found " + sequences.get(i));
        }

        // 4. Verify database sequence record matches threadCount
        ReportSequence finalSeq = sequenceRepository.findById(prefix).orElseThrow();
        assertEquals(threadCount, finalSeq.getLastSequence(),
                "Database final sequence counter does not match thread count");
    }

    @Test
    @DisplayName("Simulate 10 concurrent requests: No duplicates, no skipped allocations, no collisions")
    void test10ConcurrentRequests() throws Exception {
        runConcurrencyTest(10, "PV-TEST10-");
    }

    @Autowired
    private org.springframework.transaction.PlatformTransactionManager transactionManager;

    @Test
    @DisplayName("Simulate 25 concurrent requests: No duplicates, no skipped allocations, no collisions")
    void test25ConcurrentRequests() throws Exception {
        runConcurrencyTest(25, "PV-TEST25-");
    }

    @Test
    @DisplayName("Simulate 50 concurrent requests: No duplicates, no skipped allocations, no collisions")
    void test50ConcurrentRequests() throws Exception {
        runConcurrencyTest(50, "PV-TEST50-");
    }

    @Test
    @DisplayName("Rollback Safety: If transaction fails before commit, sequence allocation rolls back without gap")
    void testRollbackSafety() {
        String prefix = "PV-ROLLBACK-";
        sequenceRepository.saveAndFlush(new ReportSequence(prefix, 10L));

        org.springframework.transaction.support.TransactionTemplate txTemplate =
                new org.springframework.transaction.support.TransactionTemplate(transactionManager);

        // Transaction 1: Fails and rolls back
        assertThrows(RuntimeException.class, () -> {
            txTemplate.execute(status -> {
                String num = generatorService.generateNextReportNumberForPrefix(prefix);
                assertEquals("PV-ROLLBACK-0011", num);
                throw new RuntimeException("Simulated order submission failure before commit");
            });
        });

        // Verify database sequence was NOT incremented (rolled back to 10)
        ReportSequence seqAfterRollback = sequenceRepository.findById(prefix).orElseThrow();
        assertEquals(10L, seqAfterRollback.getLastSequence(),
                "Sequence counter should remain 10 after transaction rollback");

        // Transaction 2: Succeeds, safely allocates the exact sequence number without gap
        String nextNumber = txTemplate.execute(status -> generatorService.generateNextReportNumberForPrefix(prefix));
        assertEquals("PV-ROLLBACK-0011", nextNumber,
                "Subsequent transaction must re-acquire 0011 without leaving any gap");

        ReportSequence finalSeq = sequenceRepository.findById(prefix).orElseThrow();
        assertEquals(11L, finalSeq.getLastSequence());
    }

    @Test
    @DisplayName("Collision Safety: Advances cleanly past any pre-existing un-tracked order numbers")
    void testCollisionSafety() {
        String prefix = "PV-COLLISION-";
        sequenceRepository.saveAndFlush(new ReportSequence(prefix, 0L));

        // Insert a simulated pre-existing order at 0001
        com.provaluer.model.Order existingOrder = new com.provaluer.model.Order();
        existingOrder.setClientId(1L);
        existingOrder.setPropertyCategory("LAND_AND_BUILDING");
        existingOrder.setPurpose("BANK_COLLATERAL");
        existingOrder.setReportNumber("PV-COLLISION-0001");
        existingOrder.setStatus("DRAFT");
        orderRepository.saveAndFlush(existingOrder);

        // Generator should detect existing 0001 and safely advance to 0002 without collision or failure
        String generated = generatorService.generateNextReportNumberForPrefix(prefix);
        assertEquals("PV-COLLISION-0002", generated);

        ReportSequence finalSeq = sequenceRepository.findById(prefix).orElseThrow();
        assertEquals(2L, finalSeq.getLastSequence());

        orderRepository.delete(existingOrder);
    }
}
