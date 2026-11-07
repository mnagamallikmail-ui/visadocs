# Production Deployment & Endpoint Validation Report
**Domain:** `app.provaluer.in`  
**Host IP:** `66.116.241.171`  
**File Location:** `android/PRODUCTION_DEPLOYMENT_VALIDATION.md`  
**Audit Date:** November 7, 2026  
**Status:** 100% Deployed & Live  

---

## 1. Production Distribution Endpoints Status

| Endpoint | Public URL | HTTP Code | Content-Type | Size / Target | Status |
| :--- | :--- | :---: | :--- | :---: | :---: |
| **Download Shortcut** | `https://app.provaluer.in/download` | `302` | `text/html` | Redirects to `/download/latest.apk` | **VERIFIED LIVE** |
| **Direct APK Stream** | `https://app.provaluer.in/download/latest.apk` | `200` | `application/vnd.android.package-archive` | `112,894,659 bytes` | **VERIFIED LIVE** |
| **Version Manifest** | `https://app.provaluer.in/app/version.json` | `200` | `application/json; charset=utf-8` | 136 bytes | **VERIFIED LIVE** |
| **Mobile Landing** | `https://app.provaluer.in/` | `200` | `text/html` | 8,873 bytes | **VERIFIED LIVE** |

---

## 2. Actual Command Execution Outputs

### 2.1 Public Download Endpoint Redirect Test:
```console
$ curl -IL https://app.provaluer.in/download
HTTP/1.1 302 Moved Temporarily
Server: nginx/1.18.0 (Ubuntu)
Date: Sat, 07 Nov 2026 01:44:08 GMT
Content-Type: text/html
Content-Length: 154
Location: https://app.provaluer.in/download/latest.apk
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()

HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Sat, 07 Nov 2026 01:44:08 GMT
Content-Type: application/vnd.android.package-archive
Content-Length: 112894659
Last-Modified: Sat, 07 Nov 2026 01:22:26 GMT
ETag: "6aee7d52-6baa2c3"
Content-Disposition: attachment; filename="ProValuer-v1.0.0.apk"
Cache-Control: no-cache, no-store, must-revalidate
Accept-Ranges: bytes
```

### 2.2 Version Manifest Endpoint Test:
```console
$ curl -s https://app.provaluer.in/app/version.json
{
  "versionName": "1.0.0",
  "versionCode": 101,
  "apkUrl": "https://app.provaluer.in/download/latest.apk",
  "forceUpdate": false
}
```

---

## 3. Physical File Integrity on VPS (`66.116.241.171`)

Queried directly from the host filesystem via SSH:

```console
root@66.116.241.171:~# ls -la /var/www/provaluer/downloads/
total 220528
drwxr-xr-x 2 root root      4096 Nov  7 01:24 .
drwxr-xr-x 4 root root      4096 Nov  7 01:21 ..
-rw-r--r-- 1 root root 112894659 Nov  7 01:23 app-v1.0.0-101.apk
-rw-r--r-- 1 root root      8873 Nov  7 01:24 index.html
-rw-r--r-- 1 root root 112894659 Nov  7 01:22 latest.apk
-rw-r--r-- 1 root root       136 Nov  7 01:24 version.json

root@66.116.241.171:~# ls -la /var/www/provaluer/app/
total 12
drwxr-xr-x 2 root root 4096 Nov  7 01:24 .
drwxr-xr-x 4 root root 4096 Nov  7 01:21 ..
-rw-r--r-- 1 root root  136 Nov  7 01:24 version.json

root@66.116.241.171:~# sha256sum /var/www/provaluer/downloads/latest.apk
02d8f268c05a93647257a72fcaaaf4a65225bd19ed06111237de23926ad8c58d  /var/www/provaluer/downloads/latest.apk
```

---

## 4. Real Browser Execution Evidence

Headless rendering sessions captured to disk:
1. **Google Chrome Landing Page Screenshot:**  
   Path: `d:\Demo\Visadocs\chrome_test.png` (40,023 bytes)  
   Resolution: 1280x1024  
   Validation: Zero SSL warnings; HTTP 200; rendered branding, version pill, download button, and QR code.
2. **Microsoft Edge Landing Page Screenshot:**  
   Path: `d:\Demo\Visadocs\edge_test.png` (40,757 bytes)  
   Validation: Zero SSL warnings; HTTP 200.
3. **Google Chrome Version Manifest JSON Screenshot:**  
   Path: `d:\Demo\Visadocs\chrome_version_json.png` (10,929 bytes)  
   Validation: Rendered JSON text with zero certificate warning.
