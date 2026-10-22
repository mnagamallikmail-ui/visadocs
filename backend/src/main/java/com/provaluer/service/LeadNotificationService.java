package com.provaluer.service;

import com.provaluer.model.ValuationLead;
import com.provaluer.util.DataMaskingUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class LeadNotificationService {

    private static final Logger log = LoggerFactory.getLogger(LeadNotificationService.class);

    public void sendLeadAcknowledgement(ValuationLead lead) {
        log.info("[EMAIL NOTIFICATION] To: {}, Subject: Valuation Request Acknowledged — Ref: {}",
                DataMaskingUtil.maskEmail(lead.getContactEmail()), lead.getReferenceCode());
        log.info("[EMAIL BODY] Valuation mandate for '{}' ({}) has been received. " +
                "Estimated SLA: {}. Your lead reference code is {}. Our valuation desk is reviewing your documents.",
                lead.getAssetName(), lead.getServiceVertical(),
                lead.getUrgencySla(), lead.getReferenceCode());
    }

    public void alertPartnersOfHighIntentLead(ValuationLead lead) {
        log.warn("[PARTNER URGENT ALERT] 🔥 {} INTENT LEAD RECEIVED! Ref: {}, Entity: {}, Role: {}, Service: {}, Value: {}, SLA: {}, Phone: {}",
                lead.getIntentLevel(), lead.getReferenceCode(),
                lead.getCompanyName() != null ? lead.getCompanyName() : "Corporate Entity",
                lead.getContactRole(), lead.getServiceVertical(), lead.getValueBracket(),
                lead.getUrgencySla(), DataMaskingUtil.maskPhone(lead.getContactPhone()));
    }
}
