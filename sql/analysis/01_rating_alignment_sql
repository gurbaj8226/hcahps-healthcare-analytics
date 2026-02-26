-- ============================================
-- Q1: Rating vs Recommend Alignment
-- Dataset: CMS HCAHPS 2024
-- KPI: H_RECMND_DY
-- ============================================

SET @measure := 'H_RECMND_DY';
SET @period  := '2024-01-01';

-- Weighted average recommend by rating

WITH base AS (
    SELECT
        h.hospital_overall_rating AS rating,
        f.answer_percent AS recommend_percent,
        f.completed_surveys
    FROM hospital_info_raw h
    JOIN hcahps_raw f
        ON f.facility_id = h.facility_id
    WHERE f.measure_id = @measure
      AND f.start_date = @period
      AND f.answer_percent IS NOT NULL
      AND h.hospital_overall_rating IS NOT NULL
)

SELECT
    rating,
    COUNT(*) AS hospitals,
    AVG(recommend_percent) AS avg_recommend_percent,
    SUM(completed_surveys) AS total_surveys,
    SUM(recommend_percent * completed_surveys)
        / NULLIF(SUM(completed_surveys), 0)
        AS weighted_avg_recommend_percent
FROM base
GROUP BY rating
ORDER BY rating;
