package com.provaluer.repository;

import com.provaluer.model.SeoDailyMetric;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface SeoDailyMetricRepository extends JpaRepository<SeoDailyMetric, Long> {
    Optional<SeoDailyMetric> findByPageIdAndSourceAndDate(Long pageId, String source, LocalDate date);

    List<SeoDailyMetric> findByPageIdOrderByDateDesc(Long pageId);

    List<SeoDailyMetric> findByDateBetweenOrderByDateAsc(LocalDate startDate, LocalDate endDate);

    @Query("SELECT SUM(m.impressions) FROM SeoDailyMetric m WHERE m.date = :date")
    Long sumImpressionsByDate(@Param("date") LocalDate date);

    @Query("SELECT SUM(m.clicks) FROM SeoDailyMetric m WHERE m.date = :date")
    Long sumClicksByDate(@Param("date") LocalDate date);

    @Query("SELECT SUM(m.impressions) FROM SeoDailyMetric m")
    Long sumTotalImpressions();

    @Query("SELECT SUM(m.clicks) FROM SeoDailyMetric m")
    Long sumTotalClicks();

    @Query("SELECT AVG(m.avgPosition) FROM SeoDailyMetric m WHERE m.avgPosition > 0")
    Double calculateOverallAvgPosition();
}
