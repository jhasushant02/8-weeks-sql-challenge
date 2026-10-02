-- Case Study #1: Danny's Diner | MySQL 8+
USE dannys_diner;

-- Q1. Total amount each customer spent
SELECT s.customer_id, SUM(m.price) AS total_sales
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- Q2. Days each customer visited (DISTINCT so same-day orders count once)
SELECT customer_id, COUNT(DISTINCT order_date) AS visit_days
FROM sales
GROUP BY customer_id;

-- Q3. First item(s) purchased by each customer
-- dense_rank keeps every item bought on the first day; GROUP BY removes duplicate rows
WITH cte AS (
  SELECT s.customer_id, s.order_date, m.product_name,
         DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
  FROM sales s
  LEFT JOIN menu m ON s.product_id = m.product_id
)
SELECT customer_id, product_name
FROM cte
WHERE rnk = 1
GROUP BY customer_id, product_name;

-- Q4. Most purchased item and how many times it was purchased
SELECT m.product_name, COUNT(*) AS total_count
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_count DESC
LIMIT 1;

-- Q5. Most popular item for each customer (ties are kept)
WITH cte AS (
  SELECT s.customer_id, m.product_name, COUNT(*) AS order_count,
         DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rnk
  FROM sales s
  LEFT JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, order_count
FROM cte
WHERE rnk = 1;

-- Q6. First item purchased after becoming a member
-- Join date counts as a member day (>=), consistent with Q10 and the bonus questions
WITH cte AS (
  SELECT s.customer_id, s.order_date, me.product_name,
         DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
  FROM members m
  JOIN sales s ON m.customer_id = s.customer_id AND s.order_date >= m.join_date
  JOIN menu me ON s.product_id = me.product_id
)
SELECT customer_id, GROUP_CONCAT(product_name ORDER BY product_name) AS first_order
FROM cte
WHERE rnk = 1
GROUP BY customer_id
ORDER BY customer_id;

-- Q7. Item(s) purchased just before becoming a member
WITH cte AS (
  SELECT s.customer_id, s.order_date, me.product_name,
         DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
  FROM sales s
  JOIN members m ON s.customer_id = m.customer_id AND s.order_date < m.join_date
  JOIN menu me ON s.product_id = me.product_id
)
SELECT customer_id, GROUP_CONCAT(product_name ORDER BY product_name) AS last_order
FROM cte
WHERE rnk = 1
GROUP BY customer_id;

-- Q8. Total items and amount spent before becoming a member
SELECT s.customer_id,
       COUNT(*) AS items_purchased,
       SUM(me.price) AS total_spend
FROM sales s
JOIN members m ON s.customer_id = m.customer_id AND s.order_date < m.join_date
JOIN menu me ON s.product_id = me.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- Q9. Points: $1 = 10 points, sushi earns 2x
SELECT s.customer_id,
       SUM(CASE WHEN m.product_name = 'sushi' THEN m.price * 20
                ELSE m.price * 10 END) AS total_points
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- Q10. Points for A and B at end of January
-- Counts ALL January orders (not only post-join ones).
-- 2x applies to sushi always, and to every item in the first 7 days of membership (join date + 6 days).
SELECT s.customer_id,
       SUM(CASE
             WHEN me.product_name = 'sushi' THEN me.price * 20
             WHEN s.order_date BETWEEN m.join_date AND DATE_ADD(m.join_date, INTERVAL 6 DAY) THEN me.price * 20
             ELSE me.price * 10
           END) AS total_points
FROM sales s
JOIN members m ON s.customer_id = m.customer_id   -- inner join keeps only A and B
JOIN menu me ON s.product_id = me.product_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- Bonus 1. Join all the things
SELECT s.customer_id, s.order_date, m.product_name, m.price,
       CASE WHEN mem.join_date IS NOT NULL AND s.order_date >= mem.join_date THEN 'Y'
            ELSE 'N' END AS member
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mem ON s.customer_id = mem.customer_id
ORDER BY s.customer_id, s.order_date;

-- Bonus 2. Rank all the things (NULL ranking for non-member purchases)
WITH cte AS (
  SELECT s.customer_id, s.order_date, m.product_name, m.price,
         CASE WHEN mem.join_date IS NOT NULL AND s.order_date >= mem.join_date THEN 'Y'
              ELSE 'N' END AS member
  FROM sales s
  LEFT JOIN menu m ON s.product_id = m.product_id
  LEFT JOIN members mem ON s.customer_id = mem.customer_id
)
SELECT *,
       CASE WHEN member = 'Y'
            THEN DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
            ELSE NULL END AS ranking
FROM cte
ORDER BY customer_id, order_date;
