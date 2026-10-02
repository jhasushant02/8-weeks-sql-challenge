# Data

`schema.sql` creates the `foodie_fi` schema and loads two tables:

| Table | What it holds | Rows |
|---|---|---|
| `plans` | plan_id, plan_name, price (trial, basic monthly, pro monthly, pro annual, churn) | 5 |
| `subscriptions` | one row per plan change: customer_id, plan_id, start_date | one per event, 1,000 customers |

Data is provided by the challenge: https://8weeksqlchallenge.com/case-study-3/

## The data is clean, but the dates are not literal

- `subscriptions` is an event log, not a snapshot. A customer's current plan is their **latest** row, not any single row.
- `start_date` means different things by plan: a downgrade takes effect at the end of the billing period, an upgrade can start immediately, and a churned customer keeps access until the period ends even though the churn row appears earlier.
- `churn` (plan_id 4) has a `NULL` price. It is an event, not a plan someone pays for.
- Data covers 2020 plus a few months of 2021, so "after 2020" questions only see a partial year.

The queries in `analysis/solutions.sql` handle this with `LEAD`, `LAG`, `ROW_NUMBER` and `string_agg` over each customer's timeline.

## To reproduce

The queries are written for **DuckDB**. Open a DuckDB session (CLI, Python, or a DuckDB workbench), run `schema.sql`, then run `../analysis/solutions.sql`. Section C drops and rebuilds `foodie_fi.payments`, so it is safe to re-run.
