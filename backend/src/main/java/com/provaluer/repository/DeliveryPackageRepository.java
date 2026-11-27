package com.provaluer.repository;

import com.provaluer.model.DeliveryPackage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryPackageRepository extends JpaRepository<DeliveryPackage, Long> {
    Optional<DeliveryPackage> findByOrderId(Long orderId);
    Optional<DeliveryPackage> findFirstByOrderIdOrderByRevisionNumberDesc(Long orderId);
    List<DeliveryPackage> findAllByOrderIdOrderByRevisionNumberDesc(Long orderId);
    boolean existsByOrderId(Long orderId);
}
