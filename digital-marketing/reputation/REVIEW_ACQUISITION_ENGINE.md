# Phase 3: Review Acquisition Engine & Client Feedback System

**Core Standard:** 100% Genuine Client Feedback. **Zero fake reviews, zero review incentives, zero review gating or manipulation.**  
**Objective:** Systematically harvest 5-star Google Business Profile reviews from satisfied commercial, residential, banking, and visa valuation clients at the psychological peak of client satisfaction.

---

## 1. The Client Review Funnel

```
+-------------------------------------------------------------+
| Step 1: Valuation Report Handover / Digital Dispatch        |
| (Client inspects sealed dossier; verifies statutory stamps)  |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
| Step 2: Milestone Satisfaction Check (WhatsApp / SMS)       |
| "Did your valuation report meet all bank / embassy norms?"  |
+-------------------------------------------------------------+
                              |
          +-------------------+-------------------+
          |                                       |
    [Satisfied (4-5 Star)]                  [Needs Assistance (1-3 Star)]
          |                                       |
          v                                       v
+-----------------------------+     +-----------------------------+
| Direct Google Review Link   |     | Immediate Executive Call    |
| -> https://provaluer.in/    |     | Senior Partner addresses    |
|    review                   |     | document queries directly   |
| -> Google Maps 5-Star modal |     | within 2 hours              |
+-----------------------------+     +-----------------------------+
```

---

## 2. Review Collection Standard Operating Procedure (SOP)

| Step | Action Owner | Timing | Channel | Key Deliverable |
| :--- | :--- | :--- | :--- | :--- |
| **SOP-01: Dossier QR Card** | Valuation Binding Team | Day of Report Binding | Physical Insert | Glossy tamper-evident review card slipped inside the report cover dossier. |
| **SOP-02: Delivery Confirmation** | Client Relationship Officer | T + 2 Hours after Delivery | WhatsApp & SMS | Notification containing tracking link, PDF copy, and feedback invitation. |
| **SOP-03: Outcome Follow-up** | Relationship Partner | T + 3 Business Days | WhatsApp / Phone | Check if bank branch / visa officer accepted report without queries. |
| **SOP-04: Review Invitation** | Automated Dispatch Engine | T + 4 Days (Post-acceptance) | WhatsApp | Direct 1-tap Google Review shortlink (`https://www.provaluer.in/review`). |
| **SOP-05: Final Courtesy Check** | Practice Manager | T + 10 Days | Email / SMS | Final closure sequence for completed mandates. |

---

## 3. High-Conversion Follow-up Message Templates

### Template A: Immediate Post-Delivery (WhatsApp)
> *Namaste [Client Name],*  
> Your certified valuation dossier for **[Asset Identifier / Locality, e.g., Kokapet 3BHK Flat]** has been officially delivered and recorded under Mandate Ref **[Order Number]**.  
>  
> Your dossier is signed by our Government Approved Valuer under Section 34AB with official security QR verification.  
>  
> If our service met your expectations, could you take 30 seconds to support our practice with a Google review? It helps home buyers, NRI families, and businesses across Hyderabad find trusted valuers:  
> 🔗 **https://www.provaluer.in/review**  
>  
> *With regards,*  
> *ProValuer Commercial — Hyderabad Valuation Desk*

---

### Template B: Post-Bank Sanction / Visa Approval (T + 3 Days)
> *Dear [Client Name],*  
> Following up on your property valuation report submitted to **[Bank Name / Consulate]** — we trust the processing went smoothly without technical objections!  
>  
> If you were satisfied with our turnaround and technical defense, please share a brief word on Google:  
> 🔗 **https://www.provaluer.in/review**  
>  
> *(Feel free to mention the locality and turnaround time!)*  
> Thank you for trusting ProValuer Commercial.

---

### Template C: Physical Dossier QR Card Text (Printed on 300 GSM Art Card)
```
+---------------------------------------------------------------+
|                      PROVALUER COMMERCIAL                     |
|           Government Approved & IBBI Registered Valuers       |
|                                                               |
|           YOUR VALUATION DOSSIER HAS BEEN CERTIFIED           |
|                                                               |
|   Scan below to verify report authenticity and share your     |
|   experience on Google:                                       |
|                                                               |
|                     [  QR CODE LINKING  ]                     |
|                     [ TO PROVALUER.IN/  ]                     |
|                     [      REVIEW       ]                     |
|                                                               |
|   Dedicated Help Desk: +91 85000 19091 | provaluer.in         |
+---------------------------------------------------------------+
```

---

## 4. Review Status Tracker & Workflow Integration

Every mandate in the PostgreSQL database (`valuation_leads` and `orders`) transitions through review telemetry:

```
[MANDATE INITIATED] 
        -> [PHYSICAL INSPECTION] 
        -> [REPORT COMPILED & BOUND] 
        -> [DELIVERED TO CLIENT] 
        -> [REVIEW_INVITATION_SENT] 
        -> [REVIEW_COMPLETED (Tracked)]
```

### PostgreSQL Telemetry Tracking Columns
In `orders` or CRM audit metadata:
- `review_invited_at` (TIMESTAMP)
- `review_followup_at` (TIMESTAMP)
- `review_channel` (`WHATSAPP`, `SMS`, `PHYSICAL_DOSSIER`)
- `review_status` (`PENDING`, `CLICKED`, `REVIEWED`, `ESCALATED`)

---

## 5. Branch Response Matrix (Service-Specific Response Playbook)

| Category of Review | Target Response Time | Tone & Compliance Mandates | Key Anchors to Include |
| :--- | :--- | :--- | :--- |
| **Visa / Student Net Worth** | Within 12 Hours | Warm, supportive, congratulatory | Mention turnaround, embassy adherence, Wealth Tax Sec 34AB |
| **Bank Loan / Mortgage** | Within 12 Hours | Professional, institutional, technical | Mention PSU/Private bank acceptance, RBI compliance, Fair Market Value |
| **Flat / Villa Appraisal** | Within 12 Hours | Localized, acknowledging locality | Mention specific micro-market (Gachibowli, Kokapet, Jubilee Hills, UDS) |
| **Plant & Machinery / CE** | Within 24 Hours | Engineering precision, authoritative | Mention Chartered Engineer certificate, customs SVB, remaining useful life |
| **Neutral / Mixed Review** | Within 2 Hours | Empathetic, solutions-oriented | Provide Senior Partner direct phone number for resolution |
| **Critical Issue / Complaint**| Within 30 Minutes | Immediate de-escalation, no public arguing| Acknowledge, take conversation offline, resolve underlying query |
