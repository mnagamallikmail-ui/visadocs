package com.provaluer.repository;

import com.provaluer.model.ValuationData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ValuationDataRepository extends JpaRepository<ValuationData, Long> {
    Optional<ValuationData> findByOrderId(Long orderId);
}
