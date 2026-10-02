# Results

Add a screenshot of each result grid to this folder (for example `a01.png` ... `d01.png`).
Expected results from running `analysis/solutions.sql` in DuckDB are below, so you can check your own output.
Cells marked "fill in" depend on the full run; paste the value from your own output.

## A. Customer nodes exploration

| Q | Question | Result |
|---|---|---|
| A1 | Unique nodes | 5 |
| A2 | Nodes per region | 5 in every region |
| A3 | Customers per region | Australia: 110, America: 105, Africa: 102, Asia: 95, Europe: 88 (500 total) |
| A4 | Avg days before reallocation (per customer-node pair) | fill in |
| A5 | Median / P80 / P95 reallocation days per region (per stay) | fill in (one row per region) |

## B. Customer transactions

| Q | Question | Result |
|---|---|---|
| B1 | Deposits | 2,671 transactions, $1,359,168 |
| B1 | Purchases | 1,617 transactions, $806,537 |
| B1 | Withdrawals | 1,580 transactions, $793,003 |
| B2 | Average deposits per customer | 5 deposits, $2,718.34 |
| B3 | Customers with more than 1 deposit and a purchase or withdrawal | Jan: 168, Feb: 181, Mar: 192, Apr: 70 |
| B4 | Closing balance per customer per active month | fill in (rows only for months with transactions) |
| B5 | Customers with a more than 5% month-over-month balance increase | fill in (per region and total) |

## C. Data allocation challenge

| Item | Result |
|---|---|
| C1 | Running balance after each transaction, one row per transaction |
| C2 | Month-end balance per customer, one row per customer per month (Jan to Apr 2020) |
| C3 | Min, average and max running balance, one row per customer (500 rows) |
| C4 | Monthly data required: Option 1 and Option 2 start in February (they need a previous period); Option 3 covers January to April. Fill in values. |

## D. Extra challenge

| Item | Result |
|---|---|
| D1 | Additional data from 6% simple daily interest, per month: fill in |
| D2 | Compounding version: not built |

## Extension: marketing slides

Built outside SQL (slides for investors and customers from the node insights and the data provisioning options). Not included in this repo.
