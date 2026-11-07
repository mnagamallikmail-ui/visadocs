# ProValuer Google Play Store Readiness & Compliance Specification
**Document Target:** `android/PLAYSTORE_READINESS.md`  
**Package Name:** `in.provaluer.app`  
**Application Display Name:** `Pro Valuer`  
**Version:** 2.0.0  
**Status:** Audit Baselined & Ready for Store Submission  

---

## 1. Technical Manifest & Android OS Compliance

* **Target SDK Version**: `34` (Android 14) / `35` (Android 15 ready).
* **Minimum SDK Version**: `24` (Android 7.0 Nougat - covers 99.2% of active Android devices).
* **Compile SDK Version**: `34`.
* **64-bit Compliance**: Native libraries packaged for `arm64-v8a`, `armeabi-v7a`, and `x86_64`.
* **Package Format**: Android App Bundle (`.aab`) utilizing Google Play Dynamic Delivery for optimized binary downloads.

---

## 2. In-App Updates Readiness

In accordance with [`android/AUTO_UPDATE_ARCHITECTURE.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/android/AUTO_UPDATE_ARCHITECTURE.md):
* Integrated Google Play Core In-App Updates (`in_app_update`).
* Supports **Flexible Updates** for standard releases without field disruption.
* Supports **Immediate Updates** for critical schema or cryptographic updates.

---

## 3. Native Permissions & Data Safety Audit

| Requested Permission | Rationale & User Facing Disclosure | Data Safety Declaration |
| :--- | :--- | :--- |
| `android.permission.CAMERA` | Used by appraisers to take on-site inspection photos of properties and collateral. | Collected for valuation report generation; not shared with third parties. |
| `android.permission.READ_MEDIA_IMAGES` | Allows selecting existing inspection photos from device gallery. | Ephemeral access during report upload. |
| `android.permission.USE_BIOMETRIC` | Enables quick hardware authentication via Fingerprint or Face Unlock. | Biometric data never leaves hardware Keystore/TEE; zero cloud transmission. |
| `android.permission.INTERNET` | Communication with Spring Boot backend APIs and Google Play update services. | All traffic encrypted via TLS 1.3. |
| `android.permission.ACCESS_NETWORK_STATE` | Monitors connectivity to automatically trigger offline sync queue flushes. | Network state checked locally; not logged or tracked. |

---

## 4. Google Play Store Assets Checklist

- [x] **App Name**: `Pro Valuer`
- [x] **Short Description (80 chars)**: `Enterprise Property & Collateral Valuation Suite for Field Appraisers.`
- [x] **Full Description**: Detailed overview of valuation workflows, PA/SPA signoffs, and banking mandates.
- [x] **Hi-Res Icon**: 512×512 PNG (32-bit color, official PV emblem on clean background).
- [x] **Feature Graphic**: 1024×500 PNG highlighting the mobile field appraiser workspace.
- [x] **Screenshots**: High-resolution screenshots captured across 360×800, 393×852, and tablet viewports.
- [x] **Privacy Policy URL**: Dedicated DPDP-compliant privacy URL hosted on `provaluer.in/privacy`.
