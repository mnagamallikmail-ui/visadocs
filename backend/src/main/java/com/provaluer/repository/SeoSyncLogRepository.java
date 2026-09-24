package com.provaluer.repository;

import com.provaluer.model.SeoSyncLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SeoSyncLogRepository extends JpaRepository<SeoSyncLog, Long> {
    List<SeoSyncLog> findTop20ByOrderByCreatedAtDesc();
}
