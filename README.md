# Bank Customer Churn: Survival Analysis (Kaplan-Meier & Cox Proportional Hazards)

## Project Overview

| | |
|---|---|
| **Objective** | Identify which customer characteristics accelerate or delay churn, and quantify *how much* they matter |
| **Dataset** | [Bank Customer Churn Prediction](https://www.kaggle.com/datasets/radheshyamkollipara/bank-customer-churn) — 10,000 customers, 18 features |
| **Tools** | SQL (SQLite) for exploratory analysis, Python (`lifelines`) for survival modeling |
| **Techniques** | Kaplan-Meier estimation, Cox Proportional Hazards regression |
| **Key metric** | Concordance Index = 0.77 |

## Why This Project

Most churn analysis portfolios frame the problem as binary classification: will a customer churn, yes or no. This throws away a critical piece of information — *when* they churn. A customer who leaves after 2 months and one who leaves after 8 years are treated identically in that framing, even though they represent very different business problems.

This project uses **survival analysis** instead, which models *time-to-event* directly. It answers two questions standard classification can't:
1. What does the retention curve actually look like over time?
2. Which variables speed up or slow down churn, and by how much — controlling for all other variables at once?

SQL window functions and cohort-style segmentation were used for exploratory analysis, while Python handled the statistical modeling — deliberately splitting the work this way to demonstrate both skill sets rather than routing everything through one tool.

## Dataset

Source: Kaggle, "Bank Customer Churn Prediction" (includes a `Complain` field not present in the original/classic version of this dataset).

| Column | Description |
|---|---|
| CustomerId | Unique customer identifier |
| CreditScore | Customer's credit score |
| Geography | Country (France, Germany, Spain) |
| Gender | Male/Female |
| Age | Customer age |
| Tenure | Years as a bank customer (0–10) |
| Balance | Account balance |
| NumOfProducts | Number of bank products held (1–4) |
| HasCrCard | Whether customer holds a credit card (0/1) |
| IsActiveMember | Whether customer is an active member (0/1) |
| EstimatedSalary | Estimated annual salary |
| Exited | Churn indicator (0/1) — event of interest |
| Complain | Whether customer has an on-record complaint (0/1) — **excluded, see Known Limitations** |
| Satisfaction Score, Card Type, Point Earned | Excluded — see Known Limitations |

**Note on data structure:** this dataset is a cross-sectional snapshot (one row per customer at a single point in time), not a longitudinal panel. `Tenure` is treated as the survival time axis, and `Exited` as the event indicator — a standard and valid approach for this data structure, though it means cohort tracking across calendar time (e.g. "customers who joined in Jan 2023") isn't possible with these fields.

## Methodology

### 1. SQL Exploratory Analysis
- Per-tenure churn rate breakdown
- Customer risk segmentation using `NTILE()` window function (quartiles by tenure)
- Churn rate by Geography and by NumOfProducts
- Cross-tabulation of `Complain` vs `Exited` to test for data leakage

### 2. Kaplan-Meier Estimation (Python, `lifelines`)
- Overall survival curve
- Stratified by Geography
- Stratified by NumOfProducts

### 3. Cox Proportional Hazards Regression
- All variables modeled jointly to isolate independent effects
- Categorical variables (Geography, Gender, NumOfProducts) one-hot encoded
- `NumOfProducts` treated as categorical rather than continuous, since exploratory analysis showed a non-monotonic (U-shaped) relationship with churn risk

## Key Insights

### 1. Customers with 2 products are the most retained segment by a wide margin
Hazard ratio = 0.30 (95% CI: 0.26–0.33) relative to customers with 1 product — a ~70% reduction in churn risk. This is the single strongest, most statistically robust effect in the model (large sample size, tight confidence interval, p < 0.005).

### 2. Germany shows substantially higher churn risk than France or Spain
Hazard ratio = 1.78 (95% CI: 1.60–1.98) relative to France. This pattern held consistently across three independent methods: raw SQL churn rate (32.4% vs ~16%), the Kaplan-Meier curve (visibly steeper decline), and the Cox model (statistically significant after controlling for all other variables). Spain, by contrast, showed no statistically significant difference from France (p = 0.13) — the apparent 10% higher risk in raw numbers cannot be distinguished from random noise at this sample size.

### 3. Active membership and product count matter more than demographics or finances
`IsActiveMember` (HR = 0.52) and `NumOfProducts` show far larger, more significant effects than `CreditScore`, `Balance`, or `EstimatedSalary` — none of which were statistically distinguishable from zero effect (p > 0.05 for all three). Tenure alone, examined independently, also showed no clear predictive pattern (churn rate stayed flat between 17–23% across all tenure years) — it only became useful in combination with other variables through the survival modeling approach.

## Known Limitations

- **`Complain` excluded due to near-perfect data leakage.** Cross-tabulation showed 99.5%+ overlap between `Complain=1` and `Exited=1`, indicating this field is likely recorded as part of the exit process itself rather than as an independent early-warning signal. Including it would have produced an artificially strong but circular result. `Satisfaction Score`, `Card Type`, and `Point Earned` were excluded on the same precautionary basis, as they appear related to the same post-complaint process.
- **NumOfProducts = 3 and 4 categories have small sample sizes** (266 and 60 customers respectively, vs. ~5,000 each for 1–2 products). While the Cox model found these statistically significant, the wider confidence intervals mean these estimates should be treated as directional rather than precise.
- **Cross-sectional data structure.** Because this is a snapshot rather than a longitudinal panel, calendar-based cohort analysis (e.g., "customers who joined in a specific month") was not possible. Tenure was used as the time axis instead, which is methodologically valid for survival analysis but answers a slightly different question than a true monthly cohort retention table would.
- **No causal claims.** All findings describe statistical association, not causation. For example, the Germany effect is reported as an observed pattern, not attributed to any specific cause (e.g., competition, product fit) without further data to support that.

## Repository Structure

```
bank-churn-survival-analysis/
├── README.md
├── data/
│   ├── Customer-Churn-Records.csv     # raw dataset
│   └── bank_churn.db                   # SQLite database
├── sql/
│   └── exploratory_queries.sql         # all SQL queries used
├── python/
│   └── survival_analysis.py            # KM + Cox modeling
└── visuals/
    ├── km_overall.png
    ├── km_by_geography.png
    ├── km_by_numproducts.png
    └── cox_forest_plot.png
```

## How to Reproduce

1. Load `Customer-Churn-Records.csv` into SQLite (see `sql/exploratory_queries.sql` for table setup and exploratory queries)
2. Install dependencies: `pip install lifelines pandas matplotlib`
3. Run `python/survival_analysis.py` to reproduce the Kaplan-Meier curves and Cox model

## About

**Jessica Leo**
Junior Data Analyst | Information Systems Student
[LinkedIn](https://www.linkedin.com/in/jessicaleooo)
