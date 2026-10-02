# Data

`schema.sql` creates the `data_bank` schema and loads three tables:

| Table | What it holds | Rows |
|---|---|---|
| `regions` | region_id, region_name | 5 |
| `customer_nodes` | one row per node allocation: customer_id, region_id, node_id, start_date, end_date | many per customer, 500 customers |
| `customer_transactions` | one row per transaction: customer_id, txn_date, txn_type (deposit, purchase, withdrawal), txn_amount | many per customer |

Data is provided by the challenge: https://8weeksqlchallenge.com/case-study-4/

## The data is clean, but the grain is easy to get wrong

- `customer_nodes` is an allocation history, not a customer list. A customer appears once per node stay, so `COUNT(*)` counts stays and `COUNT(DISTINCT customer_id)` counts customers.
- An allocation that is still open has `end_date = '9999-12-31'`. Any duration calculation has to exclude it or the averages are meaningless.
- `customer_transactions` has no balance column. Deposits add to the balance; purchases and withdrawals subtract. The running balance is built with a cumulative sum.
- Several transactions can happen on the same day for one customer, and not every customer transacts every month.
- Some customers' balances go negative at points, which matters for storage sizing (negative balances are floored at 0 in the allocation queries).
- Data covers January to April 2020, and April is a partial month.

## To reproduce

The queries are written for **DuckDB**. Open a DuckDB session (CLI, Python, or a DuckDB workbench), run `schema.sql`, then run `../analysis/solutions.sql`. Section C creates a helper table, `data_bank.daily_balance`, that section D reuses, so run them in order.
