-- Case Study #4: Data Bank | DuckDB
-- Data notes:
--   * customer_nodes is an allocation history: one row = one customer-node stay.
--     Open stays have end_date = '9999-12-31' and are excluded from duration metrics.
--   * customer_transactions has no balance column. Deposits add, purchases and
--     withdrawals subtract. Balances are built with cumulative sums.
--   * Several transactions can fall on the same day, and not every customer
--     transacts every month, so month-level logic needs a continuous calendar.

-- =====================================================
-- A. CUSTOMER NODES EXPLORATION
-- =====================================================

-- A1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM data_bank.customer_nodes;

-- A2. What is the number of nodes per region?
SELECT region_id, COUNT(DISTINCT node_id) AS nodes_per_region
FROM data_bank.customer_nodes
GROUP BY region_id
ORDER BY region_id;

-- A3. How many customers are allocated to each region?
SELECT region_id, COUNT(DISTINCT customer_id) AS customers_per_region
FROM data_bank.customer_nodes
GROUP BY region_id
ORDER BY region_id;

-- A4. How many days on average are customers reallocated to a different node?
-- Interpretation: total days a customer spends on a node, summed across repeat
-- stays on that node, then averaged over customer-node pairs. Open stays excluded.
WITH node_days AS (
    SELECT
        customer_id,
        node_id,
        end_date - start_date AS days_in_node
    FROM data_bank.customer_nodes
    WHERE end_date != DATE '9999-12-31'
),
total_node_days AS (
    SELECT customer_id, node_id, SUM(days_in_node) AS total_days_in_node
    FROM node_days
    GROUP BY customer_id, node_id
)
SELECT ROUND(AVG(total_days_in_node)) AS avg_reallocation_days
FROM total_node_days;

-- A5. Median, 80th and 95th percentile of reallocation days for each region
-- Note: this uses days per individual stay (not summed per customer-node pair
-- as in A4), so A4 and A5 measure slightly different things.
WITH node_days AS (
    SELECT
        region_id,
        end_date - start_date AS days_in_node
    FROM data_bank.customer_nodes
    WHERE end_date != DATE '9999-12-31'
)
SELECT
    r.region_name,
    ROUND(MEDIAN(nd.days_in_node), 2)              AS median_reallocation_days,
    ROUND(QUANTILE_CONT(nd.days_in_node, 0.80), 2) AS p80_reallocation_days,
    ROUND(QUANTILE_CONT(nd.days_in_node, 0.95), 2) AS p95_reallocation_days
FROM node_days nd
JOIN data_bank.regions r ON nd.region_id = r.region_id
GROUP BY r.region_name
ORDER BY r.region_name;

-- =====================================================
-- B. CUSTOMER TRANSACTIONS
-- =====================================================

-- B1. Unique count and total amount for each transaction type
SELECT
    txn_type,
    COUNT(*)                    AS txn_count,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(txn_amount)             AS total_amt
FROM data_bank.customer_transactions
GROUP BY txn_type
ORDER BY txn_type;

-- B2. Average historical deposit count and amount per customer
-- Population is every customer in customer_nodes, so customers with no deposits
-- would count as 0 rather than being dropped from the denominator.
WITH customers AS (
    SELECT DISTINCT customer_id FROM data_bank.customer_nodes
),
customer_deposits AS (
    SELECT customer_id, COUNT(*) AS deposit_count, SUM(txn_amount) AS deposit_amount
    FROM data_bank.customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
)
SELECT
    ROUND(AVG(COALESCE(cd.deposit_count, 0)), 0)  AS avg_deposit_count,
    ROUND(AVG(COALESCE(cd.deposit_amount, 0)), 2) AS avg_deposit_amount
FROM customers c
LEFT JOIN customer_deposits cd ON c.customer_id = cd.customer_id;

