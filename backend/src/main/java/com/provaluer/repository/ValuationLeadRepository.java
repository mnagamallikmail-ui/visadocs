package com.provaluer.repository;

import com.provaluer.model.ValuationLead;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ValuationLeadRepository extends JpaRepository<ValuationLead, Long> {
    Optional<ValuationLead> findByReferenceCode(String referenceCode);

    List<ValuationLead> findByStatusOrderByCreatedAtDesc(String status);

    List<ValuationLead> findByServiceVerticalOrderByCreatedAtDesc(String serviceVertical);

    List<ValuationLead> findByIntentLevelOrderByCreatedAtDesc(String intentLevel);

    @Query("SELECT l FROM ValuationLead l WHERE " +
           "(:status IS NULL OR l.status = :status) AND " +
           "(:service IS NULL OR l.serviceVertical = :service) AND " +
           "(:intent IS NULL OR l.intentLevel = :intent) " +
           "ORDER BY l.leadScore DESC, l.createdAt DESC")
    List<ValuationLead> searchLeads(@Param("status") String status,
                                    @Param("service") String service,
                                    @Param("intent") String intent);

    @Query("SELECT COUNT(l) FROM ValuationLead l WHERE l.status = 'NEW'")
    long countNewLeads();

    @Query("SELECT COUNT(l) FROM ValuationLead l WHERE l.intentLevel IN ('HIGH', 'CRITICAL')")
    long countUrgentLeads();
}
