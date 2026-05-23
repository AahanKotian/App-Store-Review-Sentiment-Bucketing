-- ============================================================
-- 04_app_rankings.sql
-- Top & bottom apps by NPS — with category breakdown
-- ============================================================
-- SKILLS: Subqueries, RANK(), JOIN, HAVING, ORDER BY
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- QUERY 1: Top 20 apps by NPS (minimum 100 reviews)
-- ────────────────────────────────────────────────────────────

WITH app_nps AS (
    SELECT
        r.app_name,
        a.category,
        a.installs,
        COUNT(*)                                                                AS total_reviews,
        ROUND(100.0 * SUM(CASE WHEN r.derived_rating = 5       THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_promoters,
        ROUND(100.0 * SUM(CASE WHEN r.derived_rating IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_detractors,
        ROUND(
            100.0 * SUM(CASE WHEN r.derived_rating = 5       THEN 1 ELSE 0 END) / COUNT(*) -
            100.0 * SUM(CASE WHEN r.derived_rating IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*)
        , 1) AS nps_score
    FROM reviews r
    JOIN apps    a ON r.app_name = a.app_name
    WHERE r.derived_rating IS NOT NULL
    GROUP BY r.app_name, a.category, a.installs
    HAVING COUNT(*) >= 100
)

SELECT
    RANK() OVER (ORDER BY nps_score DESC) AS rank,
    app_name,
    category,
    installs,
    total_reviews,
    pct_promoters   || '%' AS pct_promoters,
    pct_detractors  || '%' AS pct_detractors,
    nps_score
FROM app_nps
ORDER BY nps_score DESC
LIMIT 20;


-- ────────────────────────────────────────────────────────────
-- QUERY 2: Bottom 20 apps by NPS (most at-risk)
-- ────────────────────────────────────────────────────────────

WITH app_nps AS (
    SELECT
        r.app_name,
        a.category,
        COUNT(*)                                                                AS total_reviews,
        ROUND(
            100.0 * SUM(CASE WHEN r.derived_rating = 5       THEN 1 ELSE 0 END) / COUNT(*) -
            100.0 * SUM(CASE WHEN r.derived_rating IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*)
        , 1) AS nps_score,
        ROUND(AVG(r.sentiment_polarity), 3) AS avg_polarity
    FROM reviews r
    JOIN apps    a ON r.app_name = a.app_name
    WHERE r.derived_rating IS NOT NULL
    GROUP BY r.app_name, a.category
    HAVING COUNT(*) >= 100
)

SELECT
    RANK() OVER (ORDER BY nps_score ASC) AS rank,
    app_name,
    category,
    total_reviews,
    nps_score,
    avg_polarity,
    '🚨 High Risk' AS alert
FROM app_nps
ORDER BY nps_score ASC
LIMIT 20;


-- ────────────────────────────────────────────────────────────
-- QUERY 3: NPS by category (which categories dominate?)
-- ────────────────────────────────────────────────────────────

SELECT
    a.category,
    COUNT(DISTINCT r.app_name)                                                  AS apps_in_category,
    COUNT(r.review_id)                                                          AS total_reviews,
    ROUND(AVG(r.derived_rating), 2)                                             AS avg_rating,
    ROUND(100.0 * SUM(CASE WHEN r.derived_rating = 5       THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_promoters,
    ROUND(100.0 * SUM(CASE WHEN r.derived_rating IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_detractors,
    ROUND(
        100.0 * SUM(CASE WHEN r.derived_rating = 5       THEN 1 ELSE 0 END) / COUNT(*) -
        100.0 * SUM(CASE WHEN r.derived_rating IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*)
    , 1) AS nps_score
FROM reviews r
JOIN apps    a ON r.app_name = a.app_name
WHERE r.derived_rating IS NOT NULL
  AND a.category       IS NOT NULL
GROUP BY a.category
HAVING COUNT(*) >= 200
ORDER BY nps_score DESC;


-- ────────────────────────────────────────────────────────────
-- QUERY 4: Free vs Paid NPS comparison
-- ────────────────────────────────────────────────────────────

SELECT
    a.type                                                                      AS app_type,
    COUNT(DISTINCT r.app_name)                                                  AS total_apps,
    COUNT(r.review_id)                                                          AS total_reviews,
    ROUND(
        100.0 * SUM(CASE WHEN r.derived_rating = 5       THEN 1 ELSE 0 END) / COUNT(*) -
        100.0 * SUM(CASE WHEN r.derived_rating IN (1, 2) THEN 1 ELSE 0 END) / COUNT(*)
    , 1) AS nps_score
FROM reviews r
JOIN apps    a ON r.app_name = a.app_name
WHERE r.derived_rating IS NOT NULL
  AND a.type IN ('Free', 'Paid')
GROUP BY a.type
ORDER BY nps_score DESC;
