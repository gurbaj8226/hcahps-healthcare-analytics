-- =========================================================
-- 02_stage_to_raw_load.sql
-- Purpose: Stage (TEXT) -> Production (typed) load
-- Techniques:
-- - TRIM() keys
-- - REGEXP numeric validation before CAST
-- - STR_TO_DATE date parsing
-- - Deduplicate HCAHPS stage at defined grain before insert
-- =========================================================

USE hcahps_project;

-- -------------------------
-- Load: hospital_info_stage -> hospital_info_raw
-- -------------------------
-- TRUNCATE TABLE hospital_info_raw;

INSERT INTO hospital_info_raw (
    facility_id,
    facility_name,
    state,
    hospital_type,
    hospital_ownership,
    emergency_services,
    hospital_overall_rating
)
SELECT
    TRIM(`Facility ID`) AS facility_id,
    TRIM(`Facility Name`) AS facility_name,
    UPPER(TRIM(`State`)) AS state,
    TRIM(`Hospital Type`) AS hospital_type,
    TRIM(`Hospital Ownership`) AS hospital_ownership,
    NULLIF(TRIM(`Emergency Services`), '') AS emergency_services,
    CASE
        WHEN TRIM(`Hospital overall rating`) REGEXP '^[0-9]+$'
        THEN CAST(TRIM(`Hospital overall rating`) AS UNSIGNED)
        ELSE NULL
    END AS hospital_overall_rating
FROM hospital_info_stage;

-- -------------------------
-- Load: hcahps_stage -> hcahps_raw (deduped at grain)
-- -------------------------
-- TRUNCATE TABLE hcahps_raw;

INSERT INTO hcahps_raw
(
  facility_id,
  measure_id,
  question,
  answer_description,
  answer_percent,
  linear_mean_value,
  completed_surveys,
  response_rate_percent,
  start_date,
  end_date
)
SELECT
  facility_id,
  measure_id,
  MAX(question) AS question,
  answer_description,
  MAX(answer_percent) AS answer_percent,
  MAX(linear_mean_value) AS linear_mean_value,
  MAX(completed_surveys) AS completed_surveys,
  MAX(response_rate_percent) AS response_rate_percent,
  start_date,
  MAX(end_date) AS end_date
FROM (
    SELECT
      TRIM(`Facility ID`) AS facility_id,
      TRIM(`HCAHPS Measure ID`) AS measure_id,
      `HCAHPS Question` AS question,
      TRIM(`HCAHPS Answer Description`) AS answer_description,

      CASE
        WHEN `HCAHPS Answer Percent` REGEXP '^[0-9]+(\\.[0-9]+)?$'
        THEN CAST(`HCAHPS Answer Percent` AS DECIMAL(5,2))
        ELSE NULL
      END AS answer_percent,

      CASE
        WHEN `HCAHPS Linear Mean Value` REGEXP '^[0-9]+(\\.[0-9]+)?$'
        THEN CAST(`HCAHPS Linear Mean Value` AS DECIMAL(6,2))
        ELSE NULL
      END AS linear_mean_value,

      CASE
        WHEN `Number of Completed Surveys` REGEXP '^[0-9]+$'
        THEN CAST(`Number of Completed Surveys` AS UNSIGNED)
        ELSE NULL
      END AS completed_surveys,

      CASE
        WHEN `Survey Response Rate Percent` REGEXP '^[0-9]+(\\.[0-9]+)?$'
        THEN CAST(`Survey Response Rate Percent` AS DECIMAL(5,2))
        ELSE NULL
      END AS response_rate_percent,

      STR_TO_DATE(`Start Date`, '%m/%d/%Y') AS start_date,
      STR_TO_DATE(`End Date`, '%m/%d/%Y') AS end_date
    FROM hcahps_stage
) x
GROUP BY facility_id, measure_id, answer_description, start_date;
