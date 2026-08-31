package com.provaluer.repository;

import com.provaluer.model.ValuationSnapshot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ValuationSnapshotRepository extends JpaRepository<ValuationSnapshot, Long> {
    List<ValuationSnapshot> findByOrderIdOrderByVersionNumberDesc(Long orderId);
    Optional<ValuationSnapshot> findFirstByOrderIdOrderByVersionNumberDesc(Long orderId);
    Optional<ValuationSnapshot> findByOrderIdAndVersionNumber(Long orderId, int versionNumber);
}
