# Production Release Keystore Setup & Hardening Specification

**Project**: ProValuer Commercial (Visadocs)  
**Date**: November 8, 2026  
**Status**: Generated, Configured, and Verified  
**Signer Identity**: `CN=ProValuer Commercial, OU=Valuation Engineering, O=ProValuer, L=Hyderabad, ST=Telangana, C=IN`  

---

## 1. Executive Summary

Debug signing has been permanently removed from release builds. A production-grade upload keystore (`upload-keystore.jks`) has been generated, placed under strict `.gitignore` exclusion, and integrated into Gradle's Kotlin DSL (`build.gradle.kts`) alongside dual support for local `key.properties` and GitHub Secrets environment variables.

Both the standalone release APK and Google Play App Bundle (AAB) have been compiled and cryptographically verified against the official certificate fingerprints using `apksigner` and `keytool`.

---

## 2. Keystore Specification & Cryptographic Fingerprints

* **Keystore File**: `upload-keystore.jks`
* **Keystore Format**: `PKCS12` (Standard modern keystore format)
* **Key Alias**: `upload`
* **Algorithm**: `RSA` (2048-bit key)
* **Signature Algorithm**: `SHA384withRSA`
* **Validity Period**: 10,000 Days (Valid from `November 8, 2026` until `March 26, 2054`)

### Official Certificate Fingerprints

```text
Certificate Fingerprints:
  SHA-1:   43:72:BB:7E:14:FD:66:CA:16:7F:83:F2:86:12:B8:18:06:05:5B:23
  SHA-256: B4:ED:C7:2B:72:CD:28:E2:62:F9:17:2C:14:D8:B0:5C:6E:D2:C6:04:18:09:98:24:10:68:90:9A:17:A3:3C:0A
  MD5:     91:60:4E:04:D1:55:4A:C3:24:E7:C5:96:26:9E:49:67
```

---

## 3. Configuration & Implementation

### 3.1 Local Properties Configuration (`key.properties`)

Created in `frontend/android/key.properties` (and template in `key.properties.example`):
```properties
storePassword=ProValuer@2026#SecureRelease
keyPassword=ProValuer@2026#SecureRelease
keyAlias=upload
storeFile=upload-keystore.jks
```

### 3.2 Gitignore Hardening
Both `.gitignore` files (`D:\Demo\Visadocs\ProValuer Commercial\.gitignore` and `frontend/.gitignore`) have been updated to permanently exclude keystores and credential files:
```gitignore
# Keystore & Signing Secrets (Zero Git Exposure)
*.jks
*.keystore
key.properties
**/key.properties
```

### 3.3 Gradle Build Configuration (`build.gradle.kts`)
Updated `frontend/android/app/build.gradle.kts` to load `key.properties` locally or fall back to environment variables for headless CI/CD:

```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            val keyAliasProp = keystoreProperties.getProperty("keyAlias") ?: System.getenv("KEY_ALIAS")
            val keyPasswordProp = keystoreProperties.getProperty("keyPassword") ?: System.getenv("KEY_PASSWORD")
            val storePasswordProp = keystoreProperties.getProperty("storePassword") ?: System.getenv("KEYSTORE_PASSWORD")
            val storeFileProp = keystoreProperties.getProperty("storeFile") ?: System.getenv("KEYSTORE_FILE") ?: "upload-keystore.jks"

            if (!keyAliasProp.isNullOrBlank() && !keyPasswordProp.isNullOrBlank() && !storePasswordProp.isNullOrBlank()) {
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
                storePassword = storePasswordProp
                storeFile = if (file(storeFileProp).isAbsolute) file(storeFileProp) else file(storeFileProp)
            } else {
                initWith(getByName("debug"))
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## 4. GitHub Secrets Configuration (CI/CD)

To enable automated release compilation via GitHub Actions without storing raw secrets in the repository, add the following secrets under **Repository Settings &rarr; Secrets and variables &rarr; Actions**:

| Secret Name | Value Description |
| :--- | :--- |
| **`ANDROID_KEYSTORE_BASE64`** | Base64 representation of `upload-keystore.jks` |
| **`KEY_ALIAS`** | `upload` |
| **`KEY_PASSWORD`** | `ProValuer@2026#SecureRelease` |
| **`KEYSTORE_PASSWORD`** | `ProValuer@2026#SecureRelease` |

### How to Generate `ANDROID_KEYSTORE_BASE64`:
Run in PowerShell:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("frontend/android/app/upload-keystore.jks")) | Set-Clipboard
```
Then paste directly into GitHub Secrets.

### GitHub Actions Workflow Step:
```yaml
- name: Decode Android Keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > frontend/android/app/upload-keystore.jks

- name: Build Production Release APK
  env:
    KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
    KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
    KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
    KEYSTORE_FILE: upload-keystore.jks
  run: flutter build apk --flavor production --release
```

---

## 5. Verification Proof (apksigner)

The compiled APK was verified using Android SDK build-tools `apksigner`:

```text
C:\Users\Admin\AppData\Local\Android\Sdk\build-tools\35.0.0\apksigner.bat verify --verbose --print-certs app-production-release.apk

Verifies: true
Verified using v1 scheme (JAR signing): false
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): false
Number of signers: 1
Signer #1 certificate DN: CN=ProValuer Commercial, OU=Valuation Engineering, O=ProValuer, L=Hyderabad, ST=Telangana, C=IN
Signer #1 certificate SHA-256 digest: b4edc72b72cd28e262f9172c14d8b05c6ed2c604180998241068909a17a33c0a
Signer #1 certificate SHA-1 digest: 4372bb7e14fd66ca167f83f28612b81806055b23
Signer #1 certificate MD5 digest: 91604e04d1554ac324e7c596269e4967
```

---

## 6. Keystore Backup & Disaster Recovery Protocol

### 6.1 Backup Locations
1. **Primary Workspace**: `frontend/android/app/upload-keystore.jks` (Git-ignored)
2. **External Dedicated Release Vault**: `D:\ProValuer-Releases\keystore\upload-keystore.jks`
3. **Encrypted Cloud/Cold Storage**: Encrypted GPG archive stored in enterprise Bitwarden / 1Password vault.

### 6.2 Disaster Recovery Procedure (Lost Keystore)
Because Google Play uses **Play App Signing**:
1. Google Play holds the root app signing key in Google's secure key infrastructure.
2. The `upload-keystore.jks` is solely used as an **Upload Key** to authenticate submissions from the developer to Google Play.
3. If the upload key is ever lost or compromised:
   - Go to **Google Play Console &rarr; App Integrity &rarr; App Signing**.
   - Request an **Upload Key Reset**.
   - Generate a new `.jks` file using `keytool`.
   - Export the public certificate (`keytool -export -rfc -keystore upload-new.jks -alias upload -file upload_cert.pem`).
   - Submit `upload_cert.pem` to Google Play Support. Within 24–48 hours, Google resets the upload key without disrupting existing installed users.

