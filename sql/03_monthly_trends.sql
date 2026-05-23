-- ============================================================
-- 03_monthly_trends.sql
-- Sentiment trends over time (month-by-month)
-- ============================================================
-- SKILLS: DATE functions, window functions (LAG, RANK),
--         GROUP BY time buckets, month-over-month delta
-- ============================================================
-- NOTE: Date function syntax varies by engine:
--   SQLite:     STRFTIME('%Y-%m', review_date)
--   PostgreSQL: TO_CHAR(review_date, 'YYYY-MM')  or  DATE_TRUNC('month', review_date)
--   BigQuery:   FORMAT_DATE('%Y-%m', review_date)
--   MySQL:      DATE_FORMAT(review_date, '%Y-%m')
-- All queries below use SQLite syntax. Swap the date function as needed.
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- QUERY 1: Monthly bucket counts (stacked bar chart source)
-- ────────────────────────────────────────────────────────────

SELECT
    STRFTIME('%Y-%m', review_date)                                       AS month,
    SUM(CASE WHEN derived_rating = 5        THEN 1 ELSE 0 END)           AS promoters,
    SUM(CASE WHEN derived_rating IN (3, 4)  THEN 1 ELSE 0 END)           AS passives,
    SUM(CASE WHEN derived_rating IN (1, 2)  THEN 1 ELSE 0 END)           AS detractors,
    COUNT(*)                                                              AS total_reviews
FROM reviews
WHERE derived_rating IS NOT NULL
  AND review_date IS NOT NULL
GROUP BY STRFTIME('%Y-%m', review_date)
ORDER BY month;


-- ────────────────────────────────────────────────────────────
-- QUERY 2: Monthly NPS score with month-over-month change
-- Uses LAG() window function to compare to prior month
-- ────────────────────────────────────────────────────────────

WITH monthly_nps AS (
    SELECT
        STRFTIME('%Y-%m', review_date) AS month,
        COUNT(*)                       AS total_reviews,
        ROUND(
            100.0 * SUM(CASE WHEN derived_rating = 5       THEN 1 ELSE 0 END) / COUNT(*) -
            100.0 * SUM(CASE WHEN derived_rating IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*)
        , 1) AS nps_score
    FROM reviews
    WHERE derived_rating IS NOT NULL
      AND review_date    IS NOT NULL
    GROUP BY STRFTIME('%Y-%m', review_date)
)

SELECT
    month,
    total_reviews,
    nps_score,

    -- Prior month's NPS using LAG window function
    LAG(nps_score) OVER (ORDER BY month)                          AS prev_month_nps,

    -- Month-over-month delta
    ROUND(nps_score - LAG(nps_score) OVER (ORDER BY month), 1)   AS nps_delta,

    -- Direction indicator
    CASE
        WHEN nps_score > LAG(nps_score) OVER (ORDER BY month)  THEN '📈 Up'
        WHEN nps_score < LAG(nps_score) OVER (ORDER BY month)  THEN '📉 Down'
        ELSE                                                         '➡️  Flat'
    END AS trend

FROM monthly_nps
ORDER BY month;


-- ────────────────────────────────────────────────────────────
-- QUERY 3: Best and worst months by NPS
-- ────────────────────────────────────────────────────────────

WITH monthly_nps AS (
    SELECT
        STRFTIME('%Y-%m', review_date) AS month,
        COUNT(*)                       AS total_reviews,
        ROUND(
            100.0 * SUM(CASE WHEN derived_rating = 5       THEN 1 ELSE 0 END) / COUNT(*) -
            100.0 * SUM(CASE WHEN derived_rating IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*)
        , 1) AS nps_score
    FROM reviews
    WHERE derived_rating IS NOT NULL
      AND review_date    IS NOT NULL
    GROUP BY STRFTIME('%Y-%m', review_date)
    HAVING COUNT(*) >= 100  -- only months with meaningful volume
),

ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY nps_score DESC) AS rank_best,
        RANK() OVER (ORDER BY nps_score ASC)  AS rank_worst
    FROM monthly_nps
)

SELECT month, total_reviews, nps_score,
    CASE
        WHEN rank_best  <= 3 THEN '🥇 Top 3 Month'
        WHEN rank_worst <= 3 THEN '⚠️  Bottom 3 Month'
        ELSE                      'Average'
    END AS performance_label
FROM ranked
ORDER BY nps_score DESC;


-- ────────────────────────────────────────────────────────────
-- QUERY 4: Category-level sentiment by quarter
-- ────────────────────────────────────────────────────────────

SELECT
    a.category,
    -- SQLite: extract quarter manually; PostgreSQL: use DATE_TRUNC('quarter', r.review_date)
    STRFTIME('%Y', r.review_date) || '-Q' ||
        CASE
            WHEN STRFTIME('%m', r.review_date) IN ('01','02','03') THEN '1'
            WHEN STRFTIME('%m', r.review_date) IN ('04','05','06') THEN '2'
            WHEN STRFTIME('%m', r.review_date) IN ('07','08','09') THEN '3'
            ELSE                                                        '4'
        END                                                              AS quarter,
    COUNT(*)                                                             AS total_reviews,
    ROUND(AVG(r.sentiment_polarity), 3)                                  AS avg_polarity,
    ROUND(
        100.0 * SUM(CASE WHEN r.derived_rating = 5       THEN 1 ELSE 0 END) / COUNT(*) -
        100.0 * SUM(CASE WHEN r.derived_rating IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*)
    , 1)                                                                 AS nps_score
FROM reviews r
JOIN apps    a ON r.app_name = a.app_name
WHERE r.derived_rating IS NOT NULL
  AND r.review_date    IS NOT NULL
GROUP BY a.category, quarter
HAVING COUNT(*) >= 20
ORDER BY a.category, quarter;
