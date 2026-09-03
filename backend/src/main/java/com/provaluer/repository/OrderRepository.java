package com.provaluer.repository;

import com.provaluer.model.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface OrderRepository extends JpaRepository<Order, Long> {
    @Query("SELECT o FROM Order o WHERE o.clientId = :clientId AND o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllByClientId(Long clientId);

    @Query("SELECT o FROM Order o WHERE o.paId = :paId AND o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllByPaId(Long paId);

    @Query("SELECT o FROM Order o WHERE o.status = :status AND o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllByStatus(String status);

    @Query("SELECT o FROM Order o WHERE o.paId = :paId AND o.status = :status AND o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllByPaIdAndStatus(Long paId, String status);

    @Query("SELECT o FROM Order o WHERE o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllOrderedByCreatedAt();

    @Query("SELECT o FROM Order o WHERE o.isDeleted = true ORDER BY o.deletedAt DESC")
    List<Order> findAllDeletedOrders();

    @Query("SELECT o FROM Order o WHERE o.isDeleted = false AND o.status NOT IN ('FINAL_DELIVERY', 'DRAFT') ORDER BY o.slaExpiryTime ASC")
    List<Order> findAllActiveSlaOrders();

    long countByReportNumberStartingWith(String prefix);
}
