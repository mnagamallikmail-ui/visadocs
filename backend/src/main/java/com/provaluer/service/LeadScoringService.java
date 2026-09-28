package com.provaluer.service;

import com.provaluer.dto.LeadRequestDto;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

@Service
public class LeadScoringService {

    private static final Set<String> PUBLIC_EMAIL_DOMAINS = new HashSet<>(Arrays.asList(
        "gmail.com", "yahoo.com", "hotmail.com", "outlook.com", "rediffmail.com", "icloud.com", "protonmail.com"
    ));

    public static class ScoreResult {
        public final int score;
        public final String intentLevel;

        public ScoreResult(int score, String intentLevel) {
            this.score = score;
            this.intentLevel = intentLevel;
        }
    }

    public ScoreResult calculateScore(LeadRequestDto dto) {
        int score = 0;

        // 1. Documents Attached
        if (dto.getDocumentCount() >= 2) {
            score += 30;
        } else if (dto.getDocumentCount() == 1) {
            score += 15;
        }

        // 2. Corporate Email vs Free Public Domain
        String email = dto.getContactEmail();
        if (email != null && email.contains("@")) {
            String domain = email.substring(email.indexOf("@") + 1).toLowerCase(Locale.ROOT).trim();
            if (!PUBLIC_EMAIL_DOMAINS.contains(domain) && domain.contains(".")) {
                score += 25; // High value corporate email domain
            } else {
                score += 5;
            }
        }

        // 3. Recognized High-Value Role
        String role = dto.getContactRole();
        if (role != null) {
            String r = role.toUpperCase(Locale.ROOT);
            if (r.contains("CFO") || r.contains("CHIEF") || r.contains("FINANCIAL") ||
                r.contains("DIRECTOR") || r.contains("PROMOTER") ||
                r.contains("RESOLUTION") || r.contains("RP") || r.contains("PARTNER") ||
                r.contains("VP") || r.contains("FOUNDER") || r.contains("ADVOCATE") ||
                r.contains("BANKER") || r.contains("CHARTERED")) {
                score += 15;
            } else if (!role.trim().isEmpty()) {
                score += 8;
            }
        }

        // 4. Asset Scale Bracket
        String bracket = dto.getValueBracket();
        if (bracket != null) {
            switch (bracket.toUpperCase(Locale.ROOT)) {
                case "ABOVE_100CR":
                case "100CR+":
                    score += 20;
                    break;
                case "25CR_100CR":
                case "25CR - 100CR":
                    score += 15;
                    break;
                case "5CR_25CR":
                case "5CR - 25CR":
                    score += 10;
                    break;
                default:
                    score += 5;
                    break;
            }
        }

        // 5. Urgency SLA
        String sla = dto.getUrgencySla();
        if (sla != null) {
            if (sla.toUpperCase(Locale.ROOT).contains("EXPRESS") || sla.contains("24")) {
                score += 10;
            } else if (sla.toUpperCase(Locale.ROOT).contains("STANDARD") || sla.contains("3")) {
                score += 5;
            }
        }

        // Cap at 100
        score = Math.min(100, score);

        // Classification
        String intentLevel;
        if (score >= 80) {
            intentLevel = "CRITICAL";
        } else if (score >= 60) {
            intentLevel = "HIGH";
        } else if (score >= 35) {
            intentLevel = "MEDIUM";
        } else {
            intentLevel = "LOW";
        }

        return new ScoreResult(score, intentLevel);
    }
}
