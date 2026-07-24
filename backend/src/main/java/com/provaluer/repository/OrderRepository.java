package com.provaluer.repository;

import com.provaluer.model.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findAllByClientId(Long clientId);
    List<Order> findAllByPaId(Long paId);
    List<Order> findAllByStatus(String status);
    List<Order> findAllByPaIdAndStatus(Long paId, String status);

    @Query("SELECT o FROM Order o ORDER BY o.createdAt DESC")
    List<Order> findAllOrderedByCreatedAt();

    @Query("SELECT o FROM Order o WHERE o.status NOT IN ('FINAL_DELIVERY', 'DRAFT') ORDER BY o.slaExpiryTime ASC")
    List<Order> findAllActiveSlaOrders();

    long countByReportNumberStartingWith(String prefix);
}
