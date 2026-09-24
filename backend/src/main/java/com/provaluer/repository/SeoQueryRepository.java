package com.provaluer.repository;

import com.provaluer.model.SeoQuery;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Repository interface for SEO Search Queries
 */
@Repository
public interface SeoQueryRepository extends JpaRepository<SeoQuery, Long> {
    Optional<SeoQuery> findByPageIdAndQueryAndSourceAndDate(Long pageId, String query, String source, LocalDate date);

    List<SeoQuery> findByPageIdOrderByDateDesc(Long pageId);

    List<SeoQuery> findTop50ByOrderByClicksDescImpressionsDesc();

    @Query("SELECT q FROM SeoQuery q WHERE q.date = (SELECT MAX(q2.date) FROM SeoQuery q2) ORDER BY q.clicks DESC, q.impressions DESC")
    List<SeoQuery> findLatestTopQueries();
}
