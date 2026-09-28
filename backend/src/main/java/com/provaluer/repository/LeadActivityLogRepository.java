package com.provaluer.repository;

import com.provaluer.model.LeadActivityLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LeadActivityLogRepository extends JpaRepository<LeadActivityLog, Long> {
    List<LeadActivityLog> findByLeadIdOrderByCreatedAtDesc(Long leadId);
}
