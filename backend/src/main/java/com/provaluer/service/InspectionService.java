package com.provaluer.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.provaluer.dto.*;
import com.provaluer.model.*;
import com.provaluer.repository.InspectionPhotoRepository;
import com.provaluer.repository.OrderInspectionRepository;
import com.provaluer.repository.OrderRepository;
import com.provaluer.repository.UserRepository;
import com.provaluer.security.UserDetailsImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class InspectionService {

    private static final Logger log = LoggerFactory.getLogger(InspectionService.class);

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderInspectionRepository orderInspectionRepository;

    @Autowired
    private InspectionPhotoRepository inspectionPhotoRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuditLogService auditLogService;

    @Autowired
    private TelegramNotificationService telegramNotificationService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * SPRINT 5: Schedule inspection appointment.
     * Transitions status: ASSIGNED → INSPECTION_SCHEDULED
     */
    @Transactional
    public InspectionSummaryDto scheduleInspection(Long orderId, ScheduleInspectionRequest req, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId));

        validatePaOrAdmin(order, principal);

        if (!"ASSIGNED".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Order must be in ASSIGNED status to schedule inspection. Current status: " + order.getStatus());
        }

        if (req.getInspectionDate() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Inspection date is mandatory");
        }
        if (req.getInspectionTime() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Inspection time is mandatory");
        }
        if (req.getSiteContactName() == null || req.getSiteContactName().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Site contact name is mandatory");
        }
        if (req.getSiteContactNumber() == null || req.getSiteContactNumber().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Site contact number is mandatory");
        }

        OrderInspection inspection = orderInspectionRepository.findByOrderId(orderId)
                .orElseGet(() -> {
                    OrderInspection newInsp = new OrderInspection();
                    newInsp.setOrderId(order.getId());
                    newInsp.setPaId(order.getPaId() != null ? order.getPaId() : principal.getId());
                    return newInsp;
                });

        inspection.setInspectionDate(req.getInspectionDate());
        inspection.setInspectionTime(req.getInspectionTime());
        inspection.setSiteContactName(req.getSiteContactName().trim());
        inspection.setSiteContactNumber(req.getSiteContactNumber().trim());
        inspection.setAltContactName(req.getAltContactName() != null ? req.getAltContactName().trim() : null);
        inspection.setAltContactNumber(req.getAltContactNumber() != null ? req.getAltContactNumber().trim() : null);
        inspection.setPropertyAccessNotes(req.getPropertyAccessNotes() != null ? req.getPropertyAccessNotes().trim() : null);
        inspection.setScheduledAt(LocalDateTime.now());
        inspection.setUpdatedAt(LocalDateTime.now());

        OrderInspection savedInspection = orderInspectionRepository.save(inspection);

        String previousStatus = order.getStatus();
        order.setStatus("INSPECTION_SCHEDULED");
        order.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(order);

        // Audit log
        auditLogService.log(
                principal.getId(),
                principal.getEmail(),
                getPrincipalRole(principal),
                "INSPECTION_SCHEDULED",
                "ORDER",
                String.valueOf(order.getId()),
                previousStatus,
                "INSPECTION_SCHEDULED",
                String.format("Inspection scheduled for %s at %s by %s",
                        req.getInspectionDate(), req.getInspectionTime(), principal.getUsername())
        );

        // Telegram alert
        telegramNotificationService.sendInspectionScheduledNotification(
                order.getReferenceCode(),
                order.getReportNumber(),
                order.getClientName(),
                req.getInspectionDate().toString(),
                req.getInspectionTime().toString(),
                req.getSiteContactName(),
                principal.getUsername()
        );

        return buildInspectionSummaryDto(order, savedInspection);
    }

    /**
     * SPRINT 5: Reschedule inspection appointment.
     * Records reschedule event in JSON history.
     */
    @Transactional
    public InspectionSummaryDto rescheduleInspection(Long orderId, RescheduleInspectionRequest req, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId));

        validatePaOrAdmin(order, principal);

        if (!"INSPECTION_SCHEDULED".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Order must be in INSPECTION_SCHEDULED status to reschedule. Current status: " + order.getStatus());
        }

        if (req.getNewInspectionDate() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "New inspection date is mandatory");
        }
        if (req.getNewInspectionTime() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "New inspection time is mandatory");
        }
        if (req.getRescheduleReason() == null || req.getRescheduleReason().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reschedule reason is mandatory");
        }

        OrderInspection inspection = orderInspectionRepository.findByOrderId(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Inspection details not found for order: " + orderId));

        // Append to schedule_history JSONB array
        List<Map<String, Object>> history = parseScheduleHistory(inspection.getScheduleHistory());
        Map<String, Object> rescheduleEvent = new LinkedHashMap<>();
        rescheduleEvent.put("previousDate", inspection.getInspectionDate() != null ? inspection.getInspectionDate().toString() : null);
        rescheduleEvent.put("previousTime", inspection.getInspectionTime() != null ? inspection.getInspectionTime().toString() : null);
        rescheduleEvent.put("newDate", req.getNewInspectionDate().toString());
        rescheduleEvent.put("newTime", req.getNewInspectionTime().toString());
        rescheduleEvent.put("reason", req.getRescheduleReason().trim());
        rescheduleEvent.put("rescheduledAt", LocalDateTime.now().toString());
        rescheduleEvent.put("rescheduledBy", principal.getUsername());
        history.add(rescheduleEvent);

        try {
            inspection.setScheduleHistory(objectMapper.writeValueAsString(history));
        } catch (Exception e) {
            log.error("Failed to serialize reschedule history", e);
        }

        inspection.setInspectionDate(req.getNewInspectionDate());
        inspection.setInspectionTime(req.getNewInspectionTime());
        if (req.getSiteContactName() != null && !req.getSiteContactName().trim().isEmpty()) {
            inspection.setSiteContactName(req.getSiteContactName().trim());
        }
        if (req.getSiteContactNumber() != null && !req.getSiteContactNumber().trim().isEmpty()) {
            inspection.setSiteContactNumber(req.getSiteContactNumber().trim());
        }
        inspection.setUpdatedAt(LocalDateTime.now());
        OrderInspection savedInspection = orderInspectionRepository.save(inspection);

        // Audit log
        auditLogService.log(
                principal.getId(),
                principal.getEmail(),
                getPrincipalRole(principal),
                "INSPECTION_RESCHEDULED",
                "ORDER",
                String.valueOf(order.getId()),
                "Reschedule #" + history.size() + ": " + req.getRescheduleReason().trim()
        );

        // Telegram alert
        telegramNotificationService.sendInspectionRescheduledNotification(
                order.getReferenceCode(),
                order.getReportNumber(),
                req.getNewInspectionDate().toString(),
                req.getNewInspectionTime().toString(),
                req.getRescheduleReason().trim(),
                history.size()
        );

        return buildInspectionSummaryDto(order, savedInspection);
    }

    /**
     * SPRINT 5: Mark inspection in progress.
     * Transitions status: INSPECTION_SCHEDULED → INSPECTION_IN_PROGRESS
     */
    @Transactional
    public InspectionSummaryDto startInspection(Long orderId, StartInspectionRequest req, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId));

        validatePaOrAdmin(order, principal);

        if (!"INSPECTION_SCHEDULED".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Order must be in INSPECTION_SCHEDULED status to start inspection. Current status: " + order.getStatus());
        }

        OrderInspection inspection = orderInspectionRepository.findByOrderId(orderId)
                .orElseGet(() -> {
                    OrderInspection newInsp = new OrderInspection();
                    newInsp.setOrderId(order.getId());
                    newInsp.setPaId(order.getPaId() != null ? order.getPaId() : principal.getId());
                    return newInsp;
                });

        inspection.setStartedAt(LocalDateTime.now());
        if (req != null) {
            if (req.getGpsLat() != null) inspection.setGpsLatStart(req.getGpsLat());
            if (req.getGpsLng() != null) inspection.setGpsLngStart(req.getGpsLng());
            if (req.getGpsAccuracy() != null) inspection.setGpsAccuracyStart(req.getGpsAccuracy());
            if (req.getAccessConfirmed() != null) inspection.setAccessConfirmed(req.getAccessConfirmed());
            if (req.getAccessNotes() != null) inspection.setAccessNotes(req.getAccessNotes().trim());
        }
        inspection.setUpdatedAt(LocalDateTime.now());
        OrderInspection savedInspection = orderInspectionRepository.save(inspection);

        String previousStatus = order.getStatus();
        order.setStatus("INSPECTION_IN_PROGRESS");
        order.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(order);

        // Audit log
        auditLogService.log(
                principal.getId(),
                principal.getEmail(),
                getPrincipalRole(principal),
                "INSPECTION_STARTED",
                "ORDER",
                String.valueOf(order.getId()),
                previousStatus,
                "INSPECTION_IN_PROGRESS",
                "Site inspection marked in-progress by " + principal.getUsername()
        );

        return buildInspectionSummaryDto(order, savedInspection);
    }

    /**
     * SPRINT 5: Upload an evidence photo.
     * Enforces file size (max 8MB), MIME type (JPEG/PNG), resolution (min 800x600),
     * MD5 duplicate check, and max 100 photos limit.
     */
    @Transactional
    public InspectionPhotoDto uploadPhoto(
            Long orderId,
            MultipartFile file,
            String categoryStr,
            BigDecimal gpsLat,
            BigDecimal gpsLng,
            Float gpsAccuracy,
            String deviceTimestampStr,
            UserDetailsImpl principal) {

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId));

        validatePaOrAdmin(order, principal);

        if ("INSPECTION_COMPLETED".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Cannot upload evidence photos after inspection has been marked completed.");
        }

        // Validate category
        if (!PhotoCategory.isValid(categoryStr)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Invalid photo category: " + categoryStr + ". Valid categories: " +
                            Arrays.toString(PhotoCategory.values()));
        }
        PhotoCategory category = PhotoCategory.fromCode(categoryStr).get();

        // Validate file presence
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "File is required and cannot be empty.");
        }

        // Validate file size: 8 MB max
        if (file.getSize() > 8 * 1024 * 1024) {
            throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE,
                    "Photo exceeds maximum allowed size of 8 MB (actual: " + (file.getSize() / 1024 / 1024) + " MB)");
        }

        // Validate MIME type
        String contentType = file.getContentType();
        if (contentType == null || (!contentType.equalsIgnoreCase("image/jpeg") &&
                !contentType.equalsIgnoreCase("image/jpg") &&
                !contentType.equalsIgnoreCase("image/png"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Invalid image format (" + contentType + "). Only JPEG and PNG images are permitted.");
        }

        byte[] fileBytes;
        try {
            fileBytes = file.getBytes();
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to read uploaded photo bytes.");
        }

        // Validate image resolution: min 800x600 in either landscape or portrait
        try {
            BufferedImage image = ImageIO.read(new ByteArrayInputStream(fileBytes));
            if (image != null) {
                int width = image.getWidth();
                int height = image.getHeight();
                boolean meetsDimension = (width >= 800 && height >= 600) || (width >= 600 && height >= 800);
                if (!meetsDimension) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                            String.format("Photo resolution %dx%d is below minimum required 800x600 px.", width, height));
                }
            }
        } catch (ResponseStatusException rse) {
            throw rse;
        } catch (Exception e) {
            log.warn("Could not parse image dimensions for validation: {}", e.getMessage());
        }

        // Validate total photos count
        long totalPhotos = inspectionPhotoRepository.countByOrderIdAndIsDeletedFalse(orderId);
        if (totalPhotos >= 100) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Order has reached the maximum evidence limit of 100 photos.");
        }

        // Duplicate prevention via MD5 hash
        String md5 = computeMd5(fileBytes);
        if (inspectionPhotoRepository.existsByOrderIdAndMd5HashAndIsDeletedFalse(orderId, md5)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Duplicate photo detected: identical image has already been uploaded for this order.");
        }

        // Ensure OrderInspection exists
        OrderInspection inspection = orderInspectionRepository.findByOrderId(orderId)
                .orElseGet(() -> {
                    OrderInspection newInsp = new OrderInspection();
                    newInsp.setOrderId(order.getId());
                    newInsp.setPaId(order.getPaId() != null ? order.getPaId() : principal.getId());
                    return orderInspectionRepository.save(newInsp);
                });

        // Sequence number in category
        long currentCategoryCount = inspectionPhotoRepository.countByOrderIdAndCategoryAndIsDeletedFalse(orderId, category.name());
        int sequence = (int) currentCategoryCount + 1;

        InspectionPhoto photo = new InspectionPhoto();
        photo.setInspectionId(inspection.getId());
        photo.setOrderId(order.getId());
        photo.setPaId(order.getPaId() != null ? order.getPaId() : principal.getId());
        photo.setCategory(category.name());
        photo.setFilename(file.getOriginalFilename() != null ? file.getOriginalFilename() : "photo_" + System.currentTimeMillis() + ".jpg");
        photo.setFileSizeBytes(file.getSize());
        photo.setMimeType(contentType);
        photo.setFileContent(fileBytes);
        photo.setMd5Hash(md5);
        photo.setGpsLat(gpsLat);
        photo.setGpsLng(gpsLng);
        photo.setGpsAccuracy(gpsAccuracy);
        photo.setCaptureSequence(sequence);
        photo.setUploadedAt(LocalDateTime.now());
        photo.setUploadedBy(principal.getId());

        if (deviceTimestampStr != null && !deviceTimestampStr.trim().isEmpty()) {
            try {
                photo.setDeviceTimestamp(LocalDateTime.parse(deviceTimestampStr.trim()));
            } catch (Exception ignored) {}
        }

        InspectionPhoto saved = inspectionPhotoRepository.save(photo);

        // Audit log
        auditLogService.log(
                principal.getId(),
                principal.getEmail(),
                getPrincipalRole(principal),
                "EVIDENCE_UPLOADED",
                "INSPECTION_PHOTO",
                String.valueOf(saved.getId()),
                String.format("Photo uploaded for Order %s: category=%s, filename=%s, size=%d bytes",
                        order.getReferenceCode(), category.name(), saved.getFilename(), saved.getFileSizeBytes())
        );

        return toPhotoDto(saved);
    }

    /**
     * SPRINT 5: Soft delete inspection photo.
     */
    @Transactional
    public void deletePhoto(Long orderId, Long photoId, String reason, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId));

        validatePaOrAdmin(order, principal);

        InspectionPhoto photo = inspectionPhotoRepository.findByIdAndOrderIdAndIsDeletedFalse(photoId, orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Photo not found: " + photoId));

        boolean isAdmin = isSuperAdminOrAdmin(principal);

        // PA cannot delete photos once order is completed
        if (!isAdmin && "INSPECTION_COMPLETED".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Assigned PA cannot delete photos after inspection completion. Administrator override required.");
        }

        photo.setDeleted(true);
        photo.setDeletedAt(LocalDateTime.now());
        photo.setDeletedBy(principal.getId());
        photo.setDeleteReason(reason != null && !reason.trim().isEmpty() ? reason.trim() : "Deleted by user");
        inspectionPhotoRepository.save(photo);

        // Audit log
        auditLogService.log(
                principal.getId(),
                principal.getEmail(),
                getPrincipalRole(principal),
                "EVIDENCE_DELETED",
                "INSPECTION_PHOTO",
                String.valueOf(photo.getId()),
                "Soft deleted photo: " + photo.getFilename() + " Reason: " + photo.getDeleteReason()
        );
    }

    /**
     * SPRINT 5: Complete inspection.
     * Transitions status: INSPECTION_IN_PROGRESS → INSPECTION_COMPLETED
     * Enforces mandatory photo categories and remarks.
     */
    @Transactional
    public InspectionSummaryDto completeInspection(Long orderId, CompleteInspectionRequest req, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId));

        validatePaOrAdmin(order, principal);

        if (!"INSPECTION_IN_PROGRESS".equals(order.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Order must be in INSPECTION_IN_PROGRESS status to complete inspection. Current status: " + order.getStatus());
        }

        if (req.getInspectionRemarks() == null || req.getInspectionRemarks().trim().length() < 20) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Inspection remarks are mandatory and must be at least 20 characters in length.");
        }

        OrderInspection inspection = orderInspectionRepository.findByOrderId(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Inspection details not found for order: " + orderId));

        // Completion Gate: Check all mandatory categories
        List<PhotoCategory> missingCategories = new ArrayList<>();
        for (PhotoCategory cat : PhotoCategory.getMandatoryCategories()) {
            long count = inspectionPhotoRepository.countByOrderIdAndCategoryAndIsDeletedFalse(orderId, cat.name());
            if (count < cat.getMinPhotos()) {
                missingCategories.add(cat);
            }
        }

        if (!missingCategories.isEmpty()) {
            String missingMsg = missingCategories.stream()
                    .map(c -> String.format("%s (min %d required)", c.getDisplayName(), c.getMinPhotos()))
                    .collect(Collectors.joining(", "));
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Cannot complete inspection. Missing mandatory photo evidence: " + missingMsg);
        }

        inspection.setCompletedAt(LocalDateTime.now());
        inspection.setInspectionRemarks(req.getInspectionRemarks().trim());
        inspection.setVisitStatus(req.getVisitStatus() != null ? req.getVisitStatus().trim() : "COMPLETED");

        if (req.getGpsLat() != null) inspection.setGpsLatEnd(req.getGpsLat());
        if (req.getGpsLng() != null) inspection.setGpsLngEnd(req.getGpsLng());
        if (req.getGpsAccuracy() != null) inspection.setGpsAccuracyEnd(req.getGpsAccuracy());
        inspection.setUpdatedAt(LocalDateTime.now());

        OrderInspection savedInspection = orderInspectionRepository.save(inspection);

        String previousStatus = order.getStatus();
        order.setStatus("INSPECTION_COMPLETED");
        order.setUpdatedAt(LocalDateTime.now());
        orderRepository.save(order);

        long totalPhotos = inspectionPhotoRepository.countByOrderIdAndIsDeletedFalse(orderId);

        // Audit log
        auditLogService.log(
                principal.getId(),
                principal.getEmail(),
                getPrincipalRole(principal),
                "INSPECTION_COMPLETED",
                "ORDER",
                String.valueOf(order.getId()),
                previousStatus,
                "INSPECTION_COMPLETED",
                String.format("Inspection completed with %d evidence photos. Outcome: %s",
                        totalPhotos, inspection.getVisitStatus())
        );

        // Telegram alert
        telegramNotificationService.sendInspectionCompletedNotification(
                order.getReferenceCode(),
                order.getReportNumber(),
                order.getClientName(),
                (int) totalPhotos,
                inspection.getVisitStatus(),
                principal.getUsername()
        );

        return buildInspectionSummaryDto(order, savedInspection);
    }

    /**
     * SPRINT 5: Get full inspection summary and photo evidence manifest.
     */
    @Transactional(readOnly = true)
    public InspectionSummaryDto getInspectionSummary(Long orderId, UserDetailsImpl principal) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId));

        OrderInspection inspection = orderInspectionRepository.findByOrderId(orderId).orElse(null);
        return buildInspectionSummaryDto(order, inspection);
    }

    /**
     * SPRINT 5: Get binary photo content.
     */
    @Transactional(readOnly = true)
    public InspectionPhoto getPhotoEntity(Long orderId, Long photoId, UserDetailsImpl principal) {
        if (!orderRepository.existsById(orderId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found: " + orderId);
        }

        return inspectionPhotoRepository.findByIdAndOrderIdAndIsDeletedFalse(photoId, orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Photo not found: " + photoId));
    }

    // Helper methods

    private InspectionSummaryDto buildInspectionSummaryDto(Order order, OrderInspection inspection) {
        InspectionSummaryDto dto = new InspectionSummaryDto();
        dto.setOrderId(order.getId());
        dto.setReferenceCode(order.getReferenceCode());
        dto.setOrderStatus(order.getStatus());

        if (order.getPaId() != null) {
            dto.setPaId(order.getPaId());
            userRepository.findById(order.getPaId()).ifPresent(u -> dto.setPaName(u.getFullName() != null ? u.getFullName() : u.getUsername()));
        }

        if (inspection != null) {
            dto.setInspectionId(inspection.getId());
            dto.setInspectionDate(inspection.getInspectionDate());
            dto.setInspectionTime(inspection.getInspectionTime());
            dto.setSiteContactName(inspection.getSiteContactName());
            dto.setSiteContactNumber(inspection.getSiteContactNumber());
            dto.setAltContactName(inspection.getAltContactName());
            dto.setAltContactNumber(inspection.getAltContactNumber());
            dto.setPropertyAccessNotes(inspection.getPropertyAccessNotes());
            dto.setScheduledAt(inspection.getScheduledAt());
            dto.setScheduleHistory(inspection.getScheduleHistory());
            dto.setStartedAt(inspection.getStartedAt());
            dto.setCompletedAt(inspection.getCompletedAt());
            dto.setGpsLatStart(inspection.getGpsLatStart());
            dto.setGpsLngStart(inspection.getGpsLngStart());
            dto.setGpsAccuracyStart(inspection.getGpsAccuracyStart());
            dto.setGpsLatEnd(inspection.getGpsLatEnd());
            dto.setGpsLngEnd(inspection.getGpsLngEnd());
            dto.setGpsAccuracyEnd(inspection.getGpsAccuracyEnd());
            dto.setVisitStatus(inspection.getVisitStatus());
            dto.setInspectionRemarks(inspection.getInspectionRemarks());
            dto.setAccessConfirmed(inspection.getAccessConfirmed());
            dto.setAccessNotes(inspection.getAccessNotes());
        }

        // Category checklist
        List<PhotoCategoryStatusDto> catStatuses = new ArrayList<>();
        boolean allMandatorySatisfied = true;
        for (PhotoCategory cat : PhotoCategory.values()) {
            long count = inspectionPhotoRepository.countByOrderIdAndCategoryAndIsDeletedFalse(order.getId(), cat.name());
            PhotoCategoryStatusDto statusDto = new PhotoCategoryStatusDto(
                    cat.name(),
                    cat.getDisplayName(),
                    cat.isMandatory(),
                    cat.getMinPhotos(),
                    count
            );
            catStatuses.add(statusDto);
            if (cat.isMandatory() && count < cat.getMinPhotos()) {
                allMandatorySatisfied = false;
            }
        }
        dto.setCategoryStatuses(catStatuses);
        dto.setReadyForCompletion(allMandatorySatisfied && "INSPECTION_IN_PROGRESS".equals(order.getStatus()));

        // Photos manifest
        List<InspectionPhoto> photos = inspectionPhotoRepository.findAllByOrderIdAndIsDeletedFalseOrderByCategoryAscCaptureSequenceAsc(order.getId());
        dto.setTotalPhotos(photos.size());
        dto.setPhotos(photos.stream().map(this::toPhotoDto).collect(Collectors.toList()));

        return dto;
    }

    private InspectionPhotoDto toPhotoDto(InspectionPhoto photo) {
        InspectionPhotoDto dto = new InspectionPhotoDto();
        dto.setId(photo.getId());
        dto.setInspectionId(photo.getInspectionId());
        dto.setOrderId(photo.getOrderId());
        dto.setPaId(photo.getPaId());
        dto.setCategory(photo.getCategory());
        dto.setFilename(photo.getFilename());
        dto.setFileSizeBytes(photo.getFileSizeBytes());
        dto.setMimeType(photo.getMimeType());
        dto.setGpsLat(photo.getGpsLat());
        dto.setGpsLng(photo.getGpsLng());
        dto.setGpsAccuracy(photo.getGpsAccuracy());
        dto.setDeviceTimestamp(photo.getDeviceTimestamp());
        dto.setCaptureSequence(photo.getCaptureSequence());
        dto.setUploadedAt(photo.getUploadedAt());
        dto.setUploadedBy(photo.getUploadedBy());
        dto.setDownloadUrl("/api/v1/orders/" + photo.getOrderId() + "/inspection/photos/" + photo.getId() + "/download");
        return dto;
    }

    private void validatePaOrAdmin(Order order, UserDetailsImpl principal) {
        if (isSuperAdminOrAdmin(principal)) {
            return;
        }
        if (order.getPaId() == null || !order.getPaId().equals(principal.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Access denied: only the assigned Primary Analyst or Administrator can perform inspection operations.");
        }
    }

    private boolean isSuperAdminOrAdmin(UserDetailsImpl principal) {
        return principal.getAuthorities().stream().anyMatch(a ->
                "ROLE_SUPER_ADMIN".equals(a.getAuthority()) || "ROLE_ADMIN".equals(a.getAuthority()));
    }

    private String getPrincipalRole(UserDetailsImpl principal) {
        return principal.getAuthorities().stream()
                .map(a -> a.getAuthority().replace("ROLE_", ""))
                .findFirst().orElse("USER");
    }

    private List<Map<String, Object>> parseScheduleHistory(String historyJson) {
        if (historyJson == null || historyJson.trim().isEmpty() || "[]".equals(historyJson.trim())) {
            return new ArrayList<>();
        }
        try {
            return objectMapper.readValue(historyJson, new TypeReference<List<Map<String, Object>>>() {});
        } catch (Exception e) {
            log.warn("Could not parse schedule history JSON: {}", e.getMessage());
            return new ArrayList<>();
        }
    }

    private String computeMd5(byte[] data) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] digest = md.digest(data);
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException("MD5 calculation error", e);
        }
    }
}
