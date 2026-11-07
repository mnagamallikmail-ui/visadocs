# ProValuer Android Auto-Update Architecture
**Target Platform:** Android (Google Play Store & VPS Distribution)  
**Document Target:** `android/AUTO_UPDATE_ARCHITECTURE.md`  
**Version:** 1.0.0  
**Status:** Architecture Approved  

---

## 1. Overview & Dual-Engine Strategy

To ensure seamless field operations for valuers and appraisers, ProValuer Android employs a **dual-engine auto-update architecture**:

1. **Production Engine (Google Play Store)**: Implemented using the official **Google Play In-App Updates API** (`in_app_update`). Provides native, frictionless updates directly from Google Play without prompting for unknown-source installation permissions.
2. **Internal Testing Engine (VPS-Hosted APK)**: Implemented via an internal version-check endpoint (`/api/v1/app/version`) on the ProValuer VPS. Automatically detects new builds for internal staging testers, downloads the signed `.apk`, and invokes the Android `PackageInstaller` intent.

```
                                  [ App Launch / Periodic Trigger ]
                                                  |
                                                  v
                                     Is Build Google Play Flavor?
                                                  |
                         +------------------------+------------------------+
                         |                                                 |
                   [ YES: Production ]                              [ NO: Internal Staging ]
                         |                                                 |
                         v                                                 v
             Call InAppUpdateManager                           Query VPS /api/v1/app/version
                         |                                                 |
            Is Update Available on Play?                      Is serverVersionCode > appVersionCode?
                         |                                                 |
             +-----------+-----------+                         +-----------+-----------+
             |                       |                         |                       |
        [ YES ]                    [ NO ]                 [ YES ]                    [ NO ]
             |                       |                         |                       |
             v                       v                         v                       v
    Is it Force Update?          Continue              Is it Force Update?          Continue
     (updatePriority >= 4)         Normal               (forceUpdate == true)         Normal
             |                   Execution                     |                   Execution
     +-------+-------+                                 +-------+-------+
     |               |                                 |               |
[ IMMEDIATE ]   [ FLEXIBLE ]                      [ BLOCKING ]    [ DISMISSIBLE ]
Blocking dialog  Background                       Full-screen     User can tap
with progress;   download with                    dialog; cannot  "Update Later";
cannot cancel    "Install Now"                    bypass          downloads in
                 snack bar                                        background
```

---

## 2. Update Check Trigger Points

The client application checks for updates at three distinct lifecycle points:

1. **App Startup (`main.dart` / Splash Screen)**: Evaluates version before rendering the login screen to prevent outdated clients from hitting deprecated endpoints.
2. **Post-Authentication (`LoginScreen`)**: Re-checks when a user successfully authenticates and establishes a session.
3. **Periodic 24-Hour Interval**: A background timer runs every 24 hours while the app is active to notify long-running field sessions of critical patches.

---

## 3. Update Classification: Soft Update vs. Force Update

| Attribute | Soft Update (Flexible) | Force Update (Immediate) |
| :--- | :--- | :--- |
| **Typical Use Cases** | Non-breaking UI polish, performance improvements, new optional questionnaire templates. | Breaking backend API migrations, cryptographic certificate rotations, critical security hotfixes. |
| **User Interaction** | Displays a clean bottom sheet: *"A new version of ProValuer is available."* Options: **Update Now** or **Later**. | Displays a permanent, non-dismissible modal: *"Required Update: Please update to continue using ProValuer."* Back button disabled. |
| **Google Play Mode** | `AppUpdateType.FLEXIBLE` (downloads in background; prompts user to restart when ready). | `AppUpdateType.IMMEDIATE` (takes over screen with native Google Play progress dialog). |
| **VPS Sideload Mode** | Downloads APK in background via Android `DownloadManager`; pops notification when complete. | Shows blocking progress bar, downloads APK to cache, and immediately launches Android install intent. |

---

## 4. VPS Internal Update Contract

For non-Play Store internal APK builds, the backend exposes a lightweight, public metadata endpoint:

### `GET /api/v1/app/version`
#### Response Payload:
```json
{
  "platform": "android",
  "flavor": "internal",
  "latestVersion": "1.1.0",
  "latestVersionCode": 110,
  "minSupportedVersionCode": 105,
  "forceUpdate": false,
  "downloadUrl": "https://provaluer.in/releases/android/app-internal-release.apk",
  "apkSize": "38452104",
  "sha256": "8f3b2c1a4e5d6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a",
  "releaseNotes": [
    "Added Section-Based valuation progress indicators.",
    "Integrated 30-second local autosave.",
    "Camera-first photo capture enabled for field inspections."
  ]
}
```

### Client Logic Rules:
* If `currentVersionCode < minSupportedVersionCode` $\longrightarrow$ **Force Update** (Immediate).
* If `minSupportedVersionCode <= currentVersionCode < latestVersionCode` and `forceUpdate == false` $\longrightarrow$ **Soft Update** (Flexible).
* If `currentVersionCode >= latestVersionCode` $\longrightarrow$ **Up to Date** (No prompt).

---

## 5. Security & Permission Handling

1. **Checksum Verification**: The client calculates SHA-256 of downloaded APKs before invoking the installer to prevent MITM tampering.
2. **Android Package Installer Intent**:
   - Uses `FileProvider` (`in.provaluer.app.fileprovider`) to securely pass the APK URI to Android OS.
   - On Android 8.0+ (API 26+), requests `android.permission.REQUEST_INSTALL_PACKAGES` only when the user explicitly taps "Update Now" in internal builds.
3. **Play Store Compliance**: Play Store builds strictly disable the self-updating VPS downloader code to comply with Google Play Developer Program Policies.

---

## 6. Implementation Service Architecture

The service is packaged into a reusable, platform-gated Dart class:

```
frontend/lib/services/
└── auto_update_service.dart
    ├── checkGooglePlayUpdate()     -> Invokes InAppUpdate.checkForUpdate()
    ├── checkVpsUpdate()            -> HTTP GET to /api/v1/app/version
    ├── showSoftUpdateDialog()      -> Custom ProValuer themed bottom sheet
    ├── showForceUpdateDialog()     -> Non-dismissible full-screen modal
    └── downloadAndInstallApk()     -> Android DownloadManager + FileProvider
```

---

## 7. Verification & Testing Protocol

- [x] **Play Store Simulation**: Test via Google Play Console Internal App Sharing using dummy version codes.
- [x] **Flexible Download Verification**: Confirm app continues operating while download occurs in background; restart banner pops upon completion.
- [x] **Immediate Blocking Verification**: Confirm user cannot bypass the update screen when `forceUpdate == true`.
- [x] **VPS Sideload Verification**: Test on physical Android 11, 12, 13, and 14 devices to verify `FileProvider` installation permissions.

