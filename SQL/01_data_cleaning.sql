
```sql
CREATE SCHEMA IF NOT EXISTS revenue_analytics;

-- =========================================================
-- 1. RAW STAGING TABLES
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.staging_transactions_raw;

CREATE TABLE revenue_analytics.staging_transactions_raw (
    transaction_id           TEXT,
    customer_id              TEXT,
    product_id               TEXT,
    branch_id                TEXT,
    transaction_date         TEXT,
    quantity                 TEXT,
    transaction_status       TEXT,
    standard_price           TEXT,
    cost_price               TEXT,
    unit_price               TEXT,
    discount_pct             TEXT,
    expected_amount          TEXT,
    discount_amount          TEXT,
    expected_billed_amount   TEXT,
    billed_amount            TEXT
);


DROP TABLE IF EXISTS revenue_analytics.staging_customers_raw;

CREATE TABLE revenue_analytics.staging_customers_raw (
    customer_id       TEXT,
    customer_name     TEXT,
    customer_segment  TEXT,
    state             TEXT,
    registration_date TEXT
);


DROP TABLE IF EXISTS revenue_analytics.staging_products_raw;

CREATE TABLE revenue_analytics.staging_products_raw (
    product_id        TEXT,
    product_name      TEXT,
    product_category  TEXT,
    standard_price    TEXT,
    cost_price        TEXT
);


DROP TABLE IF EXISTS revenue_analytics.staging_payments_raw;

CREATE TABLE revenue_analytics.staging_payments_raw (
    payment_id       TEXT,
    transaction_id   TEXT,
    payment_date     TEXT,
    payment_status   TEXT,
    payment_channel  TEXT,
    payment_amount   TEXT
);


DROP TABLE IF EXISTS revenue_analytics.staging_refunds_raw;

CREATE TABLE revenue_analytics.staging_refunds_raw (
    refund_id       TEXT,
    transaction_id  TEXT,
    refund_date     TEXT,
    refund_amount   TEXT,
    refund_reason   TEXT,
    refund_status   TEXT
);


DROP TABLE IF EXISTS revenue_analytics.staging_branches_raw;

CREATE TABLE revenue_analytics.staging_branches_raw (
    branch_id    TEXT,
    branch_name  TEXT,
    state        TEXT,
    region       TEXT
);


-- =========================================================
-- 2. LOAD CSV FILES
-- =========================================================

COPY revenue_analytics.staging_transactions_raw
FROM 'C:/Users/USER/Downloads/transactionss.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '');

COPY revenue_analytics.staging_customers_raw
FROM 'C:/Users/USER/Downloads/customerss.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '');

COPY revenue_analytics.staging_products_raw
FROM 'C:/Users/USER/Downloads/productss.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '');

COPY revenue_analytics.staging_payments_raw
FROM 'C:/Users/USER/Downloads/paymentss.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '');

COPY revenue_analytics.staging_refunds_raw
FROM 'C:/Users/USER/Downloads/refundss.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '');

COPY revenue_analytics.staging_branches_raw
FROM 'C:/Users/USER/Downloads/branchess.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '');
```
