package com.provaluer.repository;

import com.provaluer.model.SeoPage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.List;

@Repository
public interface SeoPageRepository extends JpaRepository<SeoPage, Long> {
    Optional<SeoPage> findByUrl(String url);
    Optional<SeoPage> findBySlug(String slug);
    List<SeoPage> findAllByOrderByPublishedAtDesc();
    long countByIndexedTrue();
}
