package com.provaluer.repository;

import com.provaluer.model.OrderAcknowledgement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderAcknowledgementRepository extends JpaRepository<OrderAcknowledgement, Long> {
    List<OrderAcknowledgement> findByOrderIdOrderByCreatedAtDesc(Long orderId);
    boolean existsByOrderIdAndAction(Long orderId, String action);
}
