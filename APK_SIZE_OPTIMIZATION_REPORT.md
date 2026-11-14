# Production APK Size Optimization Report

**Project**: ProValuer Commercial (Visadocs)  
**Date**: November 8, 2026  
**Status**: Analysis Complete (Do Not Implement Yet - Evaluation Only)  
**Flavor**: Production Release  

---

## Executive Summary

An in-depth native binary and asset inspection was performed on the production Android build outputs of **ProValuer Commercial**. 

The investigation confirmed that the current standard production release command (`flutter build apk --flavor production --release`) builds a **Fat Universal APK** containing uncompressed 32-bit and 64-bit native libraries for three distinct hardware architectures:
1. `arm64-v8a` (Modern 64-bit ARM smartphones & tablets)
2. `armeabi-v7a` (Legacy 32-bit ARM devices)
3. `x86_64` (64-bit Intel/AMD architecture, emulators, Chromebooks)

This universal packaging inflates the standalone APK to **107.38 MB (112,599,703 bytes)**, of which **62.84 MB (58.5%)** is consumed exclusively by duplicated `.so` native engine binaries across the three architectures.

By compiling with `--split-per-abi` or `--target-platform android-arm64`, the APK size drops immediately by **~42 MB (~39% reduction)** down to **~65.4 MB**. Furthermore, via Google Play Store's **Android App Bundle (AAB)** dynamic delivery, end users only download device-tailored slices, achieving an estimated delivery size of **~45–50 MB** (over **50% savings**).

---

## Phase 1: Current Universal APK Architecture Breakdown

Inspection of the baseline release APK (`frontend/build/app/outputs/flutter-apk/app-production-release.apk`):

| Section | Files | Compressed Size | Uncompressed Size | Description |
| :--- | :--- | :--- | :--- | :--- |
| **`lib/` (Native Libraries)** | **12** | **62.84 MB** | **62.84 MB** | Native compiled C++/Dart binaries across all 3 ABIs |
| **`assets/` (Flutter Assets)** | **33** | **36.82 MB** | **36.93 MB** | Bundled static media (including 8 hero MP4 videos) |
| **`classes*.dex` (Bytecode)** | **3** | **6.76 MB** | **17.91 MB** | Compiled Android runtime DEX code |
| **`res/` & `resources.arsc`** | **427** | **0.75 MB** | **0.87 MB** | Android XML resources, icons, themes, tables |
| **`META-INF/` & Manifest** | **70** | **0.01 MB** | **0.03 MB** | Signing certificates, v1/v2/v3 signatures, manifest |
| **Total Universal APK** | — | **107.38 MB** | — | **112,599,703 bytes** |

### Per-ABI Native Library Breakdown inside Universal APK

Each supported ABI bundles four identical library components:
- `libapp.so`: Flutter Dart ahead-of-time (AOT) application bytecode
- `libflutter.so`: Flutter core C++ engine (Skia/Impeller, text layout, platform channel)
- `libdartjni.so`: Dart-to-Java native interface bridge
- `libdatastore_shared_counter.so`: Native shared preferences counter helper

| Target Architecture | `libapp.so` | `libflutter.so` | `libdartjni.so` | `libdatastore_shared_counter.so` | Total ABI Size |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`arm64-v8a`** | 10.55 MB | 11.32 MB | 0.12 MB | 0.01 MB | **20.98 MB** |
| **`armeabi-v7a`** | 11.78 MB | 8.28 MB | 0.08 MB | 0.01 MB | **19.21 MB** |
| **`x86_64`** | 11.08 MB | 12.57 MB | 0.11 MB | 0.01 MB | **22.66 MB** |
| **Combined Duplicated Libs** | **33.41 MB** | **32.17 MB** | **0.31 MB** | **0.03 MB** | **62.84 MB** |

> **Conclusion**: The universal APK carries **41.86 MB of completely redundant native code** for any given end-user device.

---

## Phase 2: Experimental Measurement & Size Comparisons

Both split-per-ABI builds (`flutter build apk --flavor production --release --split-per-abi`) and single-architecture targeted builds (`flutter build apk --flavor production --release --target-platform android-arm64`) were executed.

### Real Build Measurement Comparison

| Build Target / Variant | Generated Binary | Exact File Size (Bytes) | Size (MB) | Absolute Reduction vs Universal | Percentage Reduction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Current Universal APK** | `app-production-release.apk` | 112,599,703 | **107.38 MB** | Baseline | Baseline |
| **Split APK: `arm64-v8a`** | `app-arm64-v8a-production-release.apk` | 68,622,349 | **65.44 MB** | **-43.98 MB** | **-39.06%** |
| **Split APK: `armeabi-v7a`** | `app-armeabi-v7a-production-release.apk` | 66,760,681 | **63.67 MB** | **-45.84 MB** | **-40.71%** |
| **Split APK: `x86_64`** | `app-x86_64-production-release.apk` | 70,377,521 | **67.12 MB** | **-42.22 MB** | **-37.50%** |
| **Single Target (`android-arm64`)** | `app-production-release.apk` | 68,845,485 | **65.66 MB** | **-41.72 MB** | **-38.86%** |
| **Production AAB (App Bundle)** | `app-production-release.aab` | 93,272,068 | **88.95 MB** | — (Source bundle) | — |
| **Play Store Dynamic Delivery** | Device-specific split APK | *~47,000,000* | ***~45–48 MB*** | ***~-60 MB*** | ***~-56%*** |

