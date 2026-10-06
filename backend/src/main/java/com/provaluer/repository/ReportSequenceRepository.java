package com.provaluer.repository;

import com.provaluer.model.ReportSequence;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ReportSequenceRepository extends JpaRepository<ReportSequence, String> {

    /**
     * Acquires a pessimistic write lock (SELECT ... FOR UPDATE)
     * guaranteeing mutually exclusive execution across all concurrent threads and transactions.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT s FROM ReportSequence s WHERE s.prefix = :prefix")
    Optional<ReportSequence> findByPrefixWithLock(@Param("prefix") String prefix);
}
