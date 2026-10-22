package com.provaluer.repository;

import com.provaluer.model.RetentionExecutionLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RetentionExecutionLogRepository extends JpaRepository<RetentionExecutionLog, Long> {
    List<RetentionExecutionLog> findTop20ByOrderByExecutionTimestampDesc();
}
