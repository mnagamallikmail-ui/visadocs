# Enterprise Git Branching & Release Strategy: Dedicated Dual-Track Topology
**Project:** ProValuer Commercial  
**File Location:** `android/GIT_BRANCHING_STRATEGY.md`  
**Version:** 2.1.0 (Executive Approved with Mandatory Amendments)  
**Date:** November 7, 2026  
**Status:** Approved & Awaiting Final Execution Authorization  

---

## 1. Executive Directive & Branch Topology

To guarantee **100% Zero Impact and Zero Regression on the Production Web Application**, ProValuer Commercial operates on an isolated dual-track branching model.

The repository maintains two parallel, permanent branches at the root level:
- **`master`**: Dedicated exclusively to Production Web, VPS Deployment, Spring Boot Backend, PostgreSQL Database, and Existing Flutter Web.
- **`android`**: Dedicated exclusively to the Android Mobile Application, Mobile UX, Field-Appraiser Productivity Workflows, Biometrics, Auto Updates, APK Distribution, and Google Play Store Releases.

```
                                [ Remote Git Repository ]
                                            |
                +---------------------------+---------------------------+
                |                                                       |
                v                                                       v
      ======================                                  ======================
          BRANCH: master                                          BRANCH: android
      ======================                                  ======================
      - Production Web (VPS)                                  - Native Android Field App
      - Spring Boot Backend                                   - Mobile Drawer & Navigation
      - PostgreSQL Migrations                                 - Question-over-Answer Layouts
      - Existing Flutter Web UI                               - Field Valuer Productivity
      - Desktop Sidebars & Grids                              - Local Autosave & Draft Recovery
      - Marketing Landing Page (/)                            - Offline Forms & Photos
      - Web CI/CD -> VPS Deploy                              - Auto Sync & Global Search
                                                              - Camera-First Workflow
                                                              - Biometrics (Keystore)
                                                              - Direct Login Flow (/login)
                                                              - In-App & VPS Auto-Updates
                                                              - Android CI/CD -> Play Store / APK
```

---

## 2. Inviolable Governance Rules & Strict Firewall

The firewall between the two tracks is codified as follows:

```
                      +----------------------------------+
                      |         master (Web & Backend)   |
                      +----------------------------------+
                                        |
                 [ master -> android = selective cherry-pick only ]
                 (Backend DTOs, API updates, calculation fixes)
                                        |
                                        v
                      +----------------------------------+
                      |          android branch          |
                      +----------------------------------+
                                        |
                 [ android -> master = STRICTLY PROHIBITED ]
```

1. **`android -> master = PROHIBITED`**: Under NO circumstances shall `android` ever be merged into `master`. Android-specific presentation code, mobile layouts, Gradle configurations, and Android dependencies will never touch `master`.
2. **`master -> android = SELECTIVE CHERRY-PICK ONLY`**: Backend models, REST DTOs, or shared calculation engine fixes on `master` may be selectively ported into `android` via `git cherry-pick <commit-hash>`. Bulk merges or rebases from `master` into `android` that touch UI files are forbidden.
3. **Release Isolation**:
   - Web releases occur **ONLY** from the `master` branch.
   - Android releases (APK / AAB) occur **ONLY** from the `android` branch.
4. **CI/CD Isolation**:
   - Web CI/CD pipeline triggers **ONLY** on commits to `master`.
   - Android CI/CD pipeline triggers **ONLY** on commits to `android`.
5. **No Automatic Merging**:
   - Automated merge bots, fast-forward merges, and automated pull request synchronizations between `master` and `android` are strictly disabled.

---

## 3. Explicit Android Branch Creation Strategy

When execution is authorized, the `android` branch will be initialized and decoupled using the following deterministic sequence:

```bash
# Step 1: Ensure working tree is clean or capture current mobile assets
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

Following this procedure:
- `master` contains strictly production Web, Backend, and VPS configurations with zero Android modifications.
- `android` contains the mobile presentation layer, field appraiser tools, and Android build scripts.

---

## 4. Branching Lifecycle & Workflows

### 4.1 Web Production Workflow (`master`)
1. Backend fixes and web enhancements are developed on short-lived branches off `master` (`web-fix/*`).
2. Pull requests target **only** `master`.
3. Merging into `master` triggers `.github/workflows/web_deploy.yml`.
4. Pipeline compiles Spring Boot Backend, builds Flutter Web, and rsyncs artifacts to the production VPS with zero downtime.

### 4.2 Android Development & Release Workflow (`android`)
1. All Android mobile UX, field appraiser productivity features, biometrics, offline sync, and camera-first workflows are committed to `android` or short-lived `android/*` branches.
2. Pull requests target **only** the `android` branch.
3. Pushes and version tags (`android-v*`) on `android` trigger `.github/workflows/android_deploy.yml`.
4. Pipeline runs Flutter test suites, builds signed production APK and AAB binaries, and pushes to Google Play Console (Internal Track) and VPS APK repository.

---

## 5. Rollback Strategy (Self-Contained & Independent)

To prevent cross-environment disruptions, rollbacks are 100% self-contained within their respective branches:

```
[ Web Failure on VPS ]   --> Rollback executed ENTIRELY on master (VPS re-checkout, Nginx reload)
                             (android branch is completely unaffected)

[ Mobile Bug on Devices ] --> Rollback executed ENTIRELY on android branch
                             (master branch is NEVER modified or touched)
```

### 5.1 Android Rollback Procedure (Occurs Entirely on `android`)
When a regression is detected on mobile devices:
1. **Immediate Play Console Halt**: Halt the active rollout in Google Play Console with one click (stops distribution to new devices immediately).
2. **Branch-Internal Checkout**:
   ```bash
   git checkout android
   git checkout tags/android-v<previous-stable-tag> -b android-hotfix-rollback
   ```
3. **Emergency Version Bump**:
   - Bump `versionCode` by +1 in `android/app/build.gradle.kts`.
   - Recompile signed AAB on the `android` branch.
4. **Deploy Hotfix**:
   - Push to `android` with tag `android-v<new-patch>`.
   - CI/CD automatically uploads the hotfix to Google Play expedited review.
5. **In-App Force Update Trigger**:
   - For internal VPS APK users, set `minSupportedVersionCode` on the VPS endpoint `/api/v1/app/version` to force older clients to update to the stable build immediately.
6. **Master Independence**: **`master` is never modified, rebased, or touched during an Android rollback.**

### 5.2 Web Rollback Procedure (Occurs Entirely on `master`)
1. `git checkout master && git checkout tags/web-v<previous-stable-tag>` on the host VPS.
2. Re-run `docker compose up -d --build` and reload Nginx.
3. Recovery time $< 2$ minutes. The `android` branch remains completely unaffected.

---

## 6. CI/CD Trigger Points

* **`.github/workflows/web_deploy.yml`**:
  ```yaml
  on:
    push:
      branches: [ master ]
      paths-ignore:
        - 'android/**'
        - 'frontend/android/**'
  ```
* **`.github/workflows/android_deploy.yml`**:
  ```yaml
  on:
    push:
      branches: [ android ]
      tags:
        - 'android-v*'
  ```

---

## 7. Approval & Governance Attestation

- [x] All references to `main` replaced with `master`.
- [x] Android rollback strategy strictly confined to `android` branch with zero impact on `master`.
- [x] Explicit Android branch creation procedure specified.
- [x] Firewall codified: `android -> master = prohibited`; `master -> android = selective cherry-pick only`.
