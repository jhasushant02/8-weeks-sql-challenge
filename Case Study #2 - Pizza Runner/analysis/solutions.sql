-- Case Study #2: Pizza Runner | DuckDB
-- Data notes:
--   * Missing values appear three ways: NULL, 'null' and '' (empty string).
--   * distance / duration contain unit text ('20km', '32 minutes').
--   * One row in customer_orders = one pizza, not one order.
--     Anything measured per order (pickup time, distance) must be collapsed
--     to order level before averaging or summing, or multi-pizza orders get counted too many times.

-- =====================================================
-- A. PIZZA METRICS
-- =====================================================

-- A1. How many pizzas were ordered?
SELECT COUNT(*) AS pizza_ordered
FROM pizza_runner.customer_orders;

-- A2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_order_cnt
FROM pizza_runner.customer_orders;

-- A3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS successful_order
FROM pizza_runner.runner_orders
WHERE distance != 'null'
GROUP BY runner_id
ORDER BY runner_id;

-- A4. How many of each type of pizza was delivered?
SELECT pizza_id, COUNT(order_id) AS pizza_delivered
FROM pizza_runner.customer_orders
WHERE order_id IN (
    SELECT order_id
    FROM pizza_runner.runner_orders
    WHERE distance != 'null'
)
GROUP BY pizza_id
ORDER BY pizza_id;

