-- ============================================================
-- 02_nps_bucketing.sql
-- Core NPS-style sentiment bucketing logic
-- ============================================================
-- SKILLS: CASE WHEN, GROUP BY, aggregate functions, HAVING
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- STEP 1: Bucket every review into Promoter / Passive / Detractor
-- ────────────────────────────────────────────────────────────
-- This CTE is reused across all downstream queries.

WITH bucketed_reviews AS (
    SELECT
        review_id,
        app_name,
        derived_rating,
        review_date,
        sentiment_polarity,

        -- NPS-style classification using CASE WHEN
        CASE
            WHEN derived_rating = 5         THEN 'Promoter'
            WHEN derived_rating IN (3, 4)   THEN 'Passive'
            WHEN derived_rating IN (1, 2)   THEN 'Detractor'
            ELSE                                 'Unknown'
        END AS sentiment_bucket,

        -- Numeric encoding for easier aggregation later
        CASE
            WHEN derived_rating = 5         THEN  1
            WHEN derived_rating IN (3, 4)   THEN  0
            WHEN derived_rating IN (1, 2)   THEN -1
            ELSE                                   0
        END AS bucket_score

    FROM reviews
    WHERE derived_rating IS NOT NULL
),


-- ────────────────────────────────────────────────────────────
-- STEP 2: Aggregate NPS per app
-- ────────────────────────────────────────────────────────────

app_nps AS (
    SELECT
        app_name,
        COUNT(*)                                                        AS total_reviews,

        -- Count by bucket
        SUM(CASE WHEN sentiment_bucket = 'Promoter'  THEN 1 ELSE 0 END) AS promoter_count,
        SUM(CASE WHEN sentiment_bucket = 'Passive'   THEN 1 ELSE 0 END) AS passive_count,
        SUM(CASE WHEN sentiment_bucket = 'Detractor' THEN 1 ELSE 0 END) AS detractor_count,

        -- Percentage of each bucket  (multiply by 100.0 to avoid integer division)
        ROUND(100.0 * SUM(CASE WHEN sentiment_bucket = 'Promoter'  THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_promoters,
        ROUND(100.0 * SUM(CASE WHEN sentiment_bucket = 'Passive'   THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_passives,
        ROUND(100.0 * SUM(CASE WHEN sentiment_bucket = 'Detractor' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_detractors,

        -- NPS = % Promoters − % Detractors
        ROUND(
            100.0 * SUM(CASE WHEN sentiment_bucket = 'Promoter'  THEN 1 ELSE 0 END) / COUNT(*) -
            100.0 * SUM(CASE WHEN sentiment_bucket = 'Detractor' THEN 1 ELSE 0 END) / COUNT(*)
        , 1) AS nps_score,

        -- Average polarity as a secondary signal
        ROUND(AVG(sentiment_polarity), 3) AS avg_polarity

    FROM bucketed_reviews
    GROUP BY app_name
    HAVING COUNT(*) >= 50   -- filter out apps with too few reviews to be meaningful
)


-- ────────────────────────────────────────────────────────────
-- STEP 3: Final output — ranked by NPS score
-- ────────────────────────────────────────────────────────────

SELECT
    app_name,
    total_reviews,
    promoter_count,
    passive_count,
    detractor_count,
    pct_promoters   || '%'  AS pct_promoters,
    pct_passives    || '%'  AS pct_passives,
    pct_detractors  || '%'  AS pct_detractors,
    nps_score,
    avg_polarity,

    -- Human-readable NPS tier
    CASE
        WHEN nps_score >= 50    THEN '🌟 Excellent'
        WHEN nps_score >= 20    THEN '✅ Good'
        WHEN nps_score >= 0     THEN '⚠️  Needs Work'
        ELSE                         '🚨 Critical'
    END AS nps_tier

FROM app_nps
ORDER BY nps_score DESC;


-- ────────────────────────────────────────────────────────────
-- BONUS: Overall dataset NPS (single number)
-- ────────────────────────────────────────────────────────────

SELECT
    COUNT(*)                                                            AS total_reviews,
    ROUND(100.0 * SUM(CASE WHEN derived_rating = 5         THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_promoters,
    ROUND(100.0 * SUM(CASE WHEN derived_rating IN (3,4)    THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_passives,
    ROUND(100.0 * SUM(CASE WHEN derived_rating IN (1,2)    THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_detractors,
    ROUND(
        100.0 * SUM(CASE WHEN derived_rating = 5        THEN 1 ELSE 0 END) / COUNT(*) -
        100.0 * SUM(CASE WHEN derived_rating IN (1,2)   THEN 1 ELSE 0 END) / COUNT(*)
    , 1) AS overall_nps
FROM reviews
WHERE derived_rating IS NOT NULL;
