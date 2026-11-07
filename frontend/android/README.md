# ProValuer Commercial — Android Mobile Platform Guide

## 1. Executive Summary & Unified Architecture
ProValuer Commercial is built on a **Single Codebase Multiplatform Architecture**. Both the high-traffic VPS-hosted Web Application (`https://www.provaluer.in`) and the Android Application run from the same source code in `frontend/lib/`, sharing:
- The exact same business logic, services, models, and calculation engines.
- The exact same GoRouter routes and role-based authentication (`CLIENT`, `PA`, `SPA`, `ADMIN`, `SUPER_ADMIN`).
- The exact same UI widgets and Apple Vision Pro / Clay editorial design system.
- Direct statutory compliance with the Digital Personal Data Protection (DPDP) Act 2023.

```
                              ┌───────────────────────────────────┐
                              │     Unified Flutter Codebase      │
                              │         (frontend/lib/)           │
                              └─────────────────┬─────────────────┘
                                                │
                       ┌────────────────────────┴────────────────────────┐
                       ▼                                                 ▼
        ┌─────────────────────────────┐                   ┌─────────────────────────────┐
        │      Flutter Web Target     │                   │    Flutter Android Target   │
        │      (SPA on Port 8091)     │                   │    (in.provaluer.app)       │
        ├─────────────────────────────┤                   ├─────────────────────────────┤
        │ • HTML5 / Canvas Kit        │                   │ • Native ARM64/V7A AOT      │
        │ • window.localStorage       │                   │ • Android Keystore Vault    │
        │ • Web FilePicker Blob Anchor│                   │ • SAF & Storage Downloads   │
        │ • Web Analytics Interceptor │                   │ • BiometricPrompt (Finger/Face)
        └──────────────┬──────────────┘                   └──────────────┬──────────────┘
                       │                                                 │
                       └────────────────────────┬────────────────────────┘
                                                ▼
                              ┌───────────────────────────────────┐
                              │       Spring Boot 3.3.x VPS       │
                              │     https://www.provaluer.in      │
                              │           (Port 8082)             │
                              └─────────────────┬─────────────────┘
                                                ▼
                              ┌───────────────────────────────────┐
                              │       PostgreSQL 16 Cluster       │
                              │     (provaluer + backup db)       │
                              └───────────────────────────────────┘
```

---

## 2. Build Specifications & Flavors

| Setting | Value |
|---|---|
| **Package Name (Application ID)** | `in.provaluer.app` |
| **Application Display Name** | `ProValuer Commercial` |
| **Minimum SDK** | API 24 (Android 7.0 Nougat) |
| **Target SDK** | API 34 (Android 14) |
| **Compile SDK** | API 34 |
| **Java / Gradle Toolchain** | Java 17/21 • Gradle 8.14 • Android Gradle Plugin 8.11.1 |

### Configured Build Flavors

1. **Development (`development`)**:
   - Application ID: `in.provaluer.app.dev`
   - Label: `ProValuer Dev`
2. **Staging (`staging`)**:
   - Application ID: `in.provaluer.app.stage`
   - Label: `ProValuer Staging`
3. **Production (`production`)**:
   - Application ID: `in.provaluer.app`
   - Label: `ProValuer Commercial`

---

## 3. Exact Commands to Build APK and AAB

All Flutter build commands must be executed from the `frontend/` directory where `pubspec.yaml` resides.

### 1. Release APK (Production Flavor)
```bash
cd "d:\Demo\Visadocs\ProValuer Commercial\frontend"
flutter build apk --flavor production -t lib/main.dart --release
```
*Output Path:* `frontend/build/app/outputs/flutter-apk/app-production-release.apk`

### 2. Split Per-ABI APKs (Smaller file size for direct distribution)
```bash
cd "d:\Demo\Visadocs\ProValuer Commercial\frontend"
flutter build apk --flavor production --split-per-abi --release
```
*Output Paths:*
- `app-armeabi-v7a-production-release.apk` (~18 MB)
- `app-arm64-v8a-production-release.apk` (~21 MB)
- `app-x86_64-production-release.apk` (~22 MB)

### 3. Google Play Store Android App Bundle (AAB)
```bash
cd "d:\Demo\Visadocs\ProValuer Commercial\frontend"
flutter build appbundle --flavor production -t lib/main.dart --release
```
*Output Path:* `frontend/build/app/outputs/bundle/productionRelease/app-production-release.aab`

---

## 4. Platform-Aware Service Implementations

All platform differences are resolved cleanly via **Dart conditional imports** (`if (dart.library.html) ... if (dart.library.io) ...`), ensuring zero browser dependencies leak into the Android build:

1. **Token Vault (`TokenStorage` in `services/token_storage.dart`)**:
   - **Web:** Persists via `html.window.localStorage`.
   - **Android:** Uses **Android Keystore (AES-256 GCM)** via `flutter_secure_storage` with encrypted SharedPreferences fallback. Preloaded synchronously at application boot (`await TokenStorage.init()`).
2. **Document & Report Downloads (`DownloadService` in `services/download_service.dart`)**:
   - **Web:** In-memory `Blob` + programmatic anchor click.
   - **Android:** Writes octet streams directly to Android's `Downloads` / `AppDocuments` directory using `path_provider`, and automatically invokes the system intent viewer (`open_filex`) so the client or appraiser immediately views their DOCX or PDF report.
3. **Biometric Authentication (`BiometricService` in `services/biometric_service.dart`)**:
   - Native integration with `androidx.biometric.BiometricPrompt`.
   - `MainActivity.kt` extends `FlutterFragmentActivity` to support biometric verification for returning users.
4. **Network Connectivity & Offline Guard (`ConnectivityService` in `services/connectivity_service.dart`)**:
   - Real-time network state listener (`connectivity_plus`) providing seamless offline feedback.
5. **Native Document & Image Picking (`WebFilePicker` in `services/web_file_picker_stub.dart`)**:
   - On Android, invokes native Storage Access Framework (SAF) and Photo Picker via `file_picker` with bytes stream support.

---

## 5. Deep Linking & App Links

ProValuer Commercial supports both Android App Links and Custom Scheme routing:

* **Universal App Links (Verified Domain):**
  - Host: `https://www.provaluer.in` and `https://provaluer.in`
  - Routes: `/client/*`, `/request-valuation`, `/login`
* **Custom Scheme:**
  - `provaluer://open?route=client&order={refCode}`

