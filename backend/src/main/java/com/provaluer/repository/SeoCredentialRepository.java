package com.provaluer.repository;

import com.provaluer.model.SeoCredential;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SeoCredentialRepository extends JpaRepository<SeoCredential, Long> {
    Optional<SeoCredential> findByProvider(String provider);
}
