# Results

Add a screenshot of each result grid to this folder (for example `a01.png` ... `c01.png`).
Expected results from running `analysis/solutions.sql` in DuckDB are below, so you can check your own output.

## A. Customer journey (customers 1 to 8)

| customer_id | onboarding_journey |
|---|---|
| 1 | trial → basic monthly |
| 2 | trial → pro annual |
| 3 | trial → basic monthly |
| 4 | trial → basic monthly → churn |
| 5 | trial → basic monthly |
| 6 | trial → basic monthly → churn |
| 7 | trial → basic monthly → pro monthly |
| 8 | trial → basic monthly → pro monthly |

## B. Data analysis

| Q | Question | Result |
|---|---|---|
| B1 | Customers ever | 1,000 |
| B3 | Events after 2020 | churn: 71, pro annual: 63, pro monthly: 60, basic monthly: 8 |
| B4 | Churned customers | 307 (30.7%) |
| B5 | Churned straight after trial | 92 (9%) |
| B8 | Upgraded to annual in 2020 | 195 |
| B9 | Avg days from joining to annual | 105 |
| B11 | Pro monthly → basic monthly downgrades in 2020 | 0 |

**B2. Trial starts per month (2020)**

| Month | Trials |
|---|---|
| Jan | 88 |
| Feb | 68 |
| Mar | 94 |
| Apr | 81 |
| May | 88 |
| Jun | 79 |
| Jul | 89 |
| Aug | 88 |
| Sep | 87 |
| Oct | 79 |
| Nov | 75 |
| Dec | 84 |

**B6. Plan right after the trial**

| Plan | Customers | % |
|---|---|---|
| basic monthly | 546 | 54.6 |
| pro monthly | 325 | 32.5 |
| churn | 92 | 9.2 |
| pro annual | 37 | 3.7 |

**B7. Plan mix at 2020-12-31**

| Plan | Customers | % |
|---|---|---|
| pro monthly | 326 | 32.6 |
| churn | 236 | 23.6 |
| basic monthly | 224 | 22.4 |
| pro annual | 195 | 19.5 |
| trial | 19 | 1.9 |

**B10. Days to annual, 30-day buckets:** 12 buckets from `0 - 30` to `330 - 360`, 258 customers in total (everyone who ever reached pro annual, including 2021 upgrades). Exact bucket counts depend on the boundary rule: `FLOOR(days / 30)` puts a customer at exactly 30 days in `30 - 60`.

## C. Payments table (2020)

Spot checks to compare against `foodie_fi.payments`:

| customer | Expected payments |
|---|---|
| 1 | basic monthly $9.90 on 08-08, 09-08, 10-08, 11-08, 12-08 |
| 2 | pro annual $199.00 on 09-27 (trial straight to annual) |
| 4 | basic monthly $9.90 on 01-24, 02-24, 03-24; none after churn on 04-21 |
| 6 | basic monthly $9.90 on 12-30 only |
| 7 | basic $9.90 on 02-12, 03-12, 04-12, 05-12; pro monthly **$10.00** on 05-22 (19.90 minus 9.90 credit); then $19.90 on 06-22 to 12-22 |
| 8 | basic $9.90 on 06-18, 07-18; pro monthly **$10.00** on 08-03; then $19.90 on 09-03, 10-03, 11-03, 12-03 |
| 19 | pro monthly $19.90 on 06-29, 07-29; pro annual $199.00 on **08-29** (switch date is exactly the monthly anniversary) |

## D. Outside the box (short answers)

| Q | Takeaway |
|---|---|
| D1 | Growth: track net paid customers (new paid minus churned) next to revenue growth. Trials alone, or customer count alone, can hide a shrinking business. |
| D2 | Metrics: trial-to-paid conversion, plan mix, monthly churn, time to upgrade, annual plan share, cohort retention by trial month. |
| D3 | Journeys to study: trial straight to pro, basic that churns vs basic that upgrades, early vs late churn, the annual renewal window. |
| D4 | Exit survey: main reason, value for money (1 to 5), would a cheaper plan change your mind, missing features (optional text), likelihood to return. |
| D5 | Churn levers: annual-plan offers timed before typical churn, a win-back flow for early churners, outreach to customers stuck on basic. Validate with a holdout control group over 60 to 90 days. |
