package com.provaluer.repository;

import com.provaluer.model.OrderInput;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface OrderInputRepository extends JpaRepository<OrderInput, Long> {
    List<OrderInput> findAllByOrderId(Long orderId);
    Optional<OrderInput> findByOrderIdAndFieldKey(Long orderId, String fieldKey);
    void deleteByOrderId(Long orderId);
}
