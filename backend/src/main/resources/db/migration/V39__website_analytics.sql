-- Phase 1: Lightweight Website Analytics visit tracking table
-- Phase 2 (post-verification) will drop legacy seo_* tables in V40.

CREATE TABLE IF NOT EXISTS website_visits (
    id BIGSERIAL PRIMARY KEY,
    page_path VARCHAR(500) NOT NULL DEFAULT '/',
    country VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    state VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    city VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    device VARCHAR(50) NOT NULL DEFAULT 'Desktop',
    browser VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    referrer VARCHAR(500),
    visited_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_website_visits_visited_at ON website_visits (visited_at DESC);
CREATE INDEX IF NOT EXISTS idx_website_visits_page_path ON website_visits (page_path);
CREATE INDEX IF NOT EXISTS idx_website_visits_location ON website_visits (country, state, city);

