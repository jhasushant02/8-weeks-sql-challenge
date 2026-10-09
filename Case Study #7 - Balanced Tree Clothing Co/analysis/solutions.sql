-- Case Study #7: Balanced Tree Clothing Co. | DuckDB
-- Data notes:
--   * sales is one row per product line within a transaction. It is not a
--     transaction and not a unit sold. A transaction is all rows sharing a
--     txn_id, so transaction counts use COUNT(DISTINCT txn_id).
--   * discount is a percentage. The discount amount is qty * price * discount / 100.
--     Use 100.0, not 100, so integer inputs never hit integer division.
--   * Revenue means revenue BEFORE discount (qty * price) unless a query says
--     otherwise. Net revenue (after discount) is shown only in B6.
--   * member and start_txn_time belong to the transaction but are stored on every
--     line, so transaction-level questions collapse to one row per txn_id first.
--   * Top selling = highest quantity. Revenue is shown next to it, since the two
--     can disagree. RANK keeps ties instead of dropping them with LIMIT.
--   * Product names and the hierarchy come from joining sales.prod_id to
--     product_details.product_id.
--
-- STATUS: sets A, B and C are solved. The Reporting Challenge (D) and the Bonus
-- Challenge (E) are NOT solved yet, see the placeholders at the bottom.

-- =====================================================
-- A. HIGH LEVEL SALES ANALYSIS
-- =====================================================

-- A1. What was the total quantity sold for all products?
SELECT SUM(qty) AS total_qty_sold
FROM balanced_tree.sales;

-- A2. What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) AS gross_revenue
FROM balanced_tree.sales;

-- A3. What was the total discount amount for all products?
SELECT ROUND(SUM(qty * price * discount / 100.0), 2) AS total_discount
FROM balanced_tree.sales;

-- =====================================================
-- B. TRANSACTION ANALYSIS
-- =====================================================

-- B1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS unique_transactions
FROM balanced_tree.sales;

-- B2. What is the average unique products purchased in each transaction?
-- Distinct products per transaction, then averaged. Not the average quantity.
WITH products_per_txn AS (
    SELECT
        txn_id,
        COUNT(DISTINCT prod_id) AS products
    FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT ROUND(AVG(products), 2) AS avg_unique_products_per_txn
FROM products_per_txn;

-- B3. What are the 25th, 50th and 75th percentile values for the revenue per
-- transaction? Revenue per transaction is a sum over its lines, so build it in a
-- CTE first. quantile_cont interpolates between values (continuous percentile).
WITH txn_revenue AS (
    SELECT
        txn_id,
        SUM(qty * price) AS revenue
    FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT
    ROUND(quantile_cont(revenue, 0.25), 2) AS p25_revenue,
    ROUND(quantile_cont(revenue, 0.50), 2) AS p50_revenue,
    ROUND(quantile_cont(revenue, 0.75), 2) AS p75_revenue
FROM txn_revenue;

-- B4. What is the average discount value per transaction?
-- Per transaction, not per line: sum within each transaction, then average.
WITH txn_discount AS (
    SELECT
        txn_id,
        SUM(qty * price * discount / 100.0) AS discount_amount
    FROM balanced_tree.sales
    GROUP BY txn_id
)
SELECT ROUND(AVG(discount_amount), 2) AS avg_discount_per_txn
FROM txn_discount;

-- B5. What is the percentage split of all transactions for members vs
-- non-members? Collapse to one row per transaction first, so a basket with five
-- products counts once. The window sum is the total to divide by.
WITH txns AS (
    SELECT DISTINCT txn_id, member
    FROM balanced_tree.sales
)
SELECT
    CASE WHEN member THEN 'member' ELSE 'non-member' END AS customer_type,
    COUNT(*) AS transactions,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_transactions
FROM txns
GROUP BY customer_type
ORDER BY customer_type;

-- B6. What is the average revenue for member transactions and non-member
-- transactions? Gross revenue answers the question as asked. Net revenue sits
-- next to it, because members may get bigger discounts.
WITH txn_revenue AS (
    SELECT
        txn_id,
        member,
        SUM(qty * price) AS gross_revenue,
        SUM(qty * price * (1 - discount / 100.0)) AS net_revenue
    FROM balanced_tree.sales
    GROUP BY txn_id, member
)
SELECT
    CASE WHEN member THEN 'member' ELSE 'non-member' END AS customer_type,
    COUNT(*) AS transactions,
    ROUND(AVG(gross_revenue), 2) AS avg_gross_revenue,
    ROUND(AVG(net_revenue), 2)   AS avg_net_revenue
FROM txn_revenue
GROUP BY customer_type
ORDER BY customer_type;

-- =====================================================
-- C. PRODUCT ANALYSIS
-- =====================================================

-- C1. What are the top 3 products by total revenue before discount?
SELECT
    pd.product_name,
    SUM(s.qty * s.price) AS revenue
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd
    ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY revenue DESC
LIMIT 3;

-- C2. What is the total quantity, revenue and discount for each segment?
SELECT
    pd.segment_name,
    SUM(s.qty) AS total_qty,
    SUM(s.qty * s.price) AS revenue,
    ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS discount_amount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd
    ON s.prod_id = pd.product_id
GROUP BY pd.segment_name
ORDER BY pd.segment_name;

-- C3. What is the top selling product for each segment?
-- QUALIFY filters on the window result directly. RANK (not ROW_NUMBER) keeps ties.
WITH product_sales AS (
    SELECT
        pd.segment_name,
        pd.product_name,
        SUM(s.qty) AS total_qty,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.segment_name, pd.product_name
)
SELECT
    segment_name,
    product_name,
    total_qty,
    revenue
FROM product_sales
QUALIFY RANK() OVER (PARTITION BY segment_name ORDER BY total_qty DESC) = 1
ORDER BY segment_name;

-- C4. What is the total quantity, revenue and discount for each category?
SELECT
    pd.category_name,
    SUM(s.qty) AS total_qty,
    SUM(s.qty * s.price) AS revenue,
    ROUND(SUM(s.qty * s.price * s.discount / 100.0), 2) AS discount_amount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd
    ON s.prod_id = pd.product_id
GROUP BY pd.category_name
ORDER BY pd.category_name;

-- C5. What is the top selling product for each category?
WITH product_sales AS (
    SELECT
        pd.category_name,
        pd.product_name,
        SUM(s.qty) AS total_qty,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name, pd.product_name
)
SELECT
    category_name,
    product_name,
    total_qty,
    revenue
FROM product_sales
QUALIFY RANK() OVER (PARTITION BY category_name ORDER BY total_qty DESC) = 1
ORDER BY category_name;

-- C6. What is the percentage split of revenue by product for each segment?
-- Each product's share of its own segment; percentages within a segment add to 100.
WITH product_revenue AS (
    SELECT
        pd.segment_name,
        pd.product_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.segment_name, pd.product_name
)
SELECT
    segment_name,
    product_name,
    revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (PARTITION BY segment_name), 2) AS pct_of_segment_revenue
FROM product_revenue
ORDER BY segment_name, pct_of_segment_revenue DESC;

-- C7. What is the percentage split of revenue by segment for each category?
WITH segment_revenue AS (
    SELECT
        pd.category_name,
        pd.segment_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name, pd.segment_name
)
SELECT
    category_name,
    segment_name,
    revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (PARTITION BY category_name), 2) AS pct_of_category_revenue
