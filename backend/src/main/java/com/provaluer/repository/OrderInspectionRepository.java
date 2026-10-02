package com.provaluer.repository;

import com.provaluer.model.OrderInspection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OrderInspectionRepository extends JpaRepository<OrderInspection, Long> {
    Optional<OrderInspection> findByOrderId(Long orderId);
    boolean existsByOrderId(Long orderId);
}
