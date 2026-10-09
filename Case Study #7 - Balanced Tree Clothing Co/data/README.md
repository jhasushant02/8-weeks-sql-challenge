# Data

`schema.sql` creates the `balanced_tree` schema and four tables:

| Table | What one row is | Key columns | Rows |
|---|---|---|---|
| `product_details` | a product (one style in the range) | product_id, price, product_name, category_id, segment_id, style_id, category_name, segment_name, style_name | 12 |
| `sales` | one product line within a transaction | prod_id, qty, price, discount, member, txn_id, start_txn_time | fill in |
| `product_hierarchy` | a node in the category, segment, style tree | id, parent_id, level_text, level_name | 18 |
| `product_prices` | the price of a style | id, product_id, price | 12 |

Data is provided by the challenge: https://8weeksqlchallenge.com/case-study-7/

`product_details`, `product_hierarchy` and `product_prices` are small and are included in full in `schema.sql`. `sales` is too large to paste by hand: copy its `INSERT` block from the challenge page into `schema.sql` where marked.

Only `product_details` and `sales` are needed for the main questions. `product_hierarchy` and `product_prices` are used only by the bonus question, which rebuilds `product_details` from them.

## The grain is easy to get wrong

- `sales` has one row per **product line**. It is not a transaction and not a unit sold. A transaction is all rows sharing a `txn_id`, so `COUNT(*)` is not a transaction count.
- `discount` is a **percentage**. The discount amount is `qty * price * discount / 100`.
- `price` in `sales` repeats the price in `product_details`, so revenue can be computed from `sales` alone. `product_details` is only needed for names and the hierarchy.
- `member` and `start_txn_time` belong to the transaction but are stored on every line. A transaction-level view means collapsing them first.
- "Top selling" is ambiguous. It can mean quantity or revenue, and the two can disagree.

Hierarchy levels: Category (Womens, Mens), Segment (Jeans, Jacket, Shirt, Socks) and Style (the 12 individual products).

## To reproduce

The queries are written for **DuckDB**. Open a DuckDB session (CLI, Python, or a DuckDB workbench), paste the `sales` insert into `schema.sql` where marked, run it, then run `../analysis/solutions.sql`. The question order is A (High Level Sales), B (Transaction), C (Product).
