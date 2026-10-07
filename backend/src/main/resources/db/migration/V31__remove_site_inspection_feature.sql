-- ==============================================================================
-- ProValuer Commercial Platform — Schema Migration Version 31
-- REMOVAL: Site Inspection Feature Completely Dropped
-- Target: PostgreSQL 15+
-- ==============================================================================

-- Drop tables exclusively used by Site Inspection
DROP TABLE IF EXISTS inspection_photos CASCADE;
DROP TABLE IF EXISTS order_inspections CASCADE;
