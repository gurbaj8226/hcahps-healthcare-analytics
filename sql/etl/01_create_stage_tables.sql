-- =========================================================
-- 01_create_stage_tables.sql
-- Purpose: Landing zone tables (TEXT-only) for raw imports
-- Notes:
-- - All TEXT to avoid import failures
-- - Column names mirror source headers (Workbench import)
-- =========================================================

USE hcahps_project;

-- DROP TABLE IF EXISTS hospital_info_stage;
CREATE TABLE IF NOT EXISTS hospital_info_stage (
    `Facility ID` TEXT,
    `Facility Name` TEXT,
    `State` TEXT,
    `Hospital Type` TEXT,
    `Hospital Ownership` TEXT,
    `Emergency Services` TEXT,
    `Hospital overall rating` TEXT
);

-- DROP TABLE IF EXISTS hcahps_stage;
CREATE TABLE IF NOT EXISTS hcahps_stage (
    `Facility ID` TEXT,
    `HCAHPS Measure ID` TEXT,
    `HCAHPS Question` TEXT,
    `HCAHPS Answer Description` TEXT,
    `HCAHPS Answer Percent` TEXT,
    `HCAHPS Linear Mean Value` TEXT,
    `Number of Completed Surveys` TEXT,
    `Survey Response Rate Percent` TEXT,
    `Start Date` TEXT,
    `End Date` TEXT
);
