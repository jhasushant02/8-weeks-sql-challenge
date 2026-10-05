-- Case Study #6: Clique Bait | DuckDB
-- Data notes:
--   * events is one row per logged event. It is not a visit and not a user.
--     A visit is all events sharing a visit_id; a user owns several cookies.
--     Users, cookies, visits and events are four different counts.
--   * events carries cookie_id, not user_id. Getting to a user means joining
--     through users.
--   * A purchase (event_type 3) is logged on the Confirmation page, which has no
--     product. Product-level purchases are inferred from cart adds (event_type 2)
--     in a visit that has a purchase event. Abandoned = cart add in a visit with
--     no purchase.
--   * campaign_identifier end dates are midnight timestamps, so the campaign
--     join compares against end_date + 1 day to keep the whole last day.
--   * Event types: 1 Page View, 2 Add to Cart, 3 Purchase, 4 Ad Impression,
--     5 Ad Click.

-- =====================================================
-- A. DIGITAL ANALYSIS
-- =====================================================

-- A1. How many users are there?
SELECT COUNT(DISTINCT user_id) AS user_count
FROM clique_bait.users;

-- A2. How many cookies does each user have on average?
WITH cookies_per_user AS (
    SELECT
        user_id,
        COUNT(DISTINCT cookie_id) AS cookies
    FROM clique_bait.users
    GROUP BY user_id
)
SELECT ROUND(AVG(cookies), 2) AS avg_cookies_per_user
FROM cookies_per_user;

-- A3. What is the unique number of visits by all users per month?
-- A visit can run past midnight, so it is assigned to the month of its earliest
-- event instead of being counted once per month it touches.
WITH visit_start AS (
    SELECT
        visit_id,
        MIN(event_time) AS visit_start_time
    FROM clique_bait.events
    GROUP BY visit_id
)
SELECT
    date_trunc('month', visit_start_time)::DATE AS month,
    COUNT(*) AS unique_visits
FROM visit_start
GROUP BY month
ORDER BY month;

-- A4. What is the number of events for each event type?
SELECT
    ei.event_type,
    ei.event_name,
    COUNT(*) AS event_count
FROM clique_bait.events e
JOIN clique_bait.event_identifier ei
    ON e.event_type = ei.event_type
GROUP BY ei.event_type, ei.event_name
ORDER BY ei.event_type;

-- A5. What is the percentage of visits which have a purchase event?
SELECT
    ROUND(
        100.0 * COUNT(DISTINCT visit_id) FILTER (WHERE event_type = 3)
        / COUNT(DISTINCT visit_id),
        2
    ) AS purchase_visit_pct
FROM clique_bait.events;

-- A6. What is the percentage of visits which view the checkout page but do not
-- have a purchase event? (Base: all visits.)
WITH visit_flags AS (
    SELECT
        visit_id,
        MAX(CASE WHEN page_id = 12 AND event_type = 1 THEN 1 ELSE 0 END) AS viewed_checkout,
        MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END)                   AS purchased
    FROM clique_bait.events
    GROUP BY visit_id
)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN viewed_checkout = 1 AND purchased = 0 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS checkout_no_purchase_pct
FROM visit_flags;

-- A7. What are the top 3 pages by number of views?
SELECT
    ph.page_name,
    COUNT(*) AS page_views
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
    ON e.page_id = ph.page_id
WHERE e.event_type = 1
GROUP BY ph.page_name
ORDER BY page_views DESC
LIMIT 3;

-- A8. What is the number of views and cart adds for each product category?
SELECT
    ph.product_category,
    COUNT(*) FILTER (WHERE e.event_type = 1) AS page_views,
    COUNT(*) FILTER (WHERE e.event_type = 2) AS cart_adds
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
    ON e.page_id = ph.page_id
WHERE ph.product_id IS NOT NULL
GROUP BY ph.product_category
ORDER BY ph.product_category;

-- A9. What are the top 3 products by purchases?
-- The purchase event sits on the Confirmation page, so find the purchasing
-- visits and count the products added to the cart inside them.
WITH purchase_visits AS (
    SELECT DISTINCT visit_id
    FROM clique_bait.events
    WHERE event_type = 3
)
SELECT
    ph.page_name AS product,
    COUNT(*) AS purchases
FROM clique_bait.events e
JOIN clique_bait.page_hierarchy ph
    ON e.page_id = ph.page_id
JOIN purchase_visits pv
    ON e.visit_id = pv.visit_id
WHERE e.event_type = 2
  AND ph.product_id IS NOT NULL
GROUP BY ph.page_name
ORDER BY purchases DESC
LIMIT 3;

-- =====================================================
-- B. PRODUCT FUNNEL ANALYSIS
-- =====================================================

