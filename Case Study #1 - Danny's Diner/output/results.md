# Results

Add a screenshot of each result grid to this folder as `q01.png` ... `q10.png`, `bonus1.png`, `bonus2.png`.
Expected results are below so you can check your own output.

| Q | Question | Result |
|---|---|---|
| 1 | Total spend | A $76, B $74, C $36 |
| 2 | Visit days | A 4, B 6, C 2 |
| 3 | First item(s) | A: sushi, curry / B: curry / C: ramen |
| 4 | Most purchased | ramen, 8 times |
| 5 | Most popular per customer | A: ramen (3) / B: sushi, curry, ramen (2 each) / C: ramen (3) |
| 6 | First item as member | A: curry / B: sushi |
| 7 | Last item before joining | A: curry, sushi / B: curry |
| 8 | Before joining: items, spend | A: 2 items, $25 / B: 3 items, $40 |
| 9 | Points (sushi 2x) | A 860, B 940, C 360 |
| 10 | Points at end of January | A 1,370, B 820 |

## Bonus 1: Join all the things

| customer_id | order_date | product_name | price | member |
|---|---|---|---|---|
| A | 2021-01-01 | sushi | 10 | N |
| A | 2021-01-01 | curry | 15 | N |
| A | 2021-01-07 | curry | 15 | Y |
| A | 2021-01-10 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| A | 2021-01-11 | ramen | 12 | Y |
| B | 2021-01-01 | curry | 15 | N |
| B | 2021-01-02 | curry | 15 | N |
| B | 2021-01-04 | sushi | 10 | N |
| B | 2021-01-11 | sushi | 10 | Y |
| B | 2021-01-16 | ramen | 12 | Y |
| B | 2021-02-01 | ramen | 12 | Y |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-01 | ramen | 12 | N |
| C | 2021-01-07 | ramen | 12 | N |

## Bonus 2: Rank all the things

Same table plus `ranking`: NULL for every `N` row. A's member rows rank 1, 2, 3, 3 (the two same-day ramen orders tie). B's member rows rank 1, 2, 3.
