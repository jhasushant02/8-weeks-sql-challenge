# Results

Add a screenshot of each result grid to this folder (for example `a01.png` ... `c10.png`).
Run `data/schema.sql` (with the `sales` insert pasted in), then `analysis/solutions.sql` in DuckDB.
Cells marked "fill in" depend on the full run; paste the value from your own output.

**Status:** sets A, B and C have queries. Sets D (Reporting Challenge) and E (Bonus Challenge) are not solved yet, so they have no results.

## A. High level sales analysis

| Q | Question | Result |
|---|---|---|
| A1 | Total quantity sold for all products | fill in |
| A2 | Total revenue for all products before discounts | fill in |
| A3 | Total discount amount for all products | fill in |

## B. Transaction analysis

| Q | Question | Result |
|---|---|---|
| B1 | Unique transactions | fill in |
| B2 | Average unique products purchased per transaction | fill in |
| B3 | 25th, 50th and 75th percentile revenue per transaction | fill in (one row, three values) |
| B4 | Average discount value per transaction | fill in |
| B5 | % split of transactions, members vs non-members | fill in (2 rows, adding to 100) |
| B6 | Average revenue per member and non-member transaction | fill in (2 rows, gross and net) |

## C. Product analysis

| Q | Question | Result |
|---|---|---|
| C1 | Top 3 products by revenue before discount | fill in (3 rows) |
| C2 | Quantity, revenue and discount per segment | fill in (4 rows: Jacket, Jeans, Shirt, Socks) |
| C3 | Top selling product per segment | fill in (4 rows, more if tied) |
| C4 | Quantity, revenue and discount per category | fill in (2 rows: Mens, Womens) |
| C5 | Top selling product per category | fill in (2 rows, more if tied) |
| C6 | % split of revenue by product within each segment | fill in (12 rows, each segment adds to 100) |
| C7 | % split of revenue by segment within each category | fill in (4 rows, each category adds to 100) |
| C8 | % split of total revenue by category | fill in (2 rows, adding to 100) |
| C9 | Transaction penetration per product | fill in (12 rows) |
| C10 | Most common combination of 3 products in a transaction | fill in (1 row, more if tied) |

## D. Reporting challenge

Not solved yet. When done, add: the output tables, a table mapping each output to its question, the January run and the February run.

## E. Bonus challenge

Not solved yet. When done, add: the rebuilt `product_details` and the check against the original in both directions.
