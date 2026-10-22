package com.provaluer.repository;

import com.provaluer.model.BreachNotificationLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BreachNotificationLogRepository extends JpaRepository<BreachNotificationLog, Long> {
    List<BreachNotificationLog> findByIncidentIdOrderByNotificationTimestampDesc(String incidentId);
    List<BreachNotificationLog> findTop50ByOrderByNotificationTimestampDesc();
}
