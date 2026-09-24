package com.provaluer.repository;

import com.provaluer.model.SeoCrawlError;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SeoCrawlErrorRepository extends JpaRepository<SeoCrawlError, Long> {
    List<SeoCrawlError> findByResolvedFalseOrderByDetectedAtDesc();
    List<SeoCrawlError> findTop50ByOrderByDetectedAtDesc();
    long countByResolvedFalse();
}
