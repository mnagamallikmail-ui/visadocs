package com.provaluer.repository;

import com.provaluer.model.PrivacyCorrectionRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PrivacyCorrectionRequestRepository extends JpaRepository<PrivacyCorrectionRequest, Long> {
    List<PrivacyCorrectionRequest> findByUserIdOrderByCreatedAtDesc(Long userId);
    Optional<PrivacyCorrectionRequest> findByRequestId(String requestId);
    List<PrivacyCorrectionRequest> findAllByOrderByCreatedAtDesc();
}
