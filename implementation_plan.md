# Implementation Plan: ProValuer Full-Stack Web Application

This document outlines the system architecture, database schema, backend services, and frontend dashboards for the **ProValuer Commercial** application. It consolidates all specs from Phase 1, Phase 2, and the newly provided final requirements.

---

## User Review Required

> [!IMPORTANT]
> **Tech Stack Change (Omission of Apache POI):** 
> In Phase 2, Apache POI was listed as a backend dependency. However, your detailed functional requirements state that **Apache POI libraries must be completely omitted** and all OpenXML loops must run exclusively through the **docx4j** framework to prevent JVM starvation. We have adjusted the backend architecture to use `docx4j-core`, `docx4j-openxml-objects`, and `docx4j-JAXB-ReferenceImpl` exclusively for Word parsing and document hydration.
>
> **T&C Compliance & API Interceptor:**
> We have designed an interceptor in the Spring Boot security layer that checks the user's accepted T&C version against the global configuration. If the Admin increments the version, the API returns a `451 Unavailable For Legal Reasons` or custom error, prompting the Flutter client to display a blocking T&C dialog.

---

## Open Questions

> [!IMPORTANT]
> **1. Read-Only Backup Database Volume Configuration:**
> The specifications call for finalized reports and metadata logs to be permanently persisted in a "secure, read-only backup database volume." How would you like this configured in `docker-compose.yml`?
> - **Option A:** A separate PostgreSQL container (e.g. `pvc-backup-db`) running on a separate directory and read-only user access.
> - **Option B:** A separate read-only schema/table space within the main PostgreSQL database instance, using a distinct database directory/volume mount.
> Please indicate your preference.
>
> **2. Percentage-Based Pricing Grid Matrix:**
> How is the global pricing matrix structured? For example, is the final cost calculated as a flat base fee per Property Category/Purpose, plus a percentage of the final valuation figure? (e.g., `Fee = Base Fee + (Valuation * X%)`). Please define the mathematical rules we should implement.
>
> **3. Google OAuth2 Client and SMS API Keys:**
> Since these are third-party services (Google OAuth, Twilio/Msg91, e-Mudhra cloud signing), should we scaffold them with clean local mock implementations (with sandbox toggle logs in the console/UI) to allow seamless offline local testing?
>
> **4. Telemetry Heartbeat Frequency:**
> For the PA active session lock override, how frequently should the Flutter web client send heartbeats to `/api/v1/analysts/heartbeat` (e.g., every 30 seconds or 1 minute)?

---

## Proposed Changes

### 1. Docker Orchestration

#### [MODIFY] [docker-compose.yml](file:///d:/Demo/ProValuer%20Commercial/docker-compose.yml)
Update services to:
- **`postgres`**: Mount main storage volume (`pgdata`). If Option A is chosen for the backup database, add a secondary read-only database service.
- **`backend`**: Set up Spring Boot environment variables to connect to Postgres.
- **`frontend`**: Map port `8081:80`.

---

### 2. Backend Architecture (Spring Boot & docx4j)

#### [NEW] [build.gradle](file:///d:/Demo/ProValuer%20Commercial/backend/build.gradle)
Add all dependency definitions for Spring Boot, PostgreSQL, Security JWT, JJWT, Flyway, and `docx4j` 11.4.11 (omitting Apache POI).

#### [NEW] [V1__init_schema.sql](file:///d:/Demo/ProValuer%20Commercial/backend/src/main/resources/db/migration/V1__init_schema.sql)
Define the initial schema for:
- `users` (id, email, password, role, mobile_number, accepted_tc_version)
- `system_settings` (key, value) -- Stores active T&C version (e.g., `v1.0`) and pricing matrix JSON.
- `templates` (id, name, template_content [bytea], field_mapping [jsonb], is_active [char(1)])
- `orders` (id, client_id, pa_id, purpose, property_category, status, estimated_value, final_value, fee_charged, balance_due, is_paused, pause_reason, sla_expiry_time, claimed_at, last_heartbeat)
- `order_inputs` (id, order_id, field_key, field_value)
- `transactions` (id, order_id, amount, stage, status, transaction_ref)
- `revisions` (id, order_id, error_classification, feedback, attachment_path, round_number, status)
- `performance_ledger` (employee_id, active_allocations, files_completed, sla_timeouts, freeze_counts)

