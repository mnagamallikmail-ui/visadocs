package com.provaluer.repository;

import com.provaluer.model.Revision;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RevisionRepository extends JpaRepository<Revision, Long> {
    List<Revision> findAllByOrderId(Long orderId);
    long countByOrderId(Long orderId);
}
