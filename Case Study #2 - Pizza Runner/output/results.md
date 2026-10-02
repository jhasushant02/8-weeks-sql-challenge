# Results

Add a screenshot of each result grid to this folder (for example `a01.png` ... `d05.png`).
Expected results from running `analysis/solutions.sql` in DuckDB are below, so you can check your own output.

## A. Pizza metrics

| Q | Question | Result |
|---|---|---|
| A1 | Pizzas ordered | 14 |
| A2 | Unique orders | 10 |
| A3 | Successful deliveries per runner | Runner 1: 4, Runner 2: 3, Runner 3: 1 |
| A4 | Pizzas delivered by type | Meatlovers: 9, Vegetarian: 3 |
| A5 | Vegetarian / Meatlovers per customer | 101: 1/2, 102: 1/2, 103: 1/3, 104: 0/3, 105: 1/0 |
| A6 | Largest order | Order 4 (customer 103), 3 pizzas |
| A7 | Delivered pizzas: with change / no change | 101: 0/2, 102: 0/3, 103: 3/0, 104: 2/1, 105: 1/0 |
| A8 | Delivered pizzas with both exclusions and extras | 1 |
| A9 | Pizzas by hour | 11h: 1, 13h: 3, 18h: 3, 19h: 1, 21h: 3, 23h: 3 |
| A10 | Orders by weekday | Wed: 5, Thu: 2, Fri: 1, Sat: 2 |

## B. Runner and customer experience

| Q | Question | Result |
|---|---|---|
| B1 | Runners signed up per week | Week 1: 2, Week 2: 1, Week 3: 1 |
| B2 | Avg minutes to pickup | Runner 1: 14.33, Runner 2: 20.01, Runner 3: 10.47 |
| B3 | Prep time by pizzas in order | 1 pizza: 12.36 min (5 orders), 2 pizzas: 18.38 (2 orders), 3 pizzas: 29.28 (1 order) |
| B4 | Avg distance per customer (km) | 101: 20.0, 102: 18.4, 103: 23.4, 104: 10.0, 105: 25.0 |
| B5 | Longest minus shortest delivery | 30 minutes |
| B6 | Speed (km/h) per delivery | R1: 37.50, 44.44, 40.20, 60.00 / R2: 35.10, 60.00, 93.60 / R3: 40.00 |
| B7 | Successful delivery % | Runner 1: 100, Runner 2: 75, Runner 3: 50 |

## C. Ingredient optimisation

**C1. Standard ingredients**

| Pizza | Ingredients |
|---|---|
| Meatlovers | BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian | Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |

**C2. Most common extra:** Bacon (4)

**C3. Most common exclusion:** Cheese (4)

**C4. Order items (one per pizza, 14 rows)**

| order_id | order_item |
|---|---|
| 1 | Meatlovers |
| 2 | Meatlovers |
| 3 | Meatlovers |
| 3 | Vegetarian |
| 4 | Meatlovers - Exclude Cheese |
| 4 | Meatlovers - Exclude Cheese |
| 4 | Vegetarian - Exclude Cheese |
| 5 | Meatlovers - Extra Bacon |
| 6 | Vegetarian |
| 7 | Vegetarian - Extra Bacon |
| 8 | Meatlovers |
| 9 | Meatlovers - Exclude Cheese - Extra Bacon, Chicken |
| 10 | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |
| 10 | Meatlovers |

**C5. Ingredient lists (one per pizza, 14 rows)**

| order_id | ingredient_list |
|---|---|
| 1, 2, 3, 8 | Meatlovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3, 6 | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 4 (two pizzas) | Meatlovers: BBQ Sauce, Bacon, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 4 | Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 5 | Meatlovers: BBQ Sauce, 2xBacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 7 | Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 9 | Meatlovers: BBQ Sauce, 2xBacon, Beef, 2xChicken, Mushrooms, Pepperoni, Salami |
| 10 | Meatlovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami |
| 10 | Meatlovers: BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |

**C6. Ingredient quantities in delivered pizzas**

| Topping | Quantity |
|---|---|
| Bacon | 12 |
| Mushrooms | 11 |
| Cheese | 10 |
| Beef, Chicken, Pepperoni, Salami | 9 each |
| BBQ Sauce | 8 |
| Onions, Peppers, Tomato Sauce, Tomatoes | 3 each |

## D. Pricing and ratings

| Q | Question | Result |
|---|---|---|
| D1 | Revenue, fixed prices | Meatlovers $108 + Vegetarian $30 = **$138** |
| D2 | Revenue with $1 per extra | Meatlovers $111 + Vegetarian $31 = **$142** |
| D3 | Ratings table | 8 rows, one per delivered order (sample data) |
| D5 | After runner pay at $0.30/km | Revenue $138, distance 145.2 km, pay $43.56, left over **$94.44** |

**D4. Combined delivery table**

| customer | order | runner | rating | pickup (min) | duration (min) | speed (km/h) | pizzas |
|---|---|---|---|---|---|---|---|
| 101 | 1 | 1 | 5 | 10 | 32 | 37.50 | 1 |
| 101 | 2 | 1 | 4 | 10 | 27 | 44.44 | 1 |
| 102 | 3 | 1 | 5 | 21 | 20 | 40.20 | 2 |
| 103 | 4 | 2 | 3 | 30 | 40 | 35.10 | 3 |
| 104 | 5 | 3 | 4 | 10 | 15 | 40.00 | 1 |
| 105 | 7 | 2 | 5 | 10 | 25 | 60.00 | 1 |
| 102 | 8 | 2 | 4 | 21 | 15 | 93.60 | 1 |
| 104 | 10 | 1 | 5 | 16 | 10 | 60.00 | 2 |

## E. Bonus: Supreme pizza

Two inserts and no schema change: `(3, 'Supreme')` into `pizza_names`, and `(3, '1, 2, ..., 12')` into `pizza_recipes`.
