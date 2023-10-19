# Case Study #1 - Danny's Diner
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

-- Wednesday is the busiest day of the week with 5 orders.
-- Thursday, Friday, and Saturdate have lower order count.
-- There is no orders on the other days of week.

---
