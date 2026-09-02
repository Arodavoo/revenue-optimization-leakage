-- =========================================================
-- 03_REVENUE_ANALYSIS.SQL
-- Revenue Optimization & Leakage Detection
-- =========================================================

-- =========================================================
-- 1. MAIN REVENUE ANALYSIS TABLE
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.revenue_analysis;

CREATE TABLE revenue_analytics.revenue_analysis AS
SELECT
t.transaction_id,
t.transaction_date,
DATE_TRUNC('month', t.transaction_date)::DATE AS transaction_month,

```
t.customer_id,
c.customer_name,
c.customer_segment,
c.state AS customer_state,

t.product_id,
p.product_name,
p.product_category,

t.branch_id,
b.branch_name,
b.state AS branch_state,
b.region,

pay.payment_id,
pay.payment_status,
pay.payment_channel,
pay.payment_amount,

r.refund_id,
r.refund_amount,
r.refund_reason,
r.refund_status,

t.quantity,
t.transaction_status,

t.standard_price,
t.cost_price,
t.unit_price,
t.discount_pct,

t.expected_amount,
t.discount_amount,
t.expected_billed_amount,
t.billed_amount,

ROUND(
    t.expected_billed_amount - t.billed_amount,
    2
) AS potential_leakage,

CASE
    WHEN t.expected_billed_amount > 0
        THEN ROUND(
            (
                (t.expected_billed_amount - t.billed_amount)
                / t.expected_billed_amount
            ) * 100,
            4
        )
    ELSE 0
END AS leakage_rate_pct,

CASE
    WHEN t.transaction_status = 'Completed'
     AND t.expected_billed_amount > t.billed_amount
        THEN 1
    ELSE 0
END AS underbilled_flag
```

FROM revenue_analytics.transactions_clean t

LEFT JOIN revenue_analytics.customers_clean c
ON t.customer_id = c.customer_id

LEFT JOIN revenue_analytics.products_clean p
ON t.product_id = p.product_id

LEFT JOIN revenue_analytics.branches_clean b
ON t.branch_id = b.branch_id

LEFT JOIN revenue_analytics.payments_clean pay
ON t.transaction_id = pay.transaction_id

LEFT JOIN revenue_analytics.refunds_clean r
ON t.transaction_id = r.transaction_id;

ALTER TABLE revenue_analytics.revenue_analysis
ADD PRIMARY KEY (transaction_id);

-- =========================================================
-- 2. OVERALL REVENUE KPIs
-- =========================================================

SELECT
SUM(expected_billed_amount) AS expected_revenue,

```
SUM(billed_amount) AS actual_billed_revenue,

SUM(expected_billed_amount - billed_amount)
    AS potential_leakage,

ROUND(
    SUM(expected_billed_amount - billed_amount)
    / NULLIF(SUM(expected_billed_amount), 0) * 100,
    2
) AS leakage_rate_pct,

COUNT(*) FILTER (
    WHERE expected_billed_amount > billed_amount
) AS underbilled_transactions,

ROUND(
    AVG(expected_billed_amount - billed_amount)
    FILTER (
        WHERE expected_billed_amount > billed_amount
    ),
    2
) AS average_underbilling
```

FROM revenue_analytics.revenue_analysis
WHERE transaction_status = 'Completed';

-- =========================================================
-- 3. UNDERBILLED TRANSACTIONS
-- =========================================================

SELECT
transaction_id,
transaction_date,
customer_id,
customer_segment,
product_id,
product_name,
product_category,
branch_id,
branch_name,
payment_status,
expected_billed_amount,
billed_amount,
potential_leakage,
leakage_rate_pct

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed'
AND potential_leakage > 0

ORDER BY potential_leakage DESC;

-- =========================================================
-- 4. LEAKAGE BY CUSTOMER SEGMENT
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.leakage_by_customer_segment;

CREATE TABLE revenue_analytics.leakage_by_customer_segment AS
SELECT
customer_segment,

```
COUNT(*) AS transaction_count,

SUM(expected_billed_amount) AS expected_revenue,

SUM(billed_amount) AS actual_billed_revenue,

SUM(potential_leakage) AS potential_leakage,

COUNT(*) FILTER (
    WHERE potential_leakage > 0
) AS underbilled_transactions,

ROUND(
    AVG(potential_leakage)
    FILTER (
        WHERE potential_leakage > 0
    ),
    2
) AS average_underbilling,

ROUND(
    SUM(potential_leakage)
    / NULLIF(SUM(expected_billed_amount), 0) * 100,
    2
) AS leakage_rate_pct
```

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed'

