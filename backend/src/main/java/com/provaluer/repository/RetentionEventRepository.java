package com.provaluer.repository;

import com.provaluer.model.RetentionEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RetentionEventRepository extends JpaRepository<RetentionEvent, Long> {
    List<RetentionEvent> findTop100ByOrderByCreatedAtDesc();
}
