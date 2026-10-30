# RELEASE NOTES - PROVALUER COMMERCIAL & VISA VALUATION PLATFORM
**Release Version:** v1.0.0-production  
**Release Date:** October 30, 2026  
**Git Tag:** `v1.0.0-production`  
**Classification:** Production Release & Compliance Seal

---

## 1. EXECUTIVE SUMMARY
ProValuer Commercial Platform Release `v1.0.0-production` establishes an enterprise-grade, DPDP Act 2023 certified property valuation and immigration visa solvency certification platform. This release incorporates comprehensive security remediations, column-level AES-256-GCM encryption, privileged TOTP MFA, automated child data protection workflows, and full Data Principal rights fulfillment.

---

## 2. PRODUCTION FEATURES & CAPABILITIES
- **Automated Property Valuation Workspace:** Multi-tier valuation engines supporting land, commercial real estate, agricultural assets, and residential developments.
- **Official Visa Valuation Certification:** Automated Docx4j compiled report generation aligned with embassy net worth guidelines (Canada, US, UK, Australia, Schengen).
- **Intake Pipeline & Document Staging:** Frictionless customer lead submission with secure UUID-bound document uploads.
- **Multilingual Public Notice Framework:** Instant on-page statutory policies and notices served in English, Hindi, and Telugu.
- **Interactive Privacy Hub:** Comprehensive web portal providing self-service access for Data Principals to manage consents, request corrections, trigger erasures, and register nominees.

---

## 3. SECURITY & PERIMETER ENHANCEMENTS
- **Zero Hardcoded Secrets:** Spring Boot and Docker Compose configurations purged of static fallback credentials; fail-fast enforcement (`${APP_JWT_SECRET}`, `${SPRING_DATASOURCE_PASSWORD}`, `${DPDP_ENCRYPTION_KEY}`).
- **Network Perimeter Isolation:** Database port exposure eliminated (5432, 5434, 5435 closed to external networks); PostgreSQL strictly isolated within internal Docker bridge network.
- **Privileged Role MFA (RFC 6238):** Mandatory TOTP authentication and hashed emergency recovery codes enforced for `ADMIN`, `SUPER_ADMIN`, `PA`, and `SPA` roles.
- **Anti-Brute Force & Rate Limiting:** Account lockout triggered after 5 consecutive failed login attempts (15-minute lock); 5 requests/min per IP rate limiting on public intake endpoints.
- **Nginx Security Hardening:** Strict Transport Security (HSTS 2-year preload), Content Security Policy (CSP), X-Frame-Options (SAMEORIGIN), nosniff, and 30MB payload boundaries.
- **Upload Token Authorization:** Secure 36-character UUID token gating on `/api/leads/{id}/documents` preventing unauthenticated file injection.

---

## 4. DPDP ACT 2023 ENHANCEMENTS (COMPLIANCE CERTIFIED)
- **Column-Level Cryptography (AES-256-GCM):** Data-at-rest encryption applied to `users.full_name`, `users.email`, `users.mobile_number`, and `valuation_leads.contact_name`, `contact_email`, `contact_phone`.
- **High-Performance Blind Indexing:** HMAC-SHA256 blind indexing (`email_hash`) enabling deterministic, indexed database queries without decrypting entire tables.
- **Affirmative Statutory Consent:** Default unchecked consent states (`consentGiven = false`); immutable audit trail capturing IP address, notice checksum, and timestamp.
- **Child Data Protection (Section 9):** Automated detection of applicants under 18 years; mandatory legal guardian consent capture; permanent client-side deactivation of Google Analytics 4 and Microsoft Clarity.
- **Data Principal Rights Suite (Sections 11–14):**
  - Instant Profile Summary & Data Export (JSON/ZIP bundle).
  - Purpose-wise consent withdrawal.
  - Correction & Profile Update endpoints.
  - Right to Nominate in the event of death or incapacity.
  - DPO Grievance Desk (`dpo@visadocs.online`) with statutory 7-day resolution tracking.

---

## 5. DATABASE SCHEMA VERSION
- **Flyway Current Version:** `V36__dpdp_pii_encryption_and_mfa.sql`
- **Schema Enhancements:**
  - Column length expansion (`VARCHAR(1024)`) for ciphertext containment.
  - `email_hash` and `contact_email_hash` indexed columns.
  - `user_mfa_recovery_codes` table with salted BCrypt hashes.
  - `guardian_consent_ledger` and `privacy_nominees` audit tables.

---

## 6. KNOWN LIMITATIONS & OPERATIONAL CONSTRAINTS
- **Cold Disaster Recovery:** Current containerized database operates with RPO $\le$ 1 hour and RTO $\le$ 4 hours via automated snapshot backups and WAL shipping. Synchronous multi-region clustering is scheduled for v1.1.0.
- **Telemetry Script CSP Whitelisting:** External telemetry scripts (GA4 and MS Clarity) are governed by strict CSP headers and client-side masking; ad-blockers will block analytics without impacting core valuation workflows.
