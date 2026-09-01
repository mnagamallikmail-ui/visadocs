-- V15__valuation_say_and_separate_percentages.sql
-- Add dedicated Say values, separate realizable/distress percentages, and component breakdowns

ALTER TABLE valuation_data 
    ADD COLUMN IF NOT EXISTS say_land_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS say_building_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS land_realizable_percentage NUMERIC(5,2) DEFAULT 85.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS building_realizable_percentage NUMERIC(5,2) DEFAULT 85.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS land_distress_percentage NUMERIC(5,2) DEFAULT 75.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS building_distress_percentage NUMERIC(5,2) DEFAULT 75.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS land_realizable_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS building_realizable_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS land_distress_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS building_distress_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS land_government_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS building_government_value NUMERIC(19,2) DEFAULT 0 NOT NULL;
