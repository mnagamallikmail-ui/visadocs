package com.provaluer.repository;

import com.provaluer.model.OrderRevisionHistory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRevisionHistoryRepository extends JpaRepository<OrderRevisionHistory, Long> {

    List<OrderRevisionHistory> findAllByOrderIdOrderByRevisionNumberDesc(Long orderId);

    Page<OrderRevisionHistory> findAllByOrderIdOrderByRevisionNumberDesc(Long orderId, Pageable pageable);

    Optional<OrderRevisionHistory> findFirstByOrderIdOrderByRevisionNumberDesc(Long orderId);

    @Query("SELECT MAX(h.revisionNumber) FROM OrderRevisionHistory h WHERE h.order.id = :orderId")
    Integer findMaxRevisionNumberByOrderId(@Param("orderId") Long orderId);

    long countByOrderId(Long orderId);
}

