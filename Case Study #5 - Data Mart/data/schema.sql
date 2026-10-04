-- Case Study #5: Data Mart
-- Source: https://8weeksqlchallenge.com/case-study-5/ (created by Danny Ma)
-- Dialect: DuckDB
-- Note: week_date is TEXT in day/month/year form with no zero padding (e.g. 9/9/20),
-- and missing segments are the literal string 'null', not a real NULL.
-- Cleaning happens in analysis/solutions.sql.

CREATE SCHEMA IF NOT EXISTS data_mart;
USE data_mart;

DROP TABLE IF EXISTS data_mart.weekly_sales;
CREATE TABLE data_mart.weekly_sales (
    week_date     VARCHAR(7),
    region        VARCHAR(13),
    platform      VARCHAR(7),
    segment       VARCHAR(4),
    customer_type VARCHAR(8),
    transactions  INTEGER,
    sales         DECIMAL(14, 2)
);

-- >>> PASTE THE weekly_sales INSERT HERE <<<
-- Copy the INSERT INTO data_mart.weekly_sales (...) VALUES (...) block from the
-- data section of the blog post or the challenge page. Example row format:
-- INSERT INTO data_mart.weekly_sales (week_date, region, platform, segment, customer_type, transactions, sales) VALUES
--     ('9/9/20', 'OCEANIA', 'Shopify', 'C3', 'New', 610, 110033.89),
--     ('29/7/20', 'AFRICA', 'Retail', 'C1', 'New', 110692, 3053771.19),
--     ...;
