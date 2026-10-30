# Statutory Data Processing Agreement (DPA) Compliance Checklist

**Statutory Framework:** Digital Personal Data Protection Act, 2023 (DPDP Act, India)  
**Applicability:** Sections 8(2), 8(5), 8(6), 8(7), 9, 11, 12, 13, 14, and 16  
**Auditor / Compliance Officer:** Principal Privacy Engineer & DPDP Compliance Remediation Officer  
**Last Review:** 2026-10-30 | **Status:** Mandatory Enforcement Protocol  

---

## Statutory Checklist for Vendor & Processor Onboarding

Every vendor, cloud service provider, contractor, or technology partner processing personal data on behalf of **Pro Valuer OPC Pvt Ltd** must undergo review against the following 10 statutory criteria before agreement execution:

### 1. Valid Written Contractual Mandate (Section 8(2))
- [x] Written contract formally executed between Data Fiduciary and Data Processor.
- [x] Clear scope, nature, and purpose of processing specified in agreement schedules.
- [x] Explicit prohibition against processing data for any secondary or unauthorized purposes.
- [x] Processor legally bound to act solely upon documented instructions from Pro Valuer OPC Pvt Ltd.

### 2. Duty to Implement Reasonable Technical & Organizational Safeguards (Section 8(5))
- [x] Processor maintains ISO 27001, SOC 2 Type II, or equivalent third-party verified cybersecurity certification.
- [x] AES-256-GCM encryption enforced for personal data in transit (TLS 1.3) and at rest.
- [x] Strict Role-Based Access Control (RBAC) with Least Privilege access enforced.
- [x] Periodic independent vulnerability assessments and penetration testing (VAPT) performed at least annually.

### 3. Immediate Personal Data Breach Notification (Section 8(6))
- [x] Obligation on the processor to notify Pro Valuer OPC Pvt Ltd of any confirmed or suspected data breach **within 6 hours** of discovery.
- [x] Mandatory breach notification details: Affected data principal count, nature of compromised records, containment measures taken, and technical point of contact.
- [x] Obligation to assist Pro Valuer OPC Pvt Ltd in complying with statutory reporting to the Data Protection Board of India (DPBI) and affected Data Principals.

### 4. Data Erasure and Purge Upon Purpose Fulfillment (Section 8(7))
- [x] Processor mandated to permanently erase or cryptographically shred personal data upon:
  - Completion of contracted services;
  - Termination of the DPA; or
  - Statutory erasure request received from Pro Valuer OPC Pvt Ltd.
- [x] Written certificate of destruction required within 14 business days of contract termination.
- [x] Prohibition against retaining copies, cached logs, or derived data sets unless explicitly required by applicable law.

### 5. Child and Minor Data Restrictions (Section 9)
- [x] Strict prohibition against undertaking behavioral tracking, profiling, or targeted advertisements directed at children (< 18 years).
- [x] Permanent suppression of analytics/telemetry cookies for student/minor valuation records.

### 6. Sub-Processor Engagement Governance
- [x] Prior written authorization required before engaging any downstream sub-processor.
- [x] The processor remains fully liable for the acts, defaults, and negligence of any sub-processor.
- [x] Sub-processors must be bound by contractual terms no less restrictive than this DPA.

### 7. Support for Data Principal Rights (Sections 11, 12, 13, 14)
- [x] Technical API or administrative mechanism to extract full personal data in structured, machine-readable format within 48 hours for Right of Access (Export).
- [x] Mechanism to modify, correct, or delete records upon Data Principal correction/erasure requests.
- [x] Support for audit trail logging of all access and modification events.

### 8. Audit, Inspection & Compliance Verification Rights
- [x] Right of Pro Valuer OPC Pvt Ltd or its appointed independent auditor to conduct annual privacy and security audits of the processor's systems.
- [x] Obligation of the processor to make available all information necessary to demonstrate compliance with the DPDP Act 2023.

### 9. Cross-Border Transfer Compliance (Section 16)
- [x] Personal data cannot be transferred to or processed in any country or territory blacklisted or restricted by the Central Government of India under Section 16.
- [x] If transferred across borders, valid cross-border transfer agreements and Standard Contractual Clauses (SCCs) must be in place.

### 10. Indemnification & Regulatory Penalties
- [x] Processor contractually indemnifies Pro Valuer OPC Pvt Ltd against all administrative fines, penalties levied by the Data Protection Board of India (up to ₹ 250 Crores under Schedule of Penalties), and third-party damages arising from processor breach or negligence.

---

## Sign-off & Verification

- **Compliance Lead:** CS / Adv. R. Parthasarathy (DPO)
- **Principal Security Architect:** Head of Security Engineering & DevSecOps
- **Review Cycle:** Bi-annual review or upon material update to DPDP Rules