#### [NEW] [TcInterceptor.java](file:///d:/Demo/ProValuer%20Commercial/backend/src/main/java/com/provaluer/config/TcInterceptor.java)
An HTTP HandlerInterceptor that checks the active T&C version from `system_settings` against the user's `accepted_tc_version`. Blocks client requests with custom error codes if they do not match.

#### [NEW] [DocxTemplateEngine.java](file:///d:/Demo/ProValuer%20Commercial/backend/src/main/java/com/provaluer/util/DocxTemplateEngine.java)
Handles docx manipulation using `docx4j`:
- **Token Normalization:** Traverses XML paragraphs and runs to stitch fragmented run elements (like `<<` and `NAME` and `>>`) into a single text run before saving.
- **Placeholder Extraction:** Uses XPath or JAXB traversals to find `<<KEY_NAME>>` tokens, extracts section headings, table indices (e.g., `T0_R2_C1`), and Alternative Text from images.
- **EMU Resolution:** Walks `wp:extent` fields, reads `cx` and `cy` dimensions, converts to inches and pixels, and saves guidelines.
- **Report Assembly:** Replaces placeholders, inserts images scaled to exact EMU coordinates, and outputs the final PDF/Docx.

#### [NEW] [SlaService.java](file:///d:/Demo/ProValuer%20Commercial/backend/src/main/java/com/provaluer/service/SlaService.java)
Calculates working hours (9:00 AM - 6:00 PM, Monday-Friday) to support:
- 6-Hour Analyst session locks.
- 2-day (Visa) and 4-day (Other) operational deadlines.
- Telemetry heartbeat evaluation (overriding the 6-hour recycle if the analyst is active).
- Freeze timers during client information requests.

#### [NEW] [Controllers & APIs](file:///d:/Demo/ProValuer%20Commercial/backend/src/main/java/com/provaluer/controller/)
- `AuthController`: Google login webhook and mobile verification stub.
- `TemplateController`: Upload, mapping editing, archive deep-copy inheritance, and confirmation flow.
- `OrderController`: Progress saving, intake validations, PA claiming pool, heartbeat telemetry, and SPA approvals.
- `PaymentController`: Multi-stage deposit and balance gates.
- `SignatureController`: eSign HSM cloud integration scaffold.

---

### 3. Frontend Architecture (Flutter Web)

#### [NEW] [pubspec.yaml](file:///d:/Demo/ProValuer%20Commercial/frontend/pubspec.yaml)
Add Flutter dependencies (`go_router`, `provider`, `google_fonts`, `table_calendar`, `fl_chart`, `dotted_border`, `data_table_2`).

#### [NEW] [main.dart](file:///d:/Demo/ProValuer%20Commercial/frontend/lib/main.dart)
Initialize Montserrat typography and routing. Configure routing guards to catch T&C update prompts.

#### [NEW] [landing_page.dart](file:///d:/Demo/ProValuer%20Commercial/frontend/lib/views/landing_page.dart)
Responsive layout including the sticky NavBar, split hero section, and floating Auth Card (Login/Register toggles + Google sign-in).

