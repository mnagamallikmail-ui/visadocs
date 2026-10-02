package com.provaluer.repository;

import com.provaluer.model.DeliveryToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DeliveryTokenRepository extends JpaRepository<DeliveryToken, Long> {
    Optional<DeliveryToken> findByToken(String token);
}
