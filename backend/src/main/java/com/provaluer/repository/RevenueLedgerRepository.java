package com.provaluer.repository;

import com.provaluer.model.RevenueLedger;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RevenueLedgerRepository extends JpaRepository<RevenueLedger, Long> {
    List<RevenueLedger> findByOrderIdOrderByPostedAtAsc(Long orderId);
}
