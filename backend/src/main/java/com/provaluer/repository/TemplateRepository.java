package com.provaluer.repository;

import com.provaluer.model.Template;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface TemplateRepository extends JpaRepository<Template, Long> {
    List<Template> findAllByIsActive(String isActive);
    Optional<Template> findByIdAndIsActive(Long id, String isActive);
}
