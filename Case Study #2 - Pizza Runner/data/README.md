# Data

`schema.sql` creates the `pizza_runner` schema and loads six tables:

| Table | What it holds | Rows |
|---|---|---|
| `runners` | runner_id, registration_date | 4 |
| `customer_orders` | one row per pizza ordered, with exclusions and extras | 14 |
| `runner_orders` | one row per order: runner, pickup time, distance, duration, cancellation | 10 |
| `pizza_names` | pizza_id, pizza_name | 2 |
| `pizza_recipes` | pizza_id, comma-separated topping_ids | 2 |
| `pizza_toppings` | topping_id, topping_name | 12 |

Data is provided by the challenge: https://8weeksqlchallenge.com/case-study-2/

## The data is intentionally messy

- Missing values appear as `NULL`, the text `'null'`, and `''` (empty string).
- `distance` and `duration` are text with units mixed in (`'20km'`, `'23.4 km'`, `'32 minutes'`, `'20 mins'`, `'25mins'`).
- `exclusions`, `extras` and `toppings` hold comma-separated topping IDs in a single column.
- `customer_orders` has one row per pizza, not per order.

The queries in `analysis/solutions.sql` clean these inline.

## To reproduce

The queries are written for **DuckDB**. Open a DuckDB session (CLI, Python, or a DuckDB workbench), run `schema.sql`, then run `../analysis/solutions.sql`. The last block of the solutions file inserts a new pizza, so run it last.
