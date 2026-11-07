# Comprehensive Android Implementation Plan: Native Field-Appraiser Experience
**Target Platform:** Android (Google Play Store & VPS Distribution)  
**Baseline Principle:** **100% Zero Impact / Zero Regression on Web Application**  
**Git Structure:** Dual-Track Parallel Branches (`master` for Web/VPS, `android` for Mobile/Play Store)  
**Document Target:** `android/ANDROID_IMPLEMENTATION_PLAN.md`  
**Version:** 3.1.0 (Executive Approved with Mandatory Amendments)  
**Date:** November 7, 2026  
**Status:** Approved & Awaiting Final Code Modification Authorization  

---

## 1. Executive Summary & Mandatory Constraints

ProValuer Commercial operates on an isolated dual-track architecture:
1. **Web Portal (`master` Branch)**: Mission-critical desktop workstation for corporate banking clients, institutional administrators, and office appraisers. **Must remain 100% untouched and unchanged**.
2. **Android Application (`android` Branch)**: Dedicated mobile field-workstation tailored specifically for Valuers, Primary Appraisers (PA), Senior Property Appraisers (SPA), Administrators, and Mobile Clients on smartphones and tablets.

### Inviolable Mandates
* **Mandatory Requirement #1 (Zero Web Impact)**: No changes to web layouts, navigation, workflows, routes, desktop forms, desktop tables, landing page, marketing pages, or web UX.
* **Mandatory Requirement #2 (Dedicated Git Track)**: Two permanent branches at the same level: `master` (Web/VPS/Backend) and `android` (Mobile app, Play Store, AAB/APK).
* **Strict Firewall Policy**:
  - `android -> master = STRICTLY PROHIBITED`
  - `master -> android = SELECTIVE CHERRY-PICK ONLY`
* **Independent Rollback**: Any Android rollback or hotfix occurs entirely within the `android` branch and **never requires modifying `master`**.
* **Native Field-Appraiser UX**: Android must not feel like a website squeezed into a phone. It will deliver a fast, ergonomic field experience featuring offline data entry, camera-first site inspections, local autosave, section-by-section multi-step navigation, and hardware biometrics.

---

## 2. Explicit Android Branch Creation Strategy

When execution authorization is granted, the `android` branch will be initialized and decoupled using the following deterministic sequence:

```bash
# Step 1: Ensure master is clean and up to date
git checkout master
git pull origin master

# Step 2: Create and switch to the permanent android branch
git checkout -b android

# Step 3: Stage and commit all Android platform assets, mobile services, and mobile layouts
git add android/ frontend/lib/ services/ .github/workflows/android_deploy.yml
git commit -m "feat(android): initialize permanent android platform branch"

# Step 4: Push the new permanent branch to the remote repository
git push -u origin android

# Step 5: Switch back to master and restore pristine web production state
git checkout master
git reset --hard origin/master

# Step 6: Verify master is 100% clean and untouched
git status
```

### Firewall Rules:
* `android -> master = PROHIBITED`: Code committed to `android` is never merged into `master`.
* `master -> android = SELECTIVE CHERRY-PICK ONLY`: When shared backend DTOs or calculation algorithms update on `master`, they are ported to `android` via `git cherry-pick <commit-hash>`.

---

## 3. Phase-Wise Architecture & Implementation Roadmap

```
                                  [ Shared REST APIs & DB ]
                                             |
                         +-------------------+-------------------+
                         |                                       |
                         v                                       v
               BRANCH: master                          BRANCH: android
           (Production Web Portal)                 (Native Field Appraiser)
                         |                                       |
         - Unchanged Desktop Tables              - Phase 1: Native Sliding Drawer
         - Side-by-Side 2-Col Forms              - Phase 2: Card & Accordion Dashboards
         - Permanent Desktop Nav                 - Phase 3: Question-over-Answer Layouts
         - Public Landing Page (/)               - Phase 4: Section-Based Progress
         - Web Browser LocalStorage              - Phase 5: Biometric Authentication
         - Manual Refresh                        - Phase 6: Direct Mobile Startup Flow
         - Web File Upload Dialogs               - Phase 7: Official PV Mobile Branding
                                                 - Phase 8: Auto-Update Framework
                                                 - Phase 9: Multi-Density Screen QA
                                                 - Phase 10: Isolated Dual-Track CI/CD
                                                 - Phase 11: Field Valuer Productivity
                                                             * Autosave (30s)
                                                             * Draft Recovery
                                                             * Offline Forms
                                                             * Offline Photos
                                                             * Auto Sync
                                                             * Camera-first Workflow
                                                             * Global Search
                                                             * Section Progress Tracking
                                                 - Phase 12: Documentation & Governance
```

