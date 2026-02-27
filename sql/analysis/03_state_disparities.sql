/* ============================================================
   Q3: State-level disparities in patient recommendation
   KPI lock:
     - measure_id = 'H_RECMND_DY'
     - start_date = '2024-01-01'
     - answer_description = '"YES", patients would definitely recommend the hospital'
   Defensibility:
     - completed_surveys >= 100
     - states must have >= 20 hospitals
============================================================ */

WITH base AS (
  SELECT
    h.state,
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
    AND h.state IS NOT NULL
),

agg AS (
  SELECT
    state,
    COUNT(*) AS hospitals,
    SUM(completed_surveys) AS total_surveys,
    AVG(recommend_percent) AS avg_recommend_percent,
    SUM(recommend_percent * completed_surveys)
        / NULLIF(SUM(completed_surveys), 0) AS weighted_avg_recommend_percent
  FROM base
  GROUP BY state
)

SELECT *
FROM agg
WHERE hospitals >= 20
ORDER BY weighted_avg_recommend_percent DESC;
