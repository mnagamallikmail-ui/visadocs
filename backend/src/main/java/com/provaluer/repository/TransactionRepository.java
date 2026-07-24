package com.provaluer.repository;

import com.provaluer.model.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findAllByOrderId(Long orderId);
    List<Transaction> findAllByOrderIdAndStage(Long orderId, String stage);
}
