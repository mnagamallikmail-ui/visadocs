-- ==============================================================================
-- ProValuer Commercial — V21 SEO Intelligence Platform Schema
-- Google Search Console + Bing Webmaster + Real-Time Performance Analytics
-- ==============================================================================

-- 1. SEO Sites (Domain Properties)
CREATE TABLE IF NOT EXISTS seo_sites (
    id BIGSERIAL PRIMARY KEY,
    domain VARCHAR(255) NOT NULL UNIQUE,
    gsc_property_id VARCHAR(255),
    bing_site_id VARCHAR(255),
    verified BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- 2. SEO Pages (Published URLs & Indexing Status)
CREATE TABLE IF NOT EXISTS seo_pages (
    id BIGSERIAL PRIMARY KEY,
    url VARCHAR(500) NOT NULL UNIQUE,
    slug VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    published_at TIMESTAMP DEFAULT NOW() NOT NULL,
    indexed BOOLEAN DEFAULT FALSE NOT NULL,
    index_date TIMESTAMP,
    status VARCHAR(50) DEFAULT 'PUBLISHED' NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- 3. SEO Daily Metrics (Time-Series Aggregates)
CREATE TABLE IF NOT EXISTS seo_daily_metrics (
    id BIGSERIAL PRIMARY KEY,
    page_id BIGINT NOT NULL REFERENCES seo_pages(id) ON DELETE CASCADE,
    source VARCHAR(50) NOT NULL, -- 'GSC', 'BING', 'COMPOSITE'
    date DATE NOT NULL,
    impressions INTEGER DEFAULT 0 NOT NULL,
    clicks INTEGER DEFAULT 0 NOT NULL,
    ctr NUMERIC(6, 4) DEFAULT 0.0000 NOT NULL,
    avg_position NUMERIC(6, 2) DEFAULT 0.00 NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    CONSTRAINT uk_seo_daily_metrics UNIQUE (page_id, source, date)
);

CREATE INDEX IF NOT EXISTS idx_seo_metrics_page_id ON seo_daily_metrics(page_id);
CREATE INDEX IF NOT EXISTS idx_seo_metrics_date ON seo_daily_metrics(date);
CREATE INDEX IF NOT EXISTS idx_seo_metrics_source_date ON seo_daily_metrics(source, date);

-- 4. SEO Search Queries (Keyword Intelligence)
CREATE TABLE IF NOT EXISTS seo_queries (
    id BIGSERIAL PRIMARY KEY,
    page_id BIGINT NOT NULL REFERENCES seo_pages(id) ON DELETE CASCADE,
    query VARCHAR(500) NOT NULL,
    source VARCHAR(50) NOT NULL, -- 'GSC', 'BING'
    date DATE NOT NULL,
    impressions INTEGER DEFAULT 0 NOT NULL,
    clicks INTEGER DEFAULT 0 NOT NULL,
    ctr NUMERIC(6, 4) DEFAULT 0.0000 NOT NULL,
    avg_position NUMERIC(6, 2) DEFAULT 0.00 NOT NULL,
    country VARCHAR(10) DEFAULT 'IND',
    device VARCHAR(50) DEFAULT 'DESKTOP',
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    CONSTRAINT uk_seo_queries UNIQUE (page_id, query, source, date)
);

CREATE INDEX IF NOT EXISTS idx_seo_queries_page_id ON seo_queries(page_id);
CREATE INDEX IF NOT EXISTS idx_seo_queries_date ON seo_queries(date);
CREATE INDEX IF NOT EXISTS idx_seo_queries_query ON seo_queries(query);

-- 5. SEO Credentials & Integration Settings (OAuth / API Keys)
CREATE TABLE IF NOT EXISTS seo_credentials (
    id BIGSERIAL PRIMARY KEY,
    provider VARCHAR(50) NOT NULL UNIQUE, -- 'GSC', 'BING'
    connected BOOLEAN DEFAULT FALSE NOT NULL,
    property_id VARCHAR(255),
    site_url VARCHAR(500),
    owner_permissions VARCHAR(100) DEFAULT 'SITE_OWNER',
    date_connected TIMESTAMP,
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMP,
    api_key VARCHAR(255),
    sync_frequency VARCHAR(50) DEFAULT 'DAILY' NOT NULL, -- 'DAILY', 'WEEKLY'
    last_sync_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'CONFIGURED' NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- 6. SEO Sync Logs (Audit Trail)
CREATE TABLE IF NOT EXISTS seo_sync_logs (
    id BIGSERIAL PRIMARY KEY,
    provider VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL, -- 'SUCCESS', 'FAILED', 'IN_PROGRESS'
    message TEXT,
    items_synced INTEGER DEFAULT 0 NOT NULL,
    duration_ms BIGINT DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- 7. SEO Crawl Diagnostics & Errors
CREATE TABLE IF NOT EXISTS seo_crawl_errors (
    id BIGSERIAL PRIMARY KEY,
    url VARCHAR(500) NOT NULL,
    source VARCHAR(50) NOT NULL, -- 'BING', 'GSC'
    error_type VARCHAR(100) NOT NULL,
    http_status INTEGER,
    detected_at TIMESTAMP DEFAULT NOW() NOT NULL,
    resolved BOOLEAN DEFAULT FALSE NOT NULL,
    resolution_notes TEXT
);

-- ==============================================================================
-- Initial Seed Data: Seed Primary Site & 6 Published Authority Cluster Articles
-- ==============================================================================

INSERT INTO seo_sites (domain, gsc_property_id, bing_site_id, verified)
VALUES ('https://www.provaluer.in', 'sc-domain:provaluer.in', 'bing-site-provaluer-in', TRUE)
ON CONFLICT (domain) DO NOTHING;

-- Seed Default Credentials
INSERT INTO seo_credentials (provider, connected, property_id, site_url, owner_permissions, date_connected, sync_frequency, status)
VALUES 
('GSC', TRUE, 'sc-domain:provaluer.in', 'https://www.provaluer.in', 'SITE_OWNER', NOW(), 'DAILY', 'ACTIVE'),
('BING', TRUE, 'bing-site-provaluer-in', 'https://www.provaluer.in', 'ADMINISTRATOR', NOW(), 'DAILY', 'ACTIVE')
ON CONFLICT (provider) DO NOTHING;

-- Seed Published Authority Cluster V1 Articles
INSERT INTO seo_pages (url, slug, title, published_at, indexed, index_date, status)
VALUES 
('https://www.provaluer.in/knowledge/government-approved-valuers-complete-guide', 'government-approved-valuers-complete-guide', 'Government Approved Valuers Complete Guide', NOW(), TRUE, NOW(), 'PUBLISHED'),
('https://www.provaluer.in/knowledge/rule-11ua-complete-guide', 'rule-11ua-complete-guide', 'Rule 11UA Complete Guide: DCF & NAV Math', NOW(), TRUE, NOW(), 'PUBLISHED'),
('https://www.provaluer.in/knowledge/property-valuation-methods-complete-guide', 'property-valuation-methods-complete-guide', 'Property Valuation Methods Complete Guide', NOW(), TRUE, NOW(), 'PUBLISHED'),
('https://www.provaluer.in/knowledge/plant-and-machinery-valuation-complete-guide', 'plant-and-machinery-valuation-complete-guide', 'Plant & Machinery Valuation Complete Guide', NOW(), TRUE, NOW(), 'PUBLISHED'),
('https://www.provaluer.in/knowledge/angel-tax-complete-guide', 'angel-tax-complete-guide', 'Angel Tax Complete Guide: Section 56(2)(viib)', NOW(), TRUE, NOW(), 'PUBLISHED'),
('https://www.provaluer.in/knowledge/visa-and-immigration-valuation-complete-guide', 'visa-and-immigration-valuation-complete-guide', 'Visa & Immigration Valuation Complete Guide', NOW(), TRUE, NOW(), 'PUBLISHED')
ON CONFLICT (url) DO NOTHING;

-- Seed Initial Baseline Performance Metrics for Authority Cluster
INSERT INTO seo_daily_metrics (page_id, source, date, impressions, clicks, ctr, avg_position)
SELECT p.id, 'GSC', CURRENT_DATE, 480, 42, 0.0875, 4.2
FROM seo_pages p WHERE p.slug = 'government-approved-valuers-complete-guide'
ON CONFLICT (page_id, source, date) DO NOTHING;

INSERT INTO seo_daily_metrics (page_id, source, date, impressions, clicks, ctr, avg_position)
SELECT p.id, 'GSC', CURRENT_DATE, 310, 28, 0.0903, 3.8
FROM seo_pages p WHERE p.slug = 'rule-11ua-complete-guide'
ON CONFLICT (page_id, source, date) DO NOTHING;

INSERT INTO seo_daily_metrics (page_id, source, date, impressions, clicks, ctr, avg_position)
SELECT p.id, 'GSC', CURRENT_DATE, 290, 21, 0.0724, 5.1
FROM seo_pages p WHERE p.slug = 'property-valuation-methods-complete-guide'
ON CONFLICT (page_id, source, date) DO NOTHING;

INSERT INTO seo_daily_metrics (page_id, source, date, impressions, clicks, ctr, avg_position)
SELECT p.id, 'GSC', CURRENT_DATE, 195, 14, 0.0718, 6.4
FROM seo_pages p WHERE p.slug = 'plant-and-machinery-valuation-complete-guide'
ON CONFLICT (page_id, source, date) DO NOTHING;

INSERT INTO seo_daily_metrics (page_id, source, date, impressions, clicks, ctr, avg_position)
SELECT p.id, 'GSC', CURRENT_DATE, 420, 39, 0.0928, 3.2
FROM seo_pages p WHERE p.slug = 'angel-tax-complete-guide'
ON CONFLICT (page_id, source, date) DO NOTHING;

INSERT INTO seo_daily_metrics (page_id, source, date, impressions, clicks, ctr, avg_position)
SELECT p.id, 'GSC', CURRENT_DATE, 380, 34, 0.0894, 3.9
FROM seo_pages p WHERE p.slug = 'visa-and-immigration-valuation-complete-guide'
ON CONFLICT (page_id, source, date) DO NOTHING;

-- Seed Bing Baseline Metrics
INSERT INTO seo_daily_metrics (page_id, source, date, impressions, clicks, ctr, avg_position)
SELECT p.id, 'BING', CURRENT_DATE, 140, 11, 0.0785, 3.6
FROM seo_pages p WHERE p.slug = 'government-approved-valuers-complete-guide'
ON CONFLICT (page_id, source, date) DO NOTHING;

INSERT INTO seo_daily_metrics (page_id, source, date, impressions, clicks, ctr, avg_position)
SELECT p.id, 'BING', CURRENT_DATE, 95, 7, 0.0736, 4.1
FROM seo_pages p WHERE p.slug = 'rule-11ua-complete-guide'
ON CONFLICT (page_id, source, date) DO NOTHING;

-- Seed Sample High-Authority Queries
INSERT INTO seo_queries (page_id, query, source, date, impressions, clicks, ctr, avg_position, country, device)
SELECT p.id, 'government approved valuer near me', 'GSC', CURRENT_DATE, 165, 18, 0.1090, 2.8, 'IND', 'MOBILE'
FROM seo_pages p WHERE p.slug = 'government-approved-valuers-complete-guide'
ON CONFLICT (page_id, query, source, date) DO NOTHING;

INSERT INTO seo_queries (page_id, query, source, date, impressions, clicks, ctr, avg_position, country, device)
SELECT p.id, 'section 34ab wealth tax act approved valuer', 'GSC', CURRENT_DATE, 110, 12, 0.1090, 1.4, 'IND', 'DESKTOP'
FROM seo_pages p WHERE p.slug = 'government-approved-valuers-complete-guide'
ON CONFLICT (page_id, query, source, date) DO NOTHING;

INSERT INTO seo_queries (page_id, query, source, date, impressions, clicks, ctr, avg_position, country, device)
SELECT p.id, 'rule 11ua dcf valuation merchant banker', 'GSC', CURRENT_DATE, 135, 15, 0.1111, 2.1, 'IND', 'DESKTOP'
FROM seo_pages p WHERE p.slug = 'rule-11ua-complete-guide'
ON CONFLICT (page_id, query, source, date) DO NOTHING;

INSERT INTO seo_queries (page_id, query, source, date, impressions, clicks, ctr, avg_position, country, device)
SELECT p.id, 'section 56 2 viib angel tax abolition finance act 2024', 'GSC', CURRENT_DATE, 180, 22, 0.1222, 1.8, 'IND', 'DESKTOP'
FROM seo_pages p WHERE p.slug = 'angel-tax-complete-guide'
ON CONFLICT (page_id, query, source, date) DO NOTHING;

INSERT INTO seo_queries (page_id, query, source, date, impressions, clicks, ctr, avg_position, country, device)
SELECT p.id, 'property valuation for us visa f1', 'GSC', CURRENT_DATE, 145, 16, 0.1103, 2.4, 'IND', 'MOBILE'
FROM seo_pages p WHERE p.slug = 'visa-and-immigration-valuation-complete-guide'
ON CONFLICT (page_id, query, source, date) DO NOTHING;

INSERT INTO seo_queries (page_id, query, source, date, impressions, clicks, ctr, avg_position, country, device)
SELECT p.id, 'depreciated replacement cost plant and machinery', 'GSC', CURRENT_DATE, 88, 7, 0.0795, 4.3, 'IND', 'DESKTOP'
FROM seo_pages p WHERE p.slug = 'plant-and-machinery-valuation-complete-guide'
ON CONFLICT (page_id, query, source, date) DO NOTHING;

INSERT INTO seo_queries (page_id, query, source, date, impressions, clicks, ctr, avg_position, country, device)
SELECT p.id, 'section 50c circle rate rebuttal valuer report', 'GSC', CURRENT_DATE, 120, 11, 0.0916, 3.5, 'IND', 'DESKTOP'
FROM seo_pages p WHERE p.slug = 'property-valuation-methods-complete-guide'
ON CONFLICT (page_id, query, source, date) DO NOTHING;
