-- Phase 2: Drop legacy SEO Intelligence tables after Phase 1 verification
DROP TABLE IF EXISTS seo_crawl_errors;
DROP TABLE IF EXISTS seo_sync_logs;
DROP TABLE IF EXISTS seo_credentials;
DROP TABLE IF EXISTS seo_queries;
DROP TABLE IF EXISTS seo_daily_metrics;
DROP TABLE IF EXISTS seo_pages;
DROP TABLE IF EXISTS seo_sites;