GROUP BY customer_segment

ORDER BY potential_leakage DESC;

-- =========================================================
-- 5. LEAKAGE BY PRODUCT
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.leakage_by_product;

CREATE TABLE revenue_analytics.leakage_by_product AS
SELECT
product_id,
product_name,
product_category,

```
COUNT(*) AS transaction_count,

SUM(expected_billed_amount) AS expected_revenue,

SUM(billed_amount) AS actual_billed_revenue,

SUM(potential_leakage) AS potential_leakage,

COUNT(*) FILTER (
    WHERE potential_leakage > 0
) AS underbilled_transactions,

ROUND(
    AVG(potential_leakage)
    FILTER (
        WHERE potential_leakage > 0
    ),
    2
) AS average_underbilling,

ROUND(
    SUM(potential_leakage)
    / NULLIF(SUM(expected_billed_amount), 0) * 100,
    2
) AS leakage_rate_pct
```

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed'

GROUP BY
product_id,
product_name,
product_category

ORDER BY potential_leakage DESC;

-- =========================================================
-- 6. LEAKAGE BY PRODUCT CATEGORY
-- =========================================================

SELECT
product_category,

```
COUNT(*) AS transaction_count,

SUM(expected_billed_amount) AS expected_revenue,

SUM(billed_amount) AS actual_billed_revenue,

SUM(potential_leakage) AS potential_leakage,

COUNT(*) FILTER (
    WHERE potential_leakage > 0
) AS underbilled_transactions,

ROUND(
    SUM(potential_leakage)
    / NULLIF(SUM(expected_billed_amount), 0) * 100,
    2
) AS leakage_rate_pct
```

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed'

GROUP BY product_category

ORDER BY potential_leakage DESC;

-- =========================================================
-- 7. LEAKAGE BY BRANCH
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.branch_leakage_performance;

CREATE TABLE revenue_analytics.branch_leakage_performance AS
SELECT
branch_id,
branch_name,
branch_state AS state,
region,

```
COUNT(*) AS transaction_count,

SUM(expected_billed_amount) AS expected_revenue,

SUM(billed_amount) AS actual_billed_revenue,

SUM(potential_leakage) AS potential_leakage,

COUNT(*) FILTER (
    WHERE potential_leakage > 0
) AS underbilled_transactions,

ROUND(
    AVG(potential_leakage)
    FILTER (
        WHERE potential_leakage > 0
    ),
    2
) AS average_underbilling,

ROUND(
    SUM(potential_leakage)
    / NULLIF(SUM(expected_billed_amount), 0) * 100,
    2
) AS leakage_rate_pct
```

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed'

GROUP BY
branch_id,
branch_name,
branch_state,
region

ORDER BY potential_leakage DESC;

-- =========================================================
-- 8. LEAKAGE BY PAYMENT STATUS
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.leakage_by_payment_status;

CREATE TABLE revenue_analytics.leakage_by_payment_status AS
SELECT
payment_status,

```
COUNT(*) AS transaction_count,

SUM(expected_billed_amount) AS expected_revenue,

SUM(billed_amount) AS actual_billed_revenue,

SUM(potential_leakage) AS potential_leakage,

COUNT(*) FILTER (
    WHERE potential_leakage > 0
) AS underbilled_transactions,

ROUND(
    AVG(potential_leakage)
    FILTER (
        WHERE potential_leakage > 0
    ),
    2
) AS average_underbilling,

ROUND(
    SUM(potential_leakage)
    / NULLIF(SUM(expected_billed_amount), 0) * 100,
    2
) AS leakage_rate_pct
```

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed'

GROUP BY payment_status

ORDER BY potential_leakage DESC;

-- =========================================================
-- 9. LEAKAGE BY PAYMENT CHANNEL
-- =========================================================

SELECT
payment_channel,

```
COUNT(*) AS transaction_count,

SUM(expected_billed_amount) AS expected_revenue,

SUM(billed_amount) AS actual_billed_revenue,

SUM(potential_leakage) AS potential_leakage,

COUNT(*) FILTER (
    WHERE potential_leakage > 0
) AS underbilled_transactions,

ROUND(
    SUM(potential_leakage)
    / NULLIF(SUM(expected_billed_amount), 0) * 100,
    2
) AS leakage_rate_pct
```

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed'

