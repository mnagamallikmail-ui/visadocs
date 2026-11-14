# Git Governance & Branch Synchronization Policy

**Document Reference:** `PRV-GOV-BRANCH-POLICY-V1`  
**Status:** **FROZEN & ENFORCED**  
**Effective Date:** November 2026  
**Governing Principle:** `master` is the permanent, authoritative Source of Truth; `android` is an isolated platform extension layer.

---

## 1. Branch Ownership & Roles

| Branch | Classification | Scope & Ownership |
| :--- | :--- | :--- |
| **`master`** | **Authoritative Source of Truth** | Hosts all core platform functionality: Spring Boot backend services, PostgreSQL Flyway migrations, authentication, RBAC, JWT tokens, SSE notifications, single active session enforcement, workspace lease concurrency, Flutter shared business logic, Flutter Web screens, shared widgets, shared services, shared test suites, and web VPS CI/CD pipelines. |
| **`android`** | **Platform Extension Layer** | Contains strictly Android-specific code, build recipes, and assets: `android/` root Gradle directory, `frontend/android/` Flutter Android module, `AndroidManifest.xml`, `MainActivity.kt`, ProGuard rules, APK/AAB build automation scripts (`scripts/release_manager.py`), Play Store assets, and Android CI/CD pipelines. |

---

## 2. Shared-Code Governance ("MASTER FIRST")

Any code, asset, configuration, or document that is consumed by more than one platform—or that impacts the backend, database, web portal, or shared Flutter interface—**MUST be authored, reviewed, tested, and committed to `master` first**.

### Master Branch Inclusions (Mandatory):
- `backend/`: Controllers, services, models, repositories, security filters, DTOs, tests.
- `backend/src/main/resources/db/migration/`: All Flyway database migrations (`V1` through `V37+`).
- `frontend/lib/`: All cross-platform UI widgets, screens, providers, models, and shared services (with conditional web/io stubs).
- `frontend/test/`: All unit, widget, and concurrency test suites.
- `.github/workflows/web_deploy.yml`: Production VPS web deployment workflow.
- `scripts/`: Platform-level deployment and workspace lifecycle scripts (`cleanup_workspace.bat`, `rebuild_workspace.bat`).

### Prohibited in `android` Branch:
The `android` branch is **strictly prohibited** from maintaining unmerged, isolated, or divergent copies of:
- `backend/` services or configurations
- Database migrations (`V*.sql`)
- Shared Flutter files (`frontend/lib/`)
- Platform-level business logic
- Concurrency or authorization policies

---

## 3. Merge Strategy & Synchronization Flow

The synchronization flow is unidirectional:

```text
               ┌────────────────────────┐
               │         master         │
               │  (All Core & Shared)   │
               └───────────┬────────────┘
                           │
                           │ git merge master
                           ▼
               ┌────────────────────────┐
               │        android         │
               │ (Native Android Only)  │
               └────────────────────────┘
```

1. **Development Direction:** Core platform features are developed on or merged directly into `master`.
2. **Sync Cadence:** Before starting any Android-specific work, and immediately after any change on `master`, developers must synchronize:
   ```bash
   git checkout master
   git pull origin master
   git checkout android
   git merge master
   git push origin android
   ```
3. **No Upstream Back-Porting from Untracked State:** Never implement platform features directly on `android` with the intention of back-porting later. If work inadvertently touches shared files, immediately commit those files to `master` and push to `origin/master`.

---

## 4. Pre-Release Validation & Release Gate

Before tagging, packaging, or distributing any Android APK or AAB release, engineers must execute the Pre-Release Branch Diff Gate:

```bash
git diff master..android --name-only
```

Every modified file in the diff must be classified into one of four approved categories:
1. **Android-only:** Native Gradle, Manifests, Kotlin activity, drawables, mipmaps, ProGuard rules, local properties.
2. **Shared application code:** Prohibited in diff. If any shared file appears, **HALT THE RELEASE IMMEDIATELY**. Move the shared code to `master`, commit, push to `origin/master`, and re-sync `android`.
3. **Deployment documentation:** Android-specific architectural plans, Play Store readiness checklists, R8 enablement logs, and keystore setup guides.
4. **CI/CD configuration:** `android_deploy.yml` and `release_manager.py`.

---

## 5. Release Certification Checklist

A release is certified for production rollout only when:
- [ ] `git diff master..android --name-only` contains zero `backend/` or `frontend/lib/` diffs.
- [ ] `master` branch compiles cleanly (`./gradlew compileJava`, `flutter analyze`).
- [ ] All tests pass on `master` (`./gradlew test`, `flutter test`).
- [ ] `master` is fully pushed to `origin/master`.
- [ ] `android` is cleanly merged with `master` and pushed to `origin/android`.