-- B3. Per month: customers with more than 1 deposit and at least 1 purchase or withdrawal
WITH monthly_transactions AS (
    SELECT
        customer_id,
        EXTRACT(month FROM txn_date) AS month,
        SUM(CASE WHEN txn_type = 'deposit'    THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase'   THEN 1 ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM data_bank.customer_transactions
    GROUP BY customer_id, EXTRACT(month FROM txn_date)
)
SELECT month, COUNT(*) AS customer_count
FROM monthly_transactions
WHERE deposit_count > 1
  AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY month
ORDER BY month;

-- B4. Closing balance for each customer at the end of the month
-- Only months in which the customer transacted appear. Months with no activity
-- (balance carried forward) are not listed; see section C for a gap-free version.
WITH monthly_transactions AS (
    SELECT
        customer_id,
        CAST(date_trunc('month', txn_date) AS DATE) AS month,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS monthly_balance
    FROM data_bank.customer_transactions
    GROUP BY customer_id, CAST(date_trunc('month', txn_date) AS DATE)
)
SELECT
    customer_id,
    month,
    SUM(monthly_balance) OVER (
        PARTITION BY customer_id
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS closing_balance
FROM monthly_transactions
ORDER BY customer_id, month;

-- B5. Percentage of customers who increase their closing balance by more than 5%
-- Interpretation: a customer counts if at least one month-over-month step (between
-- consecutive months they transacted) has a positive previous balance and a rise above 5%.
-- Reported per region and in total.
WITH customer_region AS (
    SELECT DISTINCT cn.customer_id, r.region_name
    FROM data_bank.customer_nodes cn
    JOIN data_bank.regions r ON cn.region_id = r.region_id
),
monthly_transactions AS (
    SELECT
        customer_id,
        CAST(date_trunc('month', txn_date) AS DATE) AS month,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS monthly_balance
    FROM data_bank.customer_transactions
    GROUP BY customer_id, CAST(date_trunc('month', txn_date) AS DATE)
),
closing_balance AS (
    SELECT
        customer_id,
        month,
        SUM(monthly_balance) OVER (PARTITION BY customer_id ORDER BY month) AS closing_balance
    FROM monthly_transactions
),
balance_change AS (
    SELECT
        customer_id,
        month,
        closing_balance,
        LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY month) AS previous_closing_balance
    FROM closing_balance
),
customers_increase AS (
    SELECT DISTINCT customer_id
    FROM balance_change
    WHERE previous_closing_balance > 0
      AND closing_balance > previous_closing_balance * 1.05
),
region_result AS (
    SELECT
        cr.region_name,
        COUNT(ci.customer_id) AS customers_increased,
        COUNT(cr.customer_id) AS total_customers
    FROM customer_region cr
    LEFT JOIN customers_increase ci ON cr.customer_id = ci.customer_id
    GROUP BY cr.region_name
),
final_result AS (
    SELECT region_name, ROUND(100.0 * customers_increased / total_customers, 2) AS percentage_customers
    FROM region_result
    UNION ALL
    SELECT 'Total', ROUND(100.0 * COUNT(DISTINCT ci.customer_id) / COUNT(DISTINCT cr.customer_id), 2)
    FROM customer_region cr
    LEFT JOIN customers_increase ci ON cr.customer_id = ci.customer_id
)
SELECT region_name, percentage_customers
FROM final_result
ORDER BY CASE WHEN region_name = 'Total' THEN 1 ELSE 0 END, region_name;

-- =====================================================
-- C. DATA ALLOCATION CHALLENGE
-- =====================================================
-- Option 1: data based on the balance at the end of the PREVIOUS month
-- Option 2: data based on the average balance over the PREVIOUS 30 days
-- Option 3: data updated in real time (provisioned for the peak balance in the month)
--
-- Negative balances are floored at 0: a customer cannot need negative storage.
-- Data covers Jan to Apr 2020 and April is a partial month, so treat April as indicative.

-- C0. Helper: one row per customer per calendar day with the end-of-day balance.
-- A continuous calendar means days and months without transactions carry the
-- balance forward instead of disappearing from the totals.
CREATE OR REPLACE TABLE data_bank.daily_balance AS
WITH bounds AS (
    SELECT MIN(txn_date) AS min_d, MAX(txn_date) AS max_d
    FROM data_bank.customer_transactions
),
days AS (
    SELECT CAST(unnest(generate_series(min_d, max_d, INTERVAL 1 DAY)) AS DATE) AS day
    FROM bounds
),
customers AS (
    SELECT DISTINCT customer_id FROM data_bank.customer_transactions
),
daily_net AS (
    SELECT
        customer_id,
        txn_date AS day,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS net_change
    FROM data_bank.customer_transactions
    GROUP BY customer_id, txn_date
)
SELECT
    c.customer_id,
    d.day,
    CAST(date_trunc('month', d.day) AS DATE) AS month,
    SUM(COALESCE(n.net_change, 0)) OVER (
        PARTITION BY c.customer_id
        ORDER BY d.day
    ) AS balance
FROM customers c
CROSS JOIN days d
LEFT JOIN daily_net n
    ON n.customer_id = c.customer_id AND n.day = d.day;

-- C1. Running customer balance after each transaction
-- Same-day transactions have no defined order in the data, so intermediate values
-- within a day depend on row order; the end-of-day balance is always correct.
SELECT
    customer_id,
    txn_date,
    txn_type,
    txn_amount,
    SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) OVER (
        PARTITION BY customer_id
        ORDER BY txn_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_balance
FROM data_bank.customer_transactions
ORDER BY customer_id, txn_date;

-- C2. Customer balance at the end of each month (gap-free)
SELECT
    customer_id,
    month,
    balance AS month_end_balance
FROM data_bank.daily_balance
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id, month
    ORDER BY day DESC
) = 1
ORDER BY customer_id, month;

