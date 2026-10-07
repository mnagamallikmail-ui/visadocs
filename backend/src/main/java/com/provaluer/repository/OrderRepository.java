package com.provaluer.repository;

import com.provaluer.model.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface OrderRepository extends JpaRepository<Order, Long> {
    @Query("SELECT COUNT(o) FROM Order o WHERE o.isDeleted = false AND o.status IN :statuses")
    long countByStatusIn(@Param("statuses") List<String> statuses);

    @Query("SELECT o FROM Order o WHERE o.clientId = :clientId AND o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllByClientId(Long clientId);

    @Query("SELECT o FROM Order o WHERE o.paId = :paId AND o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllByPaId(Long paId);

    @Query("SELECT o FROM Order o WHERE o.status = :status AND o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllByStatus(String status);

    @Query("SELECT o FROM Order o WHERE o.status IN :statuses AND o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllByStatusIn(@Param("statuses") List<String> statuses);

    @Query("SELECT o FROM Order o WHERE o.paId = :paId AND o.status = :status AND o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllByPaIdAndStatus(Long paId, String status);

    @Query("SELECT o FROM Order o WHERE o.isDeleted = false ORDER BY o.createdAt DESC")
    List<Order> findAllOrderedByCreatedAt();

    @Query("SELECT o FROM Order o WHERE o.isDeleted = true ORDER BY o.deletedAt DESC")
    List<Order> findAllDeletedOrders();

    @Query("SELECT o FROM Order o WHERE o.isDeleted = false AND o.status NOT IN ('FINAL_DELIVERY', 'DRAFT') ORDER BY o.slaExpiryTime ASC")
    List<Order> findAllActiveSlaOrders();

    long countByReportNumberStartingWith(String prefix);

    boolean existsByReportNumber(String reportNumber);
    java.util.Optional<Order> findByReportNumber(String reportNumber);
    boolean existsByReferenceCode(String referenceCode);
    java.util.Optional<Order> findByReferenceCode(String referenceCode);
    boolean existsByQuoteNumber(String quoteNumber);
    java.util.Optional<Order> findByQuoteNumber(String quoteNumber);

    long countByTemplateId(Long templateId);

    long countByTemplateIdAndStatus(Long templateId, String status);

    long countByTemplateIdAndStatusIn(Long templateId, List<String> statuses);

    long countByTemplateVersionId(Long templateVersionId);

    List<Order> findAllByTemplateId(Long templateId);

    @Query("SELECT COALESCE(SUM(o.feeCharged), 0) FROM Order o WHERE o.isDeleted = false")
    java.math.BigDecimal sumRealizedRevenue();

    long countByIsDeletedFalse();

    long countByIsDeletedFalseAndStatus(String status);
}
