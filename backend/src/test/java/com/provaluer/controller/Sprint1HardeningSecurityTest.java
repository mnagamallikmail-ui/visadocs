package com.provaluer.controller;

import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.TelegramNotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

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
public class Sprint1HardeningSecurityTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderDocumentRepository orderDocumentRepository;

    @Autowired
    private UserRepository userRepository;

    @SpyBean
    private TelegramNotificationService telegramNotificationService;

    private User clientA;
    private User clientB;
    private User adminUser;

    private UsernamePasswordAuthenticationToken authClientA;
    private UsernamePasswordAuthenticationToken authClientB;
    private UsernamePasswordAuthenticationToken authAdmin;

    private Order orderClientA;

    @BeforeEach
    void setUp() {
        SecurityContextHolder.clearContext();

        // Client A
        clientA = userRepository.findByUsernameIgnoreCase("client_a_sec").orElseGet(() -> {
            User u = new User("client_a_sec", "client_a_sec@test.com", "pass123", UserRole.CLIENT, "9876543211", "v1.0");
            u.setFullName("Alice Client");
            return userRepository.save(u);
        });
        UserDetailsImpl principalA = UserDetailsImpl.build(clientA);
        authClientA = new UsernamePasswordAuthenticationToken(principalA, null, principalA.getAuthorities());

        // Client B (Attacker / Different User)
        clientB = userRepository.findByUsernameIgnoreCase("client_b_sec").orElseGet(() -> {
            User u = new User("client_b_sec", "client_b_sec@test.com", "pass123", UserRole.CLIENT, "9876543212", "v1.0");
            u.setFullName("Bob Client");
            return userRepository.save(u);
        });
        UserDetailsImpl principalB = UserDetailsImpl.build(clientB);
        authClientB = new UsernamePasswordAuthenticationToken(principalB, null, principalB.getAuthorities());

        // Admin User
        adminUser = userRepository.findByUsernameIgnoreCase("admin_sec_usr").orElseGet(() -> {
            User u = new User("admin_sec_usr", "admin_sec_usr@test.com", "pass123", UserRole.ADMIN, "9876543213", "v1.0");
            u.setFullName("Admin Security Officer");
            return userRepository.save(u);
        });
        UserDetailsImpl principalAdmin = UserDetailsImpl.build(adminUser);
        authAdmin = new UsernamePasswordAuthenticationToken(principalAdmin, null, principalAdmin.getAuthorities());

        // Clean up previous test orders for clientA if any
        orderRepository.findAllByClientId(clientA.getId()).forEach(o -> {
            orderDocumentRepository.findAllByOrderId(o.getId()).forEach(orderDocumentRepository::delete);
            orderRepository.delete(o);
        });

        // Order belonging to Client A
        orderClientA = new Order();
        orderClientA.setClientId(clientA.getId());
        orderClientA.setReferenceCode("REQ-2026-7788");
        orderClientA.setServiceCategory("VALUATION");
        orderClientA.setPropertyCategory("LAND_AND_BUILDING");
        orderClientA.setPurpose("BANK_LOAN");
        orderClientA.setStatus("DRAFT");
        orderClientA = orderRepository.save(orderClientA);
    }

    // =========================================================================
    // FIX 1: REFERENCE CODE ACCESS CONTROL
    // =========================================================================

    @Test
    @DisplayName("Fix 1A: Owner client can view order by reference code (200 OK)")
    void testOwnerCanAccessByReference() throws Exception {
        mockMvc.perform(get("/api/v1/orders/by-reference/REQ-2026-7788")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.referenceCode").value("REQ-2026-7788"))
                .andExpect(jsonPath("$.clientId").value(clientA.getId()));
    }

    @Test
    @DisplayName("Fix 1B: Non-owner client is blocked with 403 Forbidden")
    void testNonOwnerBlockedFromAccessByReference() throws Exception {
        mockMvc.perform(get("/api/v1/orders/by-reference/REQ-2026-7788")
                        .with(authentication(authClientB)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.error").exists());
    }

    @Test
    @DisplayName("Fix 1C: Admin can view any order by reference code (200 OK)")
    void testAdminCanAccessAnyOrderByReference() throws Exception {
        mockMvc.perform(get("/api/v1/orders/by-reference/REQ-2026-7788")
                        .with(authentication(authAdmin)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.referenceCode").value("REQ-2026-7788"));
    }

    // =========================================================================
    // FIX 2: DOCUMENT TYPE WHITELIST
    // =========================================================================

    @Test
    @DisplayName("Fix 2A: Dangerous executable and script file types are rejected (400 Bad Request)")
    void testRejectedFileTypes() throws Exception {
        String[] dangerousFiles = {
                "payload.exe", "script.bat", "run.cmd", "tool.com", "library.dll",
                "attack.js", "powershell.ps1", "screensaver.scr", "archive.zip", "archive.rar", "archive.7z"
        };

        for (String filename : dangerousFiles) {
            MockMultipartFile file = new MockMultipartFile(
                    "file", filename, "application/octet-stream", new byte[]{0x4D, 0x5A, 0x00, 0x00}
            );

            mockMvc.perform(multipart("/api/v1/orders/" + orderClientA.getId() + "/documents/upload")
                            .file(file)
                            .param("category", "OTHER")
                            .with(authentication(authClientA)))
                    .andExpect(status().isBadRequest())
                    .andExpect(content().string(org.hamcrest.Matchers.containsString("Unsupported file type")));
        }
    }

    // =========================================================================
    // FIX 3: FILE CONTENT VALIDATION (MAGIC BYTES)
    // =========================================================================

    @Test
    @DisplayName("Fix 3A: Executable renamed to PDF (virus.exe -> virus.pdf) is rejected (400 Bad Request)")
    void testExecutableRenamedToPdfRejected() throws Exception {
        // MZ header: 0x4D, 0x5A
        byte[] exeBytes = new byte[]{0x4D, 0x5A, (byte) 0x90, 0x00, 0x03, 0x00, 0x00, 0x00};
        MockMultipartFile fakePdf = new MockMultipartFile(
                "file", "virus.pdf", "application/pdf", exeBytes
        );

        mockMvc.perform(multipart("/api/v1/orders/" + orderClientA.getId() + "/documents/upload")
                        .file(fakePdf)
                        .param("category", "TITLE_DEED")
                        .with(authentication(authClientA)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Fix 3B: Random text content renamed to PDF is rejected due to signature mismatch")
    void testRandomTextRenamedToPdfRejected() throws Exception {
        byte[] textBytes = "This is a plain text file pretending to be PDF".getBytes();
        MockMultipartFile fakePdf = new MockMultipartFile(
                "file", "fake.pdf", "application/pdf", textBytes
        );

        mockMvc.perform(multipart("/api/v1/orders/" + orderClientA.getId() + "/documents/upload")
                        .file(fakePdf)
                        .param("category", "TITLE_DEED")
                        .with(authentication(authClientA)))
                .andExpect(status().isBadRequest())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("File signature mismatch")));
    }

    @Test
    @DisplayName("Fix 3C: Legitimate PDF with '%PDF' signature is accepted (200 OK)")
    void testLegitimatePdfAccepted() throws Exception {
        byte[] pdfBytes = new byte[]{0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x35}; // %PDF-1.5
        MockMultipartFile validPdf = new MockMultipartFile(
                "file", "genuine_deed.pdf", "application/pdf", pdfBytes
        );

        mockMvc.perform(multipart("/api/v1/orders/" + orderClientA.getId() + "/documents/upload")
                        .file(validPdf)
                        .param("category", "TITLE_DEED")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.filename").value("genuine_deed.pdf"));
    }

    @Test
    @DisplayName("Fix 3D: Legitimate PNG with PNG signature is accepted (200 OK)")
    void testLegitimatePngAccepted() throws Exception {
        byte[] pngBytes = new byte[]{(byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00};
        MockMultipartFile validPng = new MockMultipartFile(
                "file", "site_plan.png", "image/png", pngBytes
        );

        mockMvc.perform(multipart("/api/v1/orders/" + orderClientA.getId() + "/documents/upload")
                        .file(validPng)
                        .param("category", "SANCTION_PLAN")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.filename").value("site_plan.png"));
    }

    @Test
    @DisplayName("Fix 3E: Legitimate JPEG with FF D8 FF signature is accepted (200 OK)")
    void testLegitimateJpegAccepted() throws Exception {
        byte[] jpegBytes = new byte[]{(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, (byte) 0xE0, 0x00, 0x10};
        MockMultipartFile validJpg = new MockMultipartFile(
                "file", "tax_receipt.jpg", "image/jpeg", jpegBytes
        );

        mockMvc.perform(multipart("/api/v1/orders/" + orderClientA.getId() + "/documents/upload")
                        .file(validJpg)
                        .param("category", "TAX_RECEIPT")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.filename").value("tax_receipt.jpg"));
    }

    // =========================================================================
    // FIX 4 & FIX 5: SUBMISSION STATE GUARD & TELEGRAM DUPLICATE PREVENTION
    // =========================================================================

    @Test
    @DisplayName("Fix 4 & 5: DRAFT submission succeeds once; second submission returns 409 Conflict without duplicate Telegram alert")
    void testSubmissionStateGuardAndTelegramDuplicatePrevention() throws Exception {
        // Upload 3 mandatory documents for Client A's order
        byte[] pdfHeader = new byte[]{0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34};

        OrderDocument d1 = new OrderDocument();
        d1.setOrder(orderClientA);
        d1.setCategory("TITLE_DEED");
        d1.setFilename("deed.pdf");
        d1.setFileContent(pdfHeader);
        d1.setUploadedBy(clientA);
        orderDocumentRepository.save(d1);

        OrderDocument d2 = new OrderDocument();
        d2.setOrder(orderClientA);
        d2.setCategory("SANCTION_PLAN");
        d2.setFilename("plan.pdf");
        d2.setFileContent(pdfHeader);
        d2.setUploadedBy(clientA);
        orderDocumentRepository.save(d2);

        OrderDocument d3 = new OrderDocument();
        d3.setOrder(orderClientA);
        d3.setCategory("TAX_RECEIPT");
        d3.setFilename("tax.pdf");
        d3.setFileContent(pdfHeader);
        d3.setUploadedBy(clientA);
        orderDocumentRepository.save(d3);

        // 1st Submission: DRAFT -> QUOTE_PENDING (Must succeed)
        mockMvc.perform(post("/api/v1/orders/" + orderClientA.getId() + "/submit-request")
                        .with(authentication(authClientA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("QUOTE_PENDING"))
                .andExpect(jsonPath("$.referenceCode").exists());

        // Verify status in DB is now QUOTE_PENDING
        Order updated = orderRepository.findById(orderClientA.getId()).orElseThrow();
        assertEquals("QUOTE_PENDING", updated.getStatus());

        // Verify Telegram service was called exactly once on first successful transition
        verify(telegramNotificationService, org.mockito.Mockito.timeout(3000).times(1)).sendNewRequestNotification(
                anyString(), anyString(), anyString(), anyString(), anyString(), anyInt(), anyString()
        );

        // 2nd Submission (Retry attempt on already submitted request): MUST return 409 Conflict
        mockMvc.perform(post("/api/v1/orders/" + orderClientA.getId() + "/submit-request")
                        .with(authentication(authClientA)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("This request has already been submitted."));

        // Verify Telegram was NOT called again (still exactly 1 time)
        verify(telegramNotificationService, org.mockito.Mockito.timeout(3000).times(1)).sendNewRequestNotification(
                anyString(), anyString(), anyString(), anyString(), anyString(), anyInt(), anyString()
        );
    }
}
