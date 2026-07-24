package com.provaluer.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.time.DayOfWeek;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class SlaServiceTest {

    @Autowired
    private SlaService slaService;

    @Test
    public void testCalculateExpiryVisa() {
        // Thursday 10:00 AM. 2 working days means it should expire Monday 10:00 AM (skipping Sat, Sun)
        LocalDateTime start = LocalDateTime.of(2026, 5, 28, 10, 0); // May 28, 2026 is Thursday
        LocalDateTime expiry = slaService.calculateExpiry("Visa", start);

        assertEquals(DayOfWeek.MONDAY, expiry.getDayOfWeek());
        assertEquals(10, expiry.getHour());
        assertEquals(0, expiry.getMinute());
    }

    @Test
    public void testCalculateExpiryStandard() {
        // Monday 10:00 AM. 4 working days means it should expire Friday 10:00 AM
        LocalDateTime start = LocalDateTime.of(2026, 5, 25, 10, 0); // May 25, 2026 is Monday
        LocalDateTime expiry = slaService.calculateExpiry("Standard Commercial", start);

        assertEquals(DayOfWeek.FRIDAY, expiry.getDayOfWeek());
        assertEquals(10, expiry.getHour());
    }

    @Test
    public void testAddBusinessHoursAcrossWeekend() {
        // Friday 4:30 PM (16:30). Add 3 business hours.
        // Friday has 1.5 business hours remaining (until 18:00).
        // Remaining 1.5 hours should start Monday 9:00 AM and expire Monday 10:30 AM.
        LocalDateTime start = LocalDateTime.of(2026, 5, 29, 16, 30); // May 29, 2026 is Friday
        LocalDateTime result = slaService.addBusinessHours(start, 3.0);

        assertEquals(DayOfWeek.MONDAY, result.getDayOfWeek());
        assertEquals(6, result.getMonthValue()); // June 1, 2026
        assertEquals(1, result.getDayOfMonth());
        assertEquals(10, result.getHour());
        assertEquals(30, result.getMinute());
    }

    @Test
    public void testGetRemainingBusinessHours() {
        // Start: Monday 9:00 AM. Expiry: Tuesday 6:00 PM (18:00).
        // Total active business days: 2 * 9 hours = 18.0 hours.
        LocalDateTime start = LocalDateTime.of(2026, 5, 25, 9, 0);
        LocalDateTime expiry = LocalDateTime.of(2026, 5, 26, 18, 0);
        double hours = slaService.getRemainingBusinessHours(start, expiry);

        assertEquals(18.0, hours, 0.01);
    }
}
