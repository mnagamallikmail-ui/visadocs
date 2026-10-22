package com.provaluer.repository;

import com.provaluer.model.DeletionCertificate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeletionCertificateRepository extends JpaRepository<DeletionCertificate, Long> {
    List<DeletionCertificate> findByUserIdOrderByCompletionTimeDesc(Long userId);
    Optional<DeletionCertificate> findByCertificateNumber(String certificateNumber);
}
