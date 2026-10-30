# Statutory Third-Party Data Processor Register (DPDP Act 2023 - Section 8)

**Entity / Data Fiduciary:** Pro Valuer OPC Pvt Ltd (`visadocs.online` / `provaluer.in`)  
**Corporate Registration:** CIN U74999TG2020OPC144820  
**Data Protection Officer:** CS / Adv. R. Parthasarathy (`dpo@provaluer.in` / `grievance@provaluer.in`)  
**Effective Date:** 2026-01-01 | **Review Frequency:** Quarterly | **Status:** Formally Executed & Audit Certified  

---

## 1. Statutory Context & Principles

Under **Section 8(2)** of the Digital Personal Data Protection Act, 2023 (DPDP Act):
> *"A Data Fiduciary may engage, appoint, use or involve a Data Processor to process personal data on its behalf in connection with any activity relating to offering of goods or services to Data Principals or for another purpose specified in this Act, only under a valid contract."*

Furthermore, under **Section 8(5)**:
> *"A Data Fiduciary shall protect personal data in its possession or under its control, including in respect of any processing undertaken by it or on its behalf by a Data Processor, by taking reasonable security safeguards to prevent personal data breach."*

This Register provides comprehensive public and regulatory disclosure of all third-party data processors engaged by Pro Valuer OPC Pvt Ltd.

---

## 2. Processor Inventory & Data Processing Register

| # | Processor Identity | Service & Function | Data Categories Processed | Geographic Processing Location | Legal Safeguards & DPA Status | Data Retention & Erasure Schedule | Security Safeguards Applied |
|---|--------------------|-------------------|---------------------------|--------------------------------|-------------------------------|-----------------------------------|-----------------------------|
| **1** | **Google LLC** *(Google Analytics 4)* | Web usage telemetry, latency metrics, page views | Masked Client IP, User Agent, Device Category, Timestamp *(Zero PII)* | Global (US / EU / Asia) | Standard Contractual Clauses (SCC), Google Data Processing Addendum executed | 14 Months maximum rolling retention; User-level deletion API supported | IP Anonymization enabled; `ga-disable` script flag for non-consenting users & minors |
| **2** | **Microsoft Corporation** *(Microsoft Clarity)* | Session replay, heatmaps, UX interaction diagnostics | Session telemetry, click events, viewport dimensions *(All PII masked)* | Global (US / EU) | Microsoft DPA & BAA executed; Section 8(2) DPDP Compliant | 30 Days rolling retention | Strict `data-clarity-mask="true"` on Name, Email, Phone, PAN, GSTIN, Address, Valuation Amount; Disabled for minors |
| **3** | **Telegram FZ-LLC** *(Telegram Bot API)* | Real-time operational dispatch alerts to Certified Property Analysts & Admins | Internal Task ID, Order Reference, Stage Transitions *(Zero PII, No Client Name/Phone/Address)* | EU / Global | Telegram API Terms of Service & Privacy Policy | Ephemeral transit (Messages cleared after delivery / acknowledgment) | HTTPS TLS 1.3 webhook with bot token rotation; zero plain-text customer PII in alert payloads |
| **4** | **Amazon Web Services Inc. / Google Workspace** *(SMTP & Transactional Mail Provider)* | Transactional dispatch of OTPs, valuation quotes, payment receipts, and digitally signed reports | Client Email, Client Name, Order ID, PDF Valuation Dossier | India Region (ap-south-1 Mumbai / Hyderabad) | AWS Customer Agreement with India DPDP Data Processing Addendum | Transient spooling (Deleted from mail queue within 72 hours of successful SMTP delivery) | End-to-End TLS 1.3 enforced (STARTTLS); DKIM, SPF, DMARC authenticated; AES-256 encrypted attachments |
| **5** | **Hetzner Online GmbH / DigitalOcean LLC** *(Cloud Infrastructure & Database Hosting)* | Application hosting, Spring Boot microservices, PostgreSQL encrypted storage, automated backups | Encrypted user records, Encrypted valuation leads, Documents in storage | EU / Bangalore Datacenter (India) | Data Processing Agreement executed under DPDP Section 8(2); ISO 27001 & SOC 2 Type II Certified | Active tenure of valuation order + 8 years statutory IBBI retention; encrypted offsite backup | AES-256-GCM column encryption; LUKS full-disk volume encryption; Zero public database port exposure (internal bridge network only); strict firewalling |

---

## 3. Child Data Protection (Section 9) Processor Constraint

- Under **Section 9(1)** of the DPDP Act 2023, data processing of children (< 18 years) requires verifiable parental consent.
- Under **Section 9(3)**, a Data Fiduciary shall not undertake tracking, behavioral monitoring, or targeted advertising directed at children.
- **Enforcement:** In our intake pipeline, if an applicant indicates minority status or Date of Birth < 18 years:
  1. Google Analytics 4 (`window['ga-disable-G-XXXX'] = true`) is permanently set.
  2. Microsoft Clarity scripts are blocked from initializing and downloading.
  3. No behavioral telemetry is transmitted to Google or Microsoft.

---

## 4. International Cross-Border Transfer Assessment (Section 16)

- None of the third-party processors listed operate in any jurisdictions restricted or blacklisted by the Central Government of India under Section 16 of the DPDP Act 2023.
- All primary databases containing personal data of Indian residents remain stored within the jurisdiction of India or compliant jurisdictions with reciprocal data protection frameworks.

---

## 5. Contact & Data Principal Inquiries

For inquiries regarding our Third-Party Data Processors or to inspect Data Processing Agreements:
- **Data Protection Officer:** CS / Adv. R. Parthasarathy
- **Email:** `dpo@provaluer.in` / `grievance@provaluer.in`
- **Address:** Pro Valuer OPC Pvt Ltd, Cyber Towers Unit 402, HITEC City, Hyderabad, Telangana 500081, India
