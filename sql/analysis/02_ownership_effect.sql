/* ============================================================
   Q2: Ownership effect on patient experience (HCAHPS)
   KPI lock:
     - measure_id = 'H_RECMND_DY'
     - start_date = '2024-01-01'
     - answer_description = '"YES", patients would definitely recommend the hospital'
   Notes:
     - Weighted by completed_surveys (patient-volume lens)
============================================================ */

/* ---------------------------
   Parameters (edit here)
---------------------------- */
-- Main thresholds
SET @min_completed_surveys := 100;
SET @min_hospitals_per_group := 25;

-- Robustness thresholds
SET @min_hospitals_per_band := 10;

/* ============================================================
   Base KPI dataset (reused)
============================================================ */
WITH kpi AS (
  SELECT
    h.facility_id,
    h.hospital_ownership AS ownership,
    f.answer_percent      AS recommend_percent,
    f.completed_surveys   AS completed_surveys
  FROM hospital_info_raw h
  JOIN hcahps_raw f
    ON f.facility_id = h.facility_id
  WHERE f.measure_id = 'H_RECMND_DY'
    AND f.start_date = '2024-01-01'
    AND f.answer_description = '"YES", patients would definitely recommend the hospital'
    AND f.answer_percent IS NOT NULL
    AND h.hospital_ownership IS NOT NULL
    AND f.completed_surveys >= @min_completed_surveys
),

/* ============================================================
   Q2 (Main): Weighted recommend % by ownership
============================================================ */
ownership_agg AS (
  SELECT
    ownership,
    COUNT(*) AS hospitals,
    MIN(recommend_percent) AS min_recommend_percent,
    MAX(recommend_percent) AS max_recommend_percent,
    AVG(recommend_percent) AS avg_recommend_percent,
    SUM(completed_surveys) AS total_surveys,
    SUM(recommend_percent * completed_surveys) / NULLIF(SUM(completed_surveys), 0)
      AS weighted_avg_recommend_percent
  FROM kpi
  GROUP BY ownership
)

SELECT *
FROM ownership_agg
WHERE hospitals >= @min_hospitals_per_group
ORDER BY weighted_avg_recommend_percent DESC;

/* ============================================================
   Q2 (Robustness): Ownership comparison within survey-volume bands
   Purpose: test whether ownership differences are driven by scale 
============================================================ */

WITH kpi_banded AS (
  SELECT
    ownership,
    recommend_percent,
    completed_surveys,
    CASE
      WHEN completed_surveys BETWEEN 100 AND 199 THEN '100-199'
      WHEN completed_surveys BETWEEN 200 AND 399 THEN '200-399'
      WHEN completed_surveys BETWEEN 400 AND 799 THEN '400-799'
      WHEN completed_surveys >= 800 THEN '800+'
      ELSE '<100'
    END AS survey_band
  FROM kpi
),
band_agg AS (
  SELECT
    ownership,
    survey_band,
    COUNT(*) AS hospitals,
    SUM(completed_surveys) AS total_surveys,
    SUM(recommend_percent * completed_surveys) / NULLIF(SUM(completed_surveys), 0)
      AS weighted_avg_recommend_percent
  FROM kpi_banded
  GROUP BY ownership, survey_band
)
SELECT *
FROM band_agg
WHERE hospitals >= @min_hospitals_per_band
ORDER BY survey_band, weighted_avg_recommend_percent DESC;
