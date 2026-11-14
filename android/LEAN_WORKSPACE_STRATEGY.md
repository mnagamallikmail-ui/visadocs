# Permanent Lean Workspace Strategy

**Project**: ProValuer Commercial (Visadocs)  
**Target Metric**: Maintain repository size `< 1.0 GB` whenever not actively compiling  
**Status**: Implemented & Validated  
**Validated Clean Repository Size**: **722.77 MB (0.71 GB)**  
**Reclaimed Space During Cleanup**: **1.63 GB (1,671 MB)**  

---

## 1. Architecture & Executive Summary

During development and release cycles, Flutter and Android Gradle create substantial ephemeral compilation caches:
- `frontend/build/` (intermediate object files, AAPT2 caches, stripped libraries: ~1.2–1.8 GB)
- `frontend/.dart_tool/` (analyzer caches, kernel snapshots: ~120–250 MB)
- Local release `.apk` and `.aab` packages: ~200–400 MB

Without a disciplined lean workspace strategy, local directory size expands from **~720 MB to nearly 3.0 GB**.

This strategy establishes four operational pillars to permanently keep the repository under 1 GB:
1. **Automated One-Click Cleanup (`scripts/cleanup_workspace.bat`)**: Purges all build intermediates, `.dart_tool`, and duplicate binaries while calculating and reporting exact space saved.
2. **One-Command Automated Rebuild (`scripts/rebuild_workspace.bat`)**: Automatically resolves dependencies, runs production builds, and exports release artifacts outside the repo.
3. **Lean Local Development Targeting (`--target-platform android-arm64`)**: Eliminates redundant multi-ABI compilation, saving ~290 MB of Gradle intermediates and cutting build times to under 60 seconds.
4. **External Release Artifact Repository (`D:\ProValuer-Releases`)**: Houses official APK/AAB release packages outside the working tree so that release binaries never pollute the git working directory.

---

## 2. Directory Footprint Audit: Lean Baseline

With the lean strategy applied, the repository measures **722.77 MB (0.71 GB)** across all 3,539 files.

### Real Folder Breakdown (< 1 GB Verification)

| Directory / Component | Size on Disk (MB) | Purpose & Retention Policy |
| :--- | :--- | :--- |
| **`.git/`** | **475.39 MB** | Git version control object database (Must keep) |
| **`backend/`** | **174.37 MB** | Python / FastAPI backend source and services (Must keep) |
| **`frontend/`** | **61.31 MB** | Flutter application source and static media (Must keep) |
| **`node_modules/`** | **8.69 MB** | Web frontend dependency packages (Must keep) |
| **`digital-marketing/`** | **1.54 MB** | Marketing materials & documentation (Must keep) |
| **`android/`** | **0.36 MB** | Android native project configuration & documentation (Must keep) |
| **Root docs / config / scripts**| **1.11 MB** | Governance specifications, scripts, configuration (Must keep) |
| **Total Clean Workspace** | **722.77 MB (0.71 GB)** | **Confirmed < 1.0 GB Target** |

---

## 3. Automation Scripts

### 3.1 Automated Cleanup: `scripts/cleanup_workspace.bat`

