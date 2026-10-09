# Case Study #8: Fresh Segments

**Tool:** DuckDB | **Skills:** type casting and date conversion, `ALTER ... USING`, anti-joins, cumulative percentages, views, `rank` / `row_number`, standard deviation, conditional aggregation, rolling averages with `lag`

Challenge by Danny Ma: https://8weeksqlchallenge.com/case-study-8/

Blog post (full walkthrough): [Case Study #8: Fresh Segments](https://sushant-jha.super.site/my-blogs/case-study-8-fresh-segments)

[Back to all case studies](../README.md)

## The question

Fresh Segments is a digital marketing agency. Clients share their customer lists, and Fresh Segments turns online ad click behaviour into interest metrics: for each interest, in each month, what share of the client's customers interacted with it. Danny wants high-level insights about one major client's customer list: which interests last, which fade, and what the customers actually care about.

The brief has four parts: clean the data, decide how much history is enough, find the strongest and most unstable interests, and use the index to track the monthly leader.

## The data

Two tables: `interest_metrics` (one interest in one month for this client) and `interest_map` (one interest and its description). See [`data/`](data/).

## Approach

- **Grain first.** A row in `interest_metrics` is one interest in one month, not a customer or a click. Interest counts use `count(distinct interest_id)` and month counts use `count(distinct month_year)`.
- **Fix the date.** `month_year` is text like `07-2018`. It is converted to a `DATE` on the first of the month before anything else.
- **Rows with no month stay in the table but out of the analysis.** They cannot be placed in a trend, and deleting them would lose information someone may want to investigate.
- **Cast the join key.** `interest_id` is text and `id` is an integer, so joins compare `interest_id` with `id::varchar`. `interest_metrics` is the base table, left joined to `interest_map`.
- **Filtered dataset as a view.** Interests with fewer than 6 months of data are removed, as set by the brief and checked against the cumulative percentage in B2. The filter lives in a view, `interest_metrics_filtered`, so Sets C and D start from the same data.
- **Ties are kept.** Top-N questions use `rank`, so a list can run slightly over N. Where exactly one row per month is needed (D4), `row_number` with a tie-break is used.
- **Average composition** is `round(composition / index_value, 2)`.
- **Rolling window.** The 3-month average is computed over all months first and filtered to September 2018 onward afterwards, so the first reported month still has two months behind it.

Full queries: [`analysis/solutions.sql`](analysis/solutions.sql). Results: [`output/results.md`](output/results.md).

## What I found

- **The data needs cleaning before any metric means anything.** The date is text, the join key has different types in the two tables, and some rows have no month.
- **The date check in A7 depends on precision.** `month_year` is always the first of the month while `created_at` has a day and time, so comparing exact dates can flag an interest as measured before it existed when both fall in the same month. Checking at month level removes that false alarm.
- **The 6-month cutoff is a decision, not a step.** It removes rows from every later answer. A short history can mean a weak interest or a brand new one that is just starting to grow, and the data does not say which. The cutoff suits ranking and trend questions, but it should be written down.
- **Average rankings hide history.** An interest can average well while swinging widely between months, which is why the volatility questions (C3 and C4) matter.
- **A "max per month" metric is unstable.** The monthly leader moves whenever a different interest takes the lead, so a change in it says little on its own. Before reading a falling maximum as a business problem, check the number of interests per month, whether one client dominates the data, and seasonality.

## Design note

Storing `month_year` as `MM-YYYY` text and the interest ID as text in one table and an integer in the other pushes casting into every query. In a real system I would store the month as a date and use one type for the interest key in both tables.

## Takeaway

Clean the data before you trust it, treat every filter as a decision, and ask what the number is measuring before you ask what it is.

## Limitations

The data covers 14 months (July 2018 to August 2019), so seasonality can't be separated from a trend. It is one client's customer list, so the findings say nothing about Fresh Segments' other clients. Results depend on the 6-month cutoff, which comes from the brief, and on keeping ties in top-N lists. D5 is a judgement about what the numbers might mean, not something the data proves.

---
Dataset and problem statement © Danny Ma, 8 Week SQL Challenge. Solutions are my own.

---
*If you find any errors, feel free to email me at [sushant.kr.jha02@gmail.com](mailto:sushant.kr.jha02@gmail.com).*
