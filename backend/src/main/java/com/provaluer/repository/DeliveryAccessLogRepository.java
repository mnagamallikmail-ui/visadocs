package com.provaluer.repository;

import com.provaluer.model.DeliveryAccessLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DeliveryAccessLogRepository extends JpaRepository<DeliveryAccessLog, Long> {
    List<DeliveryAccessLog> findByOrderIdOrderByCreatedAtDesc(Long orderId);
}
