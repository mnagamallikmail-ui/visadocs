package com.provaluer.controller;

import com.provaluer.model.*;
import com.provaluer.repository.*;
import com.provaluer.security.UserDetailsImpl;
import com.provaluer.service.AuditLogService;
import com.provaluer.service.DocumentWorkspaceService;
import com.provaluer.service.PricingService;
import com.provaluer.service.SlaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/v1/admin")
@PreAuthorize("hasRole('SUPER_ADMIN')")
public class SuperAdminController {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(SuperAdminController.class);

    @Autowired private UserRepository userRepository;
    @Autowired private OrderRepository orderRepository;
    @Autowired private OrderInputRepository orderInputRepository;
    @Autowired private OrderDocumentRepository orderDocumentRepository;
    @Autowired private RevisionRepository revisionRepository;
    @Autowired private TransactionRepository transactionRepository;
    @Autowired private PerformanceLedgerRepository performanceLedgerRepository;
    @Autowired private SystemSettingRepository systemSettingRepository;
    @Autowired private TemplateRepository templateRepository;
    @Autowired private AuditLogRepository auditLogRepository;
    @Autowired private PricingService pricingService;
    @Autowired private AuditLogService auditLogService;
    @Autowired private SlaService slaService;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private DocumentWorkspaceService documentWorkspaceService;

    // ─────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────
    private UserDetailsImpl currentPrincipal() {
        return (UserDetailsImpl) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
    }

    private String actorEmail() {
        return currentPrincipal().getUsername();
    }

    private Long actorId() {
        return currentPrincipal().getId();
    }

    // ─────────────────────────────────────────────
    // 1. USER MANAGEMENT
    // ─────────────────────────────────────────────

    @GetMapping("/users")
    public ResponseEntity<?> listAllUsers(
            @RequestParam(required = false) String role,
            @RequestParam(required = false, defaultValue = "false") boolean deletedOnly) {
        List<User> users;
        if (deletedOnly) {
            users = userRepository.findAllSoftDeleted();
        } else if (role != null && !role.isBlank()) {
            try {
                users = userRepository.findAllByRole(UserRole.valueOf(role.toUpperCase()));
            } catch (IllegalArgumentException e) {
                return ResponseEntity.badRequest().body("Invalid role: " + role);
            }
        } else {
            users = userRepository.findAllActive();
        }
        return ResponseEntity.ok(users);
    }