GROUP BY payment_channel

ORDER BY potential_leakage DESC;

-- =========================================================
-- 10. LEAKAGE BY MONTH
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.leakage_by_month;

CREATE TABLE revenue_analytics.leakage_by_month AS
SELECT
transaction_month AS month,

```
COUNT(*) AS transaction_count,

SUM(expected_billed_amount) AS expected_revenue,

SUM(billed_amount) AS actual_billed_revenue,

SUM(potential_leakage) AS potential_leakage,

COUNT(*) FILTER (
    WHERE potential_leakage > 0
) AS underbilled_transactions,

ROUND(
    AVG(potential_leakage)
    FILTER (
        WHERE potential_leakage > 0
    ),
    2
) AS average_underbilling,

ROUND(
    SUM(potential_leakage)
    / NULLIF(SUM(expected_billed_amount), 0) * 100,
    2
) AS leakage_rate_pct
```

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed'

GROUP BY transaction_month

ORDER BY transaction_month;

-- =========================================================
-- 11. LEAKAGE SEVERITY
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.leakage_severity;

CREATE TABLE revenue_analytics.leakage_severity AS
SELECT
CASE
WHEN potential_leakage > 0
AND potential_leakage <= 10000
THEN 'Low'

```
    WHEN potential_leakage > 10000
     AND potential_leakage <= 25000
        THEN 'Medium'

    WHEN potential_leakage > 25000
     AND potential_leakage <= 50000
        THEN 'High'

    WHEN potential_leakage > 50000
        THEN 'Critical'

    ELSE 'No Leakage'
END AS leakage_severity,

COUNT(*) AS transaction_count,

SUM(potential_leakage) AS potential_leakage,

ROUND(
    AVG(potential_leakage)
    FILTER (
        WHERE potential_leakage > 0
    ),
    2
) AS average_underbilling
```

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed'

GROUP BY 1

ORDER BY
CASE
WHEN leakage_severity = 'No Leakage' THEN 1
WHEN leakage_severity = 'Low' THEN 2
WHEN leakage_severity = 'Medium' THEN 3
WHEN leakage_severity = 'High' THEN 4
WHEN leakage_severity = 'Critical' THEN 5
END;

-- =========================================================
-- 12. TOP LEAKAGE BRANCHES
-- =========================================================

SELECT
branch_id,
branch_name,
state,
region,
potential_leakage,
leakage_rate_pct,
underbilled_transactions,
average_underbilling

FROM revenue_analytics.branch_leakage_performance

ORDER BY potential_leakage DESC

LIMIT 10;

-- =========================================================
-- 13. TOP LEAKAGE PRODUCTS
-- =========================================================

SELECT
product_id,
product_name,
product_category,
potential_leakage,
leakage_rate_pct,
underbilled_transactions,
average_underbilling

FROM revenue_analytics.leakage_by_product

ORDER BY potential_leakage DESC

LIMIT 10;

-- =========================================================
-- 14. REFUND SUMMARY
-- Refunds are kept separate from the headline leakage KPI.
-- =========================================================

SELECT
refund_status,
COUNT(*) AS refund_count,
SUM(refund_amount) AS refund_amount

FROM revenue_analytics.refunds_clean

GROUP BY refund_status

ORDER BY refund_status;

SELECT
refund_reason,
COUNT(*) AS refund_count,
SUM(refund_amount) AS refund_amount

FROM revenue_analytics.refunds_clean

GROUP BY refund_reason

ORDER BY refund_amount DESC;

-- =========================================================
-- 15. REVENUE RECONCILIATION
-- =========================================================

SELECT
COUNT(*) AS completed_transactions,

```
ROUND(
    SUM(expected_billed_amount),
    2
) AS expected_revenue,

ROUND(
    SUM(billed_amount),
    2
) AS actual_billed_revenue,

ROUND(
    SUM(expected_billed_amount - billed_amount),
    2
) AS potential_leakage,

ROUND(
    SUM(expected_billed_amount - billed_amount)
    / NULLIF(SUM(expected_billed_amount), 0) * 100,
    2
) AS leakage_rate_pct,

COUNT(*) FILTER (
    WHERE potential_leakage > 0
) AS underbilled_transactions,

ROUND(
    AVG(potential_leakage)
    FILTER (
        WHERE potential_leakage > 0
    ),
    2
) AS average_underbilling
```

FROM revenue_analytics.revenue_analysis

WHERE transaction_status = 'Completed';
