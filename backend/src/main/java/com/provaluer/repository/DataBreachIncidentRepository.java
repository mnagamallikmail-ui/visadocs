package com.provaluer.repository;

import com.provaluer.model.DataBreachIncident;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DataBreachIncidentRepository extends JpaRepository<DataBreachIncident, Long> {
    Optional<DataBreachIncident> findByIncidentId(String incidentId);
    List<DataBreachIncident> findAllByOrderByDiscoveryTimeDesc();
    List<DataBreachIncident> findByStatus(String status);
}
