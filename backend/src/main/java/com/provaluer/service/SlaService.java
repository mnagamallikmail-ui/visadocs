package com.provaluer.service;

import org.springframework.stereotype.Service;
import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Service
public class SlaService {

    private static final LocalTime START_TIME = LocalTime.of(9, 0);
    private static final LocalTime END_TIME = LocalTime.of(18, 0);

    /**
     * Calculates project deadline based on purpose (Visa: 2 Working Days, Others: 4 Working Days).
     */
    public LocalDateTime calculateExpiry(String purpose, LocalDateTime start) {
        int days = "Visa".equalsIgnoreCase(purpose) ? 2 : 4;
        return addBusinessDays(start, days);
    }

    public LocalDateTime addBusinessDays(LocalDateTime start, int days) {
        LocalDateTime current = start;
        if (current.toLocalTime().isBefore(START_TIME)) {
            current = LocalDateTime.of(current.toLocalDate(), START_TIME);
        } else if (current.toLocalTime().isAfter(END_TIME)) {
            current = LocalDateTime.of(current.toLocalDate().plusDays(1), START_TIME);
        }
        current = adjustToWorkingDay(current);

        for (int i = 0; i < days; i++) {
            current = current.plusDays(1);
            current = adjustToWorkingDay(current);
        }
        return current;
    }

    /**
     * Adds decimal business hours to a starting date, skipping weekends and pausing outside 9am-6pm.
     */
    public LocalDateTime addBusinessHours(LocalDateTime start, double hours) {
        LocalDateTime current = start;
        if (current.toLocalTime().isBefore(START_TIME)) {
            current = LocalDateTime.of(current.toLocalDate(), START_TIME);
        } else if (current.toLocalTime().isAfter(END_TIME)) {
            current = LocalDateTime.of(current.toLocalDate().plusDays(1), START_TIME);
        }
        current = adjustToWorkingDay(current);

        double hoursRemaining = hours;
        while (hoursRemaining > 0) {
            LocalTime time = current.toLocalTime();
            double hoursToDayEnd = (double) java.time.Duration.between(time, END_TIME).toMinutes() / 60.0;
            if (hoursRemaining <= hoursToDayEnd) {
                int minutesToAdd = (int) Math.round(hoursRemaining * 60);
                current = current.plusMinutes(minutesToAdd);
                hoursRemaining = 0;
            } else {
                hoursRemaining -= hoursToDayEnd;
                current = LocalDateTime.of(current.toLocalDate().plusDays(1), START_TIME);
                current = adjustToWorkingDay(current);
            }
        }
        return current;
    }

    /**
     * Counts the exact business hours remaining between current time and the project expiry date.
     */
    public double getRemainingBusinessHours(LocalDateTime current, LocalDateTime expiry) {
        if (current.isAfter(expiry)) return 0.0;
        
        double totalHours = 0.0;
        LocalDateTime temp = adjustToWorkingDay(current);
        if (temp.toLocalTime().isBefore(START_TIME)) {
            temp = LocalDateTime.of(temp.toLocalDate(), START_TIME);
        } else if (temp.toLocalTime().isAfter(END_TIME)) {
            temp = LocalDateTime.of(temp.toLocalDate().plusDays(1), START_TIME);
            temp = adjustToWorkingDay(temp);
        }

        while (temp.isBefore(expiry)) {
            if (temp.toLocalDate().equals(expiry.toLocalDate())) {
                LocalTime tempTime = temp.toLocalTime();
                LocalTime expiryTime = expiry.toLocalTime();
                if (tempTime.isBefore(START_TIME)) tempTime = START_TIME;
                if (expiryTime.isAfter(END_TIME)) expiryTime = END_TIME;
                if (tempTime.isBefore(expiryTime)) {
                    totalHours += (double) java.time.Duration.between(tempTime, expiryTime).toMinutes() / 60.0;
                }
                break;
            } else {
                LocalTime tempTime = temp.toLocalTime();
                if (tempTime.isBefore(START_TIME)) tempTime = START_TIME;
                double hoursToDayEnd = (double) java.time.Duration.between(tempTime, END_TIME).toMinutes() / 60.0;
                totalHours += hoursToDayEnd;
                temp = LocalDateTime.of(temp.toLocalDate().plusDays(1), START_TIME);
                temp = adjustToWorkingDay(temp);
            }
        }
        return totalHours;
    }

    private LocalDateTime adjustToWorkingDay(LocalDateTime time) {
        LocalDateTime res = time;
        while (res.getDayOfWeek() == DayOfWeek.SATURDAY || res.getDayOfWeek() == DayOfWeek.SUNDAY) {
            res = res.plusDays(1);
        }
        return res;
    }
}