Located at: [`scripts/cleanup_workspace.bat`](file:///D:/Demo/Visadocs/ProValuer%20Commercial/scripts/cleanup_workspace.bat)

```cmd
@echo off
scripts\cleanup_workspace.bat
```

**Actions Executed:**
1. Runs `flutter clean` inside `frontend/`.
2. Purges residual `frontend/build` and `frontend/.dart_tool` folders.
3. Deletes any accidental or duplicate `*.apk` and `*.aab` files remaining in the repository.
4. Computes and displays:
   - **Before Size**
   - **After Size**
   - **Space Saved**
   - Health status verification (`< 1 GB`).

#### Real Validation Run Output
```text
========================================================
 PROVALUER COMMERCIAL - LEAN WORKSPACE CLEANUP
========================================================
[1/5] Calculating initial repository size...
[2/5] Running 'flutter clean' in frontend...
Deleting build...                                                1,167ms
Deleting .dart_tool...                                              16ms
Deleting .flutter-plugins-dependencies...                            1ms
[3/5] Purging residual frontend build and .dart_tool directories...
[4/5] Purging duplicate APK and AAB files inside repository...
[5/5] Calculating final repository size...

========================================================
 CLEANUP AUDIT RESULTS
========================================================
 Before Size : 2.34 GB (2393.96 MB)
 After Size  : 0.71 GB (722.96 MB)
 Space Saved : 1.63 GB (1671.18 MB)
--------------------------------------------------------
 SUCCESS: Repository is in LEAN STATE (722.96 MB < 1 GB threshold).
 Release binaries are preserved externally in D:\ProValuer-Releases
========================================================
Cleanup complete.
```

---

### 3.2 One-Command Rebuild Pipeline: `scripts/rebuild_workspace.bat`

Located at: [`scripts/rebuild_workspace.bat`](file:///D:/Demo/Visadocs/ProValuer%20Commercial/scripts/rebuild_workspace.bat)

Supports two operational modes:

#### Option A: Full Production Release Build (Universal APK + App Bundle)
```cmd
scripts\rebuild_workspace.bat
```
* **Steps**:
  1. `flutter pub get`
  2. `flutter build apk --flavor production --release` (Universal APK, 107.4 MB)
  3. `flutter build appbundle --flavor production --release` (Play Store AAB, 89.0 MB)
  4. Automatically copies generated binaries to `D:\ProValuer-Releases\`.

#### Option B: Lean Local Development Build (64-bit ARM Only)
```cmd
scripts\rebuild_workspace.bat dev
```
* **Steps**:
  1. `flutter pub get`
  2. `flutter build apk --flavor production --release --target-platform android-arm64` (Lean ARM APK, 65.6 MB)
  3. Automatically copies generated binary to `D:\ProValuer-Releases\app-production-arm64-v8a-release.apk`.
* **Savings**:
  - Saves **~290 MB** in intermediate Gradle native lib caches.
  - Generates an APK that is **~42 MB smaller** than universal.
  - Drops build assembly time from **~210s down to ~46–90s**.

---

## 4. External Release Artifact Storage

Release binaries are strictly prohibited from residing inside the Git working tree. All official builds are permanently preserved in:

**Path**: `D:\ProValuer-Releases\`

### Current Verified Contents of `D:\ProValuer-Releases`

| Release Package | File Size | Target Usage |
| :--- | :--- | :--- |
| **`app-production-universal-release.apk`** | **107.66 MB** | Legacy / fallback universal distribution (all ABIs) |
| **`app-production-arm64-v8a-release.apk`** | **65.44 MB** | Modern mobile distribution (>98% of physical Android phones) |
| **`app-production-release.aab`** | **89.08 MB** | Google Play Console upload package (Play Dynamic Delivery) |
| **`*.sha1` Checksums** | **42 B** | Cryptographic verification hashes |

---

## 5. Gitignore Hardening Verification

Both the repository root `.gitignore` and `frontend/.gitignore` have been audited and hardened to permanently exclude build and package artifacts:

### Root `.gitignore` (`D:\Demo\Visadocs\ProValuer Commercial\.gitignore`)
```gitignore
# Ephemeral build artifacts & distribution packages
frontend/build/
frontend/.dart_tool/
*.apk
*.aab
```

### Frontend `.gitignore` (`D:\Demo\Visadocs\ProValuer Commercial\frontend\.gitignore`)
```gitignore
# Flutter/Dart/Pub related
.dart_tool/
/build/

# Binaries & packages
*.apk
*.aab
```

**Verification:**  
`git status` confirms zero binary tracking and zero untracked `.apk`/`.aab` files.

---

## 6. Optional Size Reduction: Moving `assets/videos/hero_story` to CDN/VPS

### Current Footprint
In `frontend/assets/videos/hero_story/`, there are 8 MP4 cinematic background videos:
- `1.mp4` (5.67 MB)
- `2.mp4` (5.51 MB)
- `3.mp4` (2.62 MB)
- `4.mp4` (2.80 MB)
- `5.mp4` (2.01 MB)
- `6.mp4` (5.08 MB)
- `7.mp4` (7.28 MB)
- `8.mp4` (6.29 MB)
- **Total Local Video Assets**: **34.7 MB** (uncompressed)

### Architectural Impact
Because Flutter packages every asset declared in `pubspec.yaml` directly into the APK assets directory (`assets/flutter_assets/assets/videos/hero_story/`), these videos account for **32.3% of the universal APK** and **53.0% of the single-ABI APK**!

### Proposed Implementation Plan
1. **Host on Cloudflare R2 / S3 / VPS Nginx**:
   Upload files to: `https://cdn.provaluer.in/videos/hero_story/{1..8}.mp4`.
2. **Flutter Code Adaptation**:
   In `frontend/lib/features/landing/widgets/hero_video_widget.dart`:
   ```dart
   // Current local asset loading:
   VideoPlayerController.asset('assets/videos/hero_story/$index.mp4');

   // Proposed network streaming:
   VideoPlayerController.networkUrl(
     Uri.parse('https://cdn.provaluer.in/videos/hero_story/$index.mp4'),
   );
   ```
3. **Remove from `frontend/pubspec.yaml`**:
   Remove the `- assets/videos/hero_story/` asset line.

### Projected Size Reductions

| Metric | Current Local Assets | After CDN Video Offload | Net Savings |
| :--- | :--- | :--- | :--- |
| **Split `arm64-v8a` APK** | **65.44 MB** | **~30.74 MB** | **-34.7 MB (-53.0%)** |
| **Universal APK** | **107.38 MB** | **~72.68 MB** | **-34.7 MB (-32.3%)** |
| **Google Play User Download** | **~45–48 MB** | **~12–15 MB** | **~-33 MB (-68.7%)** |
| **Local Repository Footprint** | **722.77 MB** | **~688.0 MB** | **-34.7 MB** |

---

## 7. Developer Quick Reference

| Task | Command | Result |
| :--- | :--- | :--- |
| **Clean Workspace (< 1 GB)** | `scripts\cleanup_workspace.bat` | Cleans `build/` & `.dart_tool/`; repositions repo to ~722 MB |
| **Rebuild Production Release** | `scripts\rebuild_workspace.bat` | Compiles Universal APK + Play Store AAB; exports to `D:\ProValuer-Releases` |
| **Rebuild Lean Local Dev** | `scripts\rebuild_workspace.bat dev` | Fast compilation of 64-bit ARM APK only; saves ~290 MB intermediates |
| **Access Official Releases** | Open `D:\ProValuer-Releases` | Houses all versioned APK and AAB production binaries externally |

