package com.provaluer.repository;

import com.provaluer.model.ValuationBuildingItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ValuationBuildingItemRepository extends JpaRepository<ValuationBuildingItem, Long> {
    List<ValuationBuildingItem> findByOrderIdOrderBySortOrderAscIdAsc(Long orderId);
    void deleteByOrderId(Long orderId);
}