FROM segment_revenue
ORDER BY category_name, pct_of_category_revenue DESC;

-- C8. What is the percentage split of total revenue by category?
-- An empty window, OVER (), makes the denominator the grand total.
WITH category_revenue AS (
    SELECT
        pd.category_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
    GROUP BY pd.category_name
)
SELECT
    category_name,
    revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 2) AS pct_of_total_revenue
FROM category_revenue
ORDER BY pct_of_total_revenue DESC;

-- C9. What is the total transaction "penetration" for each product?
-- Penetration = transactions containing the product / total transactions.
-- A share of baskets, not a share of units.
SELECT
    pd.product_name,
    COUNT(DISTINCT s.txn_id) AS txns_with_product,
    ROUND(
        100.0 * COUNT(DISTINCT s.txn_id)
        / (SELECT COUNT(DISTINCT txn_id) FROM balanced_tree.sales),
        2
    ) AS penetration_pct
FROM balanced_tree.sales s
JOIN balanced_tree.product_details pd
    ON s.prod_id = pd.product_id
GROUP BY pd.product_name
ORDER BY penetration_pct DESC;

-- C10. What is the most common combination of at least 1 quantity of any 3
-- products in a single transaction?
-- txn_products: one row per transaction and product, deduplicated. The CTE is
-- joined to itself three times on txn_id. The condition t1 < t2 < t3 on product
-- name makes each combination appear once, in a fixed order, so (A, B, C) is not
-- also counted as (B, A, C). RANK keeps ties for first place.
WITH txn_products AS (
    SELECT DISTINCT
        s.txn_id,
        pd.product_name
    FROM balanced_tree.sales s
    JOIN balanced_tree.product_details pd
        ON s.prod_id = pd.product_id
)
SELECT
    t1.product_name AS product_1,
    t2.product_name AS product_2,
    t3.product_name AS product_3,
    COUNT(*) AS txns_together
FROM txn_products t1
JOIN txn_products t2
    ON t1.txn_id = t2.txn_id
   AND t1.product_name < t2.product_name
JOIN txn_products t3
    ON t1.txn_id = t3.txn_id
   AND t2.product_name < t3.product_name
GROUP BY t1.product_name, t2.product_name, t3.product_name
QUALIFY RANK() OVER (ORDER BY COUNT(*) DESC) = 1;

-- =====================================================
-- D. REPORTING CHALLENGE   >>> NOT SOLVED YET <<<
-- =====================================================
-- Brief: write a single SQL script that combines all of the previous questions
-- into a scheduled report the Balanced Tree team can run at the beginning of each
-- month to calculate the previous month's values. Generate the data for January
-- only, then show the same analysis runs for February without many changes (if at
-- all). Split outputs into as many tables as needed, and explicitly reference
-- which table outputs relate to which question.
--
-- TODO: solve, then add the output tables, the January run and the February run.


-- =====================================================
-- E. BONUS CHALLENGE   >>> NOT SOLVED YET <<<
-- =====================================================
-- Brief: use a single SQL query to transform the product_hierarchy and
-- product_prices datasets into the product_details table.
-- Hint from the challenge: consider a recursive CTE.
--
-- TODO: solve, then check the result against product_details in both directions
-- (EXCEPT one way, then the other).
