# ProValuer Android Distribution & Update Endpoint
**Domain:** `app.provaluer.in`  
**Target Platform:** Android (Physical Devices / Sideloading / Internal Fleet)  
**File Location:** `android/distribution/README.md`  
**Release Version:** `1.0.0` (Build `101`)  
**Release Date:** November 7, 2026  

---

## 1. Executive Endpoint Summary

| Endpoint Type | Public URL | Upstream Resource / Behavior |
| :--- | :--- | :--- |
| **Public Download Shortcut** | **`https://app.provaluer.in/download`** | Returns `302 Found` redirecting immediately to `/download/latest.apk`. Never cached. |
| **Direct APK Binary** | **`https://app.provaluer.in/download/latest.apk`** | Streams `/var/www/provaluer/downloads/latest.apk` with `application/vnd.android.package-archive`. |
| **Version Manifest** | **`https://app.provaluer.in/app/version.json`** | Returns JSON manifest evaluated by field valuer apps for update detection. |
| **Mobile Web Landing Page** | **`https://app.provaluer.in/`** | Responsive branded portal with download CTA, release notes, and installation guide. |

---

## 2. Version Manifest Specification

### Request:
```http
GET /app/version.json HTTP/1.1
Host: app.provaluer.in
Accept: application/json
```

### Response (`200 OK`):
```json
{
  "versionName": "1.0.0",
  "versionCode": 101,
  "apkUrl": "https://app.provaluer.in/download/latest.apk",
  "forceUpdate": false
}
```

### Field Definitions:
* `versionName` (*string*): Human-readable semantic release version.
* `versionCode` (*integer*): Monotonically increasing build integer compared against device `currentVersionCode`.
* `apkUrl` (*string*): Public HTTPS URL for downloading the binary package.
* `forceUpdate` (*boolean*): When `true`, presents an unskippable full-screen modal blocking application use until updated.

---

## 3. QR Code Installation

Scan the QR code below using any Android mobile camera or barcode scanner to navigate directly to `https://app.provaluer.in/download`:

```
+-----------------------------------------------------------------------------------------+
|                                                                                         |
|        [ SCAN TO DOWNLOAD PROVALUER ANDROID APK (v1.0.0+101) ]                           |
|                                                                                         |
|        Public QR Code URL:                                                              |
|        https://api.qrserver.com/v1/create-qr-code/?size=400x400&margin=15&data=https%3A%2F%2Fapp.provaluer.in%2Fdownload  |
|                                                                                         |
|        Alternative Fast CDN URL:                                                        |
|        https://quickchart.io/qr?text=https%3A%2F%2Fapp.provaluer.in%2Fdownload&size=400 |
|                                                                                         |
+-----------------------------------------------------------------------------------------+
```

---

## 4. Binary Integrity Details

* **Local Source Path:** `android/outputs/apk/app-production-release.apk`
* **File Size:** `112,894,659 bytes` (`107.66 MB`)
* **SHA-1:** `F062826F6E9BE49AE0F68ED91680B8D75E3AAA9E`
* **SHA-256:** `02D8F268C05A93647257A72FCAAAF4A65225BD19ED06111237DE23926AD8C58D`

---

## 5. VPS Step-by-Step Deployment Instructions

### Step 5.1: Configure DNS
Ensure the DNS A record for the distribution subdomain points to your VPS IP:
```
Type: A
Name: app
Domain: provaluer.in
Target: <VPS_PUBLIC_IP>
TTL: 300 (or Automatic)
```

---

### Step 5.2: Create Remote Directory Structure on VPS
Execute on the VPS as `root`:
```bash
mkdir -p /var/www/provaluer/downloads
mkdir -p /var/www/provaluer/app
mkdir -p /var/www/html
chmod -R 755 /var/www/provaluer
```

---

### Step 5.3: Upload APK, Manifest, and Landing Page
From your local workspace, use `scp` or run `./android/distribution/deploy_apk_to_vps.sh` (or `.\android\distribution\deploy_apk_to_vps.ps1`):

```bash
# 1. Upload release APK
scp -P 22 android/outputs/apk/app-production-release.apk root@<VPS_IP>:/var/www/provaluer/downloads/latest.apk

# 2. Create versioned snapshot copy on VPS
ssh root@<VPS_IP> "cp /var/www/provaluer/downloads/latest.apk /var/www/provaluer/downloads/app-v1.0.0-101.apk && chmod 644 /var/www/provaluer/downloads/*.apk"

# 3. Upload version manifest
scp -P 22 android/distribution/version.json root@<VPS_IP>:/var/www/provaluer/app/version.json

# 4. Upload mobile landing page
scp -P 22 android/distribution/index.html root@<VPS_IP>:/var/www/provaluer/downloads/index.html
```

---

### Step 5.4: Deploy Nginx Configuration & Issue SSL Certificate

1. Copy the Nginx virtual host configuration:
```bash
scp -P 22 android/distribution/nginx-app-provaluer.conf root@<VPS_IP>:/etc/nginx/sites-available/app.provaluer.in.conf
```

2. Enable the site and request SSL via Certbot on the VPS:
```bash
# On the VPS terminal:
ln -sf /etc/nginx/sites-available/app.provaluer.in.conf /etc/nginx/sites-enabled/app.provaluer.in.conf

# Obtain SSL Certificate if not already covered by wild-card
certbot --nginx -d app.provaluer.in --non-interactive --agree-tos -m admin@provaluer.in

# Verify syntax and reload Nginx
nginx -t
systemctl reload nginx
```

---

### Step 5.5: Deployment Verification Testing

Run these verification commands from any terminal:

#### 1. Verify 302 Redirect on `/download`:
```bash
curl -IL https://app.provaluer.in/download
```
*Expected Output:*
```http
HTTP/2 302
location: https://app.provaluer.in/download/latest.apk
...
HTTP/2 200
content-type: application/vnd.android.package-archive
content-disposition: attachment; filename="ProValuer-v1.0.0.apk"
content-length: 112894659
```

#### 2. Verify Version Manifest JSON:
```bash
curl -s https://app.provaluer.in/app/version.json
```
*Expected Output:*
```json
{
  "versionName": "1.0.0",
  "versionCode": 101,
  "apkUrl": "https://app.provaluer.in/download/latest.apk",
  "forceUpdate": false
}
```

#### 3. Verify Direct Header Probe:
```bash
curl -I https://app.provaluer.in/download/latest.apk
```
*Expected Output:*
```http
HTTP/2 200
content-type: application/vnd.android.package-archive
content-length: 112894659
cache-control: no-cache, no-store, must-revalidate
```

---

## 6. Sideload Installation Guide for Appraisers

1. Open **`https://app.provaluer.in/download`** or scan the QR code.
2. When the `.apk` finishes downloading, tap the notification.
3. If Android prompts *"For your security, your phone is not allowed to install unknown apps from this source"*:
   - Tap **Settings**.
   - Toggle **Allow from this source** to ON.
   - Return and tap **Install**.
4. Launch **ProValuer** and sign in.

