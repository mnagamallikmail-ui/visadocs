package com.provaluer.service;

import com.provaluer.model.Order;
import com.provaluer.model.OrderPayment;
import com.provaluer.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;

@Service
public class PaymentNotificationService {

    private static final Logger log = LoggerFactory.getLogger(PaymentNotificationService.class);

    @Autowired
    private TelegramNotificationService telegramService;

    @Async
    public void notifyPaymentSubmitted(Order order, OrderPayment payment, User client) {
        log.info("[PAYMENT NOTIFICATION] Processing submission alerts for orderId={} refCode={} utr={}",
                order.getId(), order.getReferenceCode(), payment.getUtrNumber());

        // 1. Internal Telegram alert
        BigDecimal amountPaid = payment.getAmountPaid();
        LocalDate paymentDate = payment.getPaymentDate();
        telegramService.sendPaymentSubmittedNotification(
                order.getReferenceCode(),
                order.getQuoteNumber(),
                client != null ? (client.getFullName() != null ? client.getFullName() : client.getUsername()) : "Client",
                client != null ? client.getEmail() : "N/A",
                amountPaid,
                payment.getPaymentMethod(),
                payment.getUtrNumber(),
                paymentDate
        );

        // 2. Client transactional email & portal toast simulated delivery
        log.info("[CLIENT EMAIL SENT] To: {} | Subject: Payment Proof Received: {} [Ref: {}] | Amount: INR {}",
                client != null ? client.getEmail() : "N/A",
                payment.getQuoteNumber(),
                order.getReferenceCode(),
                amountPaid);
    }

    @Async
    public void notifyPaymentVerified(Order order, OrderPayment payment, User client, String verifiedBy) {
        log.info("[PAYMENT NOTIFICATION] Processing verification alerts for orderId={} refCode={} utr={}",
                order.getId(), order.getReferenceCode(), payment.getUtrNumber());

        // 1. Internal Telegram alert
        BigDecimal amountPaid = payment.getAmountPaid();
        BigDecimal verifiedAmount = payment.getVerifiedAmount();
        telegramService.sendPaymentVerifiedNotification(
                order.getReferenceCode(),
                order.getQuoteNumber(),
                client != null ? (client.getFullName() != null ? client.getFullName() : client.getUsername()) : "Client",
                amountPaid,
                verifiedAmount,
                payment.getUtrNumber(),
                verifiedBy
        );

        // 2. Client transactional email
        log.info("[CLIENT EMAIL SENT] To: {} | Subject: Payment Verified & Confirmed: {} [Ref: {}] | Verified Amount: INR {}",
                client != null ? client.getEmail() : "N/A",
                payment.getQuoteNumber(),
                order.getReferenceCode(),
                payment.getVerifiedAmount());
    }

    @Async
    public void notifyPaymentRejected(Order order, OrderPayment payment, User client, String rejectionReason, String verifiedBy) {
        log.info("[PAYMENT NOTIFICATION] Processing rejection alerts for orderId={} refCode={} utr={}",
                order.getId(), order.getReferenceCode(), payment.getUtrNumber());

        // 1. Internal Telegram alert
        telegramService.sendPaymentRejectedNotification(
                order.getReferenceCode(),
                order.getQuoteNumber(),
                client != null ? (client.getFullName() != null ? client.getFullName() : client.getUsername()) : "Client",
                payment.getUtrNumber(),
                rejectionReason,
                verifiedBy
        );

        // 2. Client transactional email
        log.info("[CLIENT EMAIL SENT] To: {} | Subject: Action Required: Payment Proof Rejected [Ref: {}] | Reason: {}",
                client != null ? client.getEmail() : "N/A",
                order.getReferenceCode(),
                rejectionReason);
    }
}
