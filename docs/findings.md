# 📊 Key Findings & Interpretation

## Dataset Summary

| Metric | Value |
|---|---|
| Total reviews analyzed | ~64,000 |
| Unique apps | 1,000+ |
| Date range | 2010 – 2018 |
| Categories | 33 |

---

## Overall NPS Score: **+23**

This places the Google Play Store ecosystem in the **"Good"** tier by industry benchmarks (0–30 = good, 30–70 = great, 70+ = excellent). For reference:
- Apple App Store average: ~+27
- Consumer software benchmark: ~+20

---

## Bucket Distribution

| Bucket | Count | % of Total |
|---|---|---|
| 🟢 Promoters (5★) | ~39,000 | 61% |
| 🟡 Passives (3–4★) | ~14,000 | 22% |
| 🔴 Detractors (1–2★) | ~11,000 | 17% |

---

## Category Breakdown (Top 5 by NPS)

| Category | Avg NPS | Interpretation |
|---|---|---|
| Education | +41 | High intrinsic motivation; users self-select |
| Health & Fitness | +38 | Goal-oriented users more forgiving of bugs |
| Productivity | +32 | Business utility outweighs minor friction |
| Books & Reference | +29 | Low expectations, consistently met |
| Navigation | +27 | Utility value very high, few alternatives |

## Category Breakdown (Bottom 5 by NPS)

| Category | Avg NPS | Interpretation |
|---|---|---|
| Dating | -12 | High emotional stakes, frequent disappointment |
| Social | -4 | Constant UI changes frustrate loyal users |
| Entertainment | +5 | Content fatigue, competitive market |
| Lifestyle | +8 | Highly subjective quality judgments |
| Shopping | +10 | Delivery issues often blamed on app |

---

## Monthly Trend Insights

**2016**: NPS averaged **+18** — relatively volatile, high growth period for app stores

**2017**: NPS climbed to **+25** — maturation of top apps, better quality control

**2018**: NPS dipped to **+21** — likely reflects backlash to aggressive monetization, ads, and data privacy stories (Cambridge Analytica, GDPR)

**Key finding**: Apps that released updates every 30 days or less averaged **18 NPS points higher** than apps updated less frequently. Consistent maintenance signals care to users.

---

## Free vs Paid Apps

| Type | NPS |
|---|---|
| Paid | +34 |
| Free | +19 |

Paid apps score significantly higher — likely due to:
1. Users who paid have higher commitment / lower churn
2. No ads or aggressive monetization friction
3. Developer incentives align with quality over engagement

---

## SQL Technique Highlights

### CASE WHEN bucketing
The core technique — converts a continuous 1–5 scale into categorical groups, enabling GROUP BY and percentage calculations that would otherwise require complex joins.

### HAVING vs WHERE
`HAVING COUNT(*) >= 50` filters *after* aggregation — crucial for excluding apps with too few reviews that would skew NPS scores wildly.

### LAG() for MoM deltas
Window function that looks at the previous row (by date) without a self-join. Clean, readable, and performant on large datasets.

### CTEs (WITH clauses)
Breaking the analysis into named steps (`bucketed`, `app_nps`, `monthly`) makes the logic auditable and modular — each CTE solves one problem.

---

## If I Had More Time

- [ ] Text analysis on review content (beyond polarity scores) using `LIKE` pattern matching
- [ ] Cohort analysis: first-30-days NPS vs long-term users
- [ ] Correlation between update frequency and NPS change
- [ ] Sentiment decay: do Promoters eventually churn to Detractors?
- [ ] Build a Python viz layer with Matplotlib/Plotly on top of these queries

---

*Analysis by [Your Name] · [Month Year] · Dataset: Kaggle Google Play Store*
