# Data

`schema.sql` creates the `fresh_segments` schema and two empty tables.

| Table | What it holds | Key columns |
|---|---|---|
| `interest_metrics` | monthly metrics per interest, aggregated across Fresh Segments' clients | `_month`, `_year`, `month_year`, `interest_id`, `composition`, `index_value`, `ranking`, `percentile_ranking` |
| `interest_map` | lookup from interest ID to name and description | `id`, `interest_name`, `interest_summary`, `created_at`, `last_modified` |

Data is provided by the challenge: https://8weeksqlchallenge.com/case-study-8/

## Loading the data

The challenge ships the rows as INSERT statements in a DB Fiddle (about 14k rows for `interest_metrics`), so they are not copied here. Either:

1. Paste the INSERT statements from the fiddle at the bottom of `schema.sql`, or
2. Export both tables to CSV, put them in this folder and uncomment the `COPY` lines.

Then check your row counts against the challenge page before running any analysis.

## Things to watch for

- `month_year` is text in `MM-YYYY` format, not a date. The first question asks you to convert it.
- `interest_id` is text in `interest_metrics` but an integer (`id`) in `interest_map`, so joins need a cast.
- `interest_metrics` contains NULLs in the date and ID columns.
- `interest_map` has IDs that never appear in `interest_metrics`, so join direction matters.
- `_month` and `_year` were declared as integers here. If your load fails on them, switch to `VARCHAR(4)`.
