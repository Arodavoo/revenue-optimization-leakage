```sql
-- =========================================================
-- 02_DATA_VALIDATION
-- Revenue Optimization & Leakage Detection
-- =========================================================

-- =========================================================
-- 1. ROW COUNTS
-- =========================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM revenue_analytics.customers_clean

UNION ALL

SELECT 'transactions', COUNT(*)
FROM revenue_analytics.transactions_clean

UNION ALL

SELECT 'products', COUNT(*)
FROM revenue_analytics.products_clean

UNION ALL

SELECT 'payments', COUNT(*)
FROM revenue_analytics.payments_clean

UNION ALL

SELECT 'refunds', COUNT(*)
FROM revenue_analytics.refunds_clean

UNION ALL

SELECT 'branches', COUNT(*)
FROM revenue_analytics.branches_clean;


-- =========================================================
-- 2. DUPLICATE PRIMARY KEYS
-- =========================================================

SELECT customer_id, COUNT(*)
FROM revenue_analytics.customers_clean
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT transaction_id, COUNT(*)
FROM revenue_analytics.transactions_clean
GROUP BY transaction_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*)
FROM revenue_analytics.products_clean
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT payment_id, COUNT(*)
FROM revenue_analytics.payments_clean
GROUP BY payment_id
HAVING COUNT(*) > 1;

SELECT refund_id, COUNT(*)
FROM revenue_analytics.refunds_clean
GROUP BY refund_id
HAVING COUNT(*) > 1;

SELECT branch_id, COUNT(*)
FROM revenue_analytics.branches_clean
GROUP BY branch_id
HAVING COUNT(*) > 1;


-- =========================================================
-- 3. MISSING REQUIRED VALUES
-- =========================================================

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_name IS NULL) AS missing_customer_name,
    COUNT(*) FILTER (WHERE customer_segment IS NULL) AS missing_customer_segment,
    COUNT(*) FILTER (WHERE state IS NULL) AS missing_state,
    COUNT(*) FILTER (WHERE registration_date IS NULL) AS missing_registration_date
FROM revenue_analytics.customers_clean;


SELECT
    COUNT(*) FILTER (WHERE transaction_id IS NULL) AS missing_transaction_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE branch_id IS NULL) AS missing_branch_id,
    COUNT(*) FILTER (WHERE transaction_date IS NULL) AS missing_transaction_date,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS missing_quantity,
    COUNT(*) FILTER (WHERE transaction_status IS NULL) AS missing_status,
    COUNT(*) FILTER (WHERE standard_price IS NULL) AS missing_standard_price,
    COUNT(*) FILTER (WHERE cost_price IS NULL) AS missing_cost_price,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS missing_unit_price,
    COUNT(*) FILTER (WHERE discount_pct IS NULL) AS missing_discount_pct,
    COUNT(*) FILTER (WHERE expected_amount IS NULL) AS missing_expected_amount,
    COUNT(*) FILTER (WHERE discount_amount IS NULL) AS missing_discount_amount,
    COUNT(*) FILTER (WHERE expected_billed_amount IS NULL) AS missing_expected_billed,
    COUNT(*) FILTER (WHERE billed_amount IS NULL) AS missing_billed_amount
FROM revenue_analytics.transactions_clean;


SELECT
    COUNT(*) FILTER (WHERE payment_channel IS NULL) AS missing_payment_channel,
    COUNT(*) FILTER (WHERE payment_status IS NULL) AS missing_payment_status,
    COUNT(*) FILTER (WHERE payment_date IS NULL) AS missing_payment_date,
    COUNT(*) FILTER (WHERE payment_amount IS NULL) AS missing_payment_amount
FROM revenue_analytics.payments_clean;


SELECT
    COUNT(*) FILTER (WHERE refund_date IS NULL) AS missing_refund_date,
    COUNT(*) FILTER (WHERE refund_amount IS NULL) AS missing_refund_amount,
    COUNT(*) FILTER (WHERE refund_reason IS NULL) AS missing_refund_reason,
    COUNT(*) FILTER (WHERE refund_status IS NULL) AS missing_refund_status
FROM revenue_analytics.refunds_clean;


-- =========================================================
-- 4. FOREIGN KEY CHECKS
-- =========================================================

SELECT t.customer_id
FROM revenue_analytics.transactions_clean t
LEFT JOIN revenue_analytics.customers_clean c
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


SELECT t.product_id
FROM revenue_analytics.transactions_clean t
LEFT JOIN revenue_analytics.products_clean p
    ON t.product_id = p.product_id
WHERE p.product_id IS NULL;


SELECT t.branch_id
FROM revenue_analytics.transactions_clean t
LEFT JOIN revenue_analytics.branches_clean b
    ON t.branch_id = b.branch_id
WHERE b.branch_id IS NULL;


SELECT p.transaction_id
FROM revenue_analytics.payments_clean p
LEFT JOIN revenue_analytics.transactions_clean t
    ON p.transaction_id = t.transaction_id
WHERE t.transaction_id IS NULL;


SELECT r.transaction_id
FROM revenue_analytics.refunds_clean r
LEFT JOIN revenue_analytics.transactions_clean t
    ON r.transaction_id = t.transaction_id
WHERE t.transaction_id IS NULL;


-- =========================================================
-- 5. VALID CATEGORIES AND STATUSES
-- =========================================================

SELECT DISTINCT customer_segment
FROM revenue_analytics.customers_clean
WHERE customer_segment NOT IN ('Retail', 'SME', 'Corporate')
   OR customer_segment IS NULL;


SELECT DISTINCT product_category
FROM revenue_analytics.products_clean
WHERE product_category NOT IN
      ('Loans', 'Account Services', 'Transfers', 'Payments', 'Cards')
   OR product_category IS NULL;


SELECT DISTINCT transaction_status
FROM revenue_analytics.transactions_clean
WHERE transaction_status NOT IN ('Completed', 'Cancelled')
   OR transaction_status IS NULL;


SELECT DISTINCT payment_status
FROM revenue_analytics.payments_clean
WHERE payment_status NOT IN ('Successful', 'Failed', 'Pending')
   OR payment_status IS NULL;


SELECT DISTINCT payment_channel
FROM revenue_analytics.payments_clean
WHERE payment_channel IS NOT NULL
  AND payment_channel NOT IN
      ('USSD', 'Card', 'Cash', 'Online', 'Transfer');


SELECT DISTINCT refund_reason
FROM revenue_analytics.refunds_clean
WHERE refund_reason NOT IN
      ('Customer Request',
       'Duplicate Charge',
       'Incorrect Charge',
       'Service Issue')
   OR refund_reason IS NULL;


SELECT DISTINCT refund_status
FROM revenue_analytics.refunds_clean
WHERE refund_status NOT IN ('Approved', 'Rejected')
   OR refund_status IS NULL;


-- =========================================================
-- 6. DATE VALIDATION
-- =========================================================

SELECT
    MIN(transaction_date) AS first_transaction_date,
    MAX(transaction_date) AS last_transaction_date,
    COUNT(*) FILTER (
        WHERE transaction_date < DATE '2025-01-01'
           OR transaction_date > DATE '2025-12-31'
    ) AS outside_2025
FROM revenue_analytics.transactions_clean;


SELECT
    MIN(payment_date) AS first_payment_date,
    MAX(payment_date) AS last_payment_date,
    COUNT(*) FILTER (
        WHERE payment_date < DATE '2025-01-01'
           OR payment_date > DATE '2025-12-31'
    ) AS outside_2025
FROM revenue_analytics.payments_clean;


SELECT
    MIN(refund_date) AS first_refund_date,
    MAX(refund_date) AS last_refund_date,
    COUNT(*) FILTER (
        WHERE refund_date < DATE '2025-01-01'
           OR refund_date > DATE '2025-12-31'
    ) AS outside_2025
FROM revenue_analytics.refunds_clean;


SELECT
    MIN(registration_date) AS first_registration_date,
    MAX(registration_date) AS last_registration_date
FROM revenue_analytics.customers_clean;


-- Payment dates should match transaction dates

SELECT COUNT(*) AS payment_date_mismatches
FROM revenue_analytics.payments_clean p
JOIN revenue_analytics.transactions_clean t
    ON p.transaction_id = t.transaction_id
WHERE p.payment_date <> t.transaction_date;


-- Refund dates should match transaction dates

SELECT COUNT(*) AS refund_date_mismatches
FROM revenue_analytics.refunds_clean r
JOIN revenue_analytics.transactions_clean t
    ON r.transaction_id = t.transaction_id
WHERE r.refund_date <> t.transaction_date;


-- =========================================================
-- 7. NUMERIC VALIDATION
-- =========================================================

SELECT COUNT(*) AS invalid_quantity
FROM revenue_analytics.transactions_clean
WHERE quantity IS NULL
   OR quantity <= 0;


SELECT COUNT(*) AS invalid_discount
FROM revenue_analytics.transactions_clean
WHERE discount_pct IS NULL
   OR discount_pct < 0
   OR discount_pct > 1;


SELECT COUNT(*) AS invalid_prices
FROM revenue_analytics.transactions_clean
WHERE standard_price <= 0
   OR cost_price <= 0
   OR unit_price <= 0;


SELECT COUNT(*) AS cost_above_standard
FROM revenue_analytics.transactions_clean
WHERE cost_price > standard_price;


SELECT COUNT(*) AS negative_amounts
FROM revenue_analytics.transactions_clean
WHERE expected_amount < 0
   OR discount_amount < 0
   OR expected_billed_amount < 0
   OR billed_amount < 0;


-- =========================================================
-- 8. TRANSACTION CALCULATION CHECKS
-- =========================================================

SELECT COUNT(*) AS expected_amount_errors
FROM revenue_analytics.transactions_clean
WHERE ROUND(expected_amount, 2)
      <> ROUND(standard_price * quantity, 2);


SELECT COUNT(*) AS discount_amount_errors
FROM revenue_analytics.transactions_clean
WHERE ROUND(discount_amount, 2)
      <> ROUND(expected_amount * discount_pct, 2);


SELECT COUNT(*) AS expected_billed_errors
FROM revenue_analytics.transactions_clean
WHERE ROUND(expected_billed_amount, 2)
      <> ROUND(expected_amount - discount_amount, 2);


SELECT COUNT(*) AS unit_price_errors
FROM revenue_analytics.transactions_clean
WHERE ROUND(unit_price, 2)
      <> ROUND(standard_price, 2);


-- Billed amount should not exceed expected billed amount

SELECT COUNT(*) AS overbilled_transactions
FROM revenue_analytics.transactions_clean
WHERE billed_amount > expected_billed_amount;


-- =========================================================
-- 9. PAYMENT CHECKS
-- =========================================================

SELECT COUNT(*) AS invalid_payment_amount
FROM revenue_analytics.payments_clean
WHERE payment_amount < 0;


-- Successful payments match billed transaction amounts

SELECT COUNT(*) AS successful_payment_mismatches
FROM revenue_analytics.payments_clean p
JOIN revenue_analytics.transactions_clean t
    ON p.transaction_id = t.transaction_id
WHERE p.payment_status = 'Successful'
  AND ROUND(p.payment_amount, 2)
      <> ROUND(t.billed_amount, 2);


-- Failed payments should have zero payment amount

SELECT COUNT(*) AS failed_payment_amount_errors
FROM revenue_analytics.payments_clean
WHERE payment_status = 'Failed'
  AND payment_amount <> 0;


-- =========================================================
-- 10. REFUND CHECKS
-- =========================================================

SELECT COUNT(*) AS invalid_refund_amount
FROM revenue_analytics.refunds_clean
WHERE refund_amount <= 0;


SELECT COUNT(*) AS refund_above_billed_amount
FROM revenue_analytics.refunds_clean r
JOIN revenue_analytics.transactions_clean t
    ON r.transaction_id = t.transaction_id
WHERE r.refund_amount > t.billed_amount;


-- A transaction has at most one refund

SELECT transaction_id, COUNT(*) AS refund_count
FROM revenue_analytics.refunds_clean
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- =========================================================
-- 11. CROSS-TABLE COVERAGE
-- =========================================================

SELECT
    COUNT(*) AS transactions,
    COUNT(c.customer_id) AS matched_customers,
    COUNT(p.product_id) AS matched_products,
    COUNT(b.branch_id) AS matched_branches,
    COUNT(pay.transaction_id) AS matched_payments
FROM revenue_analytics.transactions_clean t
LEFT JOIN revenue_analytics.customers_clean c
    ON t.customer_id = c.customer_id
LEFT JOIN revenue_analytics.products_clean p
    ON t.product_id = p.product_id
LEFT JOIN revenue_analytics.branches_clean b
    ON t.branch_id = b.branch_id
LEFT JOIN revenue_analytics.payments_clean pay
    ON t.transaction_id = pay.transaction_id;


-- =========================================================
-- 12. KEY DATASET COUNTS
-- =========================================================

SELECT transaction_status, COUNT(*) AS transactions
FROM revenue_analytics.transactions_clean
GROUP BY transaction_status
ORDER BY transaction_status;


SELECT payment_status, COUNT(*) AS payments
FROM revenue_analytics.payments_clean
GROUP BY payment_status
ORDER BY payment_status;


SELECT customer_segment, COUNT(*) AS customers
FROM revenue_analytics.customers_clean
GROUP BY customer_segment
ORDER BY customer_segment;


SELECT product_category, COUNT(*) AS products
FROM revenue_analytics.products_clean
GROUP BY product_category
ORDER BY product_category;


SELECT refund_status, COUNT(*) AS refunds
FROM revenue_analytics.refunds_clean
GROUP BY refund_status
ORDER BY refund_status;
```
