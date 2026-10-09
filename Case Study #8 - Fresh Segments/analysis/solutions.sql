-- Case Study #8: Fresh Segments | Dialect: DuckDB
-- Run data/schema.sql and load the data first.
-- Run in order: A1 converts month_year to a DATE and every later query relies on it,
-- and B5 creates the interest_metrics_filtered view used by Sets C and D.
USE fresh_segments;

-- =====================================================================
-- A. Data Exploration and Cleansing
-- =====================================================================

-- A1. Convert month_year to a DATE (first day of the month)
ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year TYPE DATE
USING strptime('01-' || month_year, '%d-%m-%Y')::DATE;

-- A2. Records per month_year, chronological, nulls first
SELECT
    month_year,
    count(*) AS records
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY month_year ASC NULLS FIRST;

-- A3. What is in the rows with no month?
-- Decision: keep them in the table, leave them out of the analysis.
SELECT
    count(*) AS null_month_rows,
    count(interest_id) AS with_interest_id,
    count(composition) AS with_composition
FROM fresh_segments.interest_metrics
WHERE month_year IS NULL;

-- A4. Interests in one table but not the other (anti-join, both directions)
SELECT
    (
        SELECT count(DISTINCT m.interest_id)
        FROM fresh_segments.interest_metrics m
        WHERE m.interest_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM fresh_segments.interest_map mp
              WHERE mp.id::VARCHAR = m.interest_id
          )
    ) AS in_metrics_not_in_map,
    (
        SELECT count(*)
        FROM fresh_segments.interest_map mp
        WHERE NOT EXISTS (
            SELECT 1
            FROM fresh_segments.interest_metrics m
            WHERE m.interest_id = mp.id::VARCHAR
        )
    ) AS in_map_not_in_metrics;

-- A5. Is id really a key in interest_map?
SELECT
    count(*) AS total_records,
    count(DISTINCT id) AS unique_ids,
    count(*) - count(DISTINCT id) AS duplicate_ids
FROM fresh_segments.interest_map;

-- A6. Join choice: LEFT JOIN from metrics to map. Check on interest_id = 21246.
SELECT
    m.*,
    mp.interest_name,
    mp.interest_summary,
    mp.created_at,
    mp.last_modified
FROM fresh_segments.interest_metrics m
LEFT JOIN fresh_segments.interest_map mp
    ON m.interest_id = mp.id::VARCHAR
WHERE m.interest_id = '21246';

-- A7. month_year before created_at? Checked at exact-date and month level.
-- month_year is always the 1st of the month while created_at has a day and time,
-- so the exact-date check can give a false alarm.
SELECT
    count(*) FILTER (
        WHERE m.month_year < mp.created_at
    ) AS before_created_exact_date,
    count(*) FILTER (
        WHERE m.month_year < date_trunc('month', mp.created_at)
    ) AS before_created_month_level
FROM fresh_segments.interest_metrics m
JOIN fresh_segments.interest_map mp
    ON m.interest_id = mp.id::VARCHAR
WHERE m.month_year IS NOT NULL;

-- =====================================================================
-- B. Interest Analysis
-- =====================================================================

