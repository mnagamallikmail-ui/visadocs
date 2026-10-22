package com.provaluer.repository;

import com.provaluer.model.PrivacyNominee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PrivacyNomineeRepository extends JpaRepository<PrivacyNominee, Long> {
    List<PrivacyNominee> findByUserIdOrderByCreatedAtDesc(Long userId);
}
