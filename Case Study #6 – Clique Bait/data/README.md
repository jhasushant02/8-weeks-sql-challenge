# Data

`schema.sql` creates the `clique_bait` schema and five tables:

| Table | What one row is | Key columns | Rows |
|---|---|---|---|
| `users` | a cookie belonging to a user | user_id, cookie_id, start_date | fill in |
| `events` | one logged event within a visit | visit_id, cookie_id, page_id, event_type, sequence_number, event_time | fill in |
| `event_identifier` | an event type | event_type, event_name | 5 |
| `campaign_identifier` | a campaign | campaign_id, products, campaign_name, start_date, end_date | 3 |
| `page_hierarchy` | a tagged page | page_id, page_name, product_category, product_id | 13 |

Data is provided by the challenge: https://8weeksqlchallenge.com/case-study-6/

`event_identifier`, `campaign_identifier` and `page_hierarchy` are small and are included in full in `schema.sql`. `users` and `events` are too large to paste by hand: copy their `INSERT` blocks from the challenge page into `schema.sql` where marked.

## The grain is easy to get wrong

- `events` has one row per event. It is not a visit and not a user. A visit is all events sharing a `visit_id`.
- A user owns several cookies, so users, cookies and visits are three different counts.
- `events` has a `cookie_id` but no `user_id`. Getting to a user means joining through `users`.
- A purchase (event type 3) is logged on the Confirmation page, which has no product. Product-level purchases are inferred from cart adds in a purchasing visit.
- Campaign `end_date` values are midnight timestamps. A plain `BETWEEN` drops visits that start later on the last day, so the campaign join compares against `end_date + 1 day`.
- The campaigns leave gaps (nothing runs 29 January to 31 January), so some visits belong to no campaign.

Event types: 1 Page View, 2 Add to Cart, 3 Purchase, 4 Ad Impression, 5 Ad Click.

| campaign_id | products | campaign_name | start_date | end_date |
|---|---|---|---|---|
| 1 | 1-3 | BOGOF - Fishing For Compliments | 2020-01-01 | 2020-01-14 |
| 2 | 4-5 | 25% Off - Living The Lux Life | 2020-01-15 | 2020-01-28 |
| 3 | 6-8 | Half Off - Treat Your Shellf(ish) | 2020-02-01 | 2020-03-31 |

## To reproduce

The queries are written for **DuckDB**. Open a DuckDB session (CLI, Python, or a DuckDB workbench), paste the `users` and `events` inserts into `schema.sql` where marked, run it, then run `../analysis/solutions.sql`. Section B creates `product_funnel` and `product_category_funnel`, and section C creates `campaign_summary`, so run the sections in order.