---

## Phase 3: Impact Analysis

### 1. APK Size Reduction
- **Standalone Direct Distribution**:
  - Distributing `app-arm64-v8a-production-release.apk` directly drops the download size from **107.4 MB to 65.4 MB**.
  - Modern Android devices running 64-bit OS represent **>98%** of the active commercial Android ecosystem.
  - Per 1,000 downloads, bandwidth transfer decreases from **107.4 GB to 65.4 GB** (saving **42 GB** of egress bandwidth).
- **Residual Size Breakdown (Why is the split APK 65.4 MB?)**:
  - Native code: **20.98 MB** (uncompressed `arm64-v8a` `.so` files).
  - DEX bytecode: **6.76 MB** (compressed).
  - Assets: **36.82 MB**.
  - Specifically, 8 local video files in `assets/flutter_assets/assets/videos/hero_story/` total **34.7 MB**:
    - `7.mp4` (7.28 MB), `8.mp4` (6.29 MB), `1.mp4` (5.67 MB), `2.mp4` (5.51 MB), `6.mp4` (5.08 MB), `4.mp4` (2.80 MB), `3.mp4` (2.62 MB), `5.mp4` (2.01 MB).

### 2. Build Folder Size Reduction
- In Gradle's intermediate directory (`frontend/build/app/intermediates/merged_native_libs/`):
  - A universal build compiles and merges uncompressed libraries for all 3 ABIs:
    - `arm64-v8a`: **150.51 MB**
    - `armeabi-v7a`: **137.90 MB**
    - `x86_64`: **151.50 MB**
    - Total native intermediates: **~440 MB**
  - Building with `--target-platform android-arm64` generates only the targeted ABI:
    - Merged native libs: **150.51 MB**
    - Intermediate savings: **~290 MB per build cycle**.
  - **Local CI & Developer Velocity**:
    - Build execution time dropped from **140–215 seconds** down to **46.6 seconds** for split compilation when intermediate caches are hot.

### 3. Google Play Store Delivery Benefits
Google Play requires publishing via **Android App Bundle (.aab)** format.
1. **Dynamic Delivery**:
   - The developer uploads `app-production-release.aab` (88.95 MB).
   - Google Play's Dynamic Delivery engine extracts device-specific splits:
     - `base-master.apk`: Common DEX code, resources, and assets.
     - `base-config.<abi>.apk`: Exactly one ABI native slice.
     - `base-config.<density>.apk`: Only the device's screen density icons (hdpi, xhdpi, xxhdpi).
2. **On-the-Wire Compression**:
   - Google Play compresses `.so` files and resources using optimized Brotli / gzip transfer compression.
   - The delivered download size over cellular / Wi-Fi is estimated at **~45–48 MB**, compared to the 107.4 MB universal APK.
3. **Storage Footprint**:
   - The user's device never stores unneeded `.so` binaries in `/data/app/.../lib/`, saving ~42 MB of persistent flash storage per device.

---

## Phase 4: Secondary Optimization Opportunity (Assets)

Native ABI splitting achieves the maximum possible binary code reduction (~42 MB). To reduce APK size further below 65 MB, the next high-impact optimization candidate is asset storage:

| Optimization Target | Current Footprint | Proposed Action | Estimated Size After Action |
| :--- | :--- | :--- | :--- |
| **Hero Story Videos (8 files)** | 34.7 MB (bundled in APK) | Stream via CDN / Cloudflare / S3 on demand or transcode to AV1 / WebM | Split APK: **~30.7 MB**<br>Play Store delivery: **~15–18 MB** |
| **Native Libraries (`lib/`)** | 62.84 MB (universal) | Split per ABI (`arm64-v8a`) | Split APK: **20.98 MB** |

---

## Recommendations & Next Steps

1. **For Google Play Store Release**:
   - Keep current release command: `flutter build appbundle --flavor production --release`.
   - Google Play already handles splitting and serves ~45–48 MB packages to users. No changes to the bundle pipeline are required.

2. **For Direct Enterprise / Web APK Downloads**:
   - Transition from the universal build to split-per-ABI:
     ```bash
     flutter build apk --flavor production --release --split-per-abi
     ```
   - Serve `app-arm64-v8a-production-release.apk` (65.4 MB) as the default download on the website/portal, with a fallback download for `armeabi-v7a` (63.7 MB) if needed.

3. **Status**:
   - **Do not implement yet**: No modifications have been made to production source code, Gradle configurations, or CI build scripts per user instructions. All measurements reflect real compiled artifacts on disk.

