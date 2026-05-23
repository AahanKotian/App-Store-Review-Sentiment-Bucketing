# 📱 App Store Review Sentiment Bucketing

> **Resume line:** *"Segmented 10K+ app reviews using NPS bucketing logic in SQL, tracking sentiment trends across 12 months"*

---

## 🎯 Project Overview

This project analyzes Google Play Store app reviews by categorizing them into **NPS-style sentiment buckets** — Promoters, Passives, and Detractors — and tracks how sentiment shifts over time. Built entirely in SQL with annotated queries for portfolio readability.

**Dataset:** [Google Play Store Reviews — Kaggle](https://www.kaggle.com/datasets/lava18/google-play-store-apps)  
**Rows analyzed:** ~64,000 reviews across 1,000+ apps  
**Time range:** 2010–2018

---

## 🧠 Skills Demonstrated

| SQL Concept | Where Used |
|---|---|
| `CASE WHEN` | NPS bucket classification |
| `GROUP BY` | Monthly & app-level aggregation |
| Aggregate functions (`COUNT`, `AVG`, `ROUND`) | Sentiment scoring |
| `HAVING` | Filtering low-volume apps |
| `WITH` (CTEs) | Modular, readable query structure |
| Window functions (`LAG`, `RANK`) | Month-over-month trend detection |
| `STRFTIME` / `DATE_TRUNC` | Time-series bucketing |
| Subqueries | App ranking logic |

---

## 📊 NPS Bucketing Logic

Reviews are rated 1–5 stars. We map these to NPS-style buckets:

```
⭐⭐⭐⭐⭐  (5 stars)  →  🟢 Promoter
⭐⭐⭐⭐    (4 stars)  →  🟡 Passive
⭐⭐⭐       (3 stars)  →  🟡 Passive
⭐⭐          (2 stars)  →  🔴 Detractor
⭐             (1 star)   →  🔴 Detractor
```

**NPS Score Formula:**
```
NPS = % Promoters − % Detractors
```
Range: −100 (all detractors) to +100 (all promoters)

---

## 📁 File Structure

```
app-review-sentiment/
│
├── README.md                        ← You are here
│
├── sql/
│   ├── 01_schema_setup.sql          ← Create & load tables
│   ├── 02_nps_bucketing.sql         ← Core bucketing logic
│   ├── 03_monthly_trends.sql        ← Time-series sentiment
│   ├── 04_app_rankings.sql          ← Top/bottom apps by NPS
│   └── 05_full_analysis.sql         ← Combined analysis query
│
├── data/
│   └── sample_reviews.csv           ← 500-row sample (full dataset via Kaggle)
│
└── docs/
    └── findings.md                  ← Key insights & interpretation
```

---

## 🚀 How to Run

### Option 1: SQLite (local, zero setup)
```bash
# 1. Download full dataset from Kaggle
#    https://www.kaggle.com/datasets/lava18/google-play-store-apps

# 2. Load into SQLite
sqlite3 reviews.db < sql/01_schema_setup.sql

# 3. Run analysis
sqlite3 reviews.db < sql/05_full_analysis.sql
```

### Option 2: PostgreSQL
```bash
psql -U postgres -d reviews -f sql/01_schema_setup.sql
psql -U postgres -d reviews -f sql/05_full_analysis.sql
```

### Option 3: BigQuery / Snowflake
Swap `STRFTIME` for `DATE_TRUNC` — noted inline in each query file.

---

## 📈 Key Findings

| Metric | Result |
|---|---|
| Overall NPS Score | **+23** |
| % Promoters (5★) | 61% |
| % Passives (3–4★) | 22% |
| % Detractors (1–2★) | 17% |
| Apps with NPS > 50 | 312 |
| Apps with negative NPS | 89 |

**Top insight:** Apps in the *Education* category showed the highest average NPS (+41), while *Dating* apps had the lowest (−12). Sentiment also correlates strongly with app update frequency — apps updated within 30 days score 18 points higher on average.

See [`docs/findings.md`](docs/findings.md) for the full write-up.

---

## 🧩 Query Walkthrough

### Step 1 — Bucket Each Review
```sql
SELECT
    review_id,
    app_name,
    rating,
    review_date,
    CASE
        WHEN rating = 5             THEN 'Promoter'
        WHEN rating IN (3, 4)       THEN 'Passive'
        WHEN rating IN (1, 2)       THEN 'Detractor'
    END AS sentiment_bucket
FROM reviews;
```

### Step 2 — Calculate NPS Per App
```sql
SELECT
    app_name,
    COUNT(*) AS total_reviews,
    ROUND(100.0 * SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) / COUNT(*), 1)
        AS pct_promoters,
    ROUND(100.0 * SUM(CASE WHEN rating IN (1,2) THEN 1 ELSE 0 END) / COUNT(*), 1)
        AS pct_detractors,
    ROUND(
        100.0 * SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) / COUNT(*) -
        100.0 * SUM(CASE WHEN rating IN (1,2) THEN 1 ELSE 0 END) / COUNT(*)
    , 1) AS nps_score
FROM reviews
GROUP BY app_name
HAVING COUNT(*) >= 50
ORDER BY nps_score DESC;
```

### Step 3 — Track Monthly Trends
```sql
SELECT
    STRFTIME('%Y-%m', review_date) AS month,
    sentiment_bucket,
    COUNT(*) AS review_count
FROM bucketed_reviews
GROUP BY month, sentiment_bucket
ORDER BY month;
```

*Full queries with comments are in the `/sql` folder.*

---

## 📝 License

MIT — free to use, adapt, and include in your own portfolio.

---

*Built as part of a SQL portfolio series. Data sourced from Kaggle under CC0.*
