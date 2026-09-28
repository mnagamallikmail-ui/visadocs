package com.provaluer.service;

import com.provaluer.dto.LeadQuoteRequestDto;
import com.provaluer.dto.LeadRequestDto;
import com.provaluer.dto.LeadResponseDto;
import com.provaluer.model.LeadActivityLog;
import com.provaluer.model.LeadQuotation;
import com.provaluer.model.ValuationLead;
import com.provaluer.repository.LeadActivityLogRepository;
import com.provaluer.repository.LeadQuotationRepository;
import com.provaluer.repository.ValuationLeadRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class LeadScoringAndConversionEngineTest {

    @Mock
    private ValuationLeadRepository leadRepository;

    @Mock
    private LeadQuotationRepository quotationRepository;

    @Mock
    private LeadActivityLogRepository activityLogRepository;

    @Mock
    private LeadNotificationService notificationService;

    @Mock
    private DocumentUploadService documentUploadService;

    @Test
    @DisplayName("LeadScoringService correctly evaluates High/Critical commercial leads")
    void testLeadScoringCritical() {
        LeadScoringService realScoring = new LeadScoringService();
        LeadRequestDto dto = new LeadRequestDto();
        dto.setContactEmail("cfo@relianceindustries.com");
        dto.setContactRole("Chief Financial Officer");
        dto.setValueBracket("ABOVE_100CR");
        dto.setUrgencySla("24 Hours Express");
        dto.setDocumentCount(2);

        LeadScoringService.ScoreResult result = realScoring.calculateScore(dto);

        // Expected score: +30 (docs>=2) +25 (corp email) +15 (CFO role) +20 (asset) +10 (urgency) = 100
        assertEquals(100, result.score);
        assertEquals("CRITICAL", result.intentLevel);
    }

    @Test
    @DisplayName("LeadScoringService correctly evaluates Low intent residential/personal leads")
    void testLeadScoringLow() {
        LeadScoringService realScoring = new LeadScoringService();
        LeadRequestDto dto = new LeadRequestDto();
        dto.setContactEmail("user123@gmail.com");
        dto.setContactRole("Property Owner / Individual");
        dto.setValueBracket("UNDER_5CR");
        dto.setUrgencySla("Flexible (Within 2-3 Weeks)");
        dto.setDocumentCount(0);

        LeadScoringService.ScoreResult result = realScoring.calculateScore(dto);

        assertTrue(result.score < 35);
        assertEquals("LOW", result.intentLevel);
    }

    @Test
    @DisplayName("QuotationService calculates exact GST 18% and total valuation fee")
    void testQuotationCalculation() {
        QuotationService quotationService = new QuotationService(quotationRepository, leadRepository, activityLogRepository);

        ValuationLead lead = new ValuationLead();
        lead.setId(101L);
        lead.setReferenceCode("REQ-2026-0042");
        lead.setStatus("NEW");

        when(leadRepository.findById(101L)).thenReturn(Optional.of(lead));
        when(quotationRepository.save(any(LeadQuotation.class))).thenAnswer(i -> {
            LeadQuotation q = i.getArgument(0);
            q.setId(501L);
            return q;
        });

        LeadQuoteRequestDto dto = new LeadQuoteRequestDto();
        dto.setEstimatedFee(new BigDecimal("100000.00")); // ₹1,00,000 base fee
        dto.setTurnaroundDays(3);
        dto.setScopeOfWork("Full technical and statutory plant & machinery valuation for IBBI compliance.");
        dto.setTermsConditions("100% advance or 50% mobilization.");

        LeadQuotation quotation = quotationService.generateQuote(101L, dto, "Senior Partner");

        assertNotNull(quotation);
        assertEquals(new BigDecimal("100000.00"), quotation.getEstimatedFee());
        assertEquals(new BigDecimal("18000.00"), quotation.getTaxAmount());
        assertEquals(new BigDecimal("118000.00"), quotation.getTotalFee());
        assertTrue(quotation.getQuoteNumber().startsWith("QUO-"));
        assertEquals("QUOTED", lead.getStatus());
        verify(leadRepository, times(1)).save(lead);
        verify(activityLogRepository, times(1)).save(any(LeadActivityLog.class));
    }

    @Test
    @DisplayName("Lead creation automatically generates REQ-YYYY-XXXX serialized reference and scores lead")
    void testLeadCreationReferenceGeneration() {
        LeadScoringService realScoring = new LeadScoringService();
        LeadService serviceWithRealScoring = new LeadService(
                leadRepository,
                activityLogRepository,
                realScoring,
                documentUploadService,
                notificationService
        );

        when(leadRepository.save(any(ValuationLead.class))).thenAnswer(i -> {
            ValuationLead l = i.getArgument(0);
            l.setId(99L);
            return l;
        });

        LeadRequestDto dto = new LeadRequestDto();
        dto.setContactName("Rajesh Sharma");
        dto.setContactEmail("rajesh.sharma@tata.com");
        dto.setContactPhone("+91 98200 12345");
        dto.setCompanyName("Tata Projects Ltd");
        dto.setContactRole("VP Finance");
        dto.setServiceVertical("Plant & Machinery Valuation");
        dto.setMandatePurpose("Bank Collateral / Consortium Lending");
        dto.setValueBracket("25CR_100CR");
        dto.setUrgencySla("24 Hours Express");
        dto.setDocumentCount(2);

        LeadResponseDto created = serviceWithRealScoring.createLead(dto);

        assertNotNull(created);
        assertNotNull(created.getReferenceCode());
        assertTrue(created.getReferenceCode().startsWith("REQ-"));
        assertEquals("NEW", created.getStatus());
        assertEquals("Tata Projects Ltd", created.getCompanyName());
        assertTrue(created.getLeadScore() >= 80);
        assertEquals("CRITICAL", created.getIntentLevel());
    }
}
