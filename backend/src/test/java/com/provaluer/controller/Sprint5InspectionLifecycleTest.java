package com.provaluer.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.CompleteInspectionRequest;
import com.provaluer.dto.RescheduleInspectionRequest;
import com.provaluer.dto.ScheduleInspectionRequest;
import com.provaluer.dto.StartInspectionRequest;
import com.provaluer.model.*;
import com.provaluer.repository.OrderInspectionRepository;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.TelegramNotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import javax.imageio.ImageIO;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * SPRINT 5: Comprehensive Automated Integration Tests
 * Site Inspection Lifecycle: ASSIGNED → INSPECTION_SCHEDULED → INSPECTION_IN_PROGRESS → INSPECTION_COMPLETED
 * Multi-State Pause/Resume (ACTION_NEEDED)
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@TestPropertySource(properties = {"spring.flyway.validate-on-migrate=false", "spring.flyway.repair=true"})
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class Sprint5InspectionLifecycleTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private OrderRepository orderRepository;
    @Autowired private OrderInspectionRepository orderInspectionRepository;
    @Autowired private UserRepository userRepository;
    @Autowired private ObjectMapper objectMapper;

    @SpyBean private TelegramNotificationService telegramNotificationService;

    private User paUser;
    private UsernamePasswordAuthenticationToken authPa;

    @BeforeEach
    void setUp() {
        paUser = userRepository.findAll().stream()
                .filter(u -> UserRole.PA.equals(u.getRole()))
                .findFirst()
                .orElseGet(() -> {
                    User u = new User();
                    u.setUsername("pa_sprint5_" + System.nanoTime());
                    u.setPassword("$2a$10$wMxKR5N3YRj.zUXQh3rkPuEYqxlCJW2NLbXXH5s8y7r9UoL1I7Z3u");
                    u.setEmail("pa_s5_" + System.nanoTime() + "@provaluer.com");
                    u.setRole(UserRole.PA);
                    u.setMobileNumber("+919876543210");
                    return userRepository.save(u);
                });

        authPa = new UsernamePasswordAuthenticationToken(
                UserDetailsImpl.build(paUser), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + paUser.getRole().name())));
    }

    private Order createAssignedOrder() {
        Order order = new Order();
        order.setClientId(paUser.getId());
        order.setPaId(paUser.getId());
        order.setStatus("ASSIGNED");
        order.setPurpose("Commercial Mortgage");
        order.setPropertyCategory("Commercial Complex");
        order.setReferenceCode("PV-REQ-" + System.nanoTime());
        order.setReportNumber("PV-2610-" + System.nanoTime());
        order.setEstimatedValue(BigDecimal.valueOf(5000000));
        order.setClaimedAt(LocalDateTime.now());
        order.setLastHeartbeat(LocalDateTime.now());
        order.setSlaExpiryTime(LocalDateTime.now().plusDays(2));
        return orderRepository.save(order);
    }

    private byte[] createTestImage(int width, int height, Color color, String label) throws Exception {
        BufferedImage img = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = img.createGraphics();
        g.setColor(color);
        g.fillRect(0, 0, width, height);
        g.setColor(Color.WHITE);
        g.drawString(label + " - " + System.nanoTime(), 50, 50);
        g.dispose();
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        ImageIO.write(img, "jpg", baos);
        return baos.toByteArray();
    }

    @Test
    @DisplayName("1. Schedule Inspection — ASSIGNED → INSPECTION_SCHEDULED")
    void testScheduleInspectionSuccess() throws Exception {
        Order order = createAssignedOrder();

        ScheduleInspectionRequest req = new ScheduleInspectionRequest();
        req.setInspectionDate(LocalDate.now().plusDays(2));
        req.setInspectionTime(LocalTime.of(10, 30));
        req.setSiteContactName("Ramesh Kumar");
        req.setSiteContactNumber("+91-9876543210");
        req.setPropertyAccessNotes("Gate code 1234");

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/schedule-inspection")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderId").value(order.getId()))
                .andExpect(jsonPath("$.orderStatus").value("INSPECTION_SCHEDULED"))
                .andExpect(jsonPath("$.siteContactName").value("Ramesh Kumar"));

        Order updated = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("INSPECTION_SCHEDULED", updated.getStatus());
        assertTrue(orderInspectionRepository.existsByOrderId(order.getId()));
    }

    @Test
    @DisplayName("2. Schedule Inspection — Conflict when order is not in ASSIGNED status")
    void testScheduleInspectionConflict() throws Exception {
        Order order = createAssignedOrder();
        order.setStatus("PAID_INTAKE");
        orderRepository.save(order);

        ScheduleInspectionRequest req = new ScheduleInspectionRequest();
        req.setInspectionDate(LocalDate.now().plusDays(1));
        req.setInspectionTime(LocalTime.of(14, 0));
        req.setSiteContactName("Suresh");
        req.setSiteContactNumber("9876543210");

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/schedule-inspection")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict());
    }

    @Test
    @DisplayName("3. Reschedule Inspection — Append to history and update schedule")
    void testRescheduleInspection() throws Exception {
        Order order = createAssignedOrder();

        // 1. Schedule first
        ScheduleInspectionRequest req = new ScheduleInspectionRequest();
        req.setInspectionDate(LocalDate.now().plusDays(2));
        req.setInspectionTime(LocalTime.of(10, 30));
        req.setSiteContactName("Ramesh Kumar");
        req.setSiteContactNumber("+91-9876543210");

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/schedule-inspection")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        // 2. Reschedule
        RescheduleInspectionRequest rescheduleReq = new RescheduleInspectionRequest();
        rescheduleReq.setNewInspectionDate(LocalDate.now().plusDays(4));
        rescheduleReq.setNewInspectionTime(LocalTime.of(16, 0));
        rescheduleReq.setRescheduleReason("Client requested date postponement due to holiday");

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/reschedule-inspection")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(rescheduleReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderStatus").value("INSPECTION_SCHEDULED"));

        OrderInspection insp = orderInspectionRepository.findByOrderId(order.getId()).orElseThrow();
        assertEquals(LocalDate.now().plusDays(4), insp.getInspectionDate());
        assertEquals(LocalTime.of(16, 0), insp.getInspectionTime());
        assertTrue(insp.getScheduleHistory().contains("postponement"));
    }

    @Test
    @DisplayName("4. Start Inspection — INSPECTION_SCHEDULED → INSPECTION_IN_PROGRESS")
    void testStartInspection() throws Exception {
        Order order = createAssignedOrder();

        ScheduleInspectionRequest req = new ScheduleInspectionRequest();
        req.setInspectionDate(LocalDate.now().plusDays(1));
        req.setInspectionTime(LocalTime.of(11, 0));
        req.setSiteContactName("Contact");
        req.setSiteContactNumber("9999999999");

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/schedule-inspection")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk());

        StartInspectionRequest startReq = new StartInspectionRequest();
        startReq.setGpsLat(BigDecimal.valueOf(19.0760123));
        startReq.setGpsLng(BigDecimal.valueOf(72.8777456));
        startReq.setGpsAccuracy(10.5f);
        startReq.setAccessConfirmed(true);

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/start-inspection")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(startReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderStatus").value("INSPECTION_IN_PROGRESS"));

        Order updated = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("INSPECTION_IN_PROGRESS", updated.getStatus());
    }

    @Test
    @DisplayName("5. Upload Evidence Photo — Valid photo and MD5 duplicate prevention")
    void testPhotoUploadAndDuplicatePrevention() throws Exception {
        Order order = createAssignedOrder();

        // Schedule and start
        ScheduleInspectionRequest req = new ScheduleInspectionRequest();
        req.setInspectionDate(LocalDate.now().plusDays(1));
        req.setInspectionTime(LocalTime.of(11, 0));
        req.setSiteContactName("Contact");
        req.setSiteContactNumber("9999999999");
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/schedule-inspection")
                .with(authentication(authPa)).contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(req)));

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/start-inspection")
                .with(authentication(authPa)));

        byte[] validImageBytes = createTestImage(800, 600, Color.BLUE, "FrontElevationPhoto");
        MockMultipartFile file1 = new MockMultipartFile("file", "front1.jpg", "image/jpeg", validImageBytes);

        // Upload first time
        mockMvc.perform(multipart("/api/v1/orders/" + order.getId() + "/inspection/photos")
                        .file(file1)
                        .param("category", "FRONT_ELEVATION")
                        .param("gpsLat", "19.0760")
                        .param("gpsLng", "72.8777")
                        .with(authentication(authPa)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.category").value("FRONT_ELEVATION"))
                .andExpect(jsonPath("$.filename").value("front1.jpg"));

        // Upload duplicate identical bytes -> must be rejected with 409 Conflict
        MockMultipartFile duplicateFile = new MockMultipartFile("file", "front1_duplicate.jpg", "image/jpeg", validImageBytes);
        mockMvc.perform(multipart("/api/v1/orders/" + order.getId() + "/inspection/photos")
                        .file(duplicateFile)
                        .param("category", "FRONT_ELEVATION")
                        .with(authentication(authPa)))
                .andExpect(status().isConflict());
    }

    @Test
    @DisplayName("6. Completion Gate — Rejects completion when mandatory photo evidence is missing")
    void testCompleteInspectionMissingPhotos() throws Exception {
        Order order = createAssignedOrder();

        // Move to IN_PROGRESS
        ScheduleInspectionRequest req = new ScheduleInspectionRequest();
        req.setInspectionDate(LocalDate.now().plusDays(1));
        req.setInspectionTime(LocalTime.of(11, 0));
        req.setSiteContactName("Contact");
        req.setSiteContactNumber("9999999999");
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/schedule-inspection")
                .with(authentication(authPa)).contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(req)));
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/start-inspection").with(authentication(authPa)));

        // Try to complete without uploading mandatory photos
        CompleteInspectionRequest compReq = new CompleteInspectionRequest();
        compReq.setInspectionRemarks("Completed site inspection thoroughly. Structure in excellent condition.");
        compReq.setVisitStatus("COMPLETED");

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/complete-inspection")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(compReq)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("7. Complete Inspection — Success when all 7 mandatory photo categories satisfied")
    void testCompleteInspectionSuccess() throws Exception {
        Order order = createAssignedOrder();

        // 1. Schedule & Start
        ScheduleInspectionRequest req = new ScheduleInspectionRequest();
        req.setInspectionDate(LocalDate.now().plusDays(1));
        req.setInspectionTime(LocalTime.of(11, 0));
        req.setSiteContactName("Site Owner");
        req.setSiteContactNumber("9876543210");
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/schedule-inspection")
                .with(authentication(authPa)).contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(req)));
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/start-inspection").with(authentication(authPa)));

        // 2. Upload photos for all mandatory categories:
        // FRONT_ELEVATION (1), REAR_ELEVATION (1), SIDE_VIEW_LEFT (1), SIDE_VIEW_RIGHT (1),
        // STREET_VIEW (1), ACCESS_ROAD (1), SURROUNDINGS (2)
        String[] mandatoryCats = {
                "FRONT_ELEVATION", "REAR_ELEVATION", "SIDE_VIEW_LEFT", "SIDE_VIEW_RIGHT",
                "STREET_VIEW", "ACCESS_ROAD", "SURROUNDINGS", "SURROUNDINGS"
        };

        for (int i = 0; i < mandatoryCats.length; i++) {
            byte[] bytes = createTestImage(800, 600, Color.DARK_GRAY, "Cat_" + mandatoryCats[i] + "_" + i);
            MockMultipartFile file = new MockMultipartFile("file", "img_" + i + ".jpg", "image/jpeg", bytes);
            mockMvc.perform(multipart("/api/v1/orders/" + order.getId() + "/inspection/photos")
                            .file(file)
                            .param("category", mandatoryCats[i])
                            .with(authentication(authPa)))
                    .andExpect(status().isCreated());
        }

        // 3. Complete Inspection with valid remarks
        CompleteInspectionRequest compReq = new CompleteInspectionRequest();
        compReq.setInspectionRemarks("Completed comprehensive site physical verification. Property is structurally sound with clear access.");
        compReq.setVisitStatus("COMPLETED");

        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/complete-inspection")
                        .with(authentication(authPa))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(compReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderStatus").value("INSPECTION_COMPLETED"))
                .andExpect(jsonPath("$.visitStatus").value("COMPLETED"));

        Order completed = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("INSPECTION_COMPLETED", completed.getStatus());
    }

    @Test
    @DisplayName("8. Multi-State Pause & Resume — Restores pre_pause_status correctly")
    void testMultiStatePauseAndResume() throws Exception {
        Order order = createAssignedOrder();

        // 1. Move to INSPECTION_SCHEDULED
        ScheduleInspectionRequest req = new ScheduleInspectionRequest();
        req.setInspectionDate(LocalDate.now().plusDays(2));
        req.setInspectionTime(LocalTime.of(10, 0));
        req.setSiteContactName("Owner");
        req.setSiteContactNumber("9999999999");
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/schedule-inspection")
                .with(authentication(authPa)).contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(req)));

        Order beforePause = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("INSPECTION_SCHEDULED", beforePause.getStatus());

        // 2. Pause order -> ACTION_NEEDED
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/pause")
                        .param("reason", "SITE_LOCKED")
                        .param("description", "Front gate padlocked, contact unavailable")
                        .with(authentication(authPa)))
                .andExpect(status().isOk());

        Order paused = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("ACTION_NEEDED", paused.getStatus());
        assertTrue(paused.isPaused());
        assertEquals("INSPECTION_SCHEDULED", paused.getPrePauseStatus());

        // 3. Resume order -> Should restore to INSPECTION_SCHEDULED (not ASSIGNED!)
        mockMvc.perform(post("/api/v1/orders/" + order.getId() + "/resume")
                        .with(authentication(authPa)))
                .andExpect(status().isOk());

        Order resumed = orderRepository.findById(order.getId()).orElseThrow();
        assertEquals("INSPECTION_SCHEDULED", resumed.getStatus());
        assertFalse(resumed.isPaused());
        assertNull(resumed.getPrePauseStatus());
    }
}
