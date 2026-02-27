/* ============================================================
   Q4: Rating–Experience Mismatch Outliers
   KPI lock:
     - measure_id = 'H_RECMND_DY'
     - start_date = '2024-01-01'
     - answer_description = '"YES", patients would definitely recommend the hospital'
   Defensibility:
     - completed_surveys >= 100
     - exclude NULL ratings
============================================================ */
/* ============================================================
   Q4 — Rating–Experience Mismatch Outliers
   Reporting Period: 2024
   KPI: H_RECMND_DY — "% definitely recommend"
   Defensibility:
     - completed_surveys >= 100
     - exclude NULL star ratings
============================================================ */

WITH base AS (
  SELECT
    h.facility_id,
    h.facility_name,
    h.state,
    h.hospital_overall_rating AS rating,
    f.answer_percent AS recommend_percent,
    f.completed_surveys
  FROM hospital_info_raw h
  JOIN hcahps_raw f
    ON f.facility_id = h.facility_id
  WHERE f.measure_id = 'H_RECMND_DY'
    AND f.start_date = '2024-01-01'
    AND f.answer_description = '"YES", patients would definitely recommend the hospital'
    AND f.answer_percent IS NOT NULL
    AND f.completed_surveys >= 100
    AND h.hospital_overall_rating IS NOT NULL
),

ranked AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recommend_percent) AS recommend_quintile
  FROM base
)

/* ------------------------------------------------------------
   Output 1 — Full Ranked Dataset (for scatter plot export)
------------------------------------------------------------ */
SELECT *
FROM ranked
ORDER BY recommend_percent;


/* ------------------------------------------------------------
   Output 2 — High Rating (≥4) & Bottom Quintile Recommend
------------------------------------------------------------ */
SELECT *
FROM ranked
WHERE rating >= 4
  AND recommend_quintile = 1
ORDER BY recommend_percent ASC;


/* ------------------------------------------------------------
   Output 3 — Low Rating (≤2) & Top Quintile Recommend
------------------------------------------------------------ */
SELECT *
FROM ranked
WHERE rating <= 2
  AND recommend_quintile = 5
ORDER BY recommend_percent DESC;
