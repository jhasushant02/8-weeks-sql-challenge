-- Case Study #8: Fresh Segments
-- Source: https://8weeksqlchallenge.com/case-study-8/ (created by Danny Ma)
-- Dialect: DuckDB
-- Note: raw data is kept as provided. month_year is text ('MM-YYYY') and
-- interest_id is text, so cleaning and casting happen in the queries.
-- Row data is NOT included in this file: see data/README.md for how to load it.

CREATE SCHEMA IF NOT EXISTS fresh_segments;
USE fresh_segments;

-- interest_metrics
DROP TABLE IF EXISTS fresh_segments.interest_metrics;
CREATE TABLE fresh_segments.interest_metrics (
    _month INTEGER,
    _year INTEGER,
    month_year VARCHAR(7),
    interest_id VARCHAR(5),
    composition DOUBLE,
    index_value DOUBLE,
    ranking INTEGER,
    percentile_ranking DOUBLE
);

-- interest_map
DROP TABLE IF EXISTS fresh_segments.interest_map;
CREATE TABLE fresh_segments.interest_map (
    id INTEGER,
    interest_name VARCHAR(64),
    interest_summary VARCHAR(256),
    created_at TIMESTAMP,
    last_modified TIMESTAMP
);

-- Load the data (pick ONE option)
-- Option A: CSVs exported from the challenge dataset, placed in this folder
-- COPY fresh_segments.interest_metrics FROM 'interest_metrics.csv' (HEADER, NULL_PADDING true);
-- COPY fresh_segments.interest_map     FROM 'interest_map.csv'     (HEADER);
-- Option B: paste the INSERT statements from the challenge's DB Fiddle below.
