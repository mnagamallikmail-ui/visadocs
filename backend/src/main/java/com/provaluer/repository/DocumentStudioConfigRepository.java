package com.provaluer.repository;

import com.provaluer.model.DocumentStudioConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DocumentStudioConfigRepository extends JpaRepository<DocumentStudioConfig, Long> {

    /**
     * Retrieves the visual studio configuration for a specific template.
     */
    Optional<DocumentStudioConfig> findByTemplateId(Long templateId);

    /**
     * Checks if a studio configuration already exists for a template.
     */
    boolean existsByTemplateId(Long templateId);

    /**
     * Deletes studio configuration associated with a template.
     */
    void deleteByTemplateId(Long templateId);
}
