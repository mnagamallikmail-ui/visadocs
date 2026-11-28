package com.provaluer.repository;

import com.provaluer.model.WebsiteVisit;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface WebsiteVisitRepository extends JpaRepository<WebsiteVisit, Long> {

    long countByVisitedAtAfter(LocalDateTime since);

    List<WebsiteVisit> findTop50ByOrderByVisitedAtDesc();

    @Query("SELECT v.pagePath, COUNT(v) FROM WebsiteVisit v GROUP BY v.pagePath ORDER BY COUNT(v) DESC")
    List<Object[]> findTopPages(Pageable pageable);

    @Query("SELECT COALESCE(NULLIF(v.referrer, ''), 'Direct'), COUNT(v) FROM WebsiteVisit v GROUP BY COALESCE(NULLIF(v.referrer, ''), 'Direct') ORDER BY COUNT(v) DESC")
    List<Object[]> findTopReferrers(Pageable pageable);

    @Query("SELECT v.country, v.state, v.city, COUNT(v) FROM WebsiteVisit v GROUP BY v.country, v.state, v.city ORDER BY COUNT(v) DESC")
    List<Object[]> findVisitorLocations(Pageable pageable);
}

