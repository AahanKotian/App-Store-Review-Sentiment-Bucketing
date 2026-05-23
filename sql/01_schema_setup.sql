-- ============================================================
-- 01_schema_setup.sql
-- App Store Review Sentiment Bucketing
-- ============================================================
-- Compatible with: SQLite, PostgreSQL, MySQL, BigQuery*
-- *BigQuery notes inline where syntax differs
-- ============================================================

-- Drop tables if re-running setup
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS apps;

-- ============================================================
-- TABLE: apps
-- One row per app (metadata from googleplaystore.csv)
-- ============================================================
CREATE TABLE apps (
    app_name        TEXT        PRIMARY KEY,
    category        TEXT,
    rating          REAL,           -- overall avg rating (may differ from review-level)
    reviews_count   INTEGER,
    installs        TEXT,           -- e.g. "10,000+"
    type            TEXT,           -- Free / Paid
    price           TEXT,
    content_rating  TEXT,
    genres          TEXT,
    last_updated    DATE,
    current_version TEXT,
    android_ver     TEXT
);

-- ============================================================
-- TABLE: reviews
-- One row per user review (from googleplaystore_user_reviews.csv)
-- ============================================================
CREATE TABLE reviews (
    review_id           INTEGER     PRIMARY KEY,  -- synthetic key
    app_name            TEXT        NOT NULL,
    translated_review   TEXT,
    sentiment           TEXT,       -- original Kaggle label: Positive/Negative/Neutral
    sentiment_polarity  REAL,       -- −1.0 to +1.0
    sentiment_subjectivity REAL,    -- 0.0 to 1.0
    -- We derive star ratings from polarity bands for NPS bucketing:
    --   polarity >= 0.5          → 5 stars (Promoter)
    --   0.1 <= polarity < 0.5    → 4 stars (Passive)
    --   -0.1 <= polarity < 0.1   → 3 stars (Passive)
    --   -0.5 <= polarity < -0.1  → 2 stars (Detractor)
    --   polarity < -0.5          → 1 star  (Detractor)
    derived_rating      INTEGER     GENERATED ALWAYS AS (
        CASE
            WHEN sentiment_polarity >= 0.5              THEN 5
            WHEN sentiment_polarity >= 0.1              THEN 4
            WHEN sentiment_polarity >= -0.1             THEN 3
            WHEN sentiment_polarity >= -0.5             THEN 2
            ELSE                                             1
        END
    ) STORED,
    review_date         DATE,
    FOREIGN KEY (app_name) REFERENCES apps(app_name)
);

-- ============================================================
-- INDEXES for query performance
-- ============================================================
CREATE INDEX idx_reviews_app     ON reviews(app_name);
CREATE INDEX idx_reviews_date    ON reviews(review_date);
CREATE INDEX idx_reviews_rating  ON reviews(derived_rating);
CREATE INDEX idx_apps_category   ON apps(category);

-- ============================================================
-- LOAD DATA
-- If using SQLite CLI:
--   .mode csv
--   .import googleplaystore.csv apps
--   .import googleplaystore_user_reviews.csv reviews_raw
--
-- If using PostgreSQL:
--   COPY apps FROM '/path/to/googleplaystore.csv' CSV HEADER;
--   COPY reviews FROM '/path/to/googleplaystore_user_reviews.csv' CSV HEADER;
--
-- Sample data is in /data/sample_reviews.csv for quick testing.
-- ============================================================

-- Quick row-count sanity check after loading:
-- SELECT 'apps' AS tbl, COUNT(*) AS rows FROM apps
-- UNION ALL
-- SELECT 'reviews', COUNT(*) FROM reviews;
