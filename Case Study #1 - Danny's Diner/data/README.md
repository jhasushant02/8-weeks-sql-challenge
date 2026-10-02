# Data

`schema.sql` creates the `dannys_diner` database and loads three tables:

| Table | Columns | Rows |
|---|---|---|
| `sales` | customer_id, order_date, product_id | 15 |
| `menu` | product_id, product_name, price | 3 |
| `members` | customer_id, join_date | 2 |

Data is provided by the challenge: https://8weeksqlchallenge.com/case-study-1/

To reproduce: open `schema.sql` in MySQL Workbench (or run `mysql < schema.sql`), then run `../analysis/solutions.sql`.
