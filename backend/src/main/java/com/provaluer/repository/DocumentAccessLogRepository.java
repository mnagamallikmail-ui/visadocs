package com.provaluer.repository;

import com.provaluer.model.DocumentAccessLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DocumentAccessLogRepository extends JpaRepository<DocumentAccessLog, Long> {
    List<DocumentAccessLog> findByUserId(Long userId);
    List<DocumentAccessLog> findByDocumentTypeAndDocumentId(String documentType, String documentId);
    List<DocumentAccessLog> findTop50ByOrderByCreatedAtDesc();
}