-- A5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    co.customer_id,
    SUM(CASE WHEN pn.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS vegetarian,
    SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS meatlovers
FROM pizza_runner.customer_orders co
LEFT JOIN pizza_runner.pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- A6. Which order had the most pizzas, and how many?
-- (Reworded from "maximum pizzas delivered in a single order". The answer is the same
--  because the largest order was delivered.)
SELECT order_id, customer_id, COUNT(*) AS pizza_count
FROM pizza_runner.customer_orders
GROUP BY order_id, customer_id
HAVING COUNT(*) = (
    SELECT MAX(pizza_count)
    FROM (
        SELECT order_id, COUNT(*) AS pizza_count
        FROM pizza_runner.customer_orders
        GROUP BY order_id
    ) x
)
ORDER BY order_id;

-- A7. For each customer, delivered pizzas with at least 1 change vs no changes
SELECT
    co.customer_id,
    SUM(CASE
            WHEN (co.exclusions IS NOT NULL AND co.exclusions NOT IN ('', 'null'))
              OR (co.extras IS NOT NULL AND co.extras NOT IN ('', 'null'))
            THEN 1 ELSE 0
        END) AS at_least_1_change,
    SUM(CASE
            WHEN (co.exclusions IS NULL OR co.exclusions IN ('', 'null'))
             AND (co.extras IS NULL OR co.extras IN ('', 'null'))
            THEN 1 ELSE 0
        END) AS no_changes
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- A8. Delivered pizzas that had both exclusions and extras
SELECT COUNT(*) AS pizzas_with_both_changes
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
WHERE (ro.cancellation IS NULL OR ro.cancellation IN ('', 'null'))
  AND co.exclusions NOT IN ('', 'null')
  AND co.extras NOT IN ('', 'null');

-- A9. Total volume of pizzas ordered for each hour of the day
SELECT EXTRACT(hour FROM order_time) AS order_hour, COUNT(*) AS pizza_count
FROM pizza_runner.customer_orders
GROUP BY order_hour
ORDER BY order_hour;

-- A10. Volume of orders for each day of the week
SELECT
    dayname(order_time) AS day_of_week,
    COUNT(DISTINCT order_id) AS order_count
FROM pizza_runner.customer_orders
GROUP BY dayofweek(order_time), dayname(order_time)
ORDER BY dayofweek(order_time);

-- =====================================================
-- B. RUNNER AND CUSTOMER EXPERIENCE
-- =====================================================

-- B1. Runners signed up in each 1-week period (week 1 starts 2021-01-01)
SELECT
    CAST(FLOOR(date_diff('day', DATE '2021-01-01', registration_date) / 7) + 1 AS INTEGER) AS week_number,
    COUNT(*) AS runner_count
FROM pizza_runner.runners
GROUP BY week_number
ORDER BY week_number;

-- B2. Average minutes for each runner to arrive at HQ and pick up the order
-- Collapsed to one row per order first, so a 3-pizza order doesn't count 3 times.
WITH orders AS (
    SELECT order_id, MIN(order_time) AS order_time
    FROM pizza_runner.customer_orders
    GROUP BY order_id
)
SELECT
    ro.runner_id,
    ROUND(AVG(date_diff('second', o.order_time, CAST(ro.pickup_time AS TIMESTAMP)) / 60.0), 2) AS avg_pickup_minutes
FROM orders o
JOIN pizza_runner.runner_orders ro ON o.order_id = ro.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
GROUP BY ro.runner_id
ORDER BY ro.runner_id;

-- B3. Relationship between number of pizzas and preparation time
WITH per_order AS (
    SELECT
        co.order_id,
        COUNT(*) AS pizza_count,
        date_diff('second', MIN(co.order_time), CAST(ro.pickup_time AS TIMESTAMP)) / 60.0 AS prep_minutes
    FROM pizza_runner.customer_orders co
    JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
    GROUP BY co.order_id, ro.pickup_time
)
SELECT
    pizza_count,
    COUNT(*) AS orders,
    ROUND(AVG(prep_minutes), 2) AS avg_prep_minutes
FROM per_order
GROUP BY pizza_count
ORDER BY pizza_count;

-- B4. Average distance travelled for each customer (per order, not per pizza)
WITH customer_order_list AS (
    SELECT DISTINCT customer_id, order_id
    FROM pizza_runner.customer_orders
)
SELECT
    c.customer_id,
    ROUND(AVG(CAST(regexp_extract(ro.distance, '[0-9.]+') AS DOUBLE)), 2) AS avg_distance_km
FROM customer_order_list c
JOIN pizza_runner.runner_orders ro ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
GROUP BY c.customer_id
ORDER BY c.customer_id;

-- B5. Difference between longest and shortest delivery times
SELECT
    MAX(CAST(regexp_extract(duration, '[0-9]+') AS INTEGER))
    - MIN(CAST(regexp_extract(duration, '[0-9]+') AS INTEGER)) AS delivery_time_difference
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL OR cancellation IN ('', 'null');

-- B6. Average speed for each runner for each delivery
SELECT
    runner_id,
    order_id,
    ROUND(
        CAST(regexp_extract(distance, '[0-9.]+') AS DOUBLE)
        / (CAST(regexp_extract(duration, '[0-9]+') AS DOUBLE) / 60),
        2
    ) AS avg_speed_kmh
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL OR cancellation IN ('', 'null')
ORDER BY runner_id, order_id;

-- B7. Successful delivery percentage for each runner
SELECT
    runner_id,
    ROUND(
        100.0 * SUM(CASE WHEN cancellation IS NULL OR cancellation IN ('', 'null') THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS successful_delivery_pct
FROM pizza_runner.runner_orders
GROUP BY runner_id
ORDER BY runner_id;

-- =====================================================
-- C. INGREDIENT OPTIMISATION
-- =====================================================

-- C1. Standard ingredients for each pizza
SELECT
    pn.pizza_name,
    string_agg(pt.topping_name, ', ' ORDER BY pt.topping_name) AS ingredients
FROM pizza_runner.pizza_recipes pr
JOIN pizza_runner.pizza_names pn ON pr.pizza_id = pn.pizza_id
CROSS JOIN unnest(string_split(pr.toppings, ', ')) AS t(topping_id)
JOIN pizza_runner.pizza_toppings pt ON CAST(t.topping_id AS INTEGER) = pt.topping_id
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- C2. Most commonly added extra
SELECT pt.topping_name, COUNT(*) AS extra_count
FROM pizza_runner.customer_orders co
CROSS JOIN unnest(string_split(co.extras, ', ')) AS e(topping_id)
JOIN pizza_runner.pizza_toppings pt ON CAST(e.topping_id AS INTEGER) = pt.topping_id
WHERE co.extras IS NOT NULL AND co.extras NOT IN ('', 'null')
GROUP BY pt.topping_name
ORDER BY extra_count DESC
LIMIT 1;

-- C3. Most common exclusion
SELECT pt.topping_name, COUNT(*) AS exclusion_count
FROM pizza_runner.customer_orders co
CROSS JOIN unnest(string_split(co.exclusions, ', ')) AS e(topping_id)
JOIN pizza_runner.pizza_toppings pt ON CAST(e.topping_id AS INTEGER) = pt.topping_id
WHERE co.exclusions IS NOT NULL AND co.exclusions NOT IN ('', 'null')
GROUP BY pt.topping_name
ORDER BY exclusion_count DESC
LIMIT 1;

-- C4. Order item description for each pizza
-- Each row of customer_orders gets a line_id. Order 4 has two identical pizzas and
-- order 10 has two Meatlovers with different changes, so joining on (order_id, pizza_id)
-- would merge or duplicate them. line_id keeps every pizza separate.
WITH lines AS (
    SELECT ROW_NUMBER() OVER (ORDER BY order_id, pizza_id, exclusions, extras) AS line_id, *
    FROM pizza_runner.customer_orders
),
exclusions AS (
    SELECT l.line_id,
           string_agg(pt.topping_name, ', ' ORDER BY pt.topping_name) AS exclusion_names
    FROM lines l
    CROSS JOIN unnest(string_split(l.exclusions, ', ')) AS e(topping_id)
    JOIN pizza_runner.pizza_toppings pt ON CAST(e.topping_id AS INTEGER) = pt.topping_id
    WHERE l.exclusions IS NOT NULL AND l.exclusions NOT IN ('', 'null')
    GROUP BY l.line_id
),
extras AS (
    SELECT l.line_id,
           string_agg(pt.topping_name, ', ' ORDER BY pt.topping_name) AS extra_names
    FROM lines l
    CROSS JOIN unnest(string_split(l.extras, ', ')) AS e(topping_id)
    JOIN pizza_runner.pizza_toppings pt ON CAST(e.topping_id AS INTEGER) = pt.topping_id
    WHERE l.extras IS NOT NULL AND l.extras NOT IN ('', 'null')
    GROUP BY l.line_id
)
SELECT
    l.order_id,
    pn.pizza_name
    || CASE WHEN e.exclusion_names IS NOT NULL THEN ' - Exclude ' || e.exclusion_names ELSE '' END
    || CASE WHEN x.extra_names IS NOT NULL THEN ' - Extra ' || x.extra_names ELSE '' END AS order_item
FROM lines l
JOIN pizza_runner.pizza_names pn ON l.pizza_id = pn.pizza_id
LEFT JOIN exclusions e ON l.line_id = e.line_id
LEFT JOIN extras x ON l.line_id = x.line_id
ORDER BY l.order_id, l.line_id;

-- C5. Alphabetical ingredient list for each pizza, with 2x for doubled ingredients
-- Recipe toppings, minus exclusions, plus extras. A topping that is both in the
-- recipe and added as an extra appears twice, hence 2x.
WITH lines AS (
    SELECT ROW_NUMBER() OVER (ORDER BY order_id, pizza_id, exclusions, extras) AS line_id, *
    FROM pizza_runner.customer_orders
),
base AS (
    SELECT l.line_id, CAST(t.topping_id AS INTEGER) AS topping_id
    FROM lines l
    JOIN pizza_runner.pizza_recipes pr ON l.pizza_id = pr.pizza_id
    CROSS JOIN unnest(string_split(pr.toppings, ', ')) AS t(topping_id)
),
excluded AS (
    SELECT l.line_id, CAST(e.topping_id AS INTEGER) AS topping_id
    FROM lines l
    CROSS JOIN unnest(string_split(l.exclusions, ', ')) AS e(topping_id)
    WHERE l.exclusions IS NOT NULL AND l.exclusions NOT IN ('', 'null')
),
added AS (
    SELECT l.line_id, CAST(x.topping_id AS INTEGER) AS topping_id
    FROM lines l
    CROSS JOIN unnest(string_split(l.extras, ', ')) AS x(topping_id)
    WHERE l.extras IS NOT NULL AND l.extras NOT IN ('', 'null')
),
final_toppings AS (
    SELECT b.line_id, b.topping_id
    FROM base b
    WHERE NOT EXISTS (
        SELECT 1 FROM excluded ex
        WHERE ex.line_id = b.line_id AND ex.topping_id = b.topping_id
    )
    UNION ALL
    SELECT line_id, topping_id FROM added
),
quantities AS (
    SELECT f.line_id, pt.topping_name, COUNT(*) AS quantity
    FROM final_toppings f
    JOIN pizza_runner.pizza_toppings pt ON f.topping_id = pt.topping_id
    GROUP BY f.line_id, pt.topping_name
)
SELECT
    l.order_id,
    pn.pizza_name || ': ' || string_agg(
        CASE WHEN q.quantity > 1
             THEN CAST(q.quantity AS VARCHAR) || 'x' || q.topping_name
             ELSE q.topping_name END,
        ', ' ORDER BY q.topping_name
    ) AS ingredient_list
FROM lines l
JOIN pizza_runner.pizza_names pn ON l.pizza_id = pn.pizza_id
JOIN quantities q ON l.line_id = q.line_id
GROUP BY l.line_id, l.order_id, pn.pizza_name
ORDER BY l.order_id, l.line_id;

-- C6. Total quantity of each ingredient used in all delivered pizzas, most frequent first
WITH lines AS (
    SELECT ROW_NUMBER() OVER (ORDER BY co.order_id, co.pizza_id, co.exclusions, co.extras) AS line_id, co.*
    FROM pizza_runner.customer_orders co
    JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
),
base AS (
    SELECT l.line_id, CAST(t.topping_id AS INTEGER) AS topping_id
    FROM lines l
    JOIN pizza_runner.pizza_recipes pr ON l.pizza_id = pr.pizza_id
    CROSS JOIN unnest(string_split(pr.toppings, ', ')) AS t(topping_id)
),
excluded AS (
    SELECT l.line_id, CAST(e.topping_id AS INTEGER) AS topping_id
    FROM lines l
    CROSS JOIN unnest(string_split(l.exclusions, ', ')) AS e(topping_id)
    WHERE l.exclusions IS NOT NULL AND l.exclusions NOT IN ('', 'null')
),
added AS (
    SELECT l.line_id, CAST(x.topping_id AS INTEGER) AS topping_id
    FROM lines l
    CROSS JOIN unnest(string_split(l.extras, ', ')) AS x(topping_id)
    WHERE l.extras IS NOT NULL AND l.extras NOT IN ('', 'null')
),
all_toppings AS (
    SELECT b.line_id, b.topping_id
    FROM base b
    WHERE NOT EXISTS (
        SELECT 1 FROM excluded ex
        WHERE ex.line_id = b.line_id AND ex.topping_id = b.topping_id
    )
    UNION ALL
    SELECT line_id, topping_id FROM added
)
SELECT pt.topping_name, COUNT(*) AS total_quantity
FROM all_toppings a
JOIN pizza_runner.pizza_toppings pt ON a.topping_id = pt.topping_id
GROUP BY pt.topping_name
ORDER BY total_quantity DESC, pt.topping_name;

-- =====================================================
-- D. PRICING AND RATINGS
-- =====================================================

-- D1. Meatlovers $12, Vegetarian $10, no charge for changes, no delivery fees
SELECT
    COALESCE(pn.pizza_name, 'Total') AS pizza_name,
    SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 12
             WHEN pn.pizza_name = 'Vegetarian' THEN 10 END) AS total_revenue
FROM pizza_runner.customer_orders co
JOIN pizza_runner.pizza_names pn ON co.pizza_id = pn.pizza_id
JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
GROUP BY ROLLUP(pn.pizza_name)
ORDER BY CASE WHEN pn.pizza_name IS NULL THEN 2 ELSE 1 END, pn.pizza_name;

-- D2. Same, plus $1 for each extra
SELECT
    COALESCE(pn.pizza_name, 'Total') AS pizza_name,
    SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 12
             WHEN pn.pizza_name = 'Vegetarian' THEN 10 END)
    + SUM(CASE WHEN co.extras IS NULL OR co.extras IN ('', 'null') THEN 0
               ELSE LENGTH(co.extras) - LENGTH(REPLACE(co.extras, ',', '')) + 1 END) AS total_revenue
FROM pizza_runner.customer_orders co
JOIN pizza_runner.pizza_names pn ON co.pizza_id = pn.pizza_id
JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
GROUP BY ROLLUP(pn.pizza_name)
ORDER BY CASE WHEN pn.pizza_name IS NULL THEN 2 ELSE 1 END, pn.pizza_name;

-- D3. New table for runner ratings (one rating per successful order)
-- The ratings below are made-up sample data.
DROP TABLE IF EXISTS pizza_runner.runner_ratings;
CREATE TABLE pizza_runner.runner_ratings (
    order_id INTEGER PRIMARY KEY,
    rating INTEGER,
    rating_time TIMESTAMP
);
INSERT INTO pizza_runner.runner_ratings (order_id, rating, rating_time) VALUES
    (1, 5, '2020-01-01 19:00:00'),
    (2, 4, '2020-01-01 20:00:00'),
    (3, 5, '2020-01-03 01:00:00'),
    (4, 3, '2020-01-04 14:30:00'),
    (5, 4, '2020-01-08 21:45:00'),
    (7, 5, '2020-01-08 22:00:00'),
    (8, 4, '2020-01-10 01:00:00'),
    (10, 5, '2020-01-11 19:30:00');

SELECT * FROM pizza_runner.runner_ratings ORDER BY order_id;

-- D4. Combined table for successful deliveries
SELECT
    co.customer_id,
    co.order_id,
    ro.runner_id,
    rr.rating,
    MIN(co.order_time) AS order_time,
    CAST(ro.pickup_time AS TIMESTAMP) AS pickup_time,
    date_diff('minute', MIN(co.order_time), CAST(ro.pickup_time AS TIMESTAMP)) AS time_to_pickup_min,
    CAST(regexp_extract(ro.duration, '[0-9]+') AS INTEGER) AS delivery_duration_min,
    ROUND(
        CAST(regexp_extract(ro.distance, '[0-9.]+') AS DOUBLE)
        / (CAST(regexp_extract(ro.duration, '[0-9]+') AS DOUBLE) / 60),
        2
    ) AS avg_speed_kmh,
    COUNT(*) AS total_pizzas
FROM pizza_runner.customer_orders co
JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
JOIN pizza_runner.runner_ratings rr ON co.order_id = rr.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
GROUP BY co.customer_id, co.order_id, ro.runner_id, rr.rating, ro.pickup_time, ro.duration, ro.distance
ORDER BY co.order_id;

-- D5. Revenue minus runner pay ($0.30 per km), fixed pizza prices, no extras charge
-- Revenue is pizza-level but distance is order-level, so they are calculated separately.
-- (Summing distance after joining to customer_orders repeats it once per pizza.)
WITH revenue AS (
    SELECT SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 12
                    WHEN pn.pizza_name = 'Vegetarian' THEN 10 END) AS total_revenue
    FROM pizza_runner.customer_orders co
    JOIN pizza_runner.pizza_names pn ON co.pizza_id = pn.pizza_id
    JOIN pizza_runner.runner_orders ro ON co.order_id = ro.order_id
    WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
),
runner_pay AS (
    SELECT SUM(CAST(regexp_extract(distance, '[0-9.]+') AS DOUBLE)) AS total_km
    FROM pizza_runner.runner_orders
    WHERE cancellation IS NULL OR cancellation IN ('', 'null')
)
SELECT
    r.total_revenue,
    p.total_km,
    ROUND(p.total_km * 0.30, 2) AS runner_payment,
    ROUND(r.total_revenue - p.total_km * 0.30, 2) AS money_left
FROM revenue r, runner_pay p;

-- =====================================================
-- E. BONUS: add a Supreme pizza with every topping
-- Run last, this changes the data.
-- =====================================================
INSERT INTO pizza_runner.pizza_names (pizza_id, pizza_name) VALUES (3, 'Supreme');
INSERT INTO pizza_runner.pizza_recipes (pizza_id, toppings) VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

SELECT * FROM pizza_runner.pizza_names ORDER BY pizza_id;
SELECT * FROM pizza_runner.pizza_recipes ORDER BY pizza_id;
