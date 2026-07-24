package com.provaluer.controller;

import com.provaluer.model.AuditLog;
import com.provaluer.repository.AuditLogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/audit")
@PreAuthorize("hasAnyRole('SUPER_ADMIN', 'ADMIN')")
public class AuditController {

    @Autowired
    private AuditLogRepository auditLogRepository;

    @GetMapping
    public ResponseEntity<?> getAuditLogs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        Page<AuditLog> logs = auditLogRepository.findAllByOrderByTimestampDesc(
                PageRequest.of(page, size));
        return ResponseEntity.ok(logs.getContent());
    }

    @GetMapping("/actor/{actorId}")
    public ResponseEntity<?> getLogsByActor(@PathVariable Long actorId) {
        List<AuditLog> logs = auditLogRepository.findAllByActorIdOrderByTimestampDesc(actorId);
        return ResponseEntity.ok(logs);
    }

    @GetMapping("/entity/{entityType}/{entityId}")
    public ResponseEntity<?> getLogsByEntity(@PathVariable String entityType, @PathVariable String entityId) {
        List<AuditLog> logs = auditLogRepository.findAllByEntityTypeAndEntityIdOrderByTimestampDesc(entityType, entityId);
        return ResponseEntity.ok(logs);
    }
}
