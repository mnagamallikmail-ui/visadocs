package com.provaluer.scheduler;

import com.provaluer.model.SeoCredential;
import com.provaluer.repository.SeoCredentialRepository;
import com.provaluer.service.SeoIntelligenceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;

/**
 * Automated Cron Synchronization Scheduler for SEO Telemetry
 */
@Component
public class SeoSyncScheduler {
    private static final Logger log = LoggerFactory.getLogger(SeoSyncScheduler.class);

    @Autowired
    private SeoIntelligenceService seoIntelligenceService;

    @Autowired
    private SeoCredentialRepository credentialRepository;

    /**
     * Automated Cron Synchronization:
     * Runs daily at 02:00 AM server time.
     * Evaluates configured frequency ('DAILY' vs 'WEEKLY').
     */
    @Scheduled(cron = "0 0 2 * * *")
    public void runScheduledSeoSync() {
        log.info("Triggering scheduled SEO Intelligence synchronization...");

        List<SeoCredential> credentials = credentialRepository.findAll();
        boolean hasDaily = false;
        boolean hasWeekly = false;

        for (SeoCredential c : credentials) {
            if ("DAILY".equalsIgnoreCase(c.getSyncFrequency())) {
                hasDaily = true;
            } else if ("WEEKLY".equalsIgnoreCase(c.getSyncFrequency())) {
                hasWeekly = true;
            }
        }

        LocalDate today = LocalDate.now();
        boolean isMonday = today.getDayOfWeek() == DayOfWeek.MONDAY;

        if (hasDaily || (hasWeekly && isMonday)) {
            seoIntelligenceService.executeSync("ALL");
            log.info("Scheduled SEO Intelligence synchronization completed successfully.");
        } else {
            log.info("Skipping weekly SEO sync today (run scheduled for Monday).");
        }
    }
}
