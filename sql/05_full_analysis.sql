-- ============================================================
-- 05_full_analysis.sql
-- Complete NPS Sentiment Analysis — single-file version
-- Perfect for portfolio walkthroughs & interviews
-- ============================================================
-- Run this file alone for the full picture.
-- ============================================================


-- ──────────────────────────────────────────────────────────────────
-- PART 0: Snapshot — what does our dataset look like?
-- ──────────────────────────────────────────────────────────────────

SELECT
    (SELECT COUNT(*)        FROM reviews)                AS total_reviews,
    (SELECT COUNT(DISTINCT app_name) FROM reviews)       AS unique_apps,
    (SELECT COUNT(DISTINCT category) FROM apps)          AS unique_categories,
    (SELECT MIN(review_date) FROM reviews)               AS earliest_review,
    (SELECT MAX(review_date) FROM reviews)               AS latest_review;


-- ──────────────────────────────────────────────────────────────────
-- PART 1: Assign NPS buckets to every review
-- ──────────────────────────────────────────────────────────────────

WITH bucketed AS (
    SELECT
        r.review_id,
        r.app_name,
        a.category,
        a.type                                              AS app_type,
        r.derived_rating,
        r.review_date,
        r.sentiment_polarity,

        -- ★ Core CASE WHEN bucketing
        CASE
            WHEN r.derived_rating = 5        THEN 'Promoter'
            WHEN r.derived_rating IN (3, 4)  THEN 'Passive'
            WHEN r.derived_rating IN (1, 2)  THEN 'Detractor'
            ELSE                                  'Unknown'
        END AS bucket

    FROM reviews r
    LEFT JOIN apps a ON r.app_name = a.app_name
    WHERE r.derived_rating IS NOT NULL
),

-- ──────────────────────────────────────────────────────────────────
-- PART 2: Overall NPS score across all apps
-- ──────────────────────────────────────────────────────────────────

overall AS (
    SELECT
        COUNT(*)                                                            AS total,
        SUM(CASE WHEN bucket = 'Promoter'  THEN 1 ELSE 0 END)              AS promoters,
        SUM(CASE WHEN bucket = 'Passive'   THEN 1 ELSE 0 END)              AS passives,
        SUM(CASE WHEN bucket = 'Detractor' THEN 1 ELSE 0 END)              AS detractors,
        ROUND(100.0 * SUM(CASE WHEN bucket = 'Promoter'  THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_p,
        ROUND(100.0 * SUM(CASE WHEN bucket = 'Detractor' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_d,
        ROUND(
            100.0 * SUM(CASE WHEN bucket = 'Promoter'  THEN 1 ELSE 0 END) / COUNT(*) -
            100.0 * SUM(CASE WHEN bucket = 'Detractor' THEN 1 ELSE 0 END) / COUNT(*)
        , 1) AS nps
    FROM bucketed
),

-- ──────────────────────────────────────────────────────────────────
-- PART 3: Per-app NPS
-- ──────────────────────────────────────────────────────────────────

app_nps AS (
    SELECT
        app_name,
        category,
        app_type,
        COUNT(*)                                                            AS reviews,
        ROUND(100.0 * SUM(CASE WHEN bucket = 'Promoter'  THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_promoters,
        ROUND(100.0 * SUM(CASE WHEN bucket = 'Passive'   THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_passives,
        ROUND(100.0 * SUM(CASE WHEN bucket = 'Detractor' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_detractors,
        ROUND(
            100.0 * SUM(CASE WHEN bucket = 'Promoter'  THEN 1 ELSE 0 END) / COUNT(*) -
            100.0 * SUM(CASE WHEN bucket = 'Detractor' THEN 1 ELSE 0 END) / COUNT(*)
        , 1) AS nps_score,
        ROUND(AVG(sentiment_polarity), 3) AS avg_polarity
    FROM bucketed
    GROUP BY app_name, category, app_type
    HAVING COUNT(*) >= 50
),

-- ──────────────────────────────────────────────────────────────────
-- PART 4: Monthly NPS trend with MoM delta
-- ──────────────────────────────────────────────────────────────────

monthly AS (
    SELECT
        STRFTIME('%Y-%m', review_date) AS month,
        COUNT(*) AS reviews,
        ROUND(
            100.0 * SUM(CASE WHEN bucket = 'Promoter'  THEN 1 ELSE 0 END) / COUNT(*) -
            100.0 * SUM(CASE WHEN bucket = 'Detractor' THEN 1 ELSE 0 END) / COUNT(*)
        , 1) AS nps_score
    FROM bucketed
    WHERE review_date IS NOT NULL
    GROUP BY STRFTIME('%Y-%m', review_date)
),

monthly_with_delta AS (
    SELECT
        month,
        reviews,
        nps_score,
        LAG(nps_score) OVER (ORDER BY month)                           AS prev_nps,
        ROUND(nps_score - LAG(nps_score) OVER (ORDER BY month), 1)    AS mom_delta
    FROM monthly
)

-- ──────────────────────────────────────────────────────────────────
-- FINAL OUTPUT: Pick the section you want to display
-- Comment/uncomment as needed.
-- ──────────────────────────────────────────────────────────────────

-- [A] Overall NPS
SELECT 'OVERALL NPS' AS section, * FROM overall;

-- [B] Top 10 apps
-- SELECT * FROM app_nps ORDER BY nps_score DESC  LIMIT 10;

-- [C] Bottom 10 apps
-- SELECT * FROM app_nps ORDER BY nps_score ASC   LIMIT 10;

-- [D] Monthly trend
-- SELECT * FROM monthly_with_delta ORDER BY month;

-- [E] Category ranking
-- SELECT category, COUNT(*) apps, ROUND(AVG(nps_score),1) avg_nps
-- FROM app_nps GROUP BY category ORDER BY avg_nps DESC;