---

### Phase 1: Android Navigation & Native Drawer
* **Mobile Drawer Component**: Replaces the permanent desktop sidebar with a native sliding `Drawer` (`width: 290dp`) on all mobile viewports.
* **User Profile Header**: Displays user avatar, full name, organization, and a high-contrast role badge (`SUPER ADMIN`, `ADMIN`, `SPA`, `PA`, `CLIENT`).
* **Menu Items by Role**: Dynamically renders navigation options relevant to the authenticated user.
* **System Utilities**: Settings shortcut, application build version info (e.g. `v1.0.0 (Build 101)`), and a dedicated, prominent **Sign Out** button with an exit confirmation dialog.

---

### Phase 2: Android Dashboard Redesign (Cards, Accordions & Tiles)
* **The Problem**: Desktop tables compress columns on mobile screens into unreadable, 20px-wide vertical slivers where reference numbers (`PV-2610-0328`) wrap character-by-character.
* **The Solution**: Complete elimination of multi-column data tables on Android.
* **Card Architecture**:
  - **Header Row**: Reference Number (full width, bold, never wrapped) + Status Chip (e.g. `Inspection Scheduled`).
  - **Property Summary Tile**: Borrower name, property location, asset type.
  - **Date & Mandate Tile**: Clear date formatting (`07-Oct-2026`), issuing bank name.
  - **Action Row**: Thumb-accessible elevated buttons (`Open Form`, `Take Photos`, `View Report`).
* **Expansion Panels / Accordions**: Historical logs and dossier notes collapsed by default to conserve vertical screen space.

---

### Phase 3: Question-Above-Answer Design (Forms & Questionnaires)
* **The Problem**: Desktop valuation templates render questions and answers side-by-side (`Question [flex 5] | Answer [flex 6]`). On a 390px mobile screen, text labels wrap awkwardly and inputs are suffocated.
* **The Android Solution**:
  ```
  +---------------------------------------------------+
  | Question Label (Full Width, Semi-Bold)            |
  | Secondary Helper / Guidance Text (12sp grey)      |
  | +-----------------------------------------------+ |
  | | Full Width Answer Field                       | |
  | | (Auto-growing text area / styled dropdown)    | |
  | +-----------------------------------------------+ |
  +---------------------------------------------------+
  ```
* **Form Field Specifications**:
  - Padding: Minimum 16dp horizontal, 12dp vertical.
  - Auto-Growing Textboxes: `minLines: 2, maxLines: 8` for property descriptions and inspection observations.
  - No side-to-side scrolling; zero text clipping.

---

### Phase 4: Section-Based Valuation Workflow & Progress
* **The Problem**: Commercial valuation questionnaires contain 100+ parameters. Rendering all inputs on a single infinite scrollable view degrades performance and overwhelms field valuers.
* **The Android Solution**:
  - **Section Stepper / Header**:
    ```
    [✓ 1. General] -> [✓ 2. Land Details] -> [► 3. Building Structure] -> [□ 4. Valuation]
    ```
  - **Progress Indicator**: Real-time progress bar (e.g. `Section 3 of 6 (45% Completed)`).
  - **Direct Jump**: Dropdown / drawer section selector allowing appraisers to jump directly to any section.
  - **Navigation Controls**: Fixed bottom bar with `Previous Section` and `Next Section` buttons.
  - **State Memory**: Retains active section index across screen rotations and app backgrounding.

---

