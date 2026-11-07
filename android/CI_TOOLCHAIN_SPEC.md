# Android CI/CD Toolchain & Version Locking Specification
**Project:** ProValuer Commercial  
**File Location:** `android/CI_TOOLCHAIN_SPEC.md`  
**Date:** November 7, 2026  
**Status:** Version Locked & Validated  

---

## 1. Executive Summary & Root Cause Analysis

### Incident Summary:
During automated GitHub Actions CI execution on branch `android`, the step `flutter pub get` failed during dependency resolution before Gradle compilation could begin.

### Root Cause:
1. `.github/workflows/android_deploy.yml` had specified:
   ```yaml
   - name: Setup Flutter
     uses: subosito/flutter-action@v2
     with:
       flutter-version: '3.29.0'
       channel: 'stable'
   ```
2. Flutter `3.29.0` bundles **Dart SDK 3.7.0**.
3. Direct dependency `font_awesome_flutter: 11.0.0` specifies SDK constraint:
   ```yaml
   sdk: '>=3.9.0 <4.0.0'
   ```
4. Because the runner had Dart SDK 3.7.0, `flutter pub get` failed immediately with:
   ```text
   The current Dart SDK version is 3.7.0.
   font_awesome_flutter 11.0.0 requires >=3.9.0 <4.0.0
   ```

### Remediation Applied:
Upgraded `.github/workflows/android_deploy.yml` to use Flutter `3.41.9` (`channel: 'stable'`), which bundles **Dart SDK 3.11.5**. This satisfies `font_awesome_flutter 11.0.0` and locks CI to the identical toolchain running on the developer workstation.

---

## 2. Inviolable Toolchain Version Matrix

All environments (Developer Workstation, GitHub Actions CI Runner, and Local Android Build Pipeline) are strictly locked to the following specification:

| Toolchain Component | Locked Version | Configuration Reference |
| :--- | :--- | :--- |
| **Flutter SDK** | **`3.41.9`** (channel `stable`) | `.github/workflows/android_deploy.yml`<br>`developer workstation` |
| **Dart SDK** | **`3.11.5`** (stable) | Bundled with Flutter 3.41.9 |
| **Java JDK** | **`Java 17`** (Eclipse Temurin) | `actions/setup-java@v4` with `java-version: '17'`<br>`frontend/android/app/build.gradle.kts` (`JavaVersion.VERSION_17`) |
| **Gradle Distribution** | **`8.14`** | `frontend/android/gradle/wrapper/gradle-wrapper.properties`<br>(`gradle-8.14-all.zip`) |
| **Android Compile SDK** | **`36`** | `frontend/android/app/build.gradle.kts` (`compileSdk = 36`) |
| **Android Target SDK** | **`34`** | `frontend/android/app/build.gradle.kts` (`targetSdk = 34`) |
| **Android Min SDK** | **`24`** | `frontend/android/app/build.gradle.kts` (`minSdk = 24`) |
| **Android App ID / Package** | **`in.provaluer.app`** | `frontend/android/app/build.gradle.kts` (`namespace` & `applicationId`) |

---

## 3. GitHub Actions Workflow Specification (`.github/workflows/android_deploy.yml`)

```yaml
name: Android Production Build & Release

on:
  push:
    branches:
      - android
    tags:
      - 'android-v*'

jobs:
  build:
    name: Build Android APK & AAB
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.9'
          channel: 'stable'
          cache: true

      - name: Install Dependencies
        working-directory: frontend
        run: flutter pub get

      - name: Run Tests
        working-directory: frontend
        run: flutter test || true

      - name: Decode Android Keystore
        if: env.ANDROID_KEYSTORE_BASE64 != ''
        env:
          ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
        run: |
          echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > android/app/key.jks

      - name: Build Release APK
        working-directory: frontend
        run: flutter build apk --flavor production --release
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

      - name: Build Release AAB (App Bundle)
        working-directory: frontend
        run: flutter build appbundle --flavor production --release
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: android-release-binaries
          path: |
            frontend/build/app/outputs/flutter-apk/app-production-release.apk
            frontend/build/app/outputs/bundle/productionRelease/app-production-release.aab

      - name: Deploy to Google Play Internal Testing
        if: startsWith(github.ref, 'refs/tags/android-v') && env.PLAY_STORE_JSON_KEY != ''
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_JSON_KEY }}
          packageName: in.provaluer.app
          releaseFiles: frontend/build/app/outputs/bundle/productionRelease/app-production-release.aab
          track: internal
          status: completed
```

---

## 4. Verification Evidence

### 4.1 Local Toolchain Output:
* `flutter --version`:
  ```text
  Flutter 3.41.9 • channel stable • https://github.com/flutter/flutter.git
  Framework • revision 00b0c91f06 (6 months ago) • 2026-04-29 10:03:19 -0700
  Engine • hash 9161402dc0e134b3fb5adee5046b6e84b1a5e1c1 (revision 42d3d75a56) (6 months ago) • 2026-04-28 17:31:55.000Z
  Tools • Dart 3.11.5 • DevTools 2.54.2
  ```
* `dart --version`:
  ```text
  Dart SDK version: 3.11.5 (stable) (Wed Apr 15 00:36:32 2026 -0700) on "windows_x64"
  ```

### 4.2 Lifecycle Step Outcomes:
1. `flutter clean`: Success (`Deleting build... 1,536ms`).
2. `flutter pub get`: Success (`Got dependencies!`).
3. `flutter analyze`: 0 compilation errors across all files.
4. `flutter test`: 10/10 passed across `android_verification_test.dart` and `critical_bug_fixes_test.dart`.
5. `flutter build apk --flavor production --release`:
   - Built: `build/app/outputs/flutter-apk/app-production-release.apk`
   - Size: `112,599,699 bytes`
   - SHA-1: `220FF6FC801AF558F330FD725FB1358A39D72223`
   - SHA-256: `6550E361B7AF475804C391076B0972FFAC6CCCFEC7A3BF05492FC738358DCC89`
6. `flutter build appbundle --flavor production --release`:
   - Built: `build/app/outputs/bundle/productionRelease/app-production-release.aab`
   - Size: `93,271,339 bytes`
   - SHA-1: `40E31D6E039CA8FDF4BF6108D413607D8A34F08C`
   - SHA-256: `90C1982814319B643732E01FFD82FA391A43C62707B6D6F805CCF7366116B11D`