-- B1. Interests present in all months
SELECT
    interest_id,
    count(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
WHERE month_year IS NOT NULL
  AND interest_id IS NOT NULL
GROUP BY interest_id
HAVING count(DISTINCT month_year) = (
    SELECT count(DISTINCT month_year)
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL
)
ORDER BY interest_id::INT;

-- B2. Cumulative percentage of interests, starting at 14 months
WITH interest_months AS (
    SELECT
        interest_id,
        count(DISTINCT month_year) AS total_months
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL
      AND interest_id IS NOT NULL
    GROUP BY interest_id
),
months_summary AS (
    SELECT
        total_months,
        count(*) AS number_of_interests
    FROM interest_months
    GROUP BY total_months
)
SELECT
    total_months,
    number_of_interests,
    round(
        100.0 * sum(number_of_interests) OVER (
            ORDER BY total_months DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / sum(number_of_interests) OVER (),
        2
    ) AS cumulative_pct
FROM months_summary
ORDER BY total_months DESC;

-- B3. Cost of the cutoff (fewer than 6 months), in interests and rows
WITH interest_months AS (
    SELECT
        interest_id,
        count(DISTINCT month_year) AS total_months
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL
      AND interest_id IS NOT NULL
    GROUP BY interest_id
)
SELECT
    count(DISTINCT m.interest_id) AS interests_removed,
    count(*) AS data_points_removed
FROM fresh_segments.interest_metrics m
WHERE m.month_year IS NOT NULL
  AND m.interest_id IN (
      SELECT interest_id
      FROM interest_months
      WHERE total_months < 6
  );

-- B4. Kept vs removed interests, side by side
WITH interest_months AS (
    SELECT
        interest_id,
        count(DISTINCT month_year) AS total_months,
        avg(composition) AS avg_composition,
        avg(ranking) AS avg_ranking
    FROM fresh_segments.interest_metrics
    WHERE month_year IS NOT NULL
      AND interest_id IS NOT NULL
    GROUP BY interest_id
)
SELECT
    CASE
        WHEN total_months < 6 THEN 'removed (fewer than 6 months)'
        ELSE 'kept (6+ months)'
    END AS bucket,
    count(*) AS interests,
    round(avg(total_months), 1) AS avg_months_present,
    round(avg(avg_composition)::NUMERIC, 2) AS avg_composition,
    round(avg(avg_ranking)::NUMERIC, 0) AS avg_ranking
FROM interest_months
GROUP BY bucket
ORDER BY bucket DESC;

-- B5. Filtered view (used by Sets C and D) and unique interests per month
CREATE OR REPLACE VIEW fresh_segments.interest_metrics_filtered AS
SELECT m.*
FROM fresh_segments.interest_metrics m
WHERE m.month_year IS NOT NULL
  AND m.interest_id IN (
      SELECT interest_id
      FROM fresh_segments.interest_metrics
      WHERE month_year IS NOT NULL
        AND interest_id IS NOT NULL
      GROUP BY interest_id
      HAVING count(DISTINCT month_year) >= 6
  );

SELECT
    month_year,
    count(DISTINCT interest_id) AS unique_interests
FROM fresh_segments.interest_metrics_filtered
GROUP BY month_year
ORDER BY month_year;

-- =====================================================================
-- C. Segment Analysis (filtered dataset)
-- =====================================================================

-- C1. Top 10 and bottom 10 interests by peak composition, with the peak month
WITH best_month AS (
    SELECT
        interest_id,
        month_year,
        composition,
        row_number() OVER (
            PARTITION BY interest_id
            ORDER BY composition DESC, month_year
        ) AS rn
    FROM fresh_segments.interest_metrics_filtered
),
interest_peak AS (
    SELECT
        b.interest_id,
        mp.interest_name,
        b.month_year,
        b.composition,
        rank() OVER (ORDER BY b.composition DESC) AS rank_high,
        rank() OVER (ORDER BY b.composition ASC) AS rank_low
    FROM best_month b
    JOIN fresh_segments.interest_map mp
        ON b.interest_id = mp.id::VARCHAR
    WHERE b.rn = 1
)
SELECT 'top 10' AS grp, interest_name, month_year, composition
FROM interest_peak
WHERE rank_high <= 10
UNION ALL
SELECT 'bottom 10' AS grp, interest_name, month_year, composition
FROM interest_peak
WHERE rank_low <= 10
ORDER BY grp DESC, composition DESC;

-- C2. 5 interests with the lowest average ranking (1 is best; ties kept)
WITH avg_rank AS (
    SELECT
        f.interest_id,
        mp.interest_name,
        avg(f.ranking) AS avg_ranking
    FROM fresh_segments.interest_metrics_filtered f
    JOIN fresh_segments.interest_map mp
        ON f.interest_id = mp.id::VARCHAR
    GROUP BY f.interest_id, mp.interest_name
),
ranked AS (
    SELECT
        *,
        rank() OVER (ORDER BY avg_ranking ASC) AS rnk
    FROM avg_rank
)
SELECT
    interest_name,
    round(avg_ranking::NUMERIC, 2) AS avg_ranking
FROM ranked
WHERE rnk <= 5
ORDER BY avg_ranking, interest_name;

-- C3. 5 interests with the largest standard deviation in percentile_ranking
WITH volatility AS (
    SELECT
        f.interest_id,
        mp.interest_name,
        stddev(f.percentile_ranking) AS std_percentile_ranking
    FROM fresh_segments.interest_metrics_filtered f
    JOIN fresh_segments.interest_map mp
        ON f.interest_id = mp.id::VARCHAR
    GROUP BY f.interest_id, mp.interest_name
),
ranked AS (
    SELECT
        *,
        rank() OVER (ORDER BY std_percentile_ranking DESC) AS rnk
    FROM volatility
)
SELECT
    interest_name,
    round(std_percentile_ranking::NUMERIC, 2) AS std_percentile_ranking
FROM ranked
WHERE rnk <= 5
ORDER BY std_percentile_ranking DESC, interest_name;

-- C4. Min and max percentile_ranking (with month) for those 5 interests
WITH volatility AS (
    SELECT
        interest_id,
        stddev(percentile_ranking) AS std_percentile_ranking
    FROM fresh_segments.interest_metrics_filtered
    GROUP BY interest_id
),
top_volatile AS (
    SELECT
        interest_id,
        rank() OVER (ORDER BY std_percentile_ranking DESC) AS rnk
    FROM volatility
),
numbered AS (
    SELECT
        f.interest_id,
        f.month_year,
        f.percentile_ranking,
        row_number() OVER (
            PARTITION BY f.interest_id
            ORDER BY f.percentile_ranking DESC
        ) AS rn_max,
        row_number() OVER (
            PARTITION BY f.interest_id
            ORDER BY f.percentile_ranking ASC
        ) AS rn_min
    FROM fresh_segments.interest_metrics_filtered f
    WHERE f.interest_id IN (
        SELECT interest_id FROM top_volatile WHERE rnk <= 5
    )
)
SELECT
    mp.interest_name,
    max(CASE WHEN n.rn_max = 1 THEN n.month_year END) AS max_month,
    max(CASE WHEN n.rn_max = 1 THEN n.percentile_ranking END) AS max_percentile_ranking,
    max(CASE WHEN n.rn_min = 1 THEN n.month_year END) AS min_month,
    max(CASE WHEN n.rn_min = 1 THEN n.percentile_ranking END) AS min_percentile_ranking
FROM numbered n
JOIN fresh_segments.interest_map mp
    ON n.interest_id = mp.id::VARCHAR
GROUP BY mp.interest_name
ORDER BY mp.interest_name;

-- C5. Strongest interests with their descriptions (supports the written answer)
WITH peak AS (
    SELECT
        interest_id,
        max(composition) AS peak_composition,
        avg(ranking) AS avg_ranking
    FROM fresh_segments.interest_metrics_filtered
    GROUP BY interest_id
)
SELECT
    mp.interest_name,
    mp.interest_summary,
    round(p.peak_composition::NUMERIC, 2) AS peak_composition,
    round(p.avg_ranking::NUMERIC, 0) AS avg_ranking
FROM peak p
JOIN fresh_segments.interest_map mp
    ON p.interest_id = mp.id::VARCHAR
ORDER BY p.peak_composition DESC
LIMIT 10;

-- =====================================================================
-- D. Index Analysis (filtered dataset)
-- average composition = round(composition / index_value, 2)
-- =====================================================================

-- D1. Top 10 interests by average composition, each month
WITH avg_comp AS (
    SELECT
        month_year,
        interest_id,
        round((composition / nullif(index_value, 0))::NUMERIC, 2) AS avg_composition
    FROM fresh_segments.interest_metrics_filtered
),
ranked AS (
    SELECT
        *,
        rank() OVER (
            PARTITION BY month_year
            ORDER BY avg_composition DESC
        ) AS rnk
    FROM avg_comp
)
SELECT
    r.month_year,
    mp.interest_name,
    r.avg_composition,
    r.rnk
FROM ranked r
JOIN fresh_segments.interest_map mp
    ON r.interest_id = mp.id::VARCHAR
WHERE r.rnk <= 10
ORDER BY r.month_year, r.rnk, mp.interest_name;

-- D2. Which interest appears most often in the monthly top 10?
WITH avg_comp AS (
    SELECT
        month_year,
        interest_id,
        round((composition / nullif(index_value, 0))::NUMERIC, 2) AS avg_composition
    FROM fresh_segments.interest_metrics_filtered
),
ranked AS (
    SELECT
        *,
        rank() OVER (
            PARTITION BY month_year
            ORDER BY avg_composition DESC
        ) AS rnk
    FROM avg_comp
),
top_10 AS (
    SELECT month_year, interest_id
    FROM ranked
    WHERE rnk <= 10
),
appearances AS (
    SELECT
        interest_id,
        count(*) AS months_in_top_10
    FROM top_10
    GROUP BY interest_id
),
ranked_appearances AS (
    SELECT
        *,
        rank() OVER (ORDER BY months_in_top_10 DESC) AS rnk
    FROM appearances
)
SELECT
    mp.interest_name,
    a.months_in_top_10
FROM ranked_appearances a
JOIN fresh_segments.interest_map mp
    ON a.interest_id = mp.id::VARCHAR
WHERE a.rnk = 1
ORDER BY mp.interest_name;

-- D3. Average of the top 10 average compositions, each month
WITH avg_comp AS (
    SELECT
        month_year,
        interest_id,
        round((composition / nullif(index_value, 0))::NUMERIC, 2) AS avg_composition
    FROM fresh_segments.interest_metrics_filtered
),
ranked AS (
    SELECT
        *,
        rank() OVER (
            PARTITION BY month_year
            ORDER BY avg_composition DESC
        ) AS rnk
    FROM avg_comp
)
SELECT
    month_year,
    round(avg(avg_composition), 2) AS avg_of_top_10
FROM ranked
WHERE rnk <= 10
GROUP BY month_year
ORDER BY month_year;

-- D4. 3-month rolling average of the monthly max average composition,
-- Sep 2018 to Aug 2019, with the leaders of the previous two months.
-- The window runs over all months first; the date filter comes last so
-- September 2018 still has two months behind it.
WITH avg_comp AS (
    SELECT
        month_year,
        interest_id,
        round((composition / nullif(index_value, 0))::NUMERIC, 2) AS avg_composition
    FROM fresh_segments.interest_metrics_filtered
),
monthly_top AS (
    SELECT
        a.month_year,
        mp.interest_name,
        a.avg_composition AS max_index_composition,
        row_number() OVER (
            PARTITION BY a.month_year
            ORDER BY a.avg_composition DESC, a.interest_id
        ) AS rn
    FROM avg_comp a
    JOIN fresh_segments.interest_map mp
        ON a.interest_id = mp.id::VARCHAR
),
leaders AS (
    SELECT month_year, interest_name, max_index_composition
    FROM monthly_top
    WHERE rn = 1
),
rolling AS (
    SELECT
        month_year,
        interest_name,
        max_index_composition,
        round(
            avg(max_index_composition) OVER (
                ORDER BY month_year
                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS three_month_moving_avg,
        lag(interest_name, 1) OVER (ORDER BY month_year) AS prev_1_name,
        lag(max_index_composition, 1) OVER (ORDER BY month_year) AS prev_1_value,
        lag(interest_name, 2) OVER (ORDER BY month_year) AS prev_2_name,
        lag(max_index_composition, 2) OVER (ORDER BY month_year) AS prev_2_value
    FROM leaders
)
SELECT
    month_year,
    interest_name,
    max_index_composition,
    three_month_moving_avg,
    prev_1_name || ': ' || prev_1_value::VARCHAR AS "1_month_ago",
    prev_2_name || ': ' || prev_2_value::VARCHAR AS "2_months_ago"
FROM rolling
WHERE month_year BETWEEN DATE '2018-09-01' AND DATE '2019-08-01'
ORDER BY month_year;

-- D5 is a written answer: see the README and the blog post.
