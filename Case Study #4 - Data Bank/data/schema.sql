-- Case Study #4: Data Bank
-- Source: https://8weeksqlchallenge.com/case-study-4/ (created by Danny Ma)
-- Dialect: DuckDB
-- Note: customers appear in customer_nodes many times (they get reshuffled),
-- and an open-ended allocation uses end_date = '9999-12-31'. Interpretation
-- happens in the queries.

CREATE SCHEMA IF NOT EXISTS data_bank;
USE data_bank;

-- regions
DROP TABLE IF EXISTS data_bank.regions;
CREATE TABLE data_bank.regions (
    region_id INTEGER,
    region_name VARCHAR(9)
);
INSERT INTO data_bank.regions (region_id, region_name) VALUES
    (1, 'Australia'),
    (2, 'America'),
    (3, 'Africa'),
    (4, 'Asia'),
    (5, 'Europe');

-- customer_nodes (one row per customer node allocation)
DROP TABLE IF EXISTS data_bank.customer_nodes;
CREATE TABLE data_bank.customer_nodes (
    customer_id INTEGER,
    region_id INTEGER,
    node_id INTEGER,
    start_date DATE,
    end_date DATE
);

-- >>> PASTE THE customer_nodes INSERT HERE <<<
-- Copy the INSERT INTO data_bank.customer_nodes (...) VALUES (...) block from the
-- "#2 customer_nodes" section of the blog post (first row (1, 3, 4, '2020-01-02', '2020-01-03'),
-- last row (500, 2, 2, '2020-04-15', '9999-12-31')).
-- INSERT INTO data_bank.customer_nodes (customer_id, region_id, node_id, start_date, end_date) VALUES
--     (1, 3, 4, '2020-01-02', '2020-01-03'),
--     ...
--     (500, 2, 2, '2020-04-15', '9999-12-31');

-- customer_transactions (one row per transaction)
DROP TABLE IF EXISTS data_bank.customer_transactions;
CREATE TABLE data_bank.customer_transactions (
    customer_id INTEGER,
    txn_date DATE,
    txn_type VARCHAR(10),
    txn_amount INTEGER
);

-- >>> PASTE THE customer_transactions INSERT HERE <<<
-- Copy the INSERT INTO data_bank.customer_transactions (...) VALUES (...) block from the
-- "#3 customer_transactions" section of the blog post (first row (429, '2020-01-21', 'deposit', 82),
-- last row (189, '2020-01-27', 'withdrawal', 861)).
-- INSERT INTO data_bank.customer_transactions (customer_id, txn_date, txn_type, txn_amount) VALUES
--     (429, '2020-01-21', 'deposit', 82),
--     ...
--     (189, '2020-01-27', 'withdrawal', 861);
