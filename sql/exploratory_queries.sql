-- Bank Customer Churn: Survival Analysis
-- Exploratory SQL Queries
-- Database: bank_churn.db | Table: "Customer-Churn-Records"

-- ============================================================
-- 1. Churn rate by tenure (year-by-year, no bucketing needed
--    since Tenure only ranges 0-10 with 11 unique values)
-- ============================================================
SELECT 
    "Tenure" AS tenure_years,
    COUNT(*) AS total_customers,
    SUM("Exited") AS churned_customers,
    ROUND(100.0 * SUM("Exited") / COUNT(*), 2) AS churn_rate_pct
FROM "Customer-Churn-Records"
GROUP BY "Tenure"
ORDER BY "Tenure";

-- Finding: churn rate stays flat (~17-23%) across all tenure years.
-- Tenure alone is NOT a strong predictor of churn.


-- ============================================================
-- 2. Customer risk segmentation using NTILE() window function
--    Splits customers into 4 quartiles based on tenure, then
--    checks churn/complaint/activity rate per quartile
-- ============================================================
SELECT 
    tenure_risk_quartile,
    COUNT(*) AS total_customers,
    SUM("Exited") AS churned,
    ROUND(100.0 * SUM("Exited") / COUNT(*), 2) AS churn_rate_pct,
    ROUND(100.0 * SUM("Complain") / COUNT(*), 2) AS complain_rate_pct,
    ROUND(AVG("IsActiveMember") * 100, 2) AS active_member_pct
FROM (
    SELECT 
        "Tenure", "Complain", "IsActiveMember", "Exited",
        NTILE(4) OVER (ORDER BY "Tenure" ASC) AS tenure_risk_quartile
    FROM "Customer-Churn-Records"
)
GROUP BY tenure_risk_quartile
ORDER BY tenure_risk_quartile;

-- Finding: churn rate is near-identical across all 4 quartiles,
-- confirming tenure alone doesn't segment risk well.


-- ============================================================
-- 3. Churn rate by Geography
-- ============================================================
SELECT 
    "Geography",
    COUNT(*) AS total_customers,
    SUM("Exited") AS churned,
    ROUND(100.0 * SUM("Exited") / COUNT(*), 2) AS churn_rate_pct
FROM "Customer-Churn-Records"
GROUP BY "Geography"
ORDER BY churn_rate_pct DESC;

-- Finding: Germany churn rate (32.44%) is nearly 2x France/Spain (~16%).
-- This became one of the two headline insights, later confirmed by
-- Kaplan-Meier curves and the Cox model.


-- ============================================================
-- 4. Churn rate by NumOfProducts
-- ============================================================
SELECT 
    "NumOfProducts",
    COUNT(*) AS total_customers,
    SUM("Exited") AS churned,
    ROUND(100.0 * SUM("Exited") / COUNT(*), 2) AS churn_rate_pct
FROM "Customer-Churn-Records"
GROUP BY "NumOfProducts"
ORDER BY "NumOfProducts";

-- Finding: non-monotonic (U-shaped) pattern.
-- 1 product: 27.71% | 2 products: 7.6% (lowest) | 3 products: 82.71% | 4 products: 100%
-- Note: NumOfProducts 3 and 4 have small sample sizes (266 and 60 customers),
-- so these extreme rates should be treated with caution.
-- This U-shape is why NumOfProducts was modeled as categorical (not continuous)
-- in the Cox Proportional Hazards model.


-- ============================================================
-- 5. Data leakage check: Complain vs Exited
-- ============================================================
SELECT "Exited", "Complain", COUNT(*) 
FROM "Customer-Churn-Records"
GROUP BY "Exited", "Complain";

-- Finding: 99.5%+ overlap between Complain=1 and Exited=1.
-- This indicates Complain is very likely recorded as part of the
-- exit process itself, not an independent early-warning signal.
-- DECISION: Complain excluded from the Cox model due to data leakage.


-- ============================================================
-- 6. Sanity check: Tenure range
-- ============================================================
SELECT MIN("Tenure"), MAX("Tenure"), COUNT(DISTINCT "Tenure") 
FROM "Customer-Churn-Records";

-- Result: 0, 10, 11 (Tenure measured in years, range 0-10 inclusive)