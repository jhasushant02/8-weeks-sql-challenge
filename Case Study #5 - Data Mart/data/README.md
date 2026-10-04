# Data

`schema.sql` creates the `data_mart` schema and loads one table:

| Table | What it holds | Rows |
|---|---|---|
| `weekly_sales` | one row per weekly slice of sales: week_date, region, platform, segment, customer_type, transactions, sales | fill in |

Data is provided by the challenge: https://8weeksqlchallenge.com/case-study-5/

## The data is messy in small ways, and the grain is easy to get wrong

- `week_date` is text, not a date. It is written day first with no zero padding (`9/9/20`, `29/7/20`), so sorting or filtering on it is wrong until it is converted.
- Missing segments are the literal text `null`, not a real NULL. An `IS NULL` check skips them, so cleaning compares against the string.
- `segment` holds two facts: the letter is the demographic (`C` couples, `F` families) and the digit is the age group (`1` young adults, `2` middle aged, `3` or `4` retirees).
- One row is a weekly slice already rolled up by week, region, platform, segment and customer type. It is not a customer and not an order, so averaging `avg_transaction` across rows gives a misleading number. Use total sales divided by total transactions.
- Slice sizes vary a lot (24 transactions in one row, 152,921 in another), which is why simple averages of averages fail.
- The data covers only part of the calendar in 2018, 2019 and 2020, so not every week of every year exists. The before and after comparison needs the same windows from earlier years.

## To reproduce

The queries are written for **DuckDB**. Open a DuckDB session (CLI, Python, or a DuckDB workbench), paste the `weekly_sales` INSERT into `schema.sql` where marked, run it, then run `../analysis/solutions.sql`. Section A creates `data_mart.clean_weekly_sales`, which sections B, C and D all read from, so run them in order.