    @PostMapping("/users")
    @Transactional
    public ResponseEntity<?> createUser(@RequestBody CreateUserRequest req) {
        if (userRepository.findByEmailIgnoreCase(req.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Email already registered.");
        }
        UserRole role = UserRole.valueOf(req.getRole().toUpperCase());
        User user = new User();
        user.setEmail(req.getEmail());
        user.setFullName(req.getFullName());
        user.setMobileNumber(req.getMobileNumber());
        user.setPassword(passwordEncoder.encode(req.getPassword() != null ? req.getPassword() : "password"));
        user.setRole(role);
        user.setAcceptedTcVersion("v1.0");
        user.setCreatedAt(LocalDateTime.now());
        user.setUpdatedAt(LocalDateTime.now());
        User saved = userRepository.save(user);

        if (role == UserRole.PA || role == UserRole.SPA) {
            PerformanceLedger ledger = new PerformanceLedger();
            ledger.setEmployeeId(saved.getId());
            performanceLedgerRepository.save(ledger);
        }

        auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "USER_CREATE", "USER",
                String.valueOf(saved.getId()), null, req.getEmail(),
                "Created user " + req.getEmail() + " with role " + role);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/users/{id}")
    @Transactional
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody UpdateUserRequest req) {
        return userRepository.findById(id).map(user -> {
            String old = user.getEmail() + "|" + user.getRole() + "|" + user.getFullName();
            if (req.getEmail() != null) user.setEmail(req.getEmail());
            if (req.getFullName() != null) user.setFullName(req.getFullName());
            if (req.getMobileNumber() != null) user.setMobileNumber(req.getMobileNumber());
            user.setUpdatedAt(LocalDateTime.now());
            User saved = userRepository.save(user);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "USER_UPDATE", "USER",
                    String.valueOf(id), old, req.getEmail() + "|" + user.getRole(), "Updated user profile");
            return ResponseEntity.ok(saved);
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/users/{id}/lock")
    @Transactional
    public ResponseEntity<?> lockUser(@PathVariable Long id) {
        return userRepository.findById(id).map(user -> {
            user.setLocked(true);
            user.setUpdatedAt(LocalDateTime.now());
            userRepository.save(user);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "USER_LOCK", "USER",
                    String.valueOf(id), "unlocked", "locked", "Account locked by SUPER_ADMIN");
            return ResponseEntity.ok("User account locked.");
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/users/{id}/unlock")
    @Transactional
    public ResponseEntity<?> unlockUser(@PathVariable Long id) {
        return userRepository.findById(id).map(user -> {
            user.setLocked(false);
            user.setUpdatedAt(LocalDateTime.now());
            userRepository.save(user);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "USER_UNLOCK", "USER",
                    String.valueOf(id), "locked", "unlocked", "Account unlocked by SUPER_ADMIN");
            return ResponseEntity.ok("User account unlocked.");
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/users/{id}")
    @Transactional
    public ResponseEntity<?> softDeleteUser(@PathVariable Long id) {
        if (id.equals(actorId())) return ResponseEntity.badRequest().body("Cannot delete your own account.");
        return userRepository.findById(id).map(user -> {
            user.setDeleted(true);
            user.setDeletedAt(LocalDateTime.now());
            user.setUpdatedAt(LocalDateTime.now());
            userRepository.save(user);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "USER_DELETE", "USER",
                    String.valueOf(id), user.getEmail(), "deleted", "Soft-deleted user (7-day restore window)");
            return ResponseEntity.ok("User soft-deleted. Restore available for 7 days.");
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/users/{id}/hard")
    @Transactional
    public ResponseEntity<?> hardDeleteUser(@PathVariable Long id) {
        if (id.equals(actorId())) return ResponseEntity.badRequest().body("Cannot hard-delete your own account.");
        return userRepository.findById(id).map(user -> {
            String userEmail = user.getEmail();

            // 1. Cascade: remove order inputs for all orders belonging to this user
            List<Order> userOrders = orderRepository.findAllByClientId(id);
            for (Order order : userOrders) {
                orderInputRepository.deleteByOrderId(order.getId());
            }

            // 2. Cascade: remove the orders themselves
            orderRepository.deleteAll(userOrders);

            // 3. Cascade: remove performance ledger entry if staff
            performanceLedgerRepository.deleteByEmployeeId(id);

            // 4. Cascade: remove all audit logs for this user as actor
            auditLogRepository.deleteByActorId(id);

            // 5. Write final audit event BEFORE deleting user (using current admin as actor)
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "USER_HARD_DELETE", "USER",
                    String.valueOf(id), userEmail, "PURGED",
                    "PERMANENT hard-delete executed by SUPER_ADMIN — all cascaded records purged");

            // 6. Permanently remove the user
            userRepository.delete(user);

            return ResponseEntity.ok("User and all associated records permanently purged.");
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/users/{id}/restore")
    @Transactional
    public ResponseEntity<?> restoreUser(@PathVariable Long id) {
        return userRepository.findById(id).map(user -> {
            if (!user.isDeleted()) return ResponseEntity.badRequest().body("User is not deleted.");
            user.setDeleted(false);
            user.setDeletedAt(null);
            user.setUpdatedAt(LocalDateTime.now());
            userRepository.save(user);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "USER_RESTORE", "USER",
                    String.valueOf(id), "deleted", "active", "Restored soft-deleted user");
            return ResponseEntity.ok("User restored.");
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/users/{id}/role")
    @Transactional
    public ResponseEntity<?> changeUserRole(@PathVariable Long id, @RequestBody RoleChangeRequest req) {
        return userRepository.findById(id).map(user -> {
            String oldRole = user.getRole().name();
            UserRole newRole = UserRole.valueOf(req.getRole().toUpperCase());
            user.setRole(newRole);
            user.setUpdatedAt(LocalDateTime.now());
            userRepository.save(user);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "ROLE_CHANGE", "USER",
                    String.valueOf(id), oldRole, newRole.name(), "Role changed by SUPER_ADMIN");
            return ResponseEntity.ok("Role updated to " + newRole.name());
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/users/bulk-activate")
    @Transactional
    public ResponseEntity<?> bulkActivate(@RequestBody BulkIdsRequest req) {
        List<User> users = userRepository.findAllById(req.getIds());
        users.forEach(u -> { u.setLocked(false); u.setUpdatedAt(LocalDateTime.now()); });
        userRepository.saveAll(users);
        auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "BULK_ACTIVATE", "USER",
                req.getIds().toString(), null, "active", "Bulk activated " + users.size() + " users");
        return ResponseEntity.ok("Activated " + users.size() + " users.");
    }

    @PostMapping("/users/bulk-deactivate")
    @Transactional
    public ResponseEntity<?> bulkDeactivate(@RequestBody BulkIdsRequest req) {
        List<User> users = userRepository.findAllById(req.getIds());
        users.forEach(u -> { u.setLocked(true); u.setUpdatedAt(LocalDateTime.now()); });
        userRepository.saveAll(users);
        auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "BULK_DEACTIVATE", "USER",
                req.getIds().toString(), null, "locked", "Bulk deactivated " + users.size() + " users");
        return ResponseEntity.ok("Deactivated " + users.size() + " users.");
    }

    // ─────────────────────────────────────────────
    // 2. ORDER / WORKFLOW OVERRIDES
    // ─────────────────────────────────────────────

    @GetMapping("/orders")
    public ResponseEntity<?> listAllOrders(@RequestParam(required = false) String status) {
        List<Order> orders = (status != null && !status.isBlank())
                ? orderRepository.findAllByStatus(status)
                : orderRepository.findAllOrderedByCreatedAt();
        return ResponseEntity.ok(orders);
    }

    @PostMapping("/orders/{id}/reassign")
    @Transactional
    public ResponseEntity<?> reassignOrder(@PathVariable Long id, @RequestBody ReassignRequest req) {
        return orderRepository.findById(id).map(order -> {
            String oldPa = String.valueOf(order.getPaId());
            order.setPaId(req.getNewPaId());
            order.setClaimedAt(LocalDateTime.now());
            order.setLastHeartbeat(LocalDateTime.now());
            order.setUpdatedAt(LocalDateTime.now());
            orderRepository.save(order);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "FILE_REASSIGN", "ORDER",
                    String.valueOf(id), oldPa, String.valueOf(req.getNewPaId()),
                    "Order forcibly reassigned by SUPER_ADMIN");
            return ResponseEntity.ok("Order reassigned.");
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/orders/{id}/force-status")
    @Transactional
    public ResponseEntity<?> forceOrderStatus(@PathVariable Long id, @RequestBody ForceStatusRequest req) {
        return orderRepository.findById(id).map(order -> {
            String oldStatus = order.getStatus();
            order.setStatus(req.getStatus());
            order.setUpdatedAt(LocalDateTime.now());
            orderRepository.save(order);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "WORKFLOW_OVERRIDE", "ORDER",
                    String.valueOf(id), oldStatus, req.getStatus(),
                    "Status forced by SUPER_ADMIN: " + req.getReason());
            return ResponseEntity.ok("Order status forced to: " + req.getStatus());
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/orders/{id}/unlock-revision")
    @Transactional
    public ResponseEntity<?> unlockRevision(@PathVariable Long id, @RequestBody(required = false) RevisionLimitRequest req) {
        return orderRepository.findById(id).map(order -> {
            int oldLimit = order.getRevisionLimit();
            int newLimit = (req != null && req.getNewLimit() > 0) ? req.getNewLimit() : oldLimit + 1;
            order.setRevisionLimit(newLimit);
            order.setUpdatedAt(LocalDateTime.now());
            orderRepository.save(order);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "REVISION_UNLOCK", "ORDER",
                    String.valueOf(id), String.valueOf(oldLimit), String.valueOf(newLimit),
                    "Revision cap increased by SUPER_ADMIN");
            return ResponseEntity.ok("Revision limit updated to: " + newLimit);
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/orders/{id}/force-release")
    @Transactional
    public ResponseEntity<?> forceRelease(@PathVariable Long id) {
        return orderRepository.findById(id).map(order -> {
            String oldStatus = order.getStatus();
            order.setStatus("FINAL_DELIVERY");
            order.setBalanceDue(BigDecimal.ZERO);
            order.setUpdatedAt(LocalDateTime.now());
            orderRepository.save(order);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "REPORT_RELEASE_OVERRIDE", "ORDER",
                    String.valueOf(id), oldStatus, "FINAL_DELIVERY",
                    "Report forcibly released by SUPER_ADMIN");
            return ResponseEntity.ok("Order force-released to FINAL_DELIVERY.");
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/orders/{id}/sla-override")
    @Transactional
    public ResponseEntity<?> slaOverride(@PathVariable Long id, @RequestBody SlaOverrideRequest req) {
        return orderRepository.findById(id).map(order -> {
            String old = order.getSlaExpiryTime() != null ? order.getSlaExpiryTime().toString() : "null";
            order.setSlaExpiryTime(req.getNewExpiry());
            order.setUpdatedAt(LocalDateTime.now());
            orderRepository.save(order);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "SLA_OVERRIDE", "ORDER",
                    String.valueOf(id), old, req.getNewExpiry().toString(),
                    "SLA expiry overridden by SUPER_ADMIN");
            return ResponseEntity.ok("SLA expiry updated.");
        }).orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/orders/{id}/waive-payment")
    @Transactional
    public ResponseEntity<?> waivePayment(@PathVariable Long id) {
        return orderRepository.findById(id).map(order -> {
            String old = order.getBalanceDue() != null ? order.getBalanceDue().toString() : "0";
            order.setBalanceDue(BigDecimal.ZERO);
            order.setUpdatedAt(LocalDateTime.now());
            orderRepository.save(order);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "PAYMENT_WAIVE", "ORDER",
                    String.valueOf(id), old, "0",
                    "Balance payment waived by SUPER_ADMIN");
            return ResponseEntity.ok("Payment waived.");
        }).orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/orders/{id}/inputs")
    @Transactional
    public ResponseEntity<?> editOrderInputs(@PathVariable Long id, @RequestBody Map<String, String> inputs) {
        Order order = orderRepository.findById(id).orElse(null);
        if (order == null) return ResponseEntity.notFound().build();
        for (Map.Entry<String, String> entry : inputs.entrySet()) {
            Optional<OrderInput> existing = orderInputRepository.findByOrderIdAndFieldKey(id, entry.getKey());
            if (existing.isPresent()) {
                existing.get().setFieldValue(entry.getValue());
                orderInputRepository.save(existing.get());
            } else {
                orderInputRepository.save(new OrderInput(id, entry.getKey(), entry.getValue()));
            }
        }
        auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "ORDER_INPUT_EDIT", "ORDER",
                String.valueOf(id), null, inputs.toString(), "Order inputs edited directly by SUPER_ADMIN");
        return ResponseEntity.ok("Inputs updated.");
    }

    // ─────────────────────────────────────────────
    // 3. PRICING CONTROL
    // ─────────────────────────────────────────────

    @GetMapping("/pricing")
    public ResponseEntity<?> getPricingConfig() {
        return ResponseEntity.ok(pricingService.getAllConfigs());
    }

    @PutMapping("/pricing/{key}")
    @Transactional
    public ResponseEntity<?> updatePricingKey(@PathVariable String key, @RequestBody PricingUpdateRequest req) {
        try {
            PricingConfig updated = pricingService.updateConfig(key, req.getValue(), actorId());
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "PRICING_EDIT", "PRICING_CONFIG",
                    key, null, req.getValue().toString(), "Pricing key updated by SUPER_ADMIN");
            return ResponseEntity.ok(updated);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    // ─────────────────────────────────────────────
    // 4. T&C MANAGEMENT
    // ─────────────────────────────────────────────

    @GetMapping("/tc")
    public ResponseEntity<?> getTcStatus() {
        String version = systemSettingRepository.findById("tc_version")
                .map(s -> s.getSettingValue()).orElse("v1.0");
        long acceptedCount = userRepository.findAll().stream()
                .filter(u -> version.equals(u.getAcceptedTcVersion())).count();
        long pendingCount = userRepository.findAll().stream()
                .filter(u -> !version.equals(u.getAcceptedTcVersion()) && !u.isDeleted()).count();
        Map<String, Object> result = new HashMap<>();
        result.put("currentVersion", version);
        result.put("acceptedCount", acceptedCount);
        result.put("pendingCount", pendingCount);
        return ResponseEntity.ok(result);
    }

    @PutMapping("/tc")
    @Transactional
    public ResponseEntity<?> updateTcVersion(@RequestBody TcUpdateRequest req) {
        systemSettingRepository.findById("tc_version").ifPresent(s -> {
            String old = s.getSettingValue();
            s.setSettingValue(req.getVersion());
            systemSettingRepository.save(s);
            auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "TERMS_UPDATE", "SYSTEM",
                    "tc_version", old, req.getVersion(), "T&C version updated — all clients must re-accept");
        });
        return ResponseEntity.ok("T&C version updated to: " + req.getVersion() + ". Clients blocked until re-acceptance.");
    }

    @GetMapping("/tc/log")
    public ResponseEntity<?> getTcAcceptanceLog() {
        List<User> users = userRepository.findAll();
        String currentVersion = systemSettingRepository.findById("tc_version")
                .map(s -> s.getSettingValue()).orElse("v1.0");
        List<Map<String, Object>> log = new ArrayList<>();
        for (User u : users) {
            Map<String, Object> entry = new HashMap<>();
            entry.put("userId", u.getId());
            entry.put("email", u.getEmail());
            entry.put("role", u.getRole());
            entry.put("acceptedVersion", u.getAcceptedTcVersion());
            entry.put("compliant", currentVersion.equals(u.getAcceptedTcVersion()));
            log.add(entry);
        }
        return ResponseEntity.ok(log);
    }

    // ─────────────────────────────────────────────
    // 5. PERFORMANCE & SLA MONITORING
    // ─────────────────────────────────────────────

    @GetMapping("/performance")
    public ResponseEntity<?> getPerformanceLedger() {
        List<PerformanceLedger> ledgers = performanceLedgerRepository.findAll();
        List<Map<String, Object>> result = new ArrayList<>();
        for (PerformanceLedger l : ledgers) {
            userRepository.findById(l.getEmployeeId()).ifPresent(u -> {
                Map<String, Object> entry = new HashMap<>();
                entry.put("employeeId", l.getEmployeeId());
                entry.put("email", u.getEmail());
                entry.put("fullName", u.getFullName());
                entry.put("role", u.getRole());
                entry.put("activeAllocations", l.getActiveAllocations());
                entry.put("filesCompleted", l.getFilesCompleted());
                entry.put("slaTimeouts", l.getSlaTimeouts());
                entry.put("freezeCounts", l.getFreezeCounts());
                result.add(entry);
            });
        }
        return ResponseEntity.ok(result);
    }

    @GetMapping("/sla-status")
    public ResponseEntity<?> getSlaStatus() {
        List<Order> active = orderRepository.findAllActiveSlaOrders();
        List<Map<String, Object>> result = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        for (Order o : active) {
            Map<String, Object> entry = new HashMap<>();
            entry.put("orderId", o.getId());
            entry.put("status", o.getStatus());
            entry.put("purpose", o.getPurpose());
            entry.put("paId", o.getPaId());
            entry.put("slaExpiry", o.getSlaExpiryTime());
            if (o.getSlaExpiryTime() != null) {
                boolean overdue = now.isAfter(o.getSlaExpiryTime());
                double remaining = overdue ? 0 : slaService.getRemainingBusinessHours(now, o.getSlaExpiryTime());
                entry.put("overdue", overdue);
                entry.put("remainingHours", Math.round(remaining * 10.0) / 10.0);
                entry.put("slaHealth", overdue ? "CRITICAL" : (remaining < 4 ? "WARNING" : "OK"));
            } else {
                entry.put("overdue", false);
                entry.put("remainingHours", null);
                entry.put("slaHealth", "PENDING");
            }
            result.add(entry);
        }
        return ResponseEntity.ok(result);
    }

    // ─────────────────────────────────────────────
    // 6. SYSTEM OVERVIEW STATS
    // ─────────────────────────────────────────────

    @GetMapping("/overview")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
    public ResponseEntity<?> getOverviewStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalUsers", userRepository.findAllActive().size());
        stats.put("totalOrders", orderRepository.count());
        stats.put("openOrders", orderRepository.findAllByStatus("PAID_INTAKE").size()
                + orderRepository.findAllByStatus("ASSIGNED").size());
        stats.put("spaGateOrders", orderRepository.findAllByStatus("SPA_GATE").size());
        stats.put("finalDeliveryOrders", orderRepository.findAllByStatus("FINAL_DELIVERY").size());
        stats.put("activeTemplates", templateRepository.findAllByIsActive("Y").size());
        stats.put("recentAuditLogs", auditLogRepository.findTop50ByOrderByTimestampDesc().size());
        return ResponseEntity.ok(stats);
    }

    // ─────────────────────────────────────────────
    // REQUEST DTOs
    // ─────────────────────────────────────────────

    public static class CreateUserRequest {
        private String email, fullName, mobileNumber, password, role;
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getFullName() { return fullName; }
        public void setFullName(String fullName) { this.fullName = fullName; }
        public String getMobileNumber() { return mobileNumber; }
        public void setMobileNumber(String mobileNumber) { this.mobileNumber = mobileNumber; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }
    }

    public static class UpdateUserRequest {
        private String email, fullName, mobileNumber;
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getFullName() { return fullName; }
        public void setFullName(String fullName) { this.fullName = fullName; }
        public String getMobileNumber() { return mobileNumber; }
        public void setMobileNumber(String mobileNumber) { this.mobileNumber = mobileNumber; }
    }

    public static class RoleChangeRequest {
        private String role;
        public String getRole() { return role; }
        public void setRole(String role) { this.role = role; }
    }

    public static class BulkIdsRequest {
        private List<Long> ids;
        public List<Long> getIds() { return ids; }
        public void setIds(List<Long> ids) { this.ids = ids; }
    }

    public static class ReassignRequest {
        private Long newPaId;
        public Long getNewPaId() { return newPaId; }
        public void setNewPaId(Long newPaId) { this.newPaId = newPaId; }
    }

    public static class ForceStatusRequest {
        private String status, reason;
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        public String getReason() { return reason; }
        public void setReason(String reason) { this.reason = reason; }
    }

    public static class RevisionLimitRequest {
        private int newLimit;
        public int getNewLimit() { return newLimit; }
        public void setNewLimit(int newLimit) { this.newLimit = newLimit; }
    }

    public static class SlaOverrideRequest {
        private LocalDateTime newExpiry;
        public LocalDateTime getNewExpiry() { return newExpiry; }
        public void setNewExpiry(LocalDateTime newExpiry) { this.newExpiry = newExpiry; }
    }

    public static class PricingUpdateRequest {
        private BigDecimal value;
        public BigDecimal getValue() { return value; }
        public void setValue(BigDecimal value) { this.value = value; }
    }

    public static class TcUpdateRequest {
        private String version;
        public String getVersion() { return version; }
        public void setVersion(String version) { this.version = version; }
    }

    @PostMapping("/orders")
    @PreAuthorize("hasRole('SUPER_ADMIN')")
    @Transactional
    public ResponseEntity<?> createOrder(@RequestBody SuperAdminCreateOrderRequest req) {
        Order order = new Order();
        Long clientId = req.getClientId();
        if (clientId == null) {
            clientId = userRepository.findAllActive().stream()
                    .filter(u -> u.getRole() == UserRole.CLIENT)
                    .map(User::getId)
                    .findFirst()
                    .orElse(actorId());
        }
        order.setClientId(clientId);
        order.setPropertyCategory(req.getPropertyCategory());
        order.setPurpose(req.getPurpose());
        order.setEstimatedValue(req.getEstimatedValue());
        order.setTemplateId(req.getTemplateId());
        order.setStatus("DRAFT");
        
        if (req.getTemplateId() != null) {
            templateRepository.findById(req.getTemplateId()).ifPresent(t -> {
                order.setFieldMappingSnapshot(t.getFieldMapping());
            });
        }
        
        Order saved = orderRepository.save(order);
        
        if (req.getInputs() != null) {
            for (Map.Entry<String, String> entry : req.getInputs().entrySet()) {
                orderInputRepository.save(new OrderInput(saved.getId(), entry.getKey(), entry.getValue()));
            }
        }
        
        auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "ORDER_CREATE", "ORDER",
                String.valueOf(saved.getId()), null, null, "Created order directly by SUPER_ADMIN");
        return ResponseEntity.ok(saved);
    }

    /**
     * DELETE /api/v1/admin/reports/purge-all
     * Administrative purge of all orders, inputs, documents, revisions, and performance ledger
     * allowing the team to start completely afresh with clean state.
     */
    @DeleteMapping("/reports/purge-all")
    @Transactional
    public ResponseEntity<?> purgeAllReports() {
        log.warn("SUPER_ADMIN #{} initiated purge of ALL report and order data.", actorId());
        
        long docsDeleted = orderDocumentRepository.count();
        orderDocumentRepository.deleteAll();

        long inputsDeleted = orderInputRepository.count();
        orderInputRepository.deleteAll();

        long revisionsDeleted = revisionRepository.count();
        revisionRepository.deleteAll();

        long ledgerDeleted = performanceLedgerRepository.count();
        performanceLedgerRepository.deleteAll();

        long transactionsDeleted = transactionRepository.count();
        transactionRepository.deleteAll();

        long ordersDeleted = orderRepository.count();
        orderRepository.deleteAll();

        auditLogService.log(actorId(), actorEmail(), "SUPER_ADMIN", "PURGE_ALL_REPORTS", "ORDER",
                null, null, null, String.format("Purged %d orders, %d inputs, %d documents, %d revisions", ordersDeleted, inputsDeleted, docsDeleted, revisionsDeleted));

        return ResponseEntity.ok(Map.of(
            "status", "SUCCESS",
            "message", "All orders and reports successfully purged. System reset for fresh start.",
            "purgedOrders", ordersDeleted,
            "purgedDocuments", docsDeleted,
            "purgedInputs", inputsDeleted,
            "purgedRevisions", revisionsDeleted
        ));
    }

    public static class SuperAdminCreateOrderRequest {
        private String propertyCategory;
        private String purpose;
        private BigDecimal estimatedValue;
        private Long templateId;
        private Long clientId;
        private Map<String, String> inputs;

        public String getPropertyCategory() { return propertyCategory; }
        public void setPropertyCategory(String propertyCategory) { this.propertyCategory = propertyCategory; }
        public String getPurpose() { return purpose; }
        public void setPurpose(String purpose) { this.purpose = purpose; }
        public BigDecimal getEstimatedValue() { return estimatedValue; }
        public void setEstimatedValue(BigDecimal estimatedValue) { this.estimatedValue = estimatedValue; }
        public Long getTemplateId() { return templateId; }
        public void setTemplateId(Long templateId) { this.templateId = templateId; }
        public Long getClientId() { return clientId; }
        public void setClientId(Long clientId) { this.clientId = clientId; }
        public Map<String, String> getInputs() { return inputs; }
        public void setInputs(Map<String, String> inputs) { this.inputs = inputs; }
    }

    // ─────────────────────────────────────────────
    // DOM SNAPSHOT AUDIT
    // ─────────────────────────────────────────────

    /**
     * POST /api/v1/admin/dom-snapshot-audit
     *
     * Audits every order's documentDomSnapshot against its template version.
     * Rebuilds stale or missing snapshots from the live DOCX binary.
     * Returns per-order results including image placeholder verification for
     * IMG_FRONT_PAGE and IMG_PIC1–IMG_PIC8.
     */
    @PostMapping("/dom-snapshot-audit")
    public ResponseEntity<?> auditDomSnapshots() {
        log.info("DOM snapshot audit triggered by SUPER_ADMIN: {}", actorEmail());
        Map<String, Object> result = documentWorkspaceService.auditAndRebuildDomSnapshots();
        return ResponseEntity.ok(result);
    }
}
