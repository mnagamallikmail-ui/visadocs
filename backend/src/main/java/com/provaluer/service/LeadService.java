package com.provaluer.service;

import com.provaluer.dto.LeadAssignDto;
import com.provaluer.dto.LeadRequestDto;
import com.provaluer.dto.LeadResponseDto;
import com.provaluer.dto.LeadStatusUpdateDto;
import com.provaluer.model.LeadActivityLog;
import com.provaluer.model.LeadDocument;
import com.provaluer.model.ValuationLead;
import com.provaluer.repository.LeadActivityLogRepository;
import com.provaluer.repository.ValuationLeadRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.Year;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class LeadService {

    @Autowired
    private ValuationLeadRepository valuationLeadRepository;

    @Autowired
    private LeadActivityLogRepository leadActivityLogRepository;

    @Autowired
    private LeadScoringService leadScoringService;

    @Autowired
    private DocumentUploadService documentUploadService;

    @Autowired
    private LeadNotificationService leadNotificationService;

    public LeadService() {}

    public LeadService(ValuationLeadRepository valuationLeadRepository,
                       LeadActivityLogRepository leadActivityLogRepository,
                       LeadScoringService leadScoringService,
                       DocumentUploadService documentUploadService,
                       LeadNotificationService leadNotificationService) {
        this.valuationLeadRepository = valuationLeadRepository;
        this.leadActivityLogRepository = leadActivityLogRepository;
        this.leadScoringService = leadScoringService;
        this.documentUploadService = documentUploadService;
        this.leadNotificationService = leadNotificationService;
    }

    @Transactional
    public LeadResponseDto createLead(LeadRequestDto dto) {
        String refCode;
        do {
            refCode = "REQ-" + Year.now().getValue() + "-" + String.format("%04d", (int)(Math.random() * 9000) + 1000);
        } while (valuationLeadRepository.existsByReferenceCode(refCode));

        LeadScoringService.ScoreResult scoreResult = leadScoringService.calculateScore(dto);

        ValuationLead lead = new ValuationLead();
        lead.setReferenceCode(refCode);
        lead.setServiceVertical(dto.getServiceVertical());
        lead.setMandatePurpose(dto.getMandatePurpose());
        lead.setAssetName(dto.getAssetName());
        lead.setAssetLocation(dto.getAssetLocation());
        lead.setValueBracket(dto.getValueBracket());
        lead.setUrgencySla(dto.getUrgencySla());
        lead.setContactName(dto.getContactName());
        lead.setContactRole(dto.getContactRole());
        lead.setCompanyName(dto.getCompanyName());
        lead.setContactEmail(dto.getContactEmail());
        lead.setContactPhone(dto.getContactPhone());
        lead.setPreferredChannel(dto.getPreferredChannel() != null ? dto.getPreferredChannel() : "EMAIL");
        lead.setLeadScore(scoreResult.score);
        lead.setIntentLevel(scoreResult.intentLevel);
        lead.setConsentGiven(dto.isConsentGiven());
        lead.setConsentTimestamp(LocalDateTime.now());
        lead.setStatus("NEW");

        ValuationLead saved = valuationLeadRepository.save(lead);

        leadActivityLogRepository.save(new LeadActivityLog(
                saved,
                "LEAD_CREATED",
                "Lead submitted via commercial intake. Score: " + scoreResult.score + " (" + scoreResult.intentLevel + ")",
                "SYSTEM"
        ));

        // Trigger notifications
        leadNotificationService.sendLeadAcknowledgement(saved);
        if ("HIGH".equals(scoreResult.intentLevel) || "CRITICAL".equals(scoreResult.intentLevel)) {
            leadNotificationService.alertPartnersOfHighIntentLead(saved);
        }

        return LeadResponseDto.fromEntity(saved);
    }

    @Transactional
    public LeadResponseDto uploadDocumentsForLead(Long leadId, MultipartFile[] files) throws IOException {
        ValuationLead lead = valuationLeadRepository.findById(leadId)
                .orElseThrow(() -> new IllegalArgumentException("Lead not found: " + leadId));

        List<LeadDocument> savedDocs = documentUploadService.uploadDocuments(lead, files);

        // Recalculate lead score with documents attached
        LeadRequestDto dto = new LeadRequestDto();
        dto.setDocumentCount(lead.getDocuments().size() + savedDocs.size());
        dto.setContactEmail(lead.getContactEmail());
        dto.setContactRole(lead.getContactRole());
        dto.setValueBracket(lead.getValueBracket());
        dto.setUrgencySla(lead.getUrgencySla());

        LeadScoringService.ScoreResult scoreResult = leadScoringService.calculateScore(dto);
        lead.setLeadScore(scoreResult.score);
        lead.setIntentLevel(scoreResult.intentLevel);
        lead.setUpdatedAt(LocalDateTime.now());
        valuationLeadRepository.save(lead);

        leadActivityLogRepository.save(new LeadActivityLog(
                lead,
                "DOCUMENTS_UPLOADED",
                savedDocs.size() + " document(s) uploaded. Updated score: " + scoreResult.score,
                "CLIENT"
        ));

        return LeadResponseDto.fromEntity(lead);
    }

    @Transactional
    public LeadResponseDto getLeadById(Long id, String actorName) {
        ValuationLead lead = valuationLeadRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Lead not found: " + id));

        leadActivityLogRepository.save(new LeadActivityLog(
                lead,
                "LEAD_VIEWED",
                "Lead dossier inspected by " + (actorName != null ? actorName : "SYSTEM"),
                actorName != null ? actorName : "SYSTEM"
        ));

        return LeadResponseDto.fromEntity(lead);
    }

    public LeadResponseDto getLeadById(Long id) {
        return getLeadById(id, "ADMIN");
    }

    public List<LeadResponseDto> getLeads(String status, String service, String intent) {
        return valuationLeadRepository.searchLeads(status, service, intent)
                .stream()
                .map(LeadResponseDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public LeadResponseDto updateStatus(Long id, LeadStatusUpdateDto dto, String actorName) {
        ValuationLead lead = valuationLeadRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Lead not found: " + id));

        String oldStatus = lead.getStatus();
        lead.setStatus(dto.getStatus());
        lead.setUpdatedAt(LocalDateTime.now());
        valuationLeadRepository.save(lead);

        leadActivityLogRepository.save(new LeadActivityLog(
                lead,
                "STATUS_UPDATED",
                "Status transitioned from " + oldStatus + " to " + dto.getStatus() + (dto.getNote() != null ? " — Note: " + dto.getNote() : ""),
                actorName
        ));

        return LeadResponseDto.fromEntity(lead);
    }

    @Transactional
    public LeadResponseDto assignValuer(Long id, LeadAssignDto dto) {
        ValuationLead lead = valuationLeadRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Lead not found: " + id));

        lead.setAssignedValuerId(dto.getValuerId());
        lead.setUpdatedAt(LocalDateTime.now());
        valuationLeadRepository.save(lead);

        leadActivityLogRepository.save(new LeadActivityLog(
                lead,
                "VALUER_ASSIGNED",
                "Assigned to Valuer ID #" + dto.getValuerId(),
                dto.getAssignerName() != null ? dto.getAssignerName() : "ADMIN"
        ));

        return LeadResponseDto.fromEntity(lead);
    }
}