### Phase 5: Biometric Authentication & Android Keystore
* **Supported Hardware**: Fingerprint scanner, Face Unlock, Device PIN, and Device Pattern (`biometricOnly: false`).
* **Credential Protection**: Refresh tokens and authentication credentials encrypted via hardware-backed **Android Keystore** (`flutter_secure_storage`).
* **Authentication Flow**:
  1. **First Login**: Username + Password + MFA OTP $\longrightarrow$ Prompt: *"Enable Biometric Login?"*.
  2. **Future Launches**: Splash $\longrightarrow$ Native Biometric Prompt $\longrightarrow$ Instant Dashboard.
  3. **Fallback**: If sensor fails or user cancels, seamlessly falls back to standard PIN or Password entry.

---

### Phase 6: Android Startup Flow
* **Platform-Aware Routing**:
  - **Web Target (`master`)**: Public visitors land on `/` (Marketing Landing Page).
  - **Android Target (`android`)**: Valuers and staff launch directly into `Splash` $\longrightarrow$ `Login` $\longrightarrow$ `Dashboard` (bypassing marketing content completely).

---

### Phase 7: Official PV Mobile Branding
* **App Display Name**: Set to **"Pro Valuer"** in `AndroidManifest.xml` and Gradle resources.
* **Launcher Icons**: Official PV logo generated across all mipmap densities:
  - `mipmap-mdpi` (48×48), `mipmap-hdpi` (72×72), `mipmap-xhdpi` (96×96), `mipmap-xxhdpi` (144×144), `mipmap-xxxhdpi` (192×192).
* **Adaptive Icons**: Foreground vector emblem on clean branded background (`#FFFFFF` / `#1E3A8A`).
* **Splash Screen**: Native Android 12+ splash screen (`launch_background.xml`) displaying centered PV insignia.
* **Notification Icon**: Monochrome vector icon (`ic_notification.png`) conforming to Android status bar guidelines.

---

