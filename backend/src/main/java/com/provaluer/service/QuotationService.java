package com.provaluer.service;

import com.provaluer.dto.LeadQuoteRequestDto;
import com.provaluer.model.LeadActivityLog;
import com.provaluer.model.LeadQuotation;
import com.provaluer.model.ValuationLead;
import com.provaluer.repository.LeadActivityLogRepository;
import com.provaluer.repository.LeadQuotationRepository;
import com.provaluer.repository.ValuationLeadRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.Year;

@Service
public class QuotationService {

    @Autowired
    private LeadQuotationRepository leadQuotationRepository;

    @Autowired
    private ValuationLeadRepository valuationLeadRepository;

    @Autowired
    private LeadActivityLogRepository leadActivityLogRepository;

    public QuotationService() {}

    public QuotationService(LeadQuotationRepository leadQuotationRepository,
                            ValuationLeadRepository valuationLeadRepository,
                            LeadActivityLogRepository leadActivityLogRepository) {
        this.leadQuotationRepository = leadQuotationRepository;
        this.valuationLeadRepository = valuationLeadRepository;
        this.leadActivityLogRepository = leadActivityLogRepository;
    }

    @Transactional
    public LeadQuotation generateQuote(Long leadId, LeadQuoteRequestDto quoteDto, String actorName) {
        ValuationLead lead = valuationLeadRepository.findById(leadId)
                .orElseThrow(() -> new IllegalArgumentException("Lead not found: " + leadId));

        BigDecimal fee = quoteDto.getEstimatedFee();
        BigDecimal gstRate = new BigDecimal("0.18");
        BigDecimal tax = fee.multiply(gstRate).setScale(2, RoundingMode.HALF_UP);
        BigDecimal total = fee.add(tax);

        String quoteNumber = "QUO-" + Year.now().getValue() + "-" + String.format("%04d", (int)(Math.random() * 9000) + 1000);

        LeadQuotation quotation = new LeadQuotation();
        quotation.setLead(lead);
        quotation.setQuoteNumber(quoteNumber);
        quotation.setEstimatedFee(fee);
        quotation.setTaxAmount(tax);
        quotation.setTotalFee(total);
        quotation.setTurnaroundDays(quoteDto.getTurnaroundDays());
        quotation.setScopeOfWork(quoteDto.getScopeOfWork());
        quotation.setTermsConditions(quoteDto.getTermsConditions());

        LeadQuotation saved = leadQuotationRepository.save(quotation);

        lead.setStatus("QUOTED");
        lead.setUpdatedAt(LocalDateTime.now());
        valuationLeadRepository.save(lead);

        leadActivityLogRepository.save(new LeadActivityLog(
                lead,
                "QUOTE_GENERATED",
                "Quotation " + quoteNumber + " generated for Rs " + total + " (" + quoteDto.getTurnaroundDays() + " days SLA)",
                actorName
        ));

        return saved;
    }
}
