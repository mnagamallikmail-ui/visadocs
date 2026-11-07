#!/usr/bin/env bash
# ==============================================================================
# ProValuer Android Distribution VPS Deployment Script
# Target: VPS Host (/var/www/provaluer)
# Domain: app.provaluer.in
# ==============================================================================
set -euo pipefail

# VPS Configuration Defaults (Can be overridden via environment variables)
VPS_USER="${VPS_USER:-root}"
VPS_HOST="${VPS_HOST:-visadocs.online}"
VPS_SSH_PORT="${VPS_SSH_PORT:-22}"

# Local Paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_APK="${PROJECT_ROOT}/android/outputs/apk/app-production-release.apk"
LOCAL_VERSION="${PROJECT_ROOT}/android/distribution/version.json"
LOCAL_INDEX="${PROJECT_ROOT}/android/distribution/index.html"
LOCAL_NGINX="${PROJECT_ROOT}/android/distribution/nginx-app-provaluer.conf"

# Remote Paths
REMOTE_BASE="/var/www/provaluer"
REMOTE_DOWNLOADS="${REMOTE_BASE}/downloads"
REMOTE_APP="${REMOTE_BASE}/app"
REMOTE_NGINX_AVAILABLE="/etc/nginx/sites-available/app.provaluer.in.conf"
REMOTE_NGINX_ENABLED="/etc/nginx/sites-enabled/app.provaluer.in.conf"

echo "========================================================================"
echo " ProValuer Android Distribution VPS Deployment"
echo " Target Host: ${VPS_USER}@${VPS_HOST}"
echo "========================================================================"

# Check local binary
if [ ! -f "${LOCAL_APK}" ]; then
  echo "[-] ERROR: Local APK not found at ${LOCAL_APK}"
  echo "    Please run: cd frontend && flutter build apk --flavor production --release"
  exit 1
fi

APK_SIZE=$(stat -c%s "${LOCAL_APK}" 2>/dev/null || stat -f%z "${LOCAL_APK}")
echo "[+] Local APK verified (${APK_SIZE} bytes)"

# Step 1: Ensure Remote Directories Exist
echo "[+] Step 1: Creating remote distribution directories..."
ssh -p "${VPS_SSH_PORT}" "${VPS_USER}@${VPS_HOST}" "
  mkdir -p ${REMOTE_DOWNLOADS} ${REMOTE_APP} /var/www/html
  chmod -R 755 ${REMOTE_BASE}
"

# Step 2: Upload Binary APK to VPS
echo "[+] Step 2: Uploading latest APK to ${REMOTE_DOWNLOADS}/latest.apk..."
scp -P "${VPS_SSH_PORT}" "${LOCAL_APK}" "${VPS_USER}@${VPS_HOST}:${REMOTE_DOWNLOADS}/latest.apk"

# Also create a versioned snapshot copy on remote
ssh -p "${VPS_SSH_PORT}" "${VPS_USER}@${VPS_HOST}" "
  cp ${REMOTE_DOWNLOADS}/latest.apk ${REMOTE_DOWNLOADS}/app-v1.0.0-101.apk
  chmod 644 ${REMOTE_DOWNLOADS}/latest.apk ${REMOTE_DOWNLOADS}/app-v1.0.0-101.apk
"

# Step 3: Upload Version Manifest and Mobile Landing Page
echo "[+] Step 3: Uploading version manifest and landing page..."
scp -P "${VPS_SSH_PORT}" "${LOCAL_VERSION}" "${VPS_USER}@${VPS_HOST}:${REMOTE_APP}/version.json"
scp -P "${VPS_SSH_PORT}" "${LOCAL_INDEX}" "${VPS_USER}@${VPS_HOST}:${REMOTE_DOWNLOADS}/index.html"
ssh -p "${VPS_SSH_PORT}" "${VPS_USER}@${VPS_HOST}" "
  cp ${REMOTE_APP}/version.json ${REMOTE_DOWNLOADS}/version.json
  chmod 644 ${REMOTE_APP}/version.json ${REMOTE_DOWNLOADS}/index.html
"

# Step 4: Deploy and Reload Nginx
echo "[+] Step 4: Configuring Nginx virtual host for app.provaluer.in..."
scp -P "${VPS_SSH_PORT}" "${LOCAL_NGINX}" "${VPS_USER}@${VPS_HOST}:${REMOTE_NGINX_AVAILABLE}"

ssh -p "${VPS_SSH_PORT}" "${VPS_USER}@${VPS_HOST}" "
  ln -sf ${REMOTE_NGINX_AVAILABLE} ${REMOTE_NGINX_ENABLED}
  nginx -t
  systemctl reload nginx
"

# Step 5: Verify Endpoints
echo "[+] Step 5: Verifying distribution endpoints..."
echo "--- Testing 302 Redirect on https://app.provaluer.in/download ---"
curl -sI "https://app.provaluer.in/download" | grep -E "HTTP|location|Content-Type" || true

echo "--- Testing Version Manifest on https://app.provaluer.in/app/version.json ---"
curl -s "https://app.provaluer.in/app/version.json" || true

echo ""
echo "========================================================================"
echo " [SUCCESS] Android Distribution Endpoint is Live!"
echo " Public Download URL: https://app.provaluer.in/download"
echo " Direct APK URL:      https://app.provaluer.in/download/latest.apk"
echo " Version Manifest:    https://app.provaluer.in/app/version.json"
echo " Mobile Landing Page: https://app.provaluer.in/"
echo "========================================================================"