### Phase 8: Auto-Update Framework
* Implemented according to [`android/AUTO_UPDATE_ARCHITECTURE.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/android/AUTO_UPDATE_ARCHITECTURE.md).
* **Production**: Google Play In-App Updates (`in_app_update`) supporting Flexible (background) and Immediate (blocking force-update) flows.
* **Internal Testing**: VPS endpoint `/api/v1/app/version` query + Android `PackageInstaller` intent.
* **Checks**: Run on App Start, Post-Login, and every 24 hours.

---

### Phase 9: Android Responsive Multi-Density Testing
* **Validation Viewports**:
  - `360 x 800 dp` (Standard compact Android phone - e.g. Samsung Galaxy A series)
  - `393 x 852 dp` (Modern standard phone - e.g. Google Pixel 8)
  - `412 x 915 dp` (Flagship / large phone - e.g. Samsung Galaxy S24 Ultra)
* **Pass Criteria**:
  - Touch targets $\ge 48 \times 48\text{ dp}$.
  - Zero text clipping or vertical character wrapping.
  - Zero horizontal scroll indicators.
  - Zero collapsed or clipped form elements.

---

### Phase 10: Isolated Dual-Track CI/CD
* **Web Workflow (`.github/workflows/web_deploy.yml`)**:
  - Triggers on push to `master`.
  - Builds Spring Boot JAR and Flutter Web release.
  - Deploys to Production VPS via SSH/Rsync.
* **Android Workflow (`.github/workflows/android_deploy.yml`)**:
  - Triggers on push to `android`.
  - Compiles production `.apk` and signed `.aab`.
  - Deploys AAB to Google Play Console Internal Track and attaches APK to GitHub Releases.

---

### Phase 11: Field Valuer Productivity Enhancements

This dedicated phase integrates the full suite of productivity tools designed specifically for appraisers working in the field:

1. **Autosave Engine (30 Seconds)**:
   - Form inputs, selected dropdowns, and checkboxes automatically commit to local device storage every 30 seconds.
   - Saves immediately upon section navigation and when app transitions to background or minimization.
2. **Draft Recovery**:
   - Detects incomplete local drafts when an appraiser reopens a valuation assignment.
   - Displays a banner: *"Unsaved draft restored from 10:42 AM. [Discard Draft]"*.
3. **Offline Forms**:
   - Appraisers can complete entire valuation questionnaires without an internet connection.
   - Form validation runs locally against cached template schemas.
4. **Offline Photos & GPS / Timestamp Metadata**:
   - High-resolution inspection photos captured on site are stored in the local app cache.
   - **GPS Coordinates & Timestamp Metadata**: Automatically records latitude, longitude, altitude, GPS horizontal accuracy, and ISO-8601 UTC timestamp at the exact moment of shutter release.
   - Embeds metadata into EXIF headers and inspection payload, with optional on-photo text watermark (Date/Time, Lat/Long, Appraiser ID).
5. **Auto Sync Engine**:
   - Integrates `connectivity_plus` to monitor network connectivity.
   - When cellular or Wi-Fi reconnects, queued form responses and photos automatically upload to the backend without user intervention.
6. **Camera-First Workflow**:
   - Primary inspection button is `[ Take Photo ]` (launches native camera directly).
   - Secondary option `[ Choose Existing File ]` for supplemental documents.
   - Batch photo mode with quick thumbnail carousel and delete/retake controls.
7. **Global Search**:
   - App-wide search bar in `AppBar` allowing appraisers to instantly locate orders by Reference Number, Borrower Name, Property Address, or Bank Mandate.
8. **Section Progress Tracking**:
   - Clear visual indicator of valuation report completion:
     `[✓ Section 1: General] -> [✓ Section 2: Land] -> [► Section 3: Structure (Current)] -> [□ Section 4: Valuation]`
   - Direct section jump menu for non-linear inspections.
9. **Dedicated App Information Screen (`AppInfoScreen`)**:
   - Accessible via Drawer $\longrightarrow$ Settings / About Pro Valuer.
   - Displays:
     * **Version**: e.g. `1.0.0`
     * **Build Number**: e.g. `101`
     * **Release Date**: e.g. `07-Nov-2026`
     * **Branch**: `android`
     * **Last Sync Time**: e.g. `07-Nov-2026 10:45 AM (All drafts synchronized)`
     * **Check For Updates**: Interactive button triggering instant Google Play / VPS version check with status indicator.

---

### Phase 12: Documentation & Governance Deliverables

| Deliverable File | Purpose & Contents | Status |
| :--- | :--- | :---: |
| **`android/GIT_BRANCHING_STRATEGY.md`** | Master vs Android dual-track topology and firewall rules. | **Complete** |
| **`android/AUTO_UPDATE_ARCHITECTURE.md`** | In-App Updates & VPS APK auto-update design. | **Complete** |
| **`android/ANDROID_IMPLEMENTATION_PLAN.md`** | Comprehensive roadmap including Field Valuer Productivity. | **Complete** |
| **`android/ANDROID_MOBILE_REDESIGN_REPORT.md`** | Detailed screen-by-screen UX refactor specifications. | **Updated** |
| **`android/ANDROID_APP_AUDIT.md`** | Full compliance audit against all phases. | **Updated** |
| **`android/PLAYSTORE_READINESS.md`** | Google Play Store requirements, SDK 34/35, DPDP, permissions. | **Updated** |

---

## 4. Self-Contained Rollback Strategy (Occurs Entirely on `android`)

To guarantee that Web production on `master` is never jeopardized:
1. **Zero Master Modifications**: Android rollbacks occur **strictly within the `android` branch**. `master` is never modified, rebased, or deployed to during an Android incident.
2. **Immediate Store Halt**: Release halted in Google Play Console with one click.
3. **Emergency Patch on `android`**:
   - Branch from last stable release tag on `android`:
     `git checkout tags/android-v<prev-stable> -b android-hotfix-rollback`
   - Increment `versionCode` by +1 and recompile signed AAB.
   - Push to `android` to trigger expedited Play Store hotfix upload.
4. **Internal VPS Enforcement**: For internal sideloaders, the VPS `/api/v1/app/version` endpoint sets `minSupportedVersionCode` to the stable build, triggering an immediate force-update prompt.

---

## 5. Final Pre-Implementation Approval Checklist

Before source code modifications begin:
- [x] All references to `main` replaced with `master`.
- [x] Strict firewall codified (`android -> master = prohibited`; `master -> android = selective cherry-pick only`).
- [x] Rollback strategy isolated entirely to `android` branch with zero impact on `master`.
- [x] Phase 11 (Field Valuer Productivity Enhancements) fully integrated.
- [x] Explicit Android branch creation procedure specified.
- [ ] **Final Executive Confirmation to begin coding and Git branch creation received**.
