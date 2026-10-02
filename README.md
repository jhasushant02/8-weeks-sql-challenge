# 8 Week SQL Challenge

My solutions to the [8 Week SQL Challenge](https://8weeksqlchallenge.com/) by Danny Ma: eight real-world business case studies, each built around a small dataset and a set of questions to answer with SQL.

I'm working through them in order. Each case is a self-contained mini project with the problem, my approach, the queries and what I found.

## Tools

- **SQL dialect:** MySQL 8
- **Environment:** MySQL Workbench
- **Version control:** Git and GitHub

## Case studies

| # | Case study | Focus | Status |
|---|---|---|---|
| 01 | [Danny's Diner](case-01-dannys-diner/) | Customer behaviour, loyalty program | Done |
| 02 | Pizza Runner | Data cleaning, delivery operations | Coming soon |
| 03 | Foodie-Fi | Subscription analytics | Coming soon |
| 04 | Data Bank | Customer transactions | Coming soon |
| 05 | Data Mart | Sales impact analysis | Coming soon |
| 06 | Clique Bait | Digital funnel and campaigns | Coming soon |
| 07 | Balanced Tree Clothing Co. | Product and revenue analysis | Coming soon |
| 08 | Fresh Segments | Interest metrics, segmentation | Coming soon |

Original problem statements: [8weeksqlchallenge.com](https://8weeksqlchallenge.com/)

## SQL skills covered so far

- Joins (inner, left) across multiple tables
- Aggregation with `GROUP BY`, `SUM`, `COUNT(DISTINCT ...)`
- CTEs
- Window functions (`DENSE_RANK`, `ROW_NUMBER`)
- Conditional logic with `CASE`
- Date handling (`DATE_ADD`)
- Building reusable analysis tables

## Repo structure

```
8-week-sql-challenge/
├── README.md
├── case-01-dannys-diner/
│   ├── README.md      the question, approach, what I found
│   ├── data/          schema and sample data
│   ├── analysis/      SQL queries
│   └── output/        result screenshots and expected results
├── case-02-pizza-runner/
└── ...
```

## How to run a case

1. Open the case folder, e.g. `case-01-dannys-diner/`.
2. Run `data/schema.sql` in MySQL to create the database and load the data.
3. Run `analysis/solutions.sql` to reproduce the results.

## Credits

Case studies, datasets and problem statements belong to Danny Ma and the 8 Week SQL Challenge. The SQL solutions and write-ups in this repo are my own.

## Connect

- LinkedIn: [add your link]
- Portfolio: [add your link]
