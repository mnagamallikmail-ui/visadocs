package com.provaluer.repository;

import com.provaluer.model.LeadQuotation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface LeadQuotationRepository extends JpaRepository<LeadQuotation, Long> {
    Optional<LeadQuotation> findByQuoteNumber(String quoteNumber);
    List<LeadQuotation> findByLeadIdOrderByCreatedAtDesc(Long leadId);
}
