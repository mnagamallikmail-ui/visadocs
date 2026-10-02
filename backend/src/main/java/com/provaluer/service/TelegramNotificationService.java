package com.provaluer.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.LocalDate;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * High-reliability, non-blocking, async Telegram notification service.
 * Dispatches operational alerts to the Company Operations channel upon intake submission.
 */
@Service
public class TelegramNotificationService {

    private static final Logger log = LoggerFactory.getLogger(TelegramNotificationService.class);

    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;

    @Value("${app.telegram.enabled:true}")
    private boolean telegramEnabled;

    @Value("${app.telegram.bot-token:${TELEGRAM_BOT_TOKEN:}}")
    private String botToken;

    @Value("${app.telegram.chat-id:${TELEGRAM_CHAT_ID:}}")
    private String chatId;

    public TelegramNotificationService() {
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
        this.objectMapper = new ObjectMapper();
    }

    // Constructor injection for testing
    public TelegramNotificationService(HttpClient httpClient, ObjectMapper objectMapper,
                                       boolean telegramEnabled, String botToken, String chatId) {
        this.httpClient = httpClient;
        this.objectMapper = objectMapper;
        this.telegramEnabled = telegramEnabled;
        this.botToken = botToken;
        this.chatId = chatId;
    }

    /**
     * Dispatches async Telegram alert for newly submitted valuation requests.
     * Retries up to 3 times on transient failures.
     * Guaranteed never to throw an exception or block the caller.
     */
    @Async
    public CompletableFuture<Boolean> sendNewRequestNotification(
            String referenceCode,
            String clientName,
            String service,
            String asset,
            String purpose,
            int documentCount,
            String mobile) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] Bot token or chat ID not set. Simulation mode for Ref: {}", referenceCode);
            log.info("[SIMULATED TELEGRAM MESSAGE]\n" +
                    "🔔 NEW REQUEST RECEIVED\n" +
                    "Reference: {}\nClient: {}\nService: {}\nAsset: {}\nPurpose: {}\nDocuments: {}\nMobile: {}",
                    referenceCode, clientName, service, asset, purpose, documentCount, mobile);
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "🔔 <b>NEW REQUEST RECEIVED</b>\n\n" +
                "<b>Reference:</b> %s\n" +
                "<b>Client:</b> %s\n" +
                "<b>Service:</b> %s\n" +
                "<b>Asset:</b> %s\n" +
                "<b>Purpose:</b> %s\n" +
                "<b>Document Count:</b> %d\n" +
                "<b>Mobile:</b> %s",
                escapeHtml(referenceCode),
                escapeHtml(clientName != null ? clientName : "Individual Client"),
                escapeHtml(service != null ? service : "Valuation Report"),
                escapeHtml(asset != null ? asset : "Land & Building"),
                escapeHtml(purpose != null ? purpose : "Bank Collateral / Loan"),
                documentCount,
                escapeHtml(mobile != null ? mobile : "N/A")
        );

        int maxAttempts = 3;
        long backoffMs = 1000;

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                String endpoint = "https://api.telegram.org/bot" + botToken.trim() + "/sendMessage";
                Map<String, Object> payload = Map.of(
                        "chat_id", chatId.trim(),
                        "text", messageText,
                        "parse_mode", "HTML"
                );

                String jsonBody = objectMapper.writeValueAsString(payload);

                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(endpoint))
                        .timeout(Duration.ofSeconds(7))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                        .build();

                HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

                if (response.statusCode() >= 200 && response.statusCode() < 300) {
                    log.info("[TELEGRAM NOTIFICATION] Successfully delivered alert for Ref: {} (HTTP {})", referenceCode, response.statusCode());
                    return CompletableFuture.completedFuture(true);
                } else {
                    log.warn("[TELEGRAM NOTIFICATION] Attempt {}/{} failed with HTTP {}: {}", attempt, maxAttempts, response.statusCode(), response.body());
                }
            } catch (Throwable t) {
                log.warn("[TELEGRAM NOTIFICATION] Attempt {}/{} encountered error: {}", attempt, maxAttempts, t.getMessage());
            }

            if (attempt < maxAttempts) {
                try {
                    Thread.sleep(backoffMs);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
                backoffMs *= 2;
            }
        }

        log.error("[TELEGRAM NOTIFICATION] All {} attempts exhausted for Ref: {}. Request submission remains unaffected.", maxAttempts, referenceCode);
        return CompletableFuture.completedFuture(false);
    }

    /**
     * Dispatches async Telegram alert when a quotation is issued (QUOTE_PROVIDED).
     */
    @Async
    public CompletableFuture<Boolean> sendQuotationIssuedNotification(
            String referenceCode,
            String quoteNumber,
            String clientName,
            String service,
            String totalAmount,
            String turnaround,
            String quotedBy) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] Bot token or chat ID not set. Simulation mode for Quote: {} (Ref: {})", quoteNumber, referenceCode);
            log.info("[SIMULATED TELEGRAM MESSAGE]\n" +
                    "📋 QUOTATION ISSUED\n" +
                    "Quote: {}\nReference: {}\nClient: {}\nService: {}\nTotal Amount: INR {}\nTurnaround: {}\nQuoted By: {}",
                    quoteNumber, referenceCode, clientName, service, totalAmount, turnaround, quotedBy);
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "📋 <b>QUOTATION ISSUED</b>\n\n" +
                "<b>Quote Number:</b> %s\n" +
                "<b>Reference:</b> %s\n" +
                "<b>Client:</b> %s\n" +
                "<b>Service:</b> %s\n" +
                "<b>Total Quoted Fee:</b> ₹ %s\n" +
                "<b>Committed Turnaround:</b> %s\n" +
                "<b>Issued By:</b> %s\n" +
                "<b>Status:</b> QUOTE_PROVIDED",
                escapeHtml(quoteNumber),
                escapeHtml(referenceCode),
                escapeHtml(clientName != null ? clientName : "Client"),
                escapeHtml(service != null ? service : "Valuation Report"),
                escapeHtml(totalAmount != null ? totalAmount : "0.00"),
                escapeHtml(turnaround != null ? turnaround : "3-5 Working Days"),
                escapeHtml(quotedBy != null ? quotedBy : "Admin")
        );

        int maxAttempts = 3;
        long backoffMs = 1000;

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                String endpoint = "https://api.telegram.org/bot" + botToken.trim() + "/sendMessage";
                Map<String, Object> payload = Map.of(
                        "chat_id", chatId.trim(),
                        "text", messageText,
                        "parse_mode", "HTML"
                );

                String jsonBody = objectMapper.writeValueAsString(payload);
                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(endpoint))
                        .timeout(Duration.ofSeconds(10))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                        .build();

                HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

                if (response.statusCode() >= 200 && response.statusCode() < 300) {
                    log.info("[TELEGRAM NOTIFICATION] Successfully delivered Quote alert for Ref: {} (HTTP {})", referenceCode, response.statusCode());
                    return CompletableFuture.completedFuture(true);
                } else {
                    log.warn("[TELEGRAM NOTIFICATION] Attempt {}/{} failed with HTTP {}: {}", attempt, maxAttempts, response.statusCode(), response.body());
                }
            } catch (Throwable t) {
                log.warn("[TELEGRAM NOTIFICATION] Attempt {}/{} encountered error: {}", attempt, maxAttempts, t.getMessage());
            }

            if (attempt < maxAttempts) {
                try {
                    Thread.sleep(backoffMs);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
                backoffMs *= 2;
            }
        }

        log.error("[TELEGRAM NOTIFICATION] All {} attempts exhausted for Quote: {}. Quote issuance remains unaffected.", maxAttempts, quoteNumber);
        return CompletableFuture.completedFuture(false);
    }

    @Async
    public CompletableFuture<Boolean> sendPaymentSubmittedNotification(
            String referenceCode,
            String quoteNumber,
            String clientName,
            String clientEmail,
            BigDecimal amountPaid,
            String paymentMethod,
            String utrNumber,
            LocalDate paymentDate) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] Skipping payment submission notification (disabled or credentials missing)");
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "💳 <b>PAYMENT PROOF SUBMITTED</b>%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<b>Order Ref:</b> <code>%s</code>%n" +
                "<b>Quote No:</b> <code>%s</code>%n" +
                "<b>Client:</b> %s (%s)%n" +
                "<b>Amount Paid:</b> ₹ %.2f%n" +
                "<b>Method:</b> %s%n" +
                "<b>UTR:</b> <code>%s</code>%n" +
                "<b>Date:</b> %s%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<i>Awaiting administrative verification in portal.</i>",
                escapeHtml(referenceCode),
                escapeHtml(quoteNumber != null ? quoteNumber : "N/A"),
                escapeHtml(clientName != null ? clientName : "Client"),
                escapeHtml(clientEmail != null ? clientEmail : "N/A"),
                amountPaid != null ? amountPaid.doubleValue() : 0.0,
                escapeHtml(paymentMethod != null ? paymentMethod : "N/A"),
                escapeHtml(utrNumber != null ? utrNumber : "N/A"),
                paymentDate != null ? paymentDate.toString() : "Today"
        );

        return sendTelegramPayload(messageText, referenceCode, "PaymentSubmitted");
    }

    @Async
    public CompletableFuture<Boolean> sendPaymentVerifiedNotification(
            String referenceCode,
            String quoteNumber,
            String clientName,
            BigDecimal amountPaid,
            BigDecimal verifiedAmount,
            String utrNumber,
            String verifiedBy) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "✅ <b>PAYMENT VERIFIED & CONFIRMED</b>%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<b>Order Ref:</b> <code>%s</code>%n" +
                "<b>Quote No:</b> <code>%s</code>%n" +
                "<b>Client:</b> %s%n" +
                "<b>Amount Paid:</b> ₹ %.2f%n" +
                "<b>Verified In Bank:</b> ₹ %.2f%n" +
                "<b>UTR:</b> <code>%s</code>%n" +
                "<b>Verified By:</b> %s%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<i>Quotation payment confirmed. Status: PAYMENT_VERIFIED</i>",
                escapeHtml(referenceCode),
                escapeHtml(quoteNumber != null ? quoteNumber : "N/A"),
                escapeHtml(clientName != null ? clientName : "Client"),
                amountPaid != null ? amountPaid.doubleValue() : 0.0,
                verifiedAmount != null ? verifiedAmount.doubleValue() : (amountPaid != null ? amountPaid.doubleValue() : 0.0),
                escapeHtml(utrNumber != null ? utrNumber : "N/A"),
                escapeHtml(verifiedBy != null ? verifiedBy : "Admin")
        );

        return sendTelegramPayload(messageText, referenceCode, "PaymentVerified");
    }

    @Async
    public CompletableFuture<Boolean> sendPaymentRejectedNotification(
            String referenceCode,
            String quoteNumber,
            String clientName,
            String utrNumber,
            String rejectionReason,
            String verifiedBy) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "⚠️ <b>PAYMENT PROOF REJECTED</b>%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<b>Order Ref:</b> <code>%s</code>%n" +
                "<b>Quote No:</b> <code>%s</code>%n" +
                "<b>Client:</b> %s%n" +
                "<b>UTR:</b> <code>%s</code>%n" +
                "<b>Reason:</b> %s%n" +
                "<b>Rejected By:</b> %s%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<i>Client has been alerted to re-submit proof. Status: PAYMENT_REJECTED</i>",
                escapeHtml(referenceCode),
                escapeHtml(quoteNumber != null ? quoteNumber : "N/A"),
                escapeHtml(clientName != null ? clientName : "Client"),
                escapeHtml(utrNumber != null ? utrNumber : "N/A"),
                escapeHtml(rejectionReason != null ? rejectionReason : "Verification failed"),
                escapeHtml(verifiedBy != null ? verifiedBy : "Admin")
        );

        return sendTelegramPayload(messageText, referenceCode, "PaymentRejected");
    }

    /**
     * SPRINT 4: Dispatches async Telegram operations alert when an admin releases
     * a PAYMENT_VERIFIED order to the Common Pool (transitions to PAID_INTAKE).
     */
    @Async
    public CompletableFuture<Boolean> sendPoolReleaseNotification(
            String referenceCode,
            String quoteNumber,
            String clientName,
            String serviceCategory,
            String reportNumber,
            String releasedBy) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] Pool release simulation for Ref: {} ReportNo: {}", referenceCode, reportNumber);
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "🟢 <b>ORDER RELEASED TO COMMON POOL</b>%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<b>Order Ref:</b> <code>%s</code>%n" +
                "<b>Quote No:</b> <code>%s</code>%n" +
                "<b>Report No:</b> <code>%s</code>%n" +
                "<b>Client:</b> %s%n" +
                "<b>Service:</b> %s%n" +
                "<b>Released By:</b> %s%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<i>Order is now visible in Common Pool and available for PA claim. Status: PAID_INTAKE</i>",
                escapeHtml(referenceCode),
                escapeHtml(quoteNumber != null ? quoteNumber : "N/A"),
                escapeHtml(reportNumber != null ? reportNumber : "N/A"),
                escapeHtml(clientName != null ? clientName : "Client"),
                escapeHtml(serviceCategory != null ? serviceCategory : "Valuation Report"),
                escapeHtml(releasedBy != null ? releasedBy : "Admin")
        );

        return sendTelegramPayload(messageText, referenceCode, "PoolRelease");
    }

    /**
     * SPRINT 5: Dispatches async Telegram operations alert when an inspection is scheduled.
     */
    @Async
    public CompletableFuture<Boolean> sendInspectionScheduledNotification(
            String referenceCode,
            String reportNumber,
            String clientName,
            String inspectionDate,
            String inspectionTime,
            String siteContact,
            String paName) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] Inspection scheduled simulation for Ref: {} Date: {} Time: {}", referenceCode, inspectionDate, inspectionTime);
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "📅 <b>SITE INSPECTION SCHEDULED</b>%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<b>Order Ref:</b> <code>%s</code>%n" +
                "<b>Report No:</b> <code>%s</code>%n" +
                "<b>Client:</b> %s%n" +
                "<b>Inspection Date:</b> <b>%s</b> at <b>%s</b>%n" +
                "<b>Site Contact:</b> %s%n" +
                "<b>Assigned PA:</b> %s%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<i>Status: INSPECTION_SCHEDULED</i>",
                escapeHtml(referenceCode),
                escapeHtml(reportNumber != null ? reportNumber : "N/A"),
                escapeHtml(clientName != null ? clientName : "Client"),
                escapeHtml(inspectionDate != null ? inspectionDate : "TBD"),
                escapeHtml(inspectionTime != null ? inspectionTime : "TBD"),
                escapeHtml(siteContact != null ? siteContact : "N/A"),
                escapeHtml(paName != null ? paName : "Assigned Analyst")
        );

        return sendTelegramPayload(messageText, referenceCode, "InspectionScheduled");
    }

    /**
     * SPRINT 5: Dispatches async Telegram operations alert when an inspection is rescheduled.
     */
    @Async
    public CompletableFuture<Boolean> sendInspectionRescheduledNotification(
            String referenceCode,
            String reportNumber,
            String newDate,
            String newTime,
            String reason,
            int rescheduleCount) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] Inspection rescheduled simulation for Ref: {} NewDate: {} Reason: {}", referenceCode, newDate, reason);
            return CompletableFuture.completedFuture(false);
        }

        String header = rescheduleCount >= 3 ? "🚨 <b>ESCALATION: INSPECTION RESCHEDULED (3+)</b>" : "🔄 <b>INSPECTION RESCHEDULED</b>";

        String messageText = String.format(
                "%s%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<b>Order Ref:</b> <code>%s</code>%n" +
                "<b>Report No:</b> <code>%s</code>%n" +
                "<b>New Schedule:</b> <b>%s</b> at <b>%s</b>%n" +
                "<b>Reschedule Count:</b> %d%n" +
                "<b>Reason:</b> %s%n" +
                "━━━━━━━━━━━━━━━━━━━━",
                header,
                escapeHtml(referenceCode),
                escapeHtml(reportNumber != null ? reportNumber : "N/A"),
                escapeHtml(newDate != null ? newDate : "TBD"),
                escapeHtml(newTime != null ? newTime : "TBD"),
                rescheduleCount,
                escapeHtml(reason != null ? reason : "Not specified")
        );

        return sendTelegramPayload(messageText, referenceCode, "InspectionRescheduled");
    }

    /**
     * SPRINT 5: Dispatches async Telegram operations alert when an inspection is marked completed.
     */
    @Async
    public CompletableFuture<Boolean> sendInspectionCompletedNotification(
            String referenceCode,
            String reportNumber,
            String clientName,
            int photoCount,
            String visitStatus,
            String paName) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] Inspection completed simulation for Ref: {} Photos: {} Status: {}", referenceCode, photoCount, visitStatus);
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "✅ <b>SITE INSPECTION COMPLETED</b>%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<b>Order Ref:</b> <code>%s</code>%n" +
                "<b>Report No:</b> <code>%s</code>%n" +
                "<b>Client:</b> %s%n" +
                "<b>Visit Outcome:</b> <b>%s</b>%n" +
                "<b>Photos Captured:</b> %d evidence photos%n" +
                "<b>Completed By:</b> %s%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<i>Order ready for Document Workspace phase. Status: INSPECTION_COMPLETED</i>",
                escapeHtml(referenceCode),
                escapeHtml(reportNumber != null ? reportNumber : "N/A"),
                escapeHtml(clientName != null ? clientName : "Client"),
                escapeHtml(visitStatus != null ? visitStatus : "COMPLETED"),
                photoCount,
                escapeHtml(paName != null ? paName : "Assigned Analyst")
        );

        return sendTelegramPayload(messageText, referenceCode, "InspectionCompleted");
    }

    /**
     * SPRINT 5: Dispatches async Telegram operations alert when order transitions to ACTION_NEEDED.
     */
    @Async
    public CompletableFuture<Boolean> sendActionNeededNotification(
            String referenceCode,
            String reportNumber,
            String reason,
            String description,
            String pausedBy) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] ACTION_NEEDED simulation for Ref: {} Reason: {}", referenceCode, reason);
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "⚠️ <b>BLOCKER REPORTED: ACTION NEEDED</b>%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<b>Order Ref:</b> <code>%s</code>%n" +
                "<b>Report No:</b> <code>%s</code>%n" +
                "<b>Reason Code:</b> <b>%s</b>%n" +
                "<b>Description:</b> %s%n" +
                "<b>Reported By:</b> %s%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<i>SLA clock is frozen. Status: ACTION_NEEDED</i>",
                escapeHtml(referenceCode),
                escapeHtml(reportNumber != null ? reportNumber : "N/A"),
                escapeHtml(reason != null ? reason : "N/A"),
                escapeHtml(description != null ? description : "N/A"),
                escapeHtml(pausedBy != null ? pausedBy : "User")
        );

        return sendTelegramPayload(messageText, referenceCode, "ActionNeeded");
    }

    /**
     * SPRINT 6: Telegram notification when valuation draft is submitted to SPA review queue.
     */
    @Async
    public CompletableFuture<Boolean> sendSpaReviewSubmissionNotification(
            String referenceCode,
            String reportNumber,
            String clientName,
            String paUsername) {

        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] Disabled or unconfigured. Skipping SPA review alert for Ref: {}", referenceCode);
            return CompletableFuture.completedFuture(false);
        }

        String messageText = String.format(
                "📝 <b>Valuation Report Draft Submitted for SPA Review</b>%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<b>Order Ref:</b> <code>%s</code>%n" +
                "<b>Report No:</b> <code>%s</code>%n" +
                "<b>Client:</b> %s%n" +
                "<b>Submitted By:</b> %s (PA)%n" +
                "<b>Status:</b> <b>SPA_GATE</b>%n" +
                "━━━━━━━━━━━━━━━━━━━━%n" +
                "<i>All mandatory validations satisfied. Draft is now locked in SPA review gate.</i>",
                escapeHtml(referenceCode),
                escapeHtml(reportNumber != null ? reportNumber : "N/A"),
                escapeHtml(clientName != null ? clientName : "N/A"),
                escapeHtml(paUsername != null ? paUsername : "Assigned PA")
        );

        return sendTelegramPayload(messageText, referenceCode, "SpaReviewSubmission");
    }

    private CompletableFuture<Boolean> sendTelegramPayload(String messageText, String referenceCode, String actionType) {
        int maxAttempts = 3;
        long backoffMs = 1000;

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                String endpoint = "https://api.telegram.org/bot" + botToken.trim() + "/sendMessage";
                Map<String, Object> payload = Map.of(
                        "chat_id", chatId.trim(),
                        "text", messageText,
                        "parse_mode", "HTML"
                );

                String jsonBody = objectMapper.writeValueAsString(payload);
                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(endpoint))
                        .timeout(Duration.ofSeconds(10))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString(jsonBody))
                        .build();

                HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
                if (response.statusCode() >= 200 && response.statusCode() < 300) {
                    log.info("[TELEGRAM NOTIFICATION] Successfully delivered {} alert for Ref: {} (HTTP {})", actionType, referenceCode, response.statusCode());
                    return CompletableFuture.completedFuture(true);
                } else {
                    log.warn("[TELEGRAM NOTIFICATION] {} Attempt {}/{} failed with HTTP {}: {}", actionType, attempt, maxAttempts, response.statusCode(), response.body());
                }
            } catch (Throwable t) {
                log.warn("[TELEGRAM NOTIFICATION] {} Attempt {}/{} encountered error: {}", actionType, attempt, maxAttempts, t.getMessage());
            }

            if (attempt < maxAttempts) {
                try {
                    Thread.sleep(backoffMs);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
                backoffMs *= 2;
            }
        }

        log.error("[TELEGRAM NOTIFICATION] All {} attempts exhausted for {} Ref: {}.", maxAttempts, actionType, referenceCode);
        return CompletableFuture.completedFuture(false);
    }

    /**
     * SPRINT 8: Dispatches async Telegram alert for commercial delivery package release.
     */
    @Async
    public CompletableFuture<Boolean> sendDeliveryNotification(String referenceCode, String clientName, String invoiceNumber) {
        if (!telegramEnabled || botToken == null || botToken.isBlank() || chatId == null || chatId.isBlank()) {
            log.info("[TELEGRAM NOTIFICATION] Delivery notification skipped (disabled or unconfigured) for Ref: {}", referenceCode);
            return CompletableFuture.completedFuture(false);
        }

        String message = String.format(
                "🚀 <b>COMMERCIAL DELIVERY RELEASED</b>%n%n" +
                "<b>Reference:</b> <code>%s</code>%n" +
                "<b>Client:</b> %s%n" +
                "<b>Tax Invoice:</b> <code>%s</code>%n" +
                "<b>Status:</b> <b>FINAL_DELIVERY</b>%n" +
                "<b>Package:</b> AES-256 Encrypted PDF + GST Tax Invoice%n%n" +
                "<i>Client download portal session active. Ephemeral tokens ready.</i>",
                escapeHtml(referenceCode),
                escapeHtml(clientName),
                escapeHtml(invoiceNumber)
        );

        return sendTelegramPayload(message, referenceCode, "Delivery Released");
    }

    private String escapeHtml(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
    }
}
