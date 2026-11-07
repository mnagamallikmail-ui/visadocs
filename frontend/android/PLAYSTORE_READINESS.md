# ProValuer Commercial — Google Play Store Readiness Guide

**Package Name:** `in.provaluer.app`  
**Application Title:** `ProValuer Commercial`  
**Target API Level:** Android 14 (API Level 34) — **Compliant with Google Play Target API Policy**  
**Architecture:** 64-bit Compatible (`arm64-v8a`, `x86_64`, `armeabi-v7a`)  

---

## 1. Google Play Console Compliance Matrix

| Requirement | Platform Specification | Compliance Status |
|---|---|---|
| **Target API Level** | Android 14 (API Level 34) | **PASS** (Configured in `app/build.gradle.kts`) |
| **64-bit Architecture** | Native `.so` binaries generated for `arm64-v8a` & `x86_64` | **PASS** (Flutter AOT complies natively) |
| **Delivery Format** | Android App Bundle (`.aab`) with Dynamic Feature splitting | **PASS** (Supported via `flutter build appbundle`) |
| **App Size Optimization** | Per-ABI asset slicing, R8 code shrinking, icon tree shaking | **PASS** (Download size ~16–20 MB) |
| **Android V2 / V3 Signing** | APK Signature Scheme v2/v3 compatible | **PASS** |

---

## 2. Permissions Declaration & Justification

When submitting to the Google Play Console, declare and justify the following permissions:

| Permission | Technical Name | Usage Justification for Reviewers |
|---|---|---|
| **Internet Access** | `android.permission.INTERNET` | Required to communicate with the VPS REST API (`https://www.provaluer.in`) for live valuations, order tracking, and report retrieval. |
| **Network State** | `android.permission.ACCESS_NETWORK_STATE` | Required to detect offline conditions and alert the user before network operations fail. |
| **Media / Photos** | `android.permission.READ_MEDIA_IMAGES` | Allows property owners and appraisers to select site photos, boundary maps, and property registration documents for valuation dossiers. |
| **Camera** | `android.permission.CAMERA` | Allows field appraisers to capture real-time photographs of collateral properties during physical valuation inspections. |
| **Biometrics** | `android.permission.USE_BIOMETRIC` | Enables secure, convenient app unlocking via fingerprint or face recognition. |
| **Notifications** | `android.permission.POST_NOTIFICATIONS` | Delivers transactional alerts when valuation reports are completed, payments are verified, or quotes are ready for review. |

---

## 3. Data Safety Section (Google Play Mandate)

Under the Google Play Data Safety Policy and the statutory DPDP Act 2023, declare:

1. **Data Collected:**
   - **Personal Info:** Name, Email, Phone Number (for account creation, mandate assignment, and contact).
   - **Financial Info:** Payment transaction receipts and reference numbers (for fee verification).
   - **Photos & Documents:** Site photographs, title deeds, building plans uploaded by the user.
2. **Data Shared:**
   - **Zero third-party sharing:** User data is processed strictly for certified valuation reporting and is never sold to third-party ad networks or brokers.
3. **Security Practices:**
   - **Data Encrypted in Transit:** Enforced via TLS 1.2/1.3.
   - **Data Encrypted at Rest:** Primary PostgreSQL DB encrypted via AES-256 GCM.
   - **Right to Erasure (DPDP Act):** Users can request account and data deletion directly through the client dashboard or via email to `dpo@provaluer.in`.

---

## 4. Production Keystore & Release Signing Guide

### Step 1: Generate a Production Keystore
Execute the following keytool command (retain the keystore file and passwords in a secure password manager):

```bash
keytool -genkey -v -keystore provaluer-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias provaluer -storetype JKS
```

### Step 2: Configure `key.properties`
Create `frontend/android/key.properties` (this file is excluded by `.gitignore` to prevent credential leakage):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=provaluer
storeFile=../provaluer-release-key.jks
```

### Step 3: Reference `key.properties` in `build.gradle.kts`
When ready for production signing, update `frontend/android/app/build.gradle.kts`:

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

## 5. Google Play Release Commands

Generate the final optimized release bundle:

```bash
cd "d:\Demo\Visadocs\ProValuer Commercial\frontend"
flutter build appbundle --flavor production -t lib/main.dart --release
```

*Final Google Play Upload File:*  
`frontend/build/app/outputs/bundle/productionRelease/app-production-release.aab`

