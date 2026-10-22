package com.provaluer.repository;

import com.provaluer.model.ConsentLedger;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConsentLedgerRepository extends JpaRepository<ConsentLedger, Long> {
    List<ConsentLedger> findByUserIdOrderByCreatedAtDesc(Long userId);
    List<ConsentLedger> findByActorIdentifierOrderByCreatedAtDesc(String actorIdentifier);
    List<ConsentLedger> findByLeadIdOrderByCreatedAtDesc(Long leadId);
    Optional<ConsentLedger> findFirstByUserIdAndConsentTypeAndWithdrawnFalseOrderByCreatedAtDesc(Long userId, String consentType);
    Optional<ConsentLedger> findFirstByActorIdentifierAndConsentTypeAndWithdrawnFalseOrderByCreatedAtDesc(String actorIdentifier, String consentType);
}