-- B1. One table: views, cart adds, abandoned carts and purchases per product.
-- Step 1: one row per visit and product (views and cart adds as sums).
-- Step 2: the visits that contain a purchase.
-- Step 3: left join; a non-null match means the visit ended in a purchase.
CREATE OR REPLACE TABLE clique_bait.product_funnel AS
WITH product_page_events AS (
    SELECT
        e.visit_id,
        ph.product_id,
        ph.page_name AS product,
        ph.product_category,
        SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_view,  -- 1 = Page View
        SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_add    -- 2 = Add to Cart
    FROM clique_bait.events AS e
    JOIN clique_bait.page_hierarchy AS ph
        ON e.page_id = ph.page_id
    WHERE ph.product_id IS NOT NULL
    GROUP BY e.visit_id, ph.product_id, ph.page_name, ph.product_category
),

purchase_events AS (
    SELECT DISTINCT visit_id
    FROM clique_bait.events
    WHERE event_type = 3                                                 -- 3 = Purchase
),

combined_table AS (
    SELECT
        ppe.*,
        CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
    FROM product_page_events AS ppe
    LEFT JOIN purchase_events AS pe
        ON ppe.visit_id = pe.visit_id
)

SELECT
    product_id,
    product,
    product_category,
    SUM(page_view) AS views,
    SUM(cart_add)  AS cart_adds,
    SUM(CASE WHEN cart_add = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN cart_add = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchased
FROM combined_table
GROUP BY product_id, product, product_category;

SELECT * FROM clique_bait.product_funnel ORDER BY product_id;

-- B2. The same metrics per product category. All four are plain counts, so the
-- category table is the product table grouped up; nothing is recomputed.
CREATE OR REPLACE TABLE clique_bait.product_category_funnel AS
SELECT
    product_category,
    SUM(views)     AS views,
    SUM(cart_adds) AS cart_adds,
    SUM(abandoned) AS abandoned,
    SUM(purchased) AS purchased
FROM clique_bait.product_funnel
GROUP BY product_category;

SELECT * FROM clique_bait.product_category_funnel
ORDER BY product_category;

-- B3. Which product had the most views, cart adds and purchases?
SELECT
    arg_max(product, views)     AS most_views,
    arg_max(product, cart_adds) AS most_cart_adds,
    arg_max(product, purchased) AS most_purchases
FROM clique_bait.product_funnel;

-- B4. Which product was most likely to be abandoned?
-- "Most likely" is a rate question: abandoned / cart_adds, not a raw count.
-- dense_rank keeps ties for first place; the rank uses the unrounded rate so
-- rounding cannot create false ties.
WITH ranked_funnel AS (
    SELECT
        product,
        cart_adds,
        abandoned,
        ROUND(100.0 * abandoned / cart_adds, 2) AS abandon_rate_pct,
        DENSE_RANK() OVER (ORDER BY 100.0 * abandoned / cart_adds DESC) AS rnk
    FROM clique_bait.product_funnel
    WHERE cart_adds > 0
)
SELECT
    product,
    cart_adds,
    abandoned,
    abandon_rate_pct
FROM ranked_funnel
WHERE rnk = 1;

-- B5. Which product had the highest view to purchase percentage?
-- 100.0, not 100: with two integer columns, 100 * purchased / views is integer
-- division in many engines.
WITH ranked_conversion AS (
    SELECT
        product,
        product_category,
        views,
        purchased,
        ROUND(100.0 * purchased / views, 2) AS purchase_per_view_pct,
        DENSE_RANK() OVER (ORDER BY 100.0 * purchased / views DESC) AS rnk
    FROM clique_bait.product_funnel
    WHERE views > 0
)
SELECT
    product,
    product_category,
    purchase_per_view_pct
FROM ranked_conversion
WHERE rnk = 1;

-- B6. Average conversion rate from view to cart add, and from cart add to
-- purchase. Per-product rates averaged, so every product has equal weight.
-- For a traffic-weighted rate use SUM(cart_adds) / SUM(views) instead.
SELECT
    ROUND(100.0 * AVG(cart_adds / views::DECIMAL), 2)     AS avg_view_to_cart_add_pct,
    ROUND(100.0 * AVG(purchased / cart_adds::DECIMAL), 2) AS avg_cart_add_to_purchase_pct
FROM clique_bait.product_funnel;

-- =====================================================
-- C. CAMPAIGNS ANALYSIS
-- =====================================================

-- C1. One row per visit_id: start time, page views, cart adds, purchase flag,
-- campaign, impressions, clicks and cart products (in the order added).
-- Visits outside any campaign stay in with a NULL campaign_name.
DROP TABLE IF EXISTS clique_bait.campaign_summary;

CREATE TABLE clique_bait.campaign_summary AS
WITH visits AS (
    SELECT
        u.user_id,
        e.visit_id,
        MIN(e.event_time) AS visit_start_time,
        COUNT(*) FILTER (WHERE e.event_type = 1) AS page_views,
        COUNT(*) FILTER (WHERE e.event_type = 2) AS cart_adds,
        MAX(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchase,
        COUNT(*) FILTER (WHERE e.event_type = 4) AS impression,
        COUNT(*) FILTER (WHERE e.event_type = 5) AS click
    FROM clique_bait.events e
    JOIN clique_bait.users u
        ON e.cookie_id = u.cookie_id
    GROUP BY u.user_id, e.visit_id
),

cart AS (
    SELECT
        e.visit_id,
        string_agg(ph.page_name, ', ' ORDER BY e.sequence_number) AS cart_products
    FROM clique_bait.events e
    JOIN clique_bait.page_hierarchy ph
        ON e.page_id = ph.page_id
    WHERE e.event_type = 2
    GROUP BY e.visit_id
)

SELECT
    v.user_id,
    v.visit_id,
    v.visit_start_time,
    v.page_views,
    v.cart_adds,
    v.purchase,
    c.campaign_name,
    v.impression,
    v.click,
    ct.cart_products
FROM visits v
LEFT JOIN clique_bait.campaign_identifier c
    ON v.visit_start_time >= c.start_date
   AND v.visit_start_time <  c.end_date + INTERVAL 1 DAY
LEFT JOIN cart ct
    ON v.visit_id = ct.visit_id
ORDER BY v.user_id, v.visit_start_time;

SELECT * FROM clique_bait.campaign_summary LIMIT 10;

-- C2. Insight 1: do visits with an ad impression purchase more than visits
-- without?
SELECT
    campaign_name,
    CASE WHEN impression > 0 THEN 'received impression' ELSE 'no impression' END AS exposure,
    COUNT(*) AS visits,
    ROUND(100.0 * AVG(purchase), 2) AS purchase_rate,
    ROUND(AVG(page_views), 2)       AS avg_page_views,
    ROUND(AVG(cart_adds), 2)        AS avg_cart_adds
FROM clique_bait.campaign_summary
WHERE campaign_name IS NOT NULL
GROUP BY campaign_name, exposure
ORDER BY campaign_name, exposure;

-- C3. Insight 2: does clicking on an impression lead to higher purchase rates,
-- and what is the uplift? Three groups: clicked, impression only, no impression.
-- An association, not proof the ad caused the purchase: people who click are
-- probably more engaged to begin with.
WITH grouped AS (
    SELECT
        CASE
            WHEN click > 0      THEN 'clicked'
            WHEN impression > 0 THEN 'impression, no click'
            ELSE 'no impression'
        END AS grp,
        purchase
    FROM clique_bait.campaign_summary
    WHERE campaign_name IS NOT NULL
),

rates AS (
    SELECT
        grp,
        COUNT(*) AS visits,
        ROUND(100.0 * AVG(purchase), 2) AS purchase_rate
    FROM grouped
    GROUP BY grp
)

SELECT
    grp,
    visits,
    purchase_rate,
    ROUND(100.0 * (purchase_rate - (SELECT purchase_rate FROM rates WHERE grp = 'no impression'))
          / (SELECT purchase_rate FROM rates WHERE grp = 'no impression'), 2) AS uplift_vs_no_impression_pct,
    ROUND(100.0 * (purchase_rate - (SELECT purchase_rate FROM rates WHERE grp = 'impression, no click'))
          / (SELECT purchase_rate FROM rates WHERE grp = 'impression, no click'), 2) AS uplift_vs_impression_only_pct
FROM rates
ORDER BY purchase_rate DESC;

-- C4. Insight 3: how do the three campaigns compare with each other and with no
-- campaign? Visits outside any campaign are the baseline row.
SELECT
    COALESCE(campaign_name, 'No campaign') AS campaign,
    COUNT(*) AS visits,
    ROUND(100.0 * AVG(purchase), 2) AS purchase_rate,
    ROUND(100.0 * AVG(CASE WHEN impression > 0 THEN 1 ELSE 0 END), 2) AS impression_reach_pct,
    ROUND(100.0 * SUM(click) / NULLIF(SUM(impression), 0), 2) AS click_through_rate,
    ROUND(AVG(cart_adds), 2) AS avg_cart_adds
FROM clique_bait.campaign_summary
GROUP BY campaign
ORDER BY campaign;

-- C5. Insight 4: where does cart abandonment sit across campaigns?
-- Among visits with something in the cart, the share that did not purchase.
SELECT
    COALESCE(campaign_name, 'No campaign') AS campaign,
    COUNT(*) FILTER (WHERE cart_adds > 0) AS visits_with_cart,
    COUNT(*) FILTER (WHERE cart_adds > 0 AND purchase = 0) AS abandoned_visits,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE cart_adds > 0 AND purchase = 0)
        / NULLIF(COUNT(*) FILTER (WHERE cart_adds > 0), 0),
        2
    ) AS abandonment_rate
FROM clique_bait.campaign_summary
GROUP BY campaign
ORDER BY campaign;

-- C6. Insight 5: how do purchasing visits differ from non-purchasing visits?
SELECT
    CASE WHEN purchase = 1 THEN 'purchased' ELSE 'did not purchase' END AS outcome,
    COUNT(*) AS visits,
    ROUND(AVG(page_views), 2) AS avg_page_views,
    ROUND(AVG(cart_adds), 2)  AS avg_cart_adds,
    ROUND(100.0 * AVG(CASE WHEN impression > 0 THEN 1 ELSE 0 END), 2) AS pct_with_impression
FROM clique_bait.campaign_summary
GROUP BY outcome
ORDER BY outcome;
