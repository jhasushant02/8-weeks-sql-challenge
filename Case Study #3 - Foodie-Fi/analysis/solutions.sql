-- Case Study #3: Foodie-Fi | DuckDB
-- Data notes:
--   * subscriptions is an event log: one row = one customer entering one plan on one date.
--     A customer's current plan is their LATEST row, so order by start_date before aggregating.
--   * plan_id 4 (churn) has a NULL price. It marks an ending, not a paid plan.
--   * Data runs through early 2021, so "after 2020" questions see a partial year.

-- =====================================================
-- A. CUSTOMER JOURNEY (first 8 customers)
-- =====================================================

SELECT
    s.customer_id,
    string_agg(p.plan_name, ' → ' ORDER BY s.start_date) AS onboarding_journey
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE s.customer_id <= 8
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- =====================================================
-- B. DATA ANALYSIS QUESTIONS
-- =====================================================

-- B1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM foodie_fi.subscriptions;

-- B2. Monthly distribution of trial plan start_date values (start of month as the group)
SELECT
    date_trunc('month', s.start_date)::DATE AS month,
    COUNT(*) AS trial_count
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY month
ORDER BY month;

-- B3. Plan start_date values after 2020: count of events per plan_name
SELECT p.plan_name, COUNT(*) AS event_count
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE s.start_date >= DATE '2021-01-01'
GROUP BY p.plan_name
ORDER BY event_count DESC;

-- B4. Customer count and percentage of customers who have churned (1 decimal place)
SELECT
    COUNT(DISTINCT CASE WHEN s.plan_id = 4 THEN s.customer_id END) AS churned_customers,
    ROUND(COUNT(DISTINCT CASE WHEN s.plan_id = 4 THEN s.customer_id END) * 100
          / COUNT(DISTINCT s.customer_id), 1) AS churn_perc
FROM foodie_fi.subscriptions s;

-- B5. Customers who churned straight after the free trial (nearest whole percent)
-- Journey string per customer: '0 → 4' means trial then churn, nothing in between.
WITH customer_journey AS (
    SELECT
        s.customer_id,
        string_agg(CAST(s.plan_id AS VARCHAR), ' → ' ORDER BY s.start_date) AS journey
    FROM foodie_fi.subscriptions s
    GROUP BY s.customer_id
)
SELECT
    COUNT(*) AS churned_after_trial,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_journey), 0) AS churn_perc
FROM customer_journey
WHERE journey = '0 → 4';

-- B6. Number and percentage of customer plans right after the initial free trial
WITH next_plan AS (
    SELECT
        s.customer_id,
        s.plan_id,
        LEAD(s.plan_id) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan_id
    FROM foodie_fi.subscriptions s
)
SELECT
    p.plan_name,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM next_plan np
JOIN foodie_fi.plans p ON np.next_plan_id = p.plan_id
WHERE np.plan_id = 0
GROUP BY p.plan_name
ORDER BY customer_count DESC;

-- B7. Customer count and percentage for all 5 plans at 2020-12-31
-- Latest row on or before the date = the plan the customer is on.
WITH ranked_plans AS (
    SELECT
        s.customer_id,
        p.plan_name,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.start_date DESC) AS rn
    FROM foodie_fi.subscriptions s
    LEFT JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
    WHERE s.start_date <= DATE '2020-12-31'
),
current_plans AS (
    SELECT customer_id, plan_name FROM ranked_plans WHERE rn = 1
)
SELECT
    plan_name,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
FROM current_plans
GROUP BY plan_name
ORDER BY customer_count DESC;

-- B8. How many customers upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT s.customer_id) AS pro_annual_2020_count
FROM foodie_fi.subscriptions s
WHERE s.plan_id = 3
  AND date_trunc('year', s.start_date) = DATE '2020-01-01';

-- B9. Average days from joining (trial start) to an annual plan
WITH annual_customers AS (
    SELECT
        customer_id,
        MIN(start_date) FILTER (WHERE plan_id = 0) AS trial_date,
        MIN(start_date) FILTER (WHERE plan_id = 3) AS annual_date
    FROM foodie_fi.subscriptions
    GROUP BY customer_id
)
SELECT ROUND(AVG(date_diff('day', trial_date, annual_date)), 0) AS avg_days_to_annual
FROM annual_customers
WHERE annual_date IS NOT NULL;

