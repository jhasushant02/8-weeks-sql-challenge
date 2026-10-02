-- Case Study #3: Foodie-Fi
-- Source: https://8weeksqlchallenge.com/case-study-3/ (created by Danny Ma)
-- Dialect: DuckDB
-- Note: the data is clean, but start_date means different things depending on
-- the plan (see README). Interpretation happens in the queries.

CREATE SCHEMA IF NOT EXISTS foodie_fi;
USE foodie_fi;

-- plans
DROP TABLE IF EXISTS foodie_fi.plans;
CREATE TABLE foodie_fi.plans (
    plan_id INTEGER,
    plan_name VARCHAR(13),
    price DECIMAL(5,2)
);
INSERT INTO foodie_fi.plans (plan_id, plan_name, price) VALUES
    (0, 'trial', 0.00),
    (1, 'basic monthly', 9.90),
    (2, 'pro monthly', 19.90),
    (3, 'pro annual', 199.00),
    (4, 'churn', NULL);

-- subscriptions (one row per plan change, 1,000 customers)
DROP TABLE IF EXISTS foodie_fi.subscriptions;
CREATE TABLE foodie_fi.subscriptions (
    customer_id INTEGER,
    plan_id INTEGER,
    start_date DATE
);

-- >>> PASTE THE FULL INSERT HERE <<<
-- Copy the INSERT INTO foodie_fi.subscriptions (...) VALUES (...) block from the
-- "#2 Subscriptions" section of the blog post (rows (1, 0, '2020-08-01') through
-- (1000, 4, '2020-06-04')), or from the challenge page.
-- INSERT INTO foodie_fi.subscriptions (customer_id, plan_id, start_date) VALUES
--     (1, 0, '2020-08-01'),
--     ...
--     (1000, 4, '2020-06-04');
