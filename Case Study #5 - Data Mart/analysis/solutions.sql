-- Case Study #5: Data Mart | DuckDB
-- Data notes:
--   * weekly_sales has one table and no joins. One row = a weekly slice already
--     rolled up by week, region, platform, segment and customer type. It is not a
--     customer or an order, so averaging an average column gives wrong answers.
--   * week_date is text (day/month/year, no zero padding) and missing segments are
--     the string 'null', not a real NULL. Both are handled in section A.
--   * Baseline week is 2020-06-15: the first week of the "after" period.
--   * Windows filter on dates (baseline -/+ weeks*7), not week_number, so there is
--     no off-by-one risk. Weeks start on the same weekday.

-- =====================================================
-- A. DATA CLEANSING
-- =====================================================
CREATE OR REPLACE TABLE data_mart.clean_weekly_sales AS
WITH dated AS (
    SELECT
        strptime(week_date, '%d/%m/%y')::DATE AS week_date,
        region,
        platform,
        -- 'null' is a string, so check for it explicitly (and for a real NULL too)
        CASE
            WHEN segment IS NULL OR lower(trim(segment)) = 'null' THEN 'unknown'
            ELSE upper(trim(segment))
        END AS segment,
        customer_type,
        transactions,
        sales
    FROM data_mart.weekly_sales
)
SELECT
    week_date,
    ((dayofyear(week_date) - 1) // 7) + 1 AS week_number,   -- // is integer division
    month(week_date)                      AS month_number,
    year(week_date)                       AS calendar_year,
    region,
    platform,
    segment,
    CASE right(segment, 1)
        WHEN '1' THEN 'Young Adults'
        WHEN '2' THEN 'Middle Aged'
        WHEN '3' THEN 'Retirees'
        WHEN '4' THEN 'Retirees'
        ELSE 'unknown'
    END AS age_band,
    CASE left(segment, 1)
        WHEN 'C' THEN 'Couples'
        WHEN 'F' THEN 'Families'
        ELSE 'unknown'
    END AS demographic,
    customer_type,
    transactions,
    sales,
    ROUND(sales / NULLIF(transactions, 0), 2) AS avg_transaction
FROM dated;

-- Sanity check
SELECT * FROM data_mart.clean_weekly_sales LIMIT 10;

-- =====================================================
-- B. DATA EXPLORATION
-- =====================================================

-- B1. What day of the week is used for each week_date value?
SELECT DISTINCT dayname(week_date) AS day_of_week
FROM data_mart.clean_weekly_sales;

-- B2. What range of week numbers are missing from the dataset?
SELECT string_agg(CAST(w AS VARCHAR), ', ' ORDER BY w) AS missing_week_numbers
FROM range(1, 54) AS t(w)
WHERE w NOT IN (SELECT DISTINCT week_number FROM data_mart.clean_weekly_sales);

-- B3. How many total transactions were there for each year?
SELECT calendar_year, SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;

-- B4. What is the total sales for each region for each month?
SELECT region, calendar_year, month_number, SUM(sales) AS total_sales
FROM data_mart.clean_weekly_sales
GROUP BY region, calendar_year, month_number
ORDER BY region, calendar_year, month_number;

-- B5. What is the total count of transactions for each platform?
SELECT platform, SUM(transactions) AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY platform
ORDER BY platform;

-- B6. What is the percentage of sales for Retail vs Shopify for each month?
SELECT
    calendar_year,
    month_number,
    ROUND(100.0 * SUM(sales) FILTER (WHERE platform = 'Retail')  / SUM(sales), 2) AS retail_pct,
    ROUND(100.0 * SUM(sales) FILTER (WHERE platform = 'Shopify') / SUM(sales), 2) AS shopify_pct
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, month_number
ORDER BY calendar_year, month_number;

-- B7. What is the percentage of sales by demographic for each year?
SELECT
    calendar_year,
    demographic,
    SUM(sales) AS total_sales,
    ROUND(100.0 * SUM(sales) / SUM(SUM(sales)) OVER (PARTITION BY calendar_year), 2) AS pct_of_year
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, demographic
ORDER BY calendar_year, demographic;

-- B8. Which age_band and demographic values contribute the most to Retail sales?
SELECT
    age_band,
    demographic,
    SUM(sales) AS retail_sales,
    ROUND(100.0 * SUM(sales) / SUM(SUM(sales)) OVER (), 2) AS pct_of_retail
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY retail_sales DESC;

-- B9. Can we use avg_transaction to find the average transaction size per year for
-- Retail vs Shopify? No: each row is already an average over a slice of very
-- different size (24 transactions vs 152,921), so averaging them weights every
-- slice equally. Use total sales / total transactions instead.
SELECT
    calendar_year,
    platform,
    ROUND(AVG(avg_transaction), 2)           AS wrong_avg_of_avgs,
    ROUND(SUM(sales) / SUM(transactions), 2) AS correct_avg_transaction
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;

-- =====================================================
-- C. BEFORE & AFTER ANALYSIS (baseline week 2020-06-15)
-- =====================================================

-- C1. Total sales for the 4 weeks before and after 2020-06-15: actual and % change
WITH windows AS (
    SELECT
        SUM(sales) FILTER (WHERE week_date >= DATE '2020-06-15' - 28
                             AND week_date <  DATE '2020-06-15')      AS before_sales,
        SUM(sales) FILTER (WHERE week_date >= DATE '2020-06-15'
                             AND week_date <  DATE '2020-06-15' + 28) AS after_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
)
SELECT
    before_sales,
    after_sales,
    after_sales - before_sales AS change_in_sales,
    ROUND(100.0 * (after_sales - before_sales) / before_sales, 2) AS pct_change
FROM windows;

-- C2. The same for the 12 weeks before and after, per region and in total
WITH windows AS (
    SELECT
        region,
        SUM(sales) FILTER (WHERE week_date >= DATE '2020-06-15' - 84
                             AND week_date <  DATE '2020-06-15')      AS before_sales,
        SUM(sales) FILTER (WHERE week_date >= DATE '2020-06-15'
                             AND week_date <  DATE '2020-06-15' + 84) AS after_sales
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
    GROUP BY region
),
combined AS (
    SELECT region, before_sales, after_sales FROM windows
    UNION ALL
    SELECT 'Total', SUM(before_sales), SUM(after_sales) FROM windows
)
SELECT
    region,
    before_sales,
    after_sales,
    after_sales - before_sales AS change_in_sales,
    ROUND(100.0 * (after_sales - before_sales) / before_sales, 2) AS pct_change
FROM combined
ORDER BY CASE WHEN region = 'Total' THEN 1 ELSE 0 END, region;

-- C3. How do the 4 and 12 week windows compare with 2018 and 2019?
-- Each year's baseline is the first week starting on or after 15 June, then the
-- exact same windows run around it. vs_prior_years_pp is 2020's % change minus the
-- average of 2018 and 2019, in percentage points: the closest estimate of the
-- packaging effect once seasonality is removed.
WITH baseline AS (
    SELECT calendar_year, MIN(week_date) AS base_week
    FROM data_mart.clean_weekly_sales
    WHERE week_date >= make_date(calendar_year::INTEGER, 6, 15)
    GROUP BY calendar_year
),
periods AS (
    SELECT * FROM (VALUES (4), (12)) AS t(weeks)
),
windows AS (
    SELECT
        c.calendar_year,
        p.weeks,
        SUM(c.sales) FILTER (WHERE c.week_date >= b.base_week - p.weeks * 7
                               AND c.week_date <  b.base_week)                 AS before_sales,
        SUM(c.sales) FILTER (WHERE c.week_date >= b.base_week
                               AND c.week_date <  b.base_week + p.weeks * 7)   AS after_sales
    FROM data_mart.clean_weekly_sales c
    JOIN baseline b ON c.calendar_year = b.calendar_year
    CROSS JOIN periods p
    GROUP BY c.calendar_year, p.weeks
),
results AS (
    SELECT
        calendar_year,
        weeks,
        before_sales,
        after_sales,
        after_sales - before_sales AS change_in_sales,
        ROUND(100.0 * (after_sales - before_sales) / before_sales, 2) AS pct_change
    FROM windows
)
SELECT
    *,
    ROUND(pct_change - AVG(pct_change) FILTER (WHERE calendar_year < 2020)
                           OVER (PARTITION BY weeks), 2) AS vs_prior_years_pp
FROM results
ORDER BY weeks, calendar_year;

-- =====================================================
-- D. BONUS: WHICH AREAS TOOK THE BIGGEST HIT (12 weeks before vs after, 2020)
-- =====================================================
-- Five dimensions stacked into one (dimension, value) shape so one aggregation
-- judges all of them by the same rules. Transactions are tracked next to sales:
-- falling transactions = customers not showing up; stable transactions with
-- falling sales = smaller baskets. Compare values WITHIN a dimension, and read
-- sales_change (dollars) next to the percentages, since percentages flatter small slices.
WITH tagged AS (
    SELECT
        region, platform, age_band, demographic, customer_type,
        sales, transactions,
        CASE
            WHEN week_date >= DATE '2020-06-15' - 84 AND week_date < DATE '2020-06-15'      THEN 'before'
            WHEN week_date >= DATE '2020-06-15'      AND week_date < DATE '2020-06-15' + 84 THEN 'after'
        END AS period
    FROM data_mart.clean_weekly_sales
    WHERE calendar_year = 2020
),
stacked AS (
    SELECT 'region'        AS dimension, region        AS value, period, sales, transactions FROM tagged WHERE period IS NOT NULL
    UNION ALL
    SELECT 'platform',                   platform,               period, sales, transactions FROM tagged WHERE period IS NOT NULL
    UNION ALL
    SELECT 'age_band',                   age_band,               period, sales, transactions FROM tagged WHERE period IS NOT NULL
    UNION ALL
    SELECT 'demographic',                demographic,            period, sales, transactions FROM tagged WHERE period IS NOT NULL
    UNION ALL
    SELECT 'customer_type',              customer_type,          period, sales, transactions FROM tagged WHERE period IS NOT NULL
),
agg AS (
    SELECT
        dimension,
        value,
        SUM(sales)        FILTER (WHERE period = 'before') AS sales_before,
        SUM(sales)        FILTER (WHERE period = 'after')  AS sales_after,
        SUM(transactions) FILTER (WHERE period = 'before') AS txn_before,
        SUM(transactions) FILTER (WHERE period = 'after')  AS txn_after
    FROM stacked
    GROUP BY dimension, value
)
SELECT
    dimension,
    value,
    sales_after - sales_before AS sales_change,
    ROUND(100.0 * (sales_after - sales_before) / sales_before, 2) AS sales_pct_change,
    ROUND(100.0 * (txn_after - txn_before) / txn_before, 2)       AS txn_pct_change,
    -- average basket on the correct grain: total sales / total transactions
    ROUND(sales_before / txn_before, 2) AS avg_txn_before,
    ROUND(sales_after  / txn_after,  2) AS avg_txn_after
FROM agg
ORDER BY dimension, sales_change;
