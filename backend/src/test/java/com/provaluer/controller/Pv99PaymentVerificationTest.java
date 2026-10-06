package com.provaluer.controller;

import com.provaluer.model.*;
import com.provaluer.repository.OrderDocumentRepository;
import com.provaluer.repository.OrderPaymentRepository;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.UserDetailsImpl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class Pv99PaymentVerificationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderPaymentRepository orderPaymentRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @Test
    @DisplayName("Verify Scenario C: PV-99 Valid receipt submission transitions order to PAYMENT_SUBMITTED with doc & payment persisted")
    void testPv99PaymentSubmissionAndVerification() throws Exception {
        Order pv99 = orderRepository.findById(99L).orElseGet(() -> {
            Order o = new Order();
            o.setId(99L);
            o.setReferenceCode("PV-99");
            o.setServiceCategory("Valuation Report");
            o.setPropertyCategory("Land & Building");
            o.setPurpose("Bank Collateral / Loan");
            o.setStatus("QUOTE_PROVIDED");
            o.setQuoteNumber("QTE-2026-9163");
            o.setQuoteAmount(new BigDecimal("10000.00"));
            o.setQuoteTax(new BigDecimal("1800.00"));
            o.setQuoteTotal(new BigDecimal("11800.00"));
            return orderRepository.save(o);
        });

        // Ensure order is in QUOTE_PROVIDED state
        pv99.setStatus("QUOTE_PROVIDED");
        pv99.setPaymentStatus("PENDING");
        pv99 = orderRepository.save(pv99);

        // Fetch or create client user Naga Client
        Long clientId = pv99.getClientId() != null ? pv99.getClientId() : 4L;
        User clientUser = userRepository.findById(clientId).orElseGet(() -> {
            User u = new User("nagaclient", "naga@provaluer.com", "pass123", UserRole.CLIENT, "9876543210", "v1.0");
            u.setFullName("Naga Client");
            return userRepository.save(u);
        });
        pv99.setClientId(clientUser.getId());
        pv99 = orderRepository.save(pv99);

        UserDetailsImpl clientPrincipal = UserDetailsImpl.build(clientUser);
        UsernamePasswordAuthenticationToken clientAuth =
                new UsernamePasswordAuthenticationToken(clientPrincipal, null, clientPrincipal.getAuthorities());

        // Valid PDF receipt with %PDF-1.4 magic bytes
        byte[] validPdfBytes = new byte[]{0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34, 0x0A, 0x25, (byte) 0xE2, (byte) 0xE3, (byte) 0xCF, (byte) 0xD3};
        MockMultipartFile receiptFile = new MockMultipartFile(
                "file",
                "payment_receipt_pv99.pdf",
                "application/pdf",
                validPdfBytes
        );

        String utr = "UTR" + System.currentTimeMillis();

        // Perform Submit Payment
        mockMvc.perform(multipart("/api/v1/orders/99/submit-payment")
                        .file(receiptFile)
                        .param("utrNumber", utr)
                        .param("paymentMethod", "UPI")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "11800.00")
                        .param("notes", "Payment transferred via UPI for PV-99 quote QTE-2026-9163")
                        .with(authentication(clientAuth)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUBMITTED"))
                .andExpect(jsonPath("$.utrNumber").value(utr.toUpperCase()))
                .andExpect(jsonPath("$.amountPaid").value(11800.00));

        // 1. Verify order status changed to PAYMENT_SUBMITTED
        Order updatedOrder = orderRepository.findById(99L).orElseThrow();
        assertEquals("PAYMENT_SUBMITTED", updatedOrder.getStatus());
        assertEquals("SUBMITTED", updatedOrder.getPaymentStatus());
        assertNotNull(updatedOrder.getLatestPaymentId());

        // 2. Verify order_payments record exists
        OrderPayment paymentRecord = orderPaymentRepository.findById(updatedOrder.getLatestPaymentId()).orElseThrow();
        assertEquals(99L, paymentRecord.getOrderId());
        assertEquals(utr.toUpperCase(), paymentRecord.getUtrNumber());
        assertEquals(new BigDecimal("11800.00"), paymentRecord.getAmountPaid());
        assertEquals("SUBMITTED", paymentRecord.getStatus());
        assertEquals("UPI", paymentRecord.getPaymentMethod());

        // 3. Verify PAYMENT_PROOF document exists
        List<OrderDocument> docs = orderDocumentRepository.findAllByOrderId(99L);
        boolean proofFound = docs.stream().anyMatch(d -> "PAYMENT_PROOF".equals(d.getCategory()) && "payment_receipt_pv99.pdf".equals(d.getFilename()));
        assertTrue(proofFound, "PAYMENT_PROOF document must exist for order 99");

        System.out.println("=== PV-99 POST-SUBMISSION VERIFICATION SUCCESSFUL ===");
        System.out.println("Order ID: " + updatedOrder.getId());
        System.out.println("Reference Code: " + updatedOrder.getReferenceCode());
        System.out.println("Status: " + updatedOrder.getStatus());
        System.out.println("Payment Status: " + updatedOrder.getPaymentStatus());
        System.out.println("UTR Number: " + paymentRecord.getUtrNumber());
        System.out.println("Amount Paid: " + paymentRecord.getAmountPaid());
        System.out.println("Receipt Document ID: " + paymentRecord.getReceiptDocumentId());
        System.out.println("=====================================================");
    }
}
