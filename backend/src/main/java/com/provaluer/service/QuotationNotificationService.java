package com.provaluer.service;

import com.provaluer.model.Order;
import com.provaluer.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;

@Service
public class QuotationNotificationService {

    private static final Logger log = LoggerFactory.getLogger(QuotationNotificationService.class);
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd-MMM-yyyy");

    @Autowired
    private TelegramNotificationService telegramNotificationService;

    /**
     * Dispatches multi-channel notifications upon quotation generation:
     * 1. Client Email Notification (formal quote notice with breakdown and attachment link)
     * 2. Portal Notification log (for real-time in-app dashboard badge)
     * 3. Internal Operations Telegram Alert
     */
    @Async
    public void notifyQuotationIssued(Order order, User client, User admin) {
        String clientEmail = (client != null && client.getEmail() != null) ? client.getEmail() : "N/A";
        String clientName = (client != null && client.getFullName() != null && !client.getFullName().isBlank())
                ? client.getFullName() : (client != null ? client.getUsername() : "Valued Client");
        String adminName = (admin != null && admin.getFullName() != null && !admin.getFullName().isBlank())
                ? admin.getFullName() : (admin != null ? admin.getUsername() : "Operations Admin");

        String quoteNumber = order.getQuoteNumber() != null ? order.getQuoteNumber() : "QTE-PENDING";
        String refCode = order.getReferenceCode() != null ? order.getReferenceCode() : ("ORDER-" + order.getId());
        BigDecimal total = order.getQuoteTotal() != null ? order.getQuoteTotal() : BigDecimal.ZERO;
        String turnaround = order.getQuoteTurnaround() != null ? order.getQuoteTurnaround() : "3-5 Working Days";
        String service = order.getServiceCategory() != null ? order.getServiceCategory() : "Valuation Report";
        String validUntil = order.getQuoteValidUntil() != null ? order.getQuoteValidUntil().format(DATE_FMT) : "15 Days";

        // 1. Client Email Notification
        log.info("[EMAIL NOTIFICATION] To: {}, Subject: Commercial Valuation Quotation Issued — Ref: {} (Quote: {})",
                clientEmail, refCode, quoteNumber);
        log.info("[EMAIL BODY] Dear {},\n" +
                        "Your quotation for valuation mandate '{}' (Ref: {}) is ready.\n" +
                        "Quote Number: {}\n" +
                        "Professional Fee: INR {}\n" +
                        "GST (18%): INR {}\n" +
                        "Total Payable: INR {}\n" +
                        "Turnaround Commitment: {}\n" +
                        "Valid Until: {}\n" +
                        "You can review your breakdown and download the official PDF quotation from your client portal.\n" +
                        "Best regards,\nProValuer Commercial Advisory LLP",
                clientName, service, refCode, quoteNumber,
                order.getQuoteAmount(), order.getQuoteTax(), total, turnaround, validUntil);

        // 2. Client In-App Portal Notification
        log.info("[PORTAL NOTIFICATION] Order #{}: New notification recorded for client #{}: 'Quotation {} issued for mandate {}'",
                order.getId(), order.getClientId(), quoteNumber, refCode);

        // 3. Internal Operations Telegram Alert
        try {
            telegramNotificationService.sendQuotationIssuedNotification(
                    refCode,
                    quoteNumber,
                    clientName,
                    service,
                    total.toPlainString(),
                    turnaround,
                    adminName
            );
        } catch (Exception e) {
            log.warn("Failed to dispatch internal Telegram quote alert for {}: {}", quoteNumber, e.getMessage());
        }
    }
}
