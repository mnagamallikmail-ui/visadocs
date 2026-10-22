package com.provaluer.repository;

import com.provaluer.model.GuardianConsentLedger;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GuardianConsentLedgerRepository extends JpaRepository<GuardianConsentLedger, Long> {
    List<GuardianConsentLedger> findByOrderId(Long orderId);
    List<GuardianConsentLedger> findByLeadId(Long leadId);
    Optional<GuardianConsentLedger> findTopByOrderIdOrderByConsentTimestampDesc(Long orderId);
}
