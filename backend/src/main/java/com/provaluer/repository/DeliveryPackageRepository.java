package com.provaluer.repository;

import com.provaluer.model.DeliveryPackage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DeliveryPackageRepository extends JpaRepository<DeliveryPackage, Long> {
    Optional<DeliveryPackage> findByOrderId(Long orderId);
    boolean existsByOrderId(Long orderId);
}
