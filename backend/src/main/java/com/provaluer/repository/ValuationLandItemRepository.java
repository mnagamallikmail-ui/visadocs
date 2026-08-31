package com.provaluer.repository;

import com.provaluer.model.ValuationLandItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ValuationLandItemRepository extends JpaRepository<ValuationLandItem, Long> {
    List<ValuationLandItem> findByOrderIdOrderBySortOrderAscIdAsc(Long orderId);
    void deleteByOrderId(Long orderId);
}
