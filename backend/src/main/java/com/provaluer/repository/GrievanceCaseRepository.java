package com.provaluer.repository;

import com.provaluer.model.GrievanceCase;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GrievanceCaseRepository extends JpaRepository<GrievanceCase, Long> {
    List<GrievanceCase> findByUserIdOrderByCreatedAtDesc(Long userId);
    Optional<GrievanceCase> findByTicketNumber(String ticketNumber);
    List<GrievanceCase> findAllByOrderByCreatedAtDesc();
    long countByStatus(String status);
}
