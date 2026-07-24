# Project Specifications & Inputs Registry

This document registers and tracks all user inputs, design guidelines, and templates provided across the 4 phases of development. Any potential conflicts will be documented here and brought to your attention.

## Phase Inputs Tracker

| Phase | Input Description | Date Registered | Status / Conflicts |
| :--- | :--- | :--- | :--- |
| **Phase 1: Master Prompt** | Detailed system architecture, RBAC, functional core engines (T&C version control, 6-hr session lock, SLA Working Days countdown, dynamic form pipelines, value-based balance gate, eSign, docx4j template engines). | 2026-05-27 | Approved |
| **Phase 2: Tech Stack & Versions** | Docker Compose deployment specs, Flutter frontend, Spring Boot backend, Postgres 16, Nginx config, GitHub Actions workflow | 2026-05-27 | Integrated |
| **Phase 3: Design, Colors & Fonts** | *Awaiting input* (Using primary corporate blue #1E57A4, gold/amber #FABB1F, Montserrat font). | - | Pending |
| **Phase 4: Template Management Prompt** | *Awaiting input* | - | Pending |

---

## 1. Phase 1: Master Prompt & Architectural Decisions
- **Backup Database Container**: Deploy a separate, dedicated PostgreSQL container (`PVCBackupPostgres`) configured with read-only/audit access mapping to a persistent volume for the Immutable Record Archive.
- **Pricing Matrix Rules**:
  - Purpose is **Visa**: Fixed fee of ₹3,000.
  - Purpose is **Other** and Property Value is **above 10 Crores (₹100,000,000)**: Fee = 0.1% of the final property value.
  - Purpose is **Other** and Property Value is **under 10 Crores**: Flat fee of ₹10,000.
- **Third-Party Integrations**: Google OAuth2, Twilio/Msg91, and e-Mudhra cloud signing are scaffolded as local mock classes to support seamless offline testing.
- **Analyst Heartbeat Interval**: Every 30 seconds.

---

## 2. Phase 2: Software & Versions
- **Host OS**: Ubuntu 22.04 LTS VPS (Nginx on Host)
- **Frontend**: Flutter Web (Dart SDK `>=3.3.0 <4.0.0`)
- **Backend**: Spring Boot 3.3.5 (Java 21, Gradle build tool)
- **Database**: PostgreSQL 16 (docker image: `postgres:16-alpine`)
- **Deployment**: Docker Compose, GitHub Actions CI/CD pipeline, VPS Host Nginx Reverse Proxy

---

## 3. Phase 3: Design, Colors & Fonts
- **Primary Color:** #1E57A4 (Deep Corporate Trust Blue)
- **Secondary/Accent Color:** #FABB1F (Luxury Gold/Amber)
- **Background:** #FFFFFF (Pure White)
- **Surface Color:** #F8FAFC (Soft Slate White for cards/sections)
- **Border Color:** #E2E8F0 (Subtle Light Gray)
- **Text Primary:** #0F2D54 (High-Contrast Navy Blue)
- **Text Secondary:** #64748B (Muted Cool Gray)
- **Success Color:** #10B981 (Emerald Green)
- **Warning Color:** #F59E0B (Amber Notice)
- **Typography:** Montserrat font family exclusively (via Google Fonts 6.1.0).

---

## 4. Phase 4: Template Management Prompt
*Awaiting template management and application creation details.*

---

## Conflicts & Observations Log
- **Apache POI Removed**: Removed from configuration per Part 2 specifications. Only docx4j is used for OpenXML structures.