-- C3. Minimum, average and maximum running balance for each customer
WITH running_balance AS (
    SELECT
        customer_id,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_balance
    FROM data_bank.customer_transactions
)
SELECT
    customer_id,
    MIN(running_balance)           AS min_balance,
    ROUND(AVG(running_balance), 2) AS avg_balance,
    MAX(running_balance)           AS max_balance
FROM running_balance
GROUP BY customer_id
ORDER BY customer_id;

-- C4. Data required per month under each option
WITH month_end AS (
    SELECT customer_id, month, balance AS month_end_balance
    FROM data_bank.daily_balance
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id, month ORDER BY day DESC) = 1
),
option_1 AS (
    -- allocation for month M comes from the balance at the end of month M-1
    SELECT month, SUM(GREATEST(prev_balance, 0)) AS option_1_data
    FROM (
        SELECT
            customer_id,
            month,
            LAG(month_end_balance) OVER (PARTITION BY customer_id ORDER BY month) AS prev_balance
        FROM month_end
    ) m
    WHERE prev_balance IS NOT NULL
    GROUP BY month
),
option_2 AS (
    -- allocation for month M comes from the average daily balance over the 30 days
    -- before its first day (value taken on the first day of the month)
    SELECT month, SUM(GREATEST(avg_prev_30d, 0)) AS option_2_data
    FROM (
        SELECT
            customer_id,
            day,
            month,
            AVG(balance) OVER (
                PARTITION BY customer_id
                ORDER BY day
                ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
            ) AS avg_prev_30d
        FROM data_bank.daily_balance
    ) a
    WHERE day = month
      AND avg_prev_30d IS NOT NULL
    GROUP BY month
),
option_3 AS (
    -- real time: provision for each customer's peak balance during the month
    SELECT month, SUM(GREATEST(peak_balance, 0)) AS option_3_data
    FROM (
        SELECT customer_id, month, MAX(balance) AS peak_balance
        FROM data_bank.daily_balance
        GROUP BY customer_id, month
    ) p
    GROUP BY month
)
SELECT
    o3.month,
    ROUND(o1.option_1_data, 2) AS option_1_data,
    ROUND(o2.option_2_data, 2) AS option_2_data,
    ROUND(o3.option_3_data, 2) AS option_3_data
FROM option_3 o3
LEFT JOIN option_1 o1 ON o3.month = o1.month
LEFT JOIN option_2 o2 ON o3.month = o2.month
ORDER BY o3.month;

-- =====================================================
-- D. EXTRA CHALLENGE: DAILY INTEREST AT 6% PER YEAR
-- =====================================================
-- Simple interest (no compounding): each day, balance * 0.06 / 365, summed per month.
-- Uses the gap-free daily_balance table from C0, so interest accrues on every day
-- (including days with no transactions), not just days a customer transacted.
-- Negative balances earn nothing.
SELECT
    month,
    ROUND(SUM(GREATEST(balance, 0) * (0.06 / 365)), 2) AS additional_data_required
FROM data_bank.daily_balance
GROUP BY month
ORDER BY month;

-- Compounding (new balance = previous balance * (1 + 0.06 / 365) each day) was not built.
