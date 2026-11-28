# GeoLite2 City Deployment & Operations Guide

## 1. Overview
`GeoIpService` performs local, in-memory IP-to-location lookups using MaxMind's `GeoLite2-City.mmdb` (`CHMCache`).
- **Zero external API calls** and **zero request latency** overhead.
- Resolves client IP in priority order: `X-Forwarded-For` -> `X-Real-IP` -> `request.getRemoteAddr()`.
- **Graceful Fallback:** If `GeoLite2-City.mmdb` is missing or unreadable at startup, the backend logs a warning and starts normally, falling back to `Country = Unknown`, `State = Unknown`, `City = Unknown`.

---

## 2. Server Preparation & Placement

1. Create the GeoIP directory inside persistent storage on the host/container:
   ```bash
   mkdir -p /app/storage/geoip
   ```
   *(In `docker-compose.yml`, `./storage` / `lead_storage` is mounted at `/app/storage` in `PVCBackend`.)*

2. Upload `GeoLite2-City.mmdb` (do **not** commit `.mmdb` files to git) to:
   ```text
   /app/storage/geoip/GeoLite2-City.mmdb
   ```

3. Set the environment variable on the backend service:
   ```env
   GEOIP_DB_PATH=/app/storage/geoip/GeoLite2-City.mmdb
   ```
   *(This is also the default relative path `storage/geoip/GeoLite2-City.mmdb` in `application.yml`.)*

4. Verify permissions so the backend process can read the file:
   ```bash
   ls -lh /app/storage/geoip/GeoLite2-City.mmdb
   ```

---

## 3. Updating the MaxMind Database

1. Download the latest `GeoLite2-City.mmdb` archive from MaxMind (or via `geoipupdate`).
2. Stage the new file beside the active file and swap atomically:
   ```bash
   cp GeoLite2-City.mmdb /app/storage/geoip/GeoLite2-City.mmdb.new
   mv /app/storage/geoip/GeoLite2-City.mmdb.new /app/storage/geoip/GeoLite2-City.mmdb
   ```
3. Restart the backend container/service so `DatabaseReader` reloads the updated `.mmdb` into `CHMCache`:
   ```bash
   docker compose restart backend
   ```
4. Confirm startup log contains:
   `Loaded MaxMind GeoLite2 City database from /app/storage/geoip/GeoLite2-City.mmdb`

---

## 4. Phase 2 Cleanup (Post-Validation)

Only after confirming `website_visits` records populate `country`, `state`, `city`, `device`, `browser`, `referrer`, and `page_path` in production:
1. Move `backend/scripts/phase2/V40__drop_seo_tables.sql` into `backend/src/main/resources/db/migration/` (or execute it directly against PostgreSQL) to drop the legacy `seo_*` tables.

