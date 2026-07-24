package com.provaluer.repository;

import com.provaluer.model.TemplateQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface TemplateQuestionRepository extends JpaRepository<TemplateQuestion, String> {
    Optional<TemplateQuestion> findByPlaceholderKeyIgnoreCase(String placeholderKey);
}
