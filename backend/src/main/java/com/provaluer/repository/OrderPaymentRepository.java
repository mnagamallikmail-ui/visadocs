package com.provaluer.repository;

import com.provaluer.model.OrderPayment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderPaymentRepository extends JpaRepository<OrderPayment, Long> {

    List<OrderPayment> findAllByOrderIdOrderBySubmittedAtDesc(Long orderId);

    Optional<OrderPayment> findTopByOrderIdOrderBySubmittedAtDesc(Long orderId);

    Optional<OrderPayment> findByUtrNumber(String utrNumber);

    @Query("SELECT COUNT(p) > 0 FROM OrderPayment p WHERE LOWER(TRIM(p.utrNumber)) = LOWER(TRIM(:utr)) AND p.status IN (:statuses)")
    boolean existsActiveUtr(@Param("utr") String utr, @Param("statuses") Collection<String> statuses);
}
