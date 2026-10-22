package com.provaluer.repository;

import com.provaluer.model.PrivacyErasureRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PrivacyErasureRequestRepository extends JpaRepository<PrivacyErasureRequest, Long> {
    List<PrivacyErasureRequest> findByUserIdOrderByCreatedAtDesc(Long userId);
    Optional<PrivacyErasureRequest> findByRequestId(String requestId);
    List<PrivacyErasureRequest> findAllByOrderByCreatedAtDesc();
}
