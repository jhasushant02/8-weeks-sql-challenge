# Results

Add a screenshot of each result grid to this folder (for example `a01.png` ... `c06.png`).
Put the infographic here as `infographic.png` and `infographic.html`.
Run `data/schema.sql` (with the `users` and `events` inserts pasted in), then `analysis/solutions.sql` in DuckDB.
Cells marked "fill in" depend on the full run; paste the value from your own output.

## A. Digital analysis

| Q | Question | Result |
|---|---|---|
| A1 | How many users are there? | fill in |
| A2 | Average cookies per user | fill in |
| A3 | Unique visits per month | fill in (one row per month, January to May 2020) |
| A4 | Number of events per event type | fill in (Page View, Add to Cart, Purchase, Ad Impression, Ad Click) |
| A5 | % of visits with a purchase event | fill in |
| A6 | % of visits that viewed checkout but did not purchase | fill in |
| A7 | Top 3 pages by views | fill in |
| A8 | Views and cart adds per product category | fill in (Fish, Luxury, Shellfish) |
| A9 | Top 3 products by purchases | fill in |

## B. Product funnel analysis

| Q | Question | Result |
|---|---|---|
| B1 | Views, cart adds, abandoned, purchased per product | fill in (one row per product, 9 rows) |
| B2 | The same per product category | fill in (3 rows) |
| B3 | Product with the most views, cart adds and purchases | fill in |
| B4 | Product most likely to be abandoned (by rate) | fill in |
| B5 | Product with the highest view to purchase % | fill in |
| B6 | Average view to cart add % and cart add to purchase % | fill in (average of per-product rates, equal weight) |

## C. Campaigns analysis

| Q | Question | Result |
|---|---|---|
| C1 | One row per visit (`campaign_summary`) | fill in (first 10 rows) |
| C2 | Insight 1: impression vs no impression, per campaign | fill in |
| C3 | Insight 2: clicked vs impression only vs no impression, with uplift | fill in |
| C4 | Insight 3: campaign scorecard against the no-campaign baseline | fill in |
| C5 | Insight 4: cart abandonment by campaign | fill in |
| C6 | Insight 5: purchasing vs non-purchasing visits | fill in |

## Extension: infographic

A single A4 infographic for management reporting. Files: `infographic.png` and `infographic.html` in this folder.

## Extension: recommendations

Written up in the main [README](../README.md): test campaigns against a held-out group, target the highest-abandonment products with cart-recovery messaging, and track view, cart and purchase rates weekly from totals rather than averages of rates.
