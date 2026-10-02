package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.ProvideQuoteRequest;
import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.QuotationNotificationService;
import com.provaluer.service.TelegramNotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.math.BigDecimal;

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
public class Sprint2QuotationWorkflowTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @SpyBean
    private QuotationNotificationService quotationNotificationService;

    @SpyBean
    private TelegramNotificationService telegramNotificationService;

    private User clientA;
    private User clientB;
    private User adminUser;

    private UsernamePasswordAuthenticationToken authClientA;
    private UsernamePasswordAuthenticationToken authClientB;
    private UsernamePasswordAuthenticationToken authAdmin;

    private Order orderQuotePending;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();

        // Client A (Owner)
        clientA = userRepository.findByUsernameIgnoreCase("client_a_s2").orElseGet(() -> {
            User u = new User("client_a_s2", "client_a_s2@test.com", "pass123", UserRole.CLIENT, "9876543211", "v1.0");
            u.setFullName("Alice Client S2");
            return userRepository.save(u);
        });
        UserDetailsImpl principalA = UserDetailsImpl.build(clientA);
        authClientA = new UsernamePasswordAuthenticationToken(principalA, null, principalA.getAuthorities());

        // Client B (Non-Owner / Attacker)
        clientB = userRepository.findByUsernameIgnoreCase("client_b_s2").orElseGet(() -> {
            User u = new User("client_b_s2", "client_b_s2@test.com", "pass123", UserRole.CLIENT, "9876543212", "v1.0");
            u.setFullName("Bob Client S2");
            return userRepository.save(u);
        });
        UserDetailsImpl principalB = UserDetailsImpl.build(clientB);
        authClientB = new UsernamePasswordAuthenticationToken(principalB, null, principalB.getAuthorities());

        // Admin User
        adminUser = userRepository.findByUsernameIgnoreCase("admin_usr_s2").orElseGet(() -> {
            User u = new User("admin_usr_s2", "admin_usr_s2@test.com", "pass123", UserRole.ADMIN, "9876543213", "v1.0");
            u.setFullName("Admin Operations Officer");
            return userRepository.save(u);
        });
        UserDetailsImpl principalAdmin = UserDetailsImpl.build(adminUser);
        authAdmin = new UsernamePasswordAuthenticationToken(principalAdmin, null, principalAdmin.getAuthorities());

        // Clean up previous test orders for clientA if any
        orderRepository.findAllByClientId(clientA.getId()).forEach(o -> {
            orderDocumentRepository.findAllByOrderId(o.getId()).forEach(orderDocumentRepository::delete);
            orderRepository.delete(o);
        });

        // Create Order in QUOTE_PENDING status
        orderQuotePending = new Order();
        orderQuotePending.setClientId(clientA.getId());
        orderQuotePending.setReferenceCode("REQ-2026-9021");
        orderQuotePending.setServiceCategory("Valuation Report");
        orderQuotePending.setPropertyCategory("Land & Building");
        orderQuotePending.setPurpose("Bank Collateral / Loan");
        orderQuotePending.setStatus("QUOTE_PENDING");
        orderQuotePending = orderRepository.save(orderQuotePending);
    }

    @Test
    @DisplayName("Sprint 2: Admin successfully provides quotation (QUOTE_PENDING -> QUOTE_PROVIDED)")
    void testAdminCanProvideQuoteSuccessfully() throws Exception {
        ProvideQuoteRequest request = new ProvideQuoteRequest();
        request.setQuoteAmount(BigDecimal.valueOf(15000.00));
        request.setGstRate(BigDecimal.valueOf(18.00));
        request.setTurnaroundTime("3-5 Working Days");
        request.setScopeNotes("Physical site inspection and market valuation for industrial plot and shed.");
        request.setTermsConditions("Payment milestones disclosure. Quote valid for 15 days.");
        request.setValidityDays(15);

        mockMvc.perform(post("/api/v1/orders/" + orderQuotePending.getId() + "/provide-quote")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .with(authentication(authAdmin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("QUOTE_PROVIDED"))
                .andExpect(jsonPath("$.quoteNumber").exists())
                .andExpect(jsonPath("$.quoteAmount").value(15000.0))
                .andExpect(jsonPath("$.quoteTax").value(2700.0))
                .andExpect(jsonPath("$.quoteTotal").value(17700.0))
                .andExpect(jsonPath("$.turnaroundTime").value("3-5 Working Days"));

        // Verify order in database
        Order updated = orderRepository.findById(orderQuotePending.getId()).orElseThrow();
        assertEquals("QUOTE_PROVIDED", updated.getStatus());
        assertNotNull(updated.getQuoteNumber());
        assertTrue(updated.getQuoteNumber().startsWith("QTE-"));
        assertEquals(new BigDecimal("15000.00"), updated.getQuoteAmount());

        // Verify multi-channel notification was called (with timeout for async execution)
        verify(quotationNotificationService, org.mockito.Mockito.timeout(3000).times(1)).notifyQuotationIssued(any(), any(), any());
    }

    @Test
    @DisplayName("Sprint 2: State Guard rejects quote creation if status is not QUOTE_PENDING (409 Conflict)")
    void testProvideQuoteStateGuard_RejectsNonQuotePendingStatus() throws Exception {
        // Change order status to DRAFT
        orderQuotePending.setStatus("DRAFT");
        orderRepository.save(orderQuotePending);

        ProvideQuoteRequest request = new ProvideQuoteRequest();
        request.setQuoteAmount(BigDecimal.valueOf(15000.00));
        request.setTurnaroundTime("3-5 Working Days");
        request.setScopeNotes("Scope notes");

        mockMvc.perform(post("/api/v1/orders/" + orderQuotePending.getId() + "/provide-quote")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .with(authentication(authAdmin)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").exists());
    }

    @Test
    @DisplayName("Sprint 2: Non-admin client is forbidden from issuing quote (403 Forbidden)")
    void testClientCannotProvideQuote() throws Exception {
        ProvideQuoteRequest request = new ProvideQuoteRequest();
        request.setQuoteAmount(BigDecimal.valueOf(10000.00));
        request.setTurnaroundTime("3-5 Days");
        request.setScopeNotes("Notes");

        mockMvc.perform(post("/api/v1/orders/" + orderQuotePending.getId() + "/provide-quote")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .with(authentication(authClientA)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Sprint 2: Owner client can view quotation details (200 OK)")
    void testOwnerClientCanViewQuote() throws Exception {
        // First issue quote as admin
        orderQuotePending.setQuoteNumber("QTE-2026-9021");
        orderQuotePending.setQuoteAmount(new BigDecimal("20000.00"));
        orderQuotePending.setQuoteTax(new BigDecimal("3600.00"));
        orderQuotePending.setQuoteTotal(new BigDecimal("23600.00"));
        orderQuotePending.setQuoteTurnaround("2-4 Days");
        orderQuotePending.setQuoteNotes("Complete valuation scope");
        orderQuotePending.setStatus("QUOTE_PROVIDED");
        orderRepository.save(orderQuotePending);

        // Owner client views quote
        mockMvc.perform(get("/api/v1/orders/" + orderQuotePending.getId() + "/quote")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quoteNumber").value("QTE-2026-9021"))
                .andExpect(jsonPath("$.quoteTotal").value(23600.0))
                .andExpect(jsonPath("$.status").value("QUOTE_PROVIDED"));
    }

    @Test
    @DisplayName("Sprint 2: Non-owner client is forbidden from viewing quote (403 Forbidden)")
    void testNonOwnerClientForbiddenFromViewingQuote() throws Exception {
        orderQuotePending.setQuoteNumber("QTE-2026-9021");
        orderQuotePending.setQuoteAmount(new BigDecimal("20000.00"));
        orderQuotePending.setStatus("QUOTE_PROVIDED");
        orderRepository.save(orderQuotePending);

        // Client B tries to view Client A's quote
        mockMvc.perform(get("/api/v1/orders/" + orderQuotePending.getId() + "/quote")
                        .with(authentication(authClientB)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").exists());
    }

    @Test
    @DisplayName("Sprint 2: Owner client can download Quote PDF with valid PDF binary signature (200 OK)")
    void testOwnerClientCanDownloadQuotePdf() throws Exception {
        orderQuotePending.setQuoteNumber("QTE-2026-9021");
        orderQuotePending.setQuoteAmount(new BigDecimal("15000.00"));
        orderQuotePending.setQuoteTax(new BigDecimal("2700.00"));
        orderQuotePending.setQuoteTotal(new BigDecimal("17700.00"));
        orderQuotePending.setQuoteTurnaround("3-5 Working Days");
        orderQuotePending.setQuoteNotes("Commercial land and building valuation.");
        orderQuotePending.setStatus("QUOTE_PROVIDED");
        orderRepository.save(orderQuotePending);

        MvcResult result = mockMvc.perform(get("/api/v1/orders/" + orderQuotePending.getId() + "/quote-pdf")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(header().string("Content-Type", "application/pdf"))
                .andExpect(header().string("Content-Disposition", org.hamcrest.Matchers.containsString("Quotation_QTE-2026-9021.pdf")))
                .andReturn();

        byte[] pdfBytes = result.getResponse().getContentAsByteArray();
        assertNotNull(pdfBytes);
        assertTrue(pdfBytes.length > 100);

        // Verify %PDF- magic bytes signature
        assertEquals(0x25, pdfBytes[0]); // %
        assertEquals(0x50, pdfBytes[1]); // P
        assertEquals(0x44, pdfBytes[2]); // D
        assertEquals(0x46, pdfBytes[3]); // F
    }

    @Test
    @DisplayName("Sprint 2: Non-owner client is forbidden from downloading Quote PDF (403 Forbidden)")
    void testNonOwnerClientForbiddenFromDownloadingQuotePdf() throws Exception {
        orderQuotePending.setQuoteNumber("QTE-2026-9021");
        orderQuotePending.setQuoteAmount(new BigDecimal("15000.00"));
        orderQuotePending.setStatus("QUOTE_PROVIDED");
        orderRepository.save(orderQuotePending);

        mockMvc.perform(get("/api/v1/orders/" + orderQuotePending.getId() + "/quote-pdf")
                        .with(authentication(authClientB)))
                .andExpect(status().isForbidden());
    }
}
