# Results

Add a screenshot of each result grid to this folder (for example `a01.png` ... `d01.png`).
Run `data/schema.sql` (with the insert pasted in), then `analysis/solutions.sql` in DuckDB.
Cells marked "fill in" depend on the full run; paste the value from your own output.

## A. Data cleansing

| Item | Result |
|---|---|
| `clean_weekly_sales` | One row per `weekly_sales` row. Columns in order: week_date, week_number, month_number, calendar_year, region, platform, segment, age_band, demographic, customer_type, transactions, sales, avg_transaction. Missing segments show `unknown` in segment, age_band and demographic. |

## B. Data exploration

| Q | Question | Result |
|---|---|---|
| B1 | Day of week used for week_date | Monday |
| B2 | Missing week numbers | fill in |
| B3 | Total transactions per year | fill in (2018, 2019, 2020) |
| B4 | Total sales per region per month | fill in |
| B5 | Total transactions per platform | fill in (Retail, Shopify) |
| B6 | Retail vs Shopify % of sales per month | fill in |
| B7 | % of sales by demographic per year | fill in (Couples, Families, unknown) |
| B8 | Age band and demographic contribution to Retail sales | fill in |
| B9 | Average transaction size, wrong vs correct | fill in (the two columns should differ; use `correct_avg_transaction`) |

## C. Before & after analysis

| Q | Question | Result |
|---|---|---|
| C1 | 4 weeks before vs after 2020-06-15 | before: fill in, after: fill in, change: fill in, % change: fill in |
| C2 | 12 weeks before vs after, per region and total | fill in (one row per region plus Total) |
| C3 | 4 and 12 week windows for 2018, 2019, 2020 | fill in (one row per year per window), plus `vs_prior_years_pp` for 2020 |

## D. Bonus

| Item | Result |
|---|---|
| D1 | Sales change, % change and transaction % change for every value of region, platform, age_band, demographic and customer_type, ordered by dollar change within each dimension: fill in |

## Extension: recommendations

Written up in the main [README](../README.md) and the blog post: phased rollout, early communication aimed at the worst-hit segments, weekly tracking of transactions and basket size for 12 weeks, and cleaning up the `unknown` segment data.
