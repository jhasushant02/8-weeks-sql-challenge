-- Case Study #6: Clique Bait
-- Source: https://8weeksqlchallenge.com/case-study-6/ (created by Danny Ma)
-- Dialect: DuckDB
-- Note: the small lookup tables are included in full below. `users` and `events`
-- are too large to paste into this file by hand, so paste their INSERT blocks
-- where marked.

CREATE SCHEMA IF NOT EXISTS clique_bait;
USE clique_bait;

-- -----------------------------------------------------
-- event_identifier: one row per event type
-- -----------------------------------------------------
DROP TABLE IF EXISTS clique_bait.event_identifier;
CREATE TABLE clique_bait.event_identifier (
  "event_type" INTEGER,
  "event_name" VARCHAR(13)
);

INSERT INTO clique_bait.event_identifier
  ("event_type", "event_name")
VALUES
  ('1', 'Page View'),
  ('2', 'Add to Cart'),
  ('3', 'Purchase'),
  ('4', 'Ad Impression'),
  ('5', 'Ad Click');

-- -----------------------------------------------------
-- campaign_identifier: one row per campaign
-- -----------------------------------------------------
DROP TABLE IF EXISTS clique_bait.campaign_identifier;
CREATE TABLE clique_bait.campaign_identifier (
  "campaign_id" INTEGER,
  "products" VARCHAR(3),
  "campaign_name" VARCHAR(33),
  "start_date" TIMESTAMP,
  "end_date" TIMESTAMP
);

INSERT INTO clique_bait.campaign_identifier
  ("campaign_id", "products", "campaign_name", "start_date", "end_date")
VALUES
  ('1', '1-3', 'BOGOF - Fishing For Compliments', '2020-01-01', '2020-01-14'),
  ('2', '4-5', '25% Off - Living The Lux Life', '2020-01-15', '2020-01-28'),
  ('3', '6-8', 'Half Off - Treat Your Shellf(ish)', '2020-02-01', '2020-03-31');

-- -----------------------------------------------------
-- page_hierarchy: one row per tagged page
-- -----------------------------------------------------
DROP TABLE IF EXISTS clique_bait.page_hierarchy;
CREATE TABLE clique_bait.page_hierarchy (
  "page_id" INTEGER,
  "page_name" VARCHAR(14),
  "product_category" VARCHAR(9),
  "product_id" INTEGER
);

INSERT INTO clique_bait.page_hierarchy
  ("page_id", "page_name", "product_category", "product_id")
VALUES
  ('1', 'Home Page', null, null),
  ('2', 'All Products', null, null),
  ('3', 'Salmon', 'Fish', '1'),
  ('4', 'Kingfish', 'Fish', '2'),
  ('5', 'Tuna', 'Fish', '3'),
  ('6', 'Russian Caviar', 'Luxury', '4'),
  ('7', 'Black Truffle', 'Luxury', '5'),
  ('8', 'Abalone', 'Shellfish', '6'),
  ('9', 'Lobster', 'Shellfish', '7'),
  ('10', 'Crab', 'Shellfish', '8'),
  ('11', 'Oyster', 'Shellfish', '9'),
  ('12', 'Checkout', null, null),
  ('13', 'Confirmation', null, null);

-- -----------------------------------------------------
-- users: one row per cookie, owned by a user
-- -----------------------------------------------------
DROP TABLE IF EXISTS clique_bait.users;
CREATE TABLE clique_bait.users (
  "user_id" INTEGER,
  "cookie_id" VARCHAR(6),
  "start_date" TIMESTAMP
);

-- >>> PASTE THE users INSERT HERE <<<
-- INSERT INTO clique_bait.users ("user_id", "cookie_id", "start_date") VALUES
--   ('1', 'c4ca42', '2020-02-04'),
--   ...;

-- -----------------------------------------------------
-- events: one row per logged event within a visit
-- -----------------------------------------------------
DROP TABLE IF EXISTS clique_bait.events;
CREATE TABLE clique_bait.events (
  "visit_id" VARCHAR(6),
  "cookie_id" VARCHAR(6),
  "page_id" INTEGER,
  "event_type" INTEGER,
  "sequence_number" INTEGER,
  "event_time" TIMESTAMP
);

-- >>> PASTE THE events INSERT HERE <<<
-- INSERT INTO clique_bait.events
--   ("visit_id", "cookie_id", "page_id", "event_type", "sequence_number", "event_time")
-- VALUES
--   (...),
--   ...;
