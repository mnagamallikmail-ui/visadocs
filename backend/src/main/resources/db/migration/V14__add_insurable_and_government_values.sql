-- V14__add_insurable_and_government_values.sql
-- Add dedicated Insurable Value and Government Value columns to valuation_data

ALTER TABLE valuation_data 
    ADD COLUMN IF NOT EXISTS government_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    ADD COLUMN IF NOT EXISTS insurable_value NUMERIC(19,2) DEFAULT 0 NOT NULL;

-- Backfill insurable_value to match existing total_replacement_cost
UPDATE valuation_data 
SET insurable_value = COALESCE(total_replacement_cost, 0)
WHERE insurable_value = 0 AND total_replacement_cost > 0;
