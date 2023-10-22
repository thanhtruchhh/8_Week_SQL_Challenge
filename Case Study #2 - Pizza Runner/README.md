# Case Study #2 - Pizza Runner
<img src="https://8weeksqlchallenge.com/images/case-study-designs/2.png" alt="Case Study #2 - Pizza Runner Image" width="500" height="520">

## Business Task

Danny is expanding his new Pizza Empire and at the same time, he wants to Uberize it, so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

Full Description: [Case Study #2 - Pizza Runner](https://8weeksqlchallenge.com/case-study-2/)

## Dataset

Danny has prepared an [entity relationship diagram](https://dbdiagram.io/d/5f3e085ccf48a141ff558487/?utm_source=dbdiagram_embed&utm_medium=bottom_open) of his database design but requires further assistance to clean his data and apply some basic calculations so he can better direct his runners and optimise Pizza Runner’s operations.

- The `runners` table: Shows the `registration_date` for each new runner
- The `customer_orders` table: Captures customer pizza orders, with 1 row for each individual pizza that is part of the order.
- The `runner_orders` table: After each orders are received through the system - they are assigned to a runner.
- The `pizza_names` table: Maps `pizza_id` to the actual `pizza_name`.
- The `pizza_recipes` table: Each pizza_id has a standard set of toppings which are used as part of the pizza recipe.
- The `pizza_toppings` table: Contains all of the `topping_name` values with their corresponding `topping_id` value.

## Data Cleaning
**Database Environment**: PostgreSQL v13 on [DB Fiddle](https://www.db-fiddle.com/f/7VcQKQwsS3CTkGRFG7vu98/65)
### Table: `customer_orders`
Replace all 'null' or blank values with `NULL`.

```sql
CREATE TEMP TABLE customer_orders_temp AS
SELECT 
  order_id, 
  customer_id, 
  pizza_id, 
  CASE
	  WHEN exclusions = '' OR exclusions = 'null' THEN NULL
	  ELSE exclusions
  END AS exclusions,
  CASE
	  WHEN extras = '' OR extras = 'null' THEN NULL
	  ELSE extras
  END AS extras,
	order_time
FROM pizza_runner.customer_orders;

SELECT * FROM customer_orders_temp
```

**Output:**

| order_id | customer_id | pizza_id | exclusions | extras | order_time               |
| -------- | ----------- | -------- | ---------- | ------ | ------------------------ |
| 1        | 101         | 1        |            |        | 2020-01-01T18:05:02.000Z |
| 2        | 101         | 1        |            |        | 2020-01-01T19:00:52.000Z |
| 3        | 102         | 1        |            |        | 2020-01-02T23:51:23.000Z |
| 3        | 102         | 2        |            |        | 2020-01-02T23:51:23.000Z |
| 4        | 103         | 1        | 4          |        | 2020-01-04T13:23:46.000Z |
| 4        | 103         | 1        | 4          |        | 2020-01-04T13:23:46.000Z |
| 4        | 103         | 2        | 4          |        | 2020-01-04T13:23:46.000Z |
| 5        | 104         | 1        |            | 1      | 2020-01-08T21:00:29.000Z |
| 6        | 101         | 2        |            |        | 2020-01-08T21:03:13.000Z |
| 7        | 105         | 2        |            | 1      | 2020-01-08T21:20:29.000Z |
| 8        | 102         | 1        |            |        | 2020-01-09T23:54:33.000Z |
| 9        | 103         | 1        | 4          | 1, 5   | 2020-01-10T11:22:59.000Z |
| 10       | 104         | 1        |            |        | 2020-01-11T18:34:49.000Z |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2020-01-11T18:34:49.000Z |

---

### Table: `runner_orders`

- Replace all blank or 'null' values with `NULL` in the `pickup_time`, `distance`, `duration`, and `cancellation` fields.
- Remove 'km' from the `distance` field.
- Extract numeric characters from the `duration` field.
- Alter the `pickup_time`, `distance`, and `duration` columns to the correct data type.

```sql
CREATE TEMP TABLE runner_orders_temp AS
SELECT 
  order_id, 
  runner_id, 
  CASE
  	WHEN pickup_time = 'null' THEN NULL
    ELSE pickup_time::TIMESTAMP
   END AS pickup_time,
   CASE
   	WHEN distance = 'null' THEN NULL
    WHEN distance LIKE '%km' THEN TRIM(distance,'km')::FLOAT
   	ELSE distance::FLOAT
   END AS distance,
   CASE
   	WHEN duration = 'null' THEN NULL
    ELSE regexp_replace(duration, '[^0-9]', '', 'g')::INT
   END AS duration,
   CASE
   	WHEN cancellation = 'null' OR cancellation = '' THEN NULL
    ELSE cancellation
   END AS cancellation
FROM pizza_runner.runner_orders;

ALTER TABLE runner_orders_temp
ALTER COLUMN pickup_time TYPE TIMESTAMP,
ALTER COLUMN distance TYPE FLOAT,
ALTER COLUMN duration TYPE INT;
```

**Output:**

| order_id | runner_id | pickup_time              | distance | duration | cancellation            |
| -------- | --------- | ------------------------ | -------- | -------- | ----------------------- |
| 1        | 1         | 2020-01-01T18:15:34.000Z | 20       | 32       |                         |
| 2        | 1         | 2020-01-01T19:10:54.000Z | 20       | 27       |                         |
| 3        | 1         | 2020-01-03T00:12:37.000Z | 13.4     | 20       |                         |
| 4        | 2         | 2020-01-04T13:53:03.000Z | 23.4     | 40       |                         |
| 5        | 3         | 2020-01-08T21:10:57.000Z | 10       | 15       |                         |
| 6        | 3         |                          |          |          | Restaurant Cancellation |
| 7        | 2         | 2020-01-08T21:30:45.000Z | 25       | 25       |                         |
| 8        | 2         | 2020-01-10T00:15:02.000Z | 23.4     | 15       |                         |
| 9        | 2         |                          |          |          | Customer Cancellation   |
| 10       | 1         | 2020-01-11T18:50:20.000Z | 10       | 10       |                         |

---

### Table: `pizza_recipes`

- Split the `toppings` field into multiple rows.
- Alter the `toppings` column to the correct datatype.

```sql
CREATE TEMP TABLE pizza_recipes_temp AS
SELECT
	pizza_id,
    UNNEST(STRING_TO_ARRAY(toppings, ', '))::INT AS toppings
FROM pizza_runner.pizza_recipes;

ALTER TABLE pizza_recipes_temp
ALTER toppings TYPE INT;
```
**Output:**

| pizza_id | toppings |
| -------- | -------- |
| 1        | 1        |
| 1        | 2        |
| 1        | 3        |
| 1        | 4        |
| 1        | 5        |
| 1        | 6        |
| 1        | 8        |
| 1        | 10       |
| 2        | 4        |
| 2        | 6        |
| 2        | 7        |
| 2        | 9        |
| 2        | 11       |
| 2        | 12       |

---

## Questions and Solutions

### A. Pizza Metrics

#### Question 1: How many pizzas were ordered?

```sql
SELECT COUNT(pizza_id) pizza_ordered_cnt
FROM customer_orders_temp;
```

**Output:**

| pizza_ordered_cnt |
| ----------------- |
| 14                |

Total of 14 pizzas were ordered.

---

#### Question 2: How many unique customer orders were made?

```sql
SELECT COUNT(DISTINCT order_id) order_cnt
FROM customer_orders_temp;
```

**Output:**

| order_cnt |
| --------- |
| 10        |

There are 10 unique customer orders made.

---

#### Question 3: How many successful orders were delivered by each runner?

```sql
SELECT
	runner_id,
	COUNT(order_id) AS order_cnt
FROM runner_orders_temp
WHERE cancellation IS NULL
GROUP BY 1
ORDER BY 1;
```

**Output:**

| runner_id | order_cnt |
| --------- | --------- |
| 1         | 4         |
| 2         | 3         |
| 3         | 1         |

- Runner 1 deliveried successfully 4 orders.
- Runner 2 deliveried successfully 3 orders.
- Runner 3 deliveried successfully 1 order.
  
---

#### Question 4: How many of each type of pizza was delivered?

After joining tables, exclude cancelled orders.

```sql
SELECT
	pizza_id,
	pizza_name,
	COUNT(1) AS order_cnt
FROM customer_orders_temp
INNER JOIN runner_orders_temp USING(order_id)
INNER JOIN pizza_runner.pizza_names USING(pizza_id)
WHERE cancellation IS NULL
GROUP BY 1, 2
ORDER BY 1;
```

**Output:**

| pizza_id | pizza_name | order_cnt |
| -------- | ---------- | --------- |
| 1        | Meatlovers | 9         |
| 2        | Vegetarian | 3         |

- There are 9 delivered Meatlovers pizzas.
- There are 3 delivered Vegetarian pizzas.
  
---
#### Question 5: How many Vegetarian and Meatlovers were ordered by each customer?

 All the pizzas were ordered but some of them had not been delivered successfully &rarr; Not exclude cancelled orders.

```sql
SELECT
	customer_id,
	pizza_name,
	COUNT(1) AS order_cnt
FROM customer_orders_temp
INNER JOIN pizza_runner.pizza_names USING(pizza_id)
WHERE 
	pizza_name = 'Vegetarian'
	OR pizza_name = 'Meatlovers'
GROUP BY 1, 2
ORDER BY 1, 2;
```

**Output:**

| customer_id | pizza_name | order_cnt |
| ----------- | ---------- | --------- |
| 101         | Meatlovers | 2         |
| 101         | Vegetarian | 1         |
| 102         | Meatlovers | 2         |
| 102         | Vegetarian | 1         |
| 103         | Meatlovers | 3         |
| 103         | Vegetarian | 1         |
| 104         | Meatlovers | 3         |
| 105         | Vegetarian | 1         |


- Customer 101 and customer 102 ordered 2 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 103 ordered 3 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 104 ordered 3 Meatlovers pizza.
- Customer 105 ordered 1 Vegetarian pizza.

---

#### Question 6: What was the maximum number of pizzas delivered in a single order?

```sql
WITH cnt_pizza_by_order AS (
  SELECT 
    order_id,
    COUNT(*) AS pizza_cnt
  FROM customer_orders_temp
  INNER JOIN runner_orders_temp USING(order_id)
  WHERE cancellation IS NULL
  GROUP BY 1
)

SELECT MAX(pizza_cnt) AS max_pizza_in_order
FROM cnt_pizza_by_order;
```

**Output:**

| max_pizza_in_order |
| ------------------ |
| 3                  |

Maximum number of pizzas delivered in a single order is 3.

---

#### Question 7: For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```sql
WITH order_changed AS (
  SELECT 
      customer_id,
      CASE 
          WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1
          ELSE NULL
      END is_changed
  FROM customer_orders_temp
  INNER JOIN runner_orders_temp USING(order_id)
  WHERE cancellation IS NULL
)

SELECT
	customer_id,
    COUNT(is_changed) AS changed_pizza_cnt,
    COUNT(1) - COUNT(is_changed) AS not_changed_pizza_cnt
FROM order_changed
GROUP BY 1
ORDER BY 1;
```

**Output:**

| customer_id | changed_pizza_cnt | not_changed_pizza_cnt |
| ----------- | ----------------- | --------------------- |
| 101         | 0                 | 2                     |
| 102         | 0                 | 3                     |
| 103         | 3                 | 0                     |
| 104         | 2                 | 1                     |
| 105         | 1                 | 0                     |

- Customer 101 and customer 102 seem to love original pizzas.
- Customer 103, customer 104, and customer 105 have their own preference for pizza topping and requested at least 1 change on their pizzas.

---

#### Question 8: How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT COUNT(
	CASE
		WHEN exclusions IS NULL OR extras IS NULL THEN NULL
  		ELSE 1
  	END
) AS exclusions_and_extras_pizza_cnt
FROM customer_orders_temp
INNER JOIN runner_orders_temp USING(order_id)
WHERE cancellation IS NULL;
```

**Output:**

| exclusions_and_extras_pizza_cnt |
| ------------------------------- |
| 1                               |

Only 1 pizza delivered that had both extra and exclusion toppings. 

---
#### Question 9: What was the total volume of pizzas ordered for each hour of the day?

```sql
SELECT 
	EXTRACT(HOUR FROM order_time) AS hour_of_day,
	COUNT(1) AS pizza_cnt
FROM customer_orders_temp
GROUP BY 1
ORDER BY 1;
```

**Output:**

| hour_of_day | pizza_cnt |
| ----------- | --------- |
| 11          | 1         |
| 13          | 3         |
| 18          | 3         |
| 19          | 1         |
| 21          | 3         |
| 23          | 3         |

- Highest volume of pizza ordered is at 13, 18, 21, 23.
- Lowest volume of pizza ordered is at 11, 19.

---
#### Question 10: What was the volume of orders for each day of the week?

```sql
SELECT 
	TO_CHAR(order_time, 'Day') AS day_of_week,
	COUNT(1) AS pizza_cnt
FROM customer_orders_temp
GROUP BY 1
ORDER BY 2;

```

**Output:**

| day_of_week | order_cnt |
| ----------- | --------- |
| Friday      | 1         |
| Saturday    | 2         |
| Thursday    | 2         |
| Wednesday   | 5         |

- Wednesday is the busiest day of the week with 5 orders.
- Thursday, Friday, and Saturdate have lower order count.
- There is no order on the other days of week.

---

### B. Runner and Customer Experience

#### Question 1: How many runners signed up for each 1 week period? (i.e. week starts `2021-01-01`)

`EXTRACT(WEEK FROM ...` calculates weeks based on ISO 8601, which may not align with the requirement *(week starts 2021-01-01)* &rarr; Customize approach to calculate week number:

- Calculate difference in days between the `registratrion_date` and 2021-01-01.
- Convert different days to weeks by dividing it by 7.
- Add 1 to the result, so week numbers start from 1.

```sql
SELECT 
  'Week ' || DIV(registration_date - MAKE_DATE(2021, 1, 1), 7) + 1 AS registration_week,
  COUNT(runner_id) AS runner_signup
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1;
```

**Output:**

| registration_week | runner_signup |
| ----------------- | ------------- |
| Week 1            | 2             |
| Week 2            | 1             |
| Week 3            | 1             |

- On week 1 of 2021, 2 runners signed up.
- On week 2 and 3 of 2021, 1 runners signed up.
---

#### Question 2: What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```sql
WITH unique_orders AS (
  SELECT DISTINCT
      order_id,
      order_time
  FROM customer_orders_temp
)

SELECT
	AVG(EXTRACT(MINUTE FROM pickup_time - order_time)) AS avg_pickup_time
FROM unique_orders
INNER JOIN runner_orders_temp USING(order_id)
WHERE pickup_time IS NOT NULL; 
```

**Output:**

| avg_pickup_time |
| --------------- |
| 15.625          |

The average time taken by runners to arrive at Pizza Runner HQ to pick up the order is 15.625 minutes.

---

#### Question 3: Is there any relationship between the number of pizzas and how long the order takes to prepare?

Preparation time = Time from the order made to it picked up by a runner.

```sql
WITH pizza_cnt_order AS (
  SELECT DISTINCT
      order_id,
      order_time,
      COUNT(1) AS pizza_cnt		
  FROM customer_orders_temp
  GROUP BY 1, 2
)

SELECT
	pizza_cnt,
	AVG(EXTRACT(MINUTE FROM pickup_time - order_time)) AS avg_pre_time
FROM pizza_cnt_order
INNER JOIN runner_orders_temp USING(order_id)
WHERE pickup_time IS NOT NULL 
GROUP BY 1
ORDER BY 1;
```

**Output:**

| pizza_cnt | avg_pre_time |
| --------- | ------------ |
| 1         | 12           |
| 2         | 18           |
| 3         | 29           |

The number of pizzas in an order increases, the average preparation time also tends to increase.

---

#### Question 4: What was the average distance travelled for each customer?

```sql
WITH unique_order_cus AS (
  SELECT DISTINCT
  		customer_id,
		order_id
  FROM customer_orders_temp
)

SELECT
	customer_id,
    AVG(distance)
FROM unique_order_cus
INNER JOIN runner_orders_temp USING(order_id)
GROUP BY 1
ORDER BY 1;
```

**Output:**

| customer_id | avg  |
| ----------- | ---- |
| 101         | 20   |
| 102         | 18.4 |
| 103         | 23.4 |
| 104         | 10   |
| 105         | 25   |

Customer 104 stays the nearest to Pizza Runner HQ at average distance of 10km, whereas Customer 105 stays the furthest at 25km.

---

#### Question 5: What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT MAX(duration) - MIN(duration) delivery_time_diff
FROM runner_orders_temp;
```

**Output:**

| delivery_time_diff |
| ------------------ |
| 30                 |

The difference between longest and shortest delivery time for all orders is 30 minutes.

---

#### Question 6: 

```sql
SELECT 
	runner_id,
    distance,
    distance / duration * 60 AS avg_speed
FROM runner_orders_temp
WHERE cancellation IS NULL -- Exclude cancelled orders
ORDER BY 1, 2;
```

**Output:**

| runner_id | distance | avg_speed          |
| --------- | -------- | ------------------ |
| 1         | 10       | 60                 |
| 1         | 13.4     | 40.2               |
| 1         | 20       | 37.5               |
| 1         | 20       | 44.44444444444444  |
| 2         | 23.4     | 93.6               |
| 2         | 23.4     | 35.099999999999994 |
| 2         | 25       | 60                 |
| 3         | 10       | 40                 |

- Runner 1 might slow down when running longer distance.
- Runner 2 vary speed a lot although distances don't vary too much.  There might be breaks or other factors affecting the speed.

---

#### Question 7: What is the successful delivery percentage for each runner?

```sql
SELECT 
	runner_id,
	100 - ROUND(100.0 * COUNT(cancellation) / COUNT(runner_id), 2) successful_delivery_pct
FROM runner_orders_temp
GROUP BY 1
ORDER BY 1;
```

**Output:**
| runner_id | successful_delivery_pct |
| --------- | ----------------------- |
| 1         | 100.00                  |
| 2         | 75.00                   |
| 3         | 50.00                   |

- Runner 1 has 100% successful delivery.
- Runner 2 has 75% successful delivery.
- Runner 3 has 50% successful delivery

---

### C. Ingredient Optimisation

#### Question 1: What are the standard ingredients for each pizza?

Use `STRING_AGG` function to create a comma-separated list of toppings for each pizza, ensure toppings are ordered alphabetically within each group.

```sql
SELECT
	pizza_name, 
	STRING_AGG(topping_name, ', ' ORDER BY topping_name) AS toppings
FROM pizza_recipes_temp r
INNER JOIN pizza_runner.pizza_names USING(pizza_id)
INNER JOIN pizza_runner.pizza_toppings t ON r.toppings = t.topping_id
GROUP BY 1
ORDER BY 1;
```

**Output:**

| pizza_name | toppings                                                              |
| ---------- | --------------------------------------------------------------------- |
| Meatlovers | BBQ Sauce, Bacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian | Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes            |

---

#### Question 2: What was the most commonly added extra?

```sql
WITH extra_toppings AS (
  SELECT
      UNNEST(STRING_TO_ARRAY(extras, ', '))::INT AS extras,
      COUNT(1) AS fre
  FROM customer_orders_temp
  GROUP BY 1
)

SELECT 
	topping_name,
	fre
FROM extra_toppings e
INNER JOIN pizza_runner.pizza_toppings t ON e.extras = t.topping_id
WHERE fre = (
	SELECT MAX(fre)
  	FROM extra_toppings
);
```

**Output:**

| topping_name | fre |
| ------------ | --- |
| Bacon        | 4   |

The most popular extra ingredient is bacon, chosen 4 times as an extra topping of on pizza. 

---

#### Question 3: What was the most common exclusion?

```sql
WITH excluded_toppings AS (
  SELECT
      UNNEST(STRING_TO_ARRAY(exclusions, ', '))::INT AS exclusions,
      COUNT(1) AS fre
  FROM customer_orders_temp
  GROUP BY 1
)

SELECT 
	topping_name,
	fre
FROM excluded_toppings e
INNER JOIN pizza_runner.pizza_toppings t ON e.exclusions = t.topping_id
WHERE fre = (
	SELECT MAX(fre)
  	FROM excluded_toppings
);
```

**Output:**

| topping_name | fre |
| ------------ | --- |
| Cheese       | 4   |

It appears that customers don't prefer cheese, as it was excluded from 4 pizzas.

---

#### Question 4: Generate an order item for each record in the `customers_orders` table 

The format of one of the following:
- `Meat Lovers`
- `Meat Lovers - Exclude Beef`
- `Meat Lovers - Extra Bacon`
- `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`

Steps:
1. Generate row numbers for customer orders.
2. Expand exclusions and extras by splitting them into an array of integers.
3. Find names of pizzas, extras, and excluded toppings.
4. Find names of original pizzas without customization.
5. Generate the order item column and combine result for both original and customized pizzas.
   
```sql
WITH order_cus_rn AS (
  SELECT 
      ROW_NUMBER() OVER() AS rn,
      *
  FROM customer_orders_temp
),

exclusives_extras AS (
  SELECT 
      rn,
      order_id,
      pizza_id,
      UNNEST(STRING_TO_ARRAY(exclusions, ', '))::INT AS exclusions,
      UNNEST(STRING_TO_ARRAY(extras, ', '))::INT AS extras
  FROM order_cus_rn o
),

customed_pizzas AS (
  SELECT
      rn,
      order_id,
      pizza_name,
      STRING_AGG(t1.topping_name, ', ' ORDER BY exclusions) AS exclusions,
      STRING_AGG(t2.topping_name, ', ' ORDER BY extras) AS extras
  FROM exclusives_extras o
  LEFT JOIN pizza_runner.pizza_names USING(pizza_id)
  LEFT JOIN pizza_runner.pizza_toppings t1 ON o.exclusions = t1.topping_id
  LEFT JOIN pizza_runner.pizza_toppings t2 ON o.extras = t2.topping_id
  GROUP BY 1, 2, 3
),

original_pizzas AS (
  SELECT
      rn,
      order_id,
      pizza_name,
      exclusions,
      extras
  FROM order_cus_rn
  INNER JOIN pizza_runner.pizza_names USING(pizza_id)
  WHERE exclusions IS NULL 
      AND extras IS NULL
)

SELECT 
	order_id,
	order_item
FROM (
  SELECT 
      rn,
      order_id,
      pizza_name || 
      CASE 
          WHEN exclusions IS NOT NULL THEN ' - Exclude ' || exclusions
          ELSE ''
      END ||
      CASE 
          WHEN extras IS NOT NULL THEN ' - Extra ' || extras
          ELSE ''
      END AS order_item
  FROM customed_pizzas
  UNION 
  SELECT 
      rn,
      order_id,
      pizza_name AS order_item
  FROM original_pizzas
) AS orders
ORDER BY rn;
```

**Output:**
| order_id | order_item                                                      |
| -------- | --------------------------------------------------------------- |
| 1        | Meatlovers                                                      |
| 2        | Meatlovers                                                      |
| 3        | Meatlovers                                                      |
| 3        | Vegetarian                                                      |
| 4        | Meatlovers - Exclude Cheese                                     |
| 4        | Meatlovers - Exclude Cheese                                     |
| 4        | Vegetarian - Exclude Cheese                                     |
| 5        | Meatlovers - Extra Bacon                                        |
| 6        | Vegetarian                                                      |
| 7        | Vegetarian - Extra Bacon                                        |
| 8        | Meatlovers                                                      |
| 9        | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
| 10       | Meatlovers                                                      |
| 10       | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |

---

#### Question 5: How many pizzas were ordered?

```sql
SELECT COUNT(pizza_id) pizza_ordered_cnt
FROM customer_orders_temp;
```

**Output:**

| pizza_ordered_cnt |
| ----------------- |
| 14                |

Total of 14 pizzas were ordered.

---

#### Question 6: How many pizzas were ordered?

```sql
SELECT COUNT(pizza_id) pizza_ordered_cnt
FROM customer_orders_temp;
```

**Output:**

| pizza_ordered_cnt |
| ----------------- |
| 14                |

Total of 14 pizzas were ordered.

---
