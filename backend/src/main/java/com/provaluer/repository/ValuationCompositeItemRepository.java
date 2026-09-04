package com.provaluer.repository;

import com.provaluer.model.ValuationCompositeItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ValuationCompositeItemRepository extends JpaRepository<ValuationCompositeItem, Long> {
    List<ValuationCompositeItem> findByOrderIdOrderBySortOrderAscIdAsc(Long orderId);
    void deleteByOrderId(Long orderId);
}
