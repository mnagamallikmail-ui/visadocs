package com.provaluer.repository;

import com.provaluer.model.ValuationComparableSale;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ValuationComparableSaleRepository extends JpaRepository<ValuationComparableSale, Long> {
    List<ValuationComparableSale> findByOrderIdOrderBySortOrderAscIdAsc(Long orderId);
    void deleteByOrderId(Long orderId);
}
