# Data

`schema.sql` creates the `fresh_segments` schema and two empty tables.

| Table | What one row is | Key columns |
|---|---|---|
| `interest_metrics` | one interest in one month for this client | `_month`, `_year`, `month_year`, `interest_id`, `composition`, `index_value`, `ranking`, `percentile_ranking` |
| `interest_map` | one interest and its description | `id`, `interest_name`, `interest_summary`, `created_at`, `last_modified` |

Data is provided by the challenge: https://8weeksqlchallenge.com/case-study-8/

## How to read the metrics columns

| Column | Meaning |
|---|---|
| `composition` | % of the client's customer list that interacted with this interest that month |
| `index_value` | the composition as a multiple of the average composition across all Fresh Segments clients for that interest and month |
| `ranking` | order of `index_value` within each month; 1 is the best |
| `percentile_ranking` | the same ordering as a percentile; higher is better |

## Loading the data

The challenge ships the rows as INSERT statements in a DB Fiddle (about 14k rows for `interest_metrics`), so they are not copied here. Either:

1. Paste the INSERT statements from the fiddle at the bottom of `schema.sql`, or
2. Export both tables to CSV, put them in this folder and uncomment the `COPY` lines.

## Things to watch for

- `month_year` is text like `07-2018`. It cannot be sorted, compared or truncated as a date until it is converted (question A1).
- Some rows have no month at all. They cannot be placed in time, so they cannot be part of any trend.
- `interest_id` is text in `interest_metrics` but an integer (`id`) in `interest_map`, so joins need a cast.
- Months run July 2018 to August 2019, so "present in all months" means all 14.
- Ties exist in `ranking`, so any "top N" has to decide how to treat them.