-- B10. Break that average into 30-day periods (0-30, 30-60, ...)
-- Bucket = FLOOR(days / 30), so a customer at exactly 30 days lands in the 30-60 bucket.
WITH annual_customers AS (
    SELECT
        customer_id,
        MIN(start_date) FILTER (WHERE plan_id = 0) AS trial_date,
        MIN(start_date) FILTER (WHERE plan_id = 3) AS annual_date
    FROM foodie_fi.subscriptions
    GROUP BY customer_id
),
upgrade_days AS (
    SELECT customer_id, date_diff('day', trial_date, annual_date) AS days_to_annual
    FROM annual_customers
    WHERE annual_date IS NOT NULL
),
bucketed AS (
    SELECT customer_id, CAST(FLOOR(days_to_annual / 30.0) AS INTEGER) AS bucket_num
    FROM upgrade_days
)
SELECT
    (bucket_num * 30) || ' - ' || (bucket_num * 30 + 30) AS days_bucket,
    COUNT(*) AS num_of_customers
FROM bucketed
GROUP BY bucket_num
ORDER BY bucket_num;

-- B11. Customers who downgraded from pro monthly to basic monthly in 2020
WITH plan_changes AS (
    SELECT
        s.customer_id,
        s.plan_id,
        LEAD(s.plan_id)    OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan_id,
        LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_start_date
    FROM foodie_fi.subscriptions s
)
SELECT COUNT(DISTINCT customer_id) AS downgraded_customers
FROM plan_changes
WHERE plan_id = 2
  AND next_plan_id = 1
  AND next_start_date < DATE '2021-01-01';

-- =====================================================
-- C. CHALLENGE: 2020 PAYMENTS TABLE
-- =====================================================
-- Rules:
--   1. Monthly payments fall on the same day of month as the plan's start_date.
--   2. Basic -> pro upgrades start immediately and are reduced by the basic amount already paid.
--   3. Pro monthly -> pro annual is paid, and starts, at the END of the current billing period.
--   4. Once a customer churns, no more payments.
--
-- Rule 3 note: the annual start is the first monthly anniversary ON OR AFTER the switch date.
-- If the switch lands exactly on an anniversary (e.g. customer 19: pro monthly 06-29,
-- annual 08-29), the annual payment is on the switch date, not a month later.

DROP TABLE IF EXISTS foodie_fi.payments;

CREATE TABLE foodie_fi.payments AS
WITH RECURSIVE

plan_changes AS (
    SELECT
        s.customer_id,
        s.plan_id,
        p.plan_name,
        p.price,
        s.start_date,
        LAG(s.plan_id)     OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS prev_plan_id,
        LAG(s.start_date)  OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS prev_start_date,
        LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_start_date
    FROM foodie_fi.subscriptions s
    JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
    WHERE s.start_date <= DATE '2020-12-31'
),

plan_segments AS (
    SELECT
        customer_id,
        plan_id,
        plan_name,
        price,
        next_start_date,

        CASE
            WHEN plan_id = 3 AND prev_plan_id = 2
                THEN prev_start_date + INTERVAL (
                         date_diff('month', prev_start_date, start_date)
                         + CASE
                               WHEN prev_start_date
                                    + INTERVAL (date_diff('month', prev_start_date, start_date)) MONTH
                                    >= start_date
                               THEN 0 ELSE 1
                           END
                     ) MONTH
            ELSE start_date
        END AS effective_start_date,

        CASE
            WHEN prev_plan_id = 1 AND plan_id IN (2, 3)
                THEN (SELECT price FROM foodie_fi.plans WHERE plan_id = 1)
            ELSE 0
        END AS credit

    FROM plan_changes
    WHERE plan_id IN (1, 2, 3)
),

payment_calendar AS (
    SELECT
        customer_id, plan_id, plan_name, price, credit,
        effective_start_date AS payment_date,
        next_start_date
    FROM plan_segments

    UNION ALL

    SELECT
        customer_id, plan_id, plan_name, price,
        0 AS credit,
        CASE
            WHEN plan_id = 3 THEN payment_date + INTERVAL 1 YEAR
            ELSE payment_date + INTERVAL 1 MONTH
        END AS payment_date,
        next_start_date
    FROM payment_calendar
    WHERE
        CASE
            WHEN plan_id = 3 THEN payment_date + INTERVAL 1 YEAR
            ELSE payment_date + INTERVAL 1 MONTH
        END < COALESCE(next_start_date, DATE '2021-01-01')
        AND payment_date < DATE '2020-12-31'
)

SELECT
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date) AS payment_order,
    customer_id,
    plan_id,
    plan_name,
    payment_date::DATE AS payment_date,
    ROUND(price - credit, 2) AS amount
FROM payment_calendar
WHERE payment_date <= DATE '2020-12-31'
ORDER BY customer_id, payment_date;

-- Spot checks: customers 1, 2, 4, 6, 7, 8, 19 (see output/results.md for expected rows)
SELECT * FROM foodie_fi.payments
WHERE customer_id IN (1, 2, 4, 6, 7, 8, 19)
ORDER BY customer_id, payment_date;

-- =====================================================
-- D. OUTSIDE THE BOX
-- =====================================================
-- Discussion questions (growth rate, key metrics, retention journeys, exit survey,
-- churn levers). No queries; short answers are in output/results.md.