#### [NEW] [client_dashboard.dart](file:///d:/Demo/ProValuer%20Commercial/frontend/lib/views/client_dashboard.dart)
- Shows the 7-stage timeline (Intake ➔ Payment ➔ Analysis ➔ Action Needed ➔ Consultation ➔ Payment Lock ➔ Delivery) colored dynamically: Complete (Green #10B981), Active (Blue #1E57A4), and Locked (Muted Slate #64748B).
- Integrates the step-by-step intake questionnaire funnel with draft saving, file size ceilings (15MB), and file type boundaries.
- Value-Based Balance Gate UI: Renders the payment drawer or the locked preview based on the calculated delta.
- Structured Revision modal supporting feedback input and document upload.

#### [NEW] [pa_dashboard.dart](file:///d:/Demo/ProValuer%20Commercial/frontend/lib/views/pa_dashboard.dart)
- Listing of open pool files to claim.
- Data entry page linked to the template JSON schema showing generated questions, date pickers, and image uploads.
- Telemetry heartbeat system that sends status signals to the backend to prevent active session unlocks.

#### [NEW] [spa_dashboard.dart](file:///d:/Demo/ProValuer%20Commercial/frontend/lib/views/spa_dashboard.dart)
- Verification checklist for submitted PA drafts.
- Directly editable text fields to refine report details.
- Cloud eSignature authorization dialog triggering the OTP authentication loop.

#### [NEW] [admin_dashboard.dart](file:///d:/Demo/ProValuer%20Commercial/frontend/lib/views/admin_dashboard.dart)
- Template parser interface: Upload `.docx`, edit generated questions and display labels in a `DataTable2` table, and publish templates.
- Controls to update terms & conditions versions and the global pricing matrix.
- Interactive charts (using `fl_chart`) displaying employee performance metrics.

---

## Phase 3: Finalizing Report Access & Populating Layouts

### 1. Download Report Visibility for PA, SPA, and Super Admin
We will update the conditional visibility check in the sidebar status desk container so that both **PDF** and **DOCX** download options are displayed for all staff members once the report status is `FINAL_DELIVERY`.
- **Target File**: [valuation_portal_widget.dart](file:///d:/Demo/ProValuer%20Commercial/frontend/lib/features/valuation_portal/valuation_portal_widget.dart)
- **Change**: Modify `widget.role == 'SPA' || widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN'` in the PDF download button block to also allow `widget.role == 'PA'`.

### 2. Full Page Populating Layout
To prevent input text fields from being squeezed in the narrow 380px sidebar, we will:
- **Introduce Overlay**: Create a full-page Scaffold editor view `_openPopulateReportFullScreen(dynamic order, OrderProvider provider)` in [valuation_portal_widget.dart](file:///d:/Demo/ProValuer%20Commercial/frontend/lib/features/valuation_portal/valuation_portal_widget.dart).
- **Spacious Inputs Layout**: Wrap the dynamic inputs form (`_buildDynamicTemplateInputsForm`) inside a centered, scrollable page with a maximum width boundary of 800px. This provides ample, professional margins.
- **Top App Bar**: Include a header bar showcasing the report number and associated client/bank/branch metadata, with a clear "Cancel" or "Close" button.
- **Action Buttons**: Place action buttons at the bottom of this full-page interface for draft submission or data saving.
- **Sidebar Integration**: Replace the inline inputs display in the right sidebar (for both compiling and reviewing stages) with a single prominent action button `POPULATE REPORT DATA (FULL PAGE)` or `VIEW / EDIT DATA FIELDS (FULL PAGE)`.

### 3. Client & Bank Display in Report Directory Queue
- **Target File**: [valuation_portal_widget.dart](file:///d:/Demo/ProValuer%20Commercial/frontend/lib/features/valuation_portal/valuation_portal_widget.dart)
- **Change**: In `_buildDirectoryList`, update the list item card row layout to append a secondary line display: `Client: {clientName} | Bank: {bankName}` if these fields are populated.
- **Design System Style**: Style this string in `DesignSystem.primary` at `9.5` font size to look premium and align cleanly with the status badge.

---

## Verification Plan

### Manual Verification Commands (PowerShell)
You can build and deploy the services locally using docker-compose. Run the following commands in your PowerShell terminal to rebuild and verify:

1. **Rebuild and Start Database & Backend Services**:
   ```powershell
   docker-compose down
   docker-compose build backend
   docker-compose up -d postgres backup-postgres backend
   ```

2. **Check Backend Log Output & Database Migration Success**:
   ```powershell
   docker logs -f PVCBackend
   ```
   *(Verify that the console displays `Successfully applied 1 migration to schema "public", now at version v6`)*

3. **Rebuild and Start Frontend Web Client**:
   ```powershell
   docker-compose build frontend
   docker-compose up -d frontend
   ```

4. **Verify Application Services Status**:
   ```powershell
   docker ps
   ```
   *(Verify that `PVCFrontend`, `PVCBackend`, `PVCProxy`, `PVCPostgres`, and `PVCBackupPostgres` are all marked as `Up`)*

5. **Local Web App Access**:
   Access the portal locally via your web browser: `http://localhost` (proxy on port 80).
   - Login as `pa@provaluer.com` / `password` -> click "Create New Report" -> check "My Active Tasks" -> open full page data populator -> submit.
   - Login as `spa@provaluer.com` / `password` -> check "Review Queue" -> click to review in full page -> determine final valuation -> sign & seal.
   - Verify that download options are fully visible and responsive for all staff accounts.
   - Verify that report queues render the associated Client Name and Bank Name inline.
