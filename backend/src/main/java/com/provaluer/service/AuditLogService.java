package com.provaluer.service;

import com.provaluer.model.AuditLog;
import com.provaluer.repository.AuditLogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AuditLogService {

    @Autowired
    private AuditLogRepository auditLogRepository;

    /**
     * Records an immutable audit log entry for any system action.
     * All SUPER_ADMIN actions MUST be passed through this method.
     */
    public void log(Long actorId, String actorEmail, String actorRole,
                    String actionType, String entityType, String entityId,
                    String oldValue, String newValue, String description) {
        AuditLog entry = new AuditLog(
            actorId, actorEmail, actorRole,
            actionType, entityType, entityId,
            oldValue, newValue, description
        );
        auditLogRepository.save(entry);
    }

    public void log(Long actorId, String actorEmail, String actorRole,
                    String actionType, String entityType, String entityId, String description) {
        log(actorId, actorEmail, actorRole, actionType, entityType, entityId, null, null, description);
    }
}
