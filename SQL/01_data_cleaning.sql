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


-- =========================================================
-- 3. CLEAN CUSTOMERS
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.customers_clean;

CREATE TABLE revenue_analytics.customers_clean AS
SELECT
    NULLIF(TRIM(customer_id), '') AS customer_id,
    NULLIF(TRIM(customer_name), '') AS customer_name,

    CASE
        WHEN UPPER(TRIM(customer_segment)) = 'RETAIL'
            THEN 'Retail'
        WHEN UPPER(TRIM(customer_segment)) = 'SME'
            THEN 'SME'
        WHEN UPPER(TRIM(customer_segment)) = 'CORPORATE'
            THEN 'Corporate'
        ELSE NULL
    END AS customer_segment,

    CASE
        WHEN NULLIF(TRIM(state), '') IS NULL THEN NULL
        WHEN UPPER(TRIM(state)) = 'ABUJA'  THEN 'Abuja'
        WHEN UPPER(TRIM(state)) = 'KANO'   THEN 'Kano'
        WHEN UPPER(TRIM(state)) = 'LAGOS'  THEN 'Lagos'
        WHEN UPPER(TRIM(state)) = 'OGUN'   THEN 'Ogun'
        WHEN UPPER(TRIM(state)) = 'OYO'    THEN 'Oyo'
        WHEN UPPER(TRIM(state)) = 'RIVERS' THEN 'Rivers'
        ELSE INITCAP(TRIM(state))
    END AS state,

    CASE
        WHEN TRIM(registration_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(registration_date)::DATE
        ELSE NULL
    END AS registration_date

FROM revenue_analytics.staging_customers_raw;


ALTER TABLE revenue_analytics.customers_clean
ADD PRIMARY KEY (customer_id);


-- =========================================================
-- 4. CLEAN PRODUCTS
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.products_clean;

CREATE TABLE revenue_analytics.products_clean AS
SELECT
    NULLIF(TRIM(product_id), '') AS product_id,
    NULLIF(TRIM(product_name), '') AS product_name,

    CASE
        WHEN UPPER(TRIM(product_category)) = 'LOANS'
            THEN 'Loans'
        WHEN UPPER(TRIM(product_category)) = 'ACCOUNT SERVICES'
            THEN 'Account Services'
        WHEN UPPER(TRIM(product_category)) = 'TRANSFERS'
            THEN 'Transfers'
        WHEN UPPER(TRIM(product_category)) = 'PAYMENTS'
            THEN 'Payments'
        WHEN UPPER(TRIM(product_category)) = 'CARDS'
            THEN 'Cards'
        ELSE INITCAP(TRIM(product_category))
    END AS product_category,

    CASE
        WHEN TRIM(standard_price) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(standard_price)::NUMERIC(18,2)
        ELSE NULL
    END AS standard_price,

    CASE
        WHEN TRIM(cost_price) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(cost_price)::NUMERIC(18,2)
        ELSE NULL
    END AS cost_price

FROM revenue_analytics.staging_products_raw;


ALTER TABLE revenue_analytics.products_clean
ADD PRIMARY KEY (product_id);


-- =========================================================
-- 5. CLEAN BRANCHES
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.branches_clean;

CREATE TABLE revenue_analytics.branches_clean AS
SELECT
    NULLIF(TRIM(branch_id), '') AS branch_id,
    NULLIF(TRIM(branch_name), '') AS branch_name,

    CASE
        WHEN UPPER(TRIM(state)) = 'ABUJA'  THEN 'Abuja'
        WHEN UPPER(TRIM(state)) = 'KANO'   THEN 'Kano'
        WHEN UPPER(TRIM(state)) = 'LAGOS'  THEN 'Lagos'
        WHEN UPPER(TRIM(state)) = 'OGUN'   THEN 'Ogun'
        WHEN UPPER(TRIM(state)) = 'OYO'    THEN 'Oyo'
        WHEN UPPER(TRIM(state)) = 'RIVERS' THEN 'Rivers'
        ELSE INITCAP(TRIM(state))
    END AS state,

    CASE
        WHEN UPPER(TRIM(region)) = 'NORTH'
            THEN 'North'
        WHEN UPPER(TRIM(region)) = 'SOUTH WEST'
            THEN 'South West'
        WHEN UPPER(TRIM(region)) = 'SOUTH SOUTH'
            THEN 'South South'
        ELSE INITCAP(TRIM(region))
    END AS region

FROM revenue_analytics.staging_branches_raw;


ALTER TABLE revenue_analytics.branches_clean
ADD PRIMARY KEY (branch_id);


-- =========================================================
-- 6. CLEAN PAYMENTS
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.payments_clean;

CREATE TABLE revenue_analytics.payments_clean AS
SELECT
    NULLIF(TRIM(payment_id), '') AS payment_id,
    NULLIF(TRIM(transaction_id), '') AS transaction_id,

    CASE
        WHEN TRIM(payment_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(payment_date)::DATE
        ELSE NULL
    END AS payment_date,

    CASE
        WHEN UPPER(TRIM(payment_status)) = 'SUCCESSFUL'
            THEN 'Successful'
        WHEN UPPER(TRIM(payment_status)) = 'FAILED'
            THEN 'Failed'
        WHEN UPPER(TRIM(payment_status)) = 'PENDING'
            THEN 'Pending'
        ELSE NULL
    END AS payment_status,

    CASE
        WHEN NULLIF(TRIM(payment_channel), '') IS NULL
            THEN NULL
        WHEN UPPER(TRIM(payment_channel)) = 'USSD'
            THEN 'USSD'
        WHEN UPPER(TRIM(payment_channel)) = 'CARD'
            THEN 'Card'
        WHEN UPPER(TRIM(payment_channel)) = 'CASH'
            THEN 'Cash'
        WHEN UPPER(TRIM(payment_channel)) = 'ONLINE'
            THEN 'Online'
        WHEN UPPER(TRIM(payment_channel)) = 'TRANSFER'
            THEN 'Transfer'
        ELSE INITCAP(TRIM(payment_channel))
    END AS payment_channel,

    CASE
        WHEN TRIM(payment_amount) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(payment_amount)::NUMERIC(18,2)
        ELSE NULL
    END AS payment_amount

FROM revenue_analytics.staging_payments_raw;


ALTER TABLE revenue_analytics.payments_clean
ADD PRIMARY KEY (payment_id);

CREATE UNIQUE INDEX idx_payments_transaction
ON revenue_analytics.payments_clean(transaction_id);


-- =========================================================
-- 7. CLEAN REFUNDS
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.refunds_clean;

CREATE TABLE revenue_analytics.refunds_clean AS
SELECT
    NULLIF(TRIM(refund_id), '') AS refund_id,
    NULLIF(TRIM(transaction_id), '') AS transaction_id,

    CASE
        WHEN TRIM(refund_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(refund_date)::DATE
        ELSE NULL
    END AS refund_date,

    CASE
        WHEN TRIM(refund_amount) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(refund_amount)::NUMERIC(18,2)
        ELSE NULL
    END AS refund_amount,

    CASE
        WHEN UPPER(TRIM(refund_reason)) = 'CUSTOMER REQUEST'
            THEN 'Customer Request'
        WHEN UPPER(TRIM(refund_reason)) = 'DUPLICATE CHARGE'
            THEN 'Duplicate Charge'
        WHEN UPPER(TRIM(refund_reason)) = 'INCORRECT CHARGE'
            THEN 'Incorrect Charge'
        WHEN UPPER(TRIM(refund_reason)) = 'SERVICE ISSUE'
            THEN 'Service Issue'
        ELSE INITCAP(TRIM(refund_reason))
    END AS refund_reason,

    CASE
        WHEN UPPER(TRIM(refund_status)) = 'APPROVED'
            THEN 'Approved'
        WHEN UPPER(TRIM(refund_status)) = 'REJECTED'
            THEN 'Rejected'
        ELSE NULL
    END AS refund_status

FROM revenue_analytics.staging_refunds_raw;


ALTER TABLE revenue_analytics.refunds_clean
ADD PRIMARY KEY (refund_id);

CREATE UNIQUE INDEX idx_refunds_transaction
ON revenue_analytics.refunds_clean(transaction_id);


-- =========================================================
-- 8. CLEAN TRANSACTIONS
-- =========================================================

DROP TABLE IF EXISTS revenue_analytics.transactions_clean;

CREATE TABLE revenue_analytics.transactions_clean AS
SELECT
    NULLIF(TRIM(transaction_id), '') AS transaction_id,
    NULLIF(TRIM(customer_id), '') AS customer_id,
    NULLIF(TRIM(product_id), '') AS product_id,
    NULLIF(TRIM(branch_id), '') AS branch_id,

    CASE
        WHEN TRIM(transaction_date) ~ '^\d{4}-\d{2}-\d{2}$'
            THEN TRIM(transaction_date)::DATE
        ELSE NULL
    END AS transaction_date,

    CASE
        WHEN TRIM(quantity) ~ '^\d+$'
            THEN TRIM(quantity)::INTEGER
        ELSE NULL
    END AS quantity,

    CASE
        WHEN UPPER(TRIM(transaction_status)) = 'COMPLETED'
            THEN 'Completed'
        WHEN UPPER(TRIM(transaction_status)) = 'CANCELLED'
            THEN 'Cancelled'
        ELSE NULL
    END AS transaction_status,

    CASE
        WHEN TRIM(standard_price) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(standard_price)::NUMERIC(18,2)
        ELSE NULL
    END AS standard_price,

    CASE
        WHEN TRIM(cost_price) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(cost_price)::NUMERIC(18,2)
        ELSE NULL
    END AS cost_price,

    CASE
        WHEN TRIM(unit_price) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(unit_price)::NUMERIC(18,2)
        ELSE NULL
    END AS unit_price,

    CASE
        WHEN TRIM(discount_pct) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(discount_pct)::NUMERIC(8,4)
        ELSE NULL
    END AS discount_pct,

    CASE
        WHEN TRIM(expected_amount) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(expected_amount)::NUMERIC(18,2)
        ELSE NULL
    END AS expected_amount,

    CASE
        WHEN TRIM(discount_amount) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(discount_amount)::NUMERIC(18,2)
        ELSE NULL
    END AS discount_amount,

    CASE
        WHEN TRIM(expected_billed_amount) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(expected_billed_amount)::NUMERIC(18,2)
        ELSE NULL
    END AS expected_billed_amount,

    CASE
        WHEN TRIM(billed_amount) ~ '^-?[0-9]+(\.[0-9]+)?$'
            THEN TRIM(billed_amount)::NUMERIC(18,2)
        ELSE NULL
    END AS billed_amount

FROM revenue_analytics.staging_transactions_raw;


ALTER TABLE revenue_analytics.transactions_clean
ADD PRIMARY KEY (transaction_id);


-- =========================================================
-- 9. FOREIGN KEYS
-- =========================================================

ALTER TABLE revenue_analytics.transactions_clean
ADD CONSTRAINT fk_transaction_customer
FOREIGN KEY (customer_id)
REFERENCES revenue_analytics.customers_clean(customer_id);

ALTER TABLE revenue_analytics.transactions_clean
ADD CONSTRAINT fk_transaction_product
FOREIGN KEY (product_id)
REFERENCES revenue_analytics.products_clean(product_id);

ALTER TABLE revenue_analytics.transactions_clean
ADD CONSTRAINT fk_transaction_branch
FOREIGN KEY (branch_id)
REFERENCES revenue_analytics.branches_clean(branch_id);

ALTER TABLE revenue_analytics.payments_clean
ADD CONSTRAINT fk_payment_transaction
FOREIGN KEY (transaction_id)
REFERENCES revenue_analytics.transactions_clean(transaction_id);

ALTER TABLE revenue_analytics.refunds_clean
ADD CONSTRAINT fk_refund_transaction
FOREIGN KEY (transaction_id)
REFERENCES revenue_analytics.transactions_clean(transaction_id);
```

