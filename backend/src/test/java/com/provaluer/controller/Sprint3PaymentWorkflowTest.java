package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.RejectPaymentRequest;
import com.provaluer.dto.VerifyPaymentRequest;
import com.provaluer.model.*;
import com.provaluer.repository.OrderPaymentRepository;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.PaymentNotificationService;
import com.provaluer.service.TelegramNotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
public class Sprint3PaymentWorkflowTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderPaymentRepository orderPaymentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @SpyBean
    private PaymentNotificationService paymentNotificationService;

    @SpyBean
    private TelegramNotificationService telegramNotificationService;

    private User clientA;
    private User clientB;
    private User adminUser;
    private User paUser;

    private UsernamePasswordAuthenticationToken authClientA;
    private UsernamePasswordAuthenticationToken authClientB;
    private UsernamePasswordAuthenticationToken authAdmin;
    private UsernamePasswordAuthenticationToken authPa;

    private Order orderQuoteProvided;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();

        // Client A (Owner)
        clientA = userRepository.findByUsernameIgnoreCase("client_a_s3").orElseGet(() -> {
            User u = new User("client_a_s3", "client_a_s3@test.com", "pass123", UserRole.CLIENT, "9876543301", "v1.0");
            u.setFullName("Alice Client S3");
            return userRepository.save(u);
        });
        UserDetailsImpl principalA = UserDetailsImpl.build(clientA);
        authClientA = new UsernamePasswordAuthenticationToken(principalA, null, principalA.getAuthorities());

        // Client B (Non-Owner Attacker)
        clientB = userRepository.findByUsernameIgnoreCase("client_b_s3").orElseGet(() -> {
            User u = new User("client_b_s3", "client_b_s3@test.com", "pass123", UserRole.CLIENT, "9876543302", "v1.0");
            u.setFullName("Bob Client S3");
            return userRepository.save(u);
        });
        UserDetailsImpl principalB = UserDetailsImpl.build(clientB);
        authClientB = new UsernamePasswordAuthenticationToken(principalB, null, principalB.getAuthorities());

        // Admin User
        adminUser = userRepository.findByUsernameIgnoreCase("admin_usr_s3").orElseGet(() -> {
            User u = new User("admin_usr_s3", "admin_usr_s3@test.com", "pass123", UserRole.ADMIN, "9876543303", "v1.0");
            u.setFullName("Admin Compliance Officer");
            return userRepository.save(u);
        });
        UserDetailsImpl principalAdmin = UserDetailsImpl.build(adminUser);
        authAdmin = new UsernamePasswordAuthenticationToken(principalAdmin, null, principalAdmin.getAuthorities());

        // PA User (Valuer)
        paUser = userRepository.findByUsernameIgnoreCase("pa_usr_s3").orElseGet(() -> {
            User u = new User("pa_usr_s3", "pa_usr_s3@test.com", "pass123", UserRole.PA, "9876543304", "v1.0");
            u.setFullName("Field Valuer PA");
            return userRepository.save(u);
        });
        UserDetailsImpl principalPa = UserDetailsImpl.build(paUser);
        authPa = new UsernamePasswordAuthenticationToken(principalPa, null, principalPa.getAuthorities());

        // Create Order in QUOTE_PROVIDED status
        orderQuoteProvided = new Order();
        orderQuoteProvided.setClientId(clientA.getId());
        orderQuoteProvided.setServiceCategory("Valuation Report");
        orderQuoteProvided.setPropertyCategory("Land & Building");
        orderQuoteProvided.setPurpose("Bank Collateral / Loan");
        orderQuoteProvided.setEstimatedValue(new BigDecimal("5000000.00"));
        orderQuoteProvided.setStatus("QUOTE_PROVIDED");
        orderQuoteProvided.setPaymentStatus("PENDING");
        orderQuoteProvided.setReferenceCode("REQ-2026-" + System.nanoTime());
        orderQuoteProvided.setQuoteNumber("QTE-2026-" + System.nanoTime());
        orderQuoteProvided.setQuoteAmount(new BigDecimal("15000.00"));
        orderQuoteProvided.setQuoteTax(new BigDecimal("2700.00"));
        orderQuoteProvided.setQuoteTotal(new BigDecimal("17700.00"));
        orderQuoteProvided.setQuoteTurnaround("3-5 Working Days");
        orderQuoteProvided.setQuoteValidUntil(LocalDateTime.now().plusDays(15));
        orderQuoteProvided.setQuotedBy(adminUser.getId());
        orderQuoteProvided.setQuotedAt(LocalDateTime.now().minusDays(1));
        orderQuoteProvided = orderRepository.save(orderQuoteProvided);
    }

    private MockMultipartFile createValidPdfReceipt() {
        byte[] pdfMagic = new byte[]{0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34}; // %PDF-1.4
        return new MockMultipartFile("file", "bank_receipt.pdf", "application/pdf", pdfMagic);
    }

    @Test
    @DisplayName("1. Client Owner can submit payment proof on order in QUOTE_PROVIDED status")
    void testClientOwnerSubmitPaymentSuccess() throws Exception {
        MockMultipartFile file = createValidPdfReceipt();
        String uniqueUtr = "UTR" + System.currentTimeMillis();

        mockMvc.perform(multipart("/api/v1/orders/" + orderQuoteProvided.getId() + "/submit-payment")
                        .file(file)
                        .param("utrNumber", uniqueUtr)
                        .param("paymentMethod", "NEFT")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .param("notes", "Paid from HDFC Current Account")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUBMITTED"))
                .andExpect(jsonPath("$.utrNumber").value(uniqueUtr.toUpperCase()))
                .andExpect(jsonPath("$.amountPaid").value(17700.00));

        Order updated = orderRepository.findById(orderQuoteProvided.getId()).orElseThrow();
        assertEquals("PAYMENT_SUBMITTED", updated.getStatus());
        assertEquals("SUBMITTED", updated.getPaymentStatus());
        assertNotNull(updated.getLatestPaymentId());

        verify(paymentNotificationService, Mockito.timeout(3000))
                .notifyPaymentSubmitted(any(Order.class), any(OrderPayment.class), any());
    }

    @Test
    @DisplayName("2. Non-owner Client B receives 403 Forbidden when attempting payment submission")
    void testNonOwnerSubmitPaymentForbidden() throws Exception {
        MockMultipartFile file = createValidPdfReceipt();

        mockMvc.perform(multipart("/api/v1/orders/" + orderQuoteProvided.getId() + "/submit-payment")
                        .file(file)
                        .param("utrNumber", "ATTACKER12345")
                        .param("paymentMethod", "UPI")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .with(authentication(authClientB)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("3. Submitting payment on invalid order state returns 409 Conflict")
    void testSubmitPaymentInvalidStateConflict() throws Exception {
        Order draftOrder = new Order();
        draftOrder.setClientId(clientA.getId());
        draftOrder.setServiceCategory("Valuation Report");
        draftOrder.setPropertyCategory("Land & Building");
        draftOrder.setPurpose("Bank Collateral / Loan");
        draftOrder.setEstimatedValue(new BigDecimal("5000000.00"));
        draftOrder.setStatus("QUOTE_PENDING");
        draftOrder = orderRepository.save(draftOrder);

        MockMultipartFile file = createValidPdfReceipt();

        mockMvc.perform(multipart("/api/v1/orders/" + draftOrder.getId() + "/submit-payment")
                        .file(file)
                        .param("utrNumber", "UTRINVALID001")
                        .param("paymentMethod", "IMPS")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "1000.00")
                        .with(authentication(authClientA)))
                .andExpect(status().isConflict());
    }

    @Test
    @DisplayName("4. Duplicate active UTR returns 409 Conflict")
    void testDuplicateUtrConflict() throws Exception {
        String utr = "UTRDUP" + System.currentTimeMillis();

        // First submission succeeds
        mockMvc.perform(multipart("/api/v1/orders/" + orderQuoteProvided.getId() + "/submit-payment")
                        .file(createValidPdfReceipt())
                        .param("utrNumber", utr)
                        .param("paymentMethod", "RTGS")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk());

        // Create second order for Client A
        Order secondOrder = new Order();
        secondOrder.setClientId(clientA.getId());
        secondOrder.setServiceCategory("Valuation Report");
        secondOrder.setPropertyCategory("Land & Building");
        secondOrder.setPurpose("Bank Collateral / Loan");
        secondOrder.setEstimatedValue(new BigDecimal("5000000.00"));
        secondOrder.setStatus("QUOTE_PROVIDED");
        secondOrder = orderRepository.save(secondOrder);

        // Attempt using same UTR -> 409 Conflict
        mockMvc.perform(multipart("/api/v1/orders/" + secondOrder.getId() + "/submit-payment")
                        .file(createValidPdfReceipt())
                        .param("utrNumber", utr.toLowerCase()) // Case-insensitive test
                        .param("paymentMethod", "RTGS")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .with(authentication(authClientA)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value(org.hamcrest.Matchers.containsString("already been claimed")));
    }

    @Test
    @DisplayName("5. Admin verifies submitted payment -> transitions to PAYMENT_VERIFIED and stops pipeline")
    void testAdminVerifyPaymentSuccess() throws Exception {
        String utr = "UTRVFY" + System.currentTimeMillis();

        // Client submits
        mockMvc.perform(multipart("/api/v1/orders/" + orderQuoteProvided.getId() + "/submit-payment")
                        .file(createValidPdfReceipt())
                        .param("utrNumber", utr)
                        .param("paymentMethod", "NEFT")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk());

        // Admin verifies with verifiedAmount
        VerifyPaymentRequest vReq = new VerifyPaymentRequest();
        vReq.setVerifiedAmount(new BigDecimal("17700.00"));
        vReq.setAdminNotes("Confirmed in HDFC Current A/c bank statement");

        mockMvc.perform(post("/api/v1/orders/" + orderQuoteProvided.getId() + "/verify-payment")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(vReq))
                        .with(authentication(authAdmin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("VERIFIED"))
                .andExpect(jsonPath("$.verifiedAmount").value(17700.00))
                .andExpect(jsonPath("$.verifiedBy").value(adminUser.getEmail()));

        Order verifiedOrder = orderRepository.findById(orderQuoteProvided.getId()).orElseThrow();
        assertEquals("PAYMENT_VERIFIED", verifiedOrder.getStatus());
        assertEquals("VERIFIED", verifiedOrder.getPaymentStatus());

        // STOP CONDITION VERIFICATION: Status must NOT be PAID_INTAKE or ASSIGNED
        assertNotEquals("PAID_INTAKE", verifiedOrder.getStatus());
        assertNull(verifiedOrder.getPaId());

        verify(paymentNotificationService, Mockito.timeout(3000))
                .notifyPaymentVerified(any(Order.class), any(OrderPayment.class), any(), anyString());
    }

    @Test
    @DisplayName("6. Non-admin receives 403 Forbidden when attempting payment verification")
    void testNonAdminVerifyPaymentForbidden() throws Exception {
        mockMvc.perform(post("/api/v1/orders/" + orderQuoteProvided.getId() + "/verify-payment")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}")
                        .with(authentication(authClientA)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("7. Admin rejects submitted payment -> transitions to PAYMENT_REJECTED and client can re-submit")
    void testAdminRejectAndClientResubmit() throws Exception {
        String utr = "UTRREJ" + System.currentTimeMillis();

        // 1. Submit
        mockMvc.perform(multipart("/api/v1/orders/" + orderQuoteProvided.getId() + "/submit-payment")
                        .file(createValidPdfReceipt())
                        .param("utrNumber", utr)
                        .param("paymentMethod", "UPI")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk());

        // 2. Reject
        RejectPaymentRequest rReq = new RejectPaymentRequest();
        rReq.setRejectionReason("FUNDS_NOT_RECEIVED");
        rReq.setAdminNotes("UTR not reflecting in bank statement after 24h clearance cycle");

        mockMvc.perform(post("/api/v1/orders/" + orderQuoteProvided.getId() + "/reject-payment")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(rReq))
                        .with(authentication(authAdmin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"))
                .andExpect(jsonPath("$.rejectionReason").value("FUNDS_NOT_RECEIVED"));

        Order rejectedOrder = orderRepository.findById(orderQuoteProvided.getId()).orElseThrow();
        assertEquals("PAYMENT_REJECTED", rejectedOrder.getStatus());

        // 3. Client Re-submits with new UTR -> allowed on PAYMENT_REJECTED status!
        String newUtr = "UTRNEW" + System.currentTimeMillis();
        mockMvc.perform(multipart("/api/v1/orders/" + orderQuoteProvided.getId() + "/submit-payment")
                        .file(createValidPdfReceipt())
                        .param("utrNumber", newUtr)
                        .param("paymentMethod", "IMPS")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUBMITTED"));

        Order resubmitted = orderRepository.findById(orderQuoteProvided.getId()).orElseThrow();
        assertEquals("PAYMENT_SUBMITTED", resubmitted.getStatus());
    }

    @Test
    @DisplayName("8. Immutable verified payments: once verified, further submissions are blocked (409 Conflict)")
    void testImmutableVerifiedPaymentBlocked() throws Exception {
        String utr = "UTRLOCK" + System.currentTimeMillis();

        // Submit & Verify
        mockMvc.perform(multipart("/api/v1/orders/" + orderQuoteProvided.getId() + "/submit-payment")
                        .file(createValidPdfReceipt())
                        .param("utrNumber", utr)
                        .param("paymentMethod", "BANK_TRANSFER")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/orders/" + orderQuoteProvided.getId() + "/verify-payment")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}")
                        .with(authentication(authAdmin)))
                .andExpect(status().isOk());

        // Attempt another submission -> 409 Conflict
        mockMvc.perform(multipart("/api/v1/orders/" + orderQuoteProvided.getId() + "/submit-payment")
                        .file(createValidPdfReceipt())
                        .param("utrNumber", "UTRLOCKED_AGAIN")
                        .param("paymentMethod", "UPI")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .with(authentication(authClientA)))
                .andExpect(status().isConflict());
    }

    @Test
    @DisplayName("9. PA / SPA valuers are explicitly denied access to PAYMENT_PROOF documents")
    void testPaDeniedPaymentProofAccess() throws Exception {
        String utr = "UTRSEC" + System.currentTimeMillis();

        mockMvc.perform(multipart("/api/v1/orders/" + orderQuoteProvided.getId() + "/submit-payment")
                        .file(createValidPdfReceipt())
                        .param("utrNumber", utr)
                        .param("paymentMethod", "UPI")
                        .param("paymentDate", LocalDate.now().toString())
                        .param("amountPaid", "17700.00")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk());

        OrderPayment p = orderPaymentRepository.findTopByOrderIdOrderBySubmittedAtDesc(orderQuoteProvided.getId()).orElseThrow();
        Long receiptDocId = p.getReceiptDocumentId();
        assertNotNull(receiptDocId);

        // PA attempts download -> 403 Forbidden
        mockMvc.perform(get("/api/v1/orders/documents/" + receiptDocId + "/download")
                        .with(authentication(authPa)))
                .andExpect(status().isForbidden());

        // Client Owner attempts download -> 200 OK
        mockMvc.perform(get("/api/v1/orders/documents/" + receiptDocId + "/download")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk());

        // Admin attempts download -> 200 OK
        mockMvc.perform(get("/api/v1/orders/documents/" + receiptDocId + "/download")
                        .with(authentication(authAdmin)))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("10. GET /payment-details returns configured bank/UPI particulars and payment records")
    void testGetPaymentDetailsSuccess() throws Exception {
        mockMvc.perform(get("/api/v1/orders/" + orderQuoteProvided.getId() + "/payment-details")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderId").value(orderQuoteProvided.getId()))
                .andExpect(jsonPath("$.quoteTotal").value(17700.00))
                .andExpect(jsonPath("$.bankDetails.beneficiaryName").isNotEmpty())
                .andExpect(jsonPath("$.bankDetails.accountNumber").isNotEmpty())
                .andExpect(jsonPath("$.bankDetails.ifsc").isNotEmpty())
                .andExpect(jsonPath("$.bankDetails.upiId").isNotEmpty())
                .andExpect(jsonPath("$.bankDetails.upiQrString").isNotEmpty());
    }
}
