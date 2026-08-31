package com.provaluer.repository;

import com.provaluer.model.TemplateVersion;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface TemplateVersionRepository extends JpaRepository<TemplateVersion, Long> {
    List<TemplateVersion> findAllByTemplateIdOrderByVersionDesc(Long templateId);
    Optional<TemplateVersion> findByTemplateIdAndVersion(Long templateId, int version);
    void deleteAllByTemplateId(Long templateId);
}
