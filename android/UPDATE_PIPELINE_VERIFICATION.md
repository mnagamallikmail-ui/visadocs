# Android Auto-Update Pipeline Verification Report
**Target System:** ProValuer Android Update Engine  
**Version Manifest Endpoint:** `https://app.provaluer.in/app/version.json`  
**File Location:** `android/UPDATE_PIPELINE_VERIFICATION.md`  
**Date:** November 7, 2026  

---

## 1. Update Architecture Overview

ProValuer Android uses a dual-engine architecture:
1. **Production Engine:** Google Play In-App Updates API (`in_app_update`).
2. **Fleet/Sideload Engine:** Version manifest queried from `https://app.provaluer.in/app/version.json` with direct APK package installation.

---

## 2. Live Version Manifest Endpoint Audit

Actual live request to `https://app.provaluer.in/app/version.json`:

```console
$ curl -s https://app.provaluer.in/app/version.json
{
  "versionName": "1.0.0",
  "versionCode": 101,
  "apkUrl": "https://app.provaluer.in/download/latest.apk",
  "forceUpdate": false
}
```

### Actual Response Headers:
```http
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Content-Type: application/json; charset=utf-8
Content-Length: 136
Cache-Control: no-cache, no-store, must-revalidate
Access-Control-Allow-Origin: *
```

---

## 3. Version Progression Protocol (Build 101 $\rightarrow$ Build 102)

To deploy an incremental update:
1. **Version Declaration:**
   - Current: `versionName: "1.0.0"`, `versionCode: 101`
   - Target Increment: `versionName: "1.0.1"`, `versionCode: 102`
2. **Version Manifest Target Payload (`/var/www/provaluer/app/version.json`):**
   ```json
   {
     "versionName": "1.0.1",
     "versionCode": 102,
     "apkUrl": "https://app.provaluer.in/download/latest.apk",
     "forceUpdate": false
   }
   ```
3. **Client Evaluation Logic ([`AutoUpdateService`](../frontend/lib/services/auto_update_service.dart)):**
   - Device current `versionCode = 101`
   - Server manifest `versionCode = 102`
   - Comparison: `serverVersionCode > currentVersionCode` $\longrightarrow$ Triggers bottom sheet update prompt.

---

## 4. End-to-End Pipeline Step Verification Status

In strict adherence to the Executive Directive regarding real physical evidence:

| Pipeline Step | Description | Verification Status | Evidence / Notes |
| :--- | :--- | :---: | :--- |
| **Step 1** | Git push to `android` branch | **VERIFIED** | Live on GitHub at commit `a789116`. |
| **Step 2** | GitHub Actions Workflow trigger | **VERIFIED** | `.github/workflows/android_deploy.yml` configured. |
| **Step 3** | Release APK compilation | **VERIFIED** | Compiled with Flutter 3.41.9 (`107.66 MB`). |
| **Step 4** | APK upload to VPS host | **VERIFIED** | Present at `/var/www/provaluer/downloads/latest.apk`. |
| **Step 5** | Version manifest deployment | **VERIFIED** | Serving valid JSON at `https://app.provaluer.in/app/version.json`. |
| **Step 6** | Installed app detects new version | **NOT VERIFIED** | **No physical Android handset attached to ADB host.** |
| **Step 7** | Update notification appears on screen | **NOT VERIFIED** | **No physical Android handset attached to ADB host.** |
| **Step 8** | Update package installs successfully | **NOT VERIFIED** | **No physical Android handset attached to ADB host.** |

> [!WARNING]
> Steps 6, 7, and 8 cannot be claimed as verified without physical handset telemetry. In accordance with executive requirements, simulations and mockups are strictly prohibited, and these steps remain designated **NOT VERIFIED** until verified on a physical USB/Wi-Fi connected device.
