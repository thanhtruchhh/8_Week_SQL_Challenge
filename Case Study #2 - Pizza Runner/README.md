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
