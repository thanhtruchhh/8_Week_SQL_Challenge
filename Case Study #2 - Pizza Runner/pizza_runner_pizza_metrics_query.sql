-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/10/20

/* --------------------
   Data Cleaning
   --------------------*/

-- Table: customer_orders
-- Replace all blank or 'null' values wiht NULL in the exclusions and extras fields.

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


-- Table: runner_orders
-- Replace all blank or 'null' values wiht NULL in the pickup_time, distance, duration, and cancellation fields.
-- Remove 'km' from the distance field.
-- Extract numeric characters from the duration field.

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

-- Change data type in the runner_orders_temp table
ALTER TABLE runner_orders_temp
ALTER COLUMN pickup_time TYPE TIMESTAMP,
ALTER COLUMN distance TYPE FLOAT,
ALTER COLUMN duration TYPE INT;


-- Table: pizza_recipes
-- Split comma delimited lists into rows.
CREATE TEMP TABLE pizza_recipes_temp AS
SELECT
	pizza_id,
    UNNEST(STRING_TO_ARRAY(toppings, ', '))::INT AS toppings
FROM pizza_runner.pizza_recipes;

-- Change data type in the pizza_recipes_temp table
ALTER TABLE pizza_recipes_temp
ALTER toppings TYPE INT;


/* --------------------
   A. Pizza Metrics
   --------------------*/
-- Ordered pizzas, made orders: Include cancelled orders.
-- Delivered pizzas, delivered orders, successful orders: Exclude cancelled orders.
   
-- 1. How many pizzas were ordered?

SELECT COUNT(pizza_id) pizza_ordered_cnt
FROM customer_orders_temp;


-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) order_cnt
FROM customer_orders_temp;


-- 3. How many successful orders were delivered by each runner?

SELECT
	runner_id,
	COUNT(order_id) AS order_cnt
FROM runner_orders_temp
WHERE cancellation IS NULL
GROUP BY 1
ORDER BY 1;


-- 4. How many of each type of pizza was delivered?

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


-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

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


-- 6. What was the maximum number of pizzas delivered in a single order?

-- Calc number of pizzas of each order
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


-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

-- Mark which is changed in each order line
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


-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(
	CASE
		WHEN exclusions IS NULL OR extras IS NULL THEN NULL
  		ELSE 1
  	END
) AS exclusions_and_extras_pizza_cnt
FROM customer_orders_temp
INNER JOIN runner_orders_temp USING(order_id)
WHERE cancellation IS NULL;


-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT 
	EXTRACT(HOUR FROM order_time) AS hour_of_day,
	COUNT(1) AS pizza_cnt
FROM customer_orders_temp
GROUP BY 1
ORDER BY 1;


-- 10. What was the volume of orders for each day of the week?

SELECT 
	TO_CHAR(order_time, 'Day') AS day_of_week,
	COUNT(DISTINCT order_id) AS order_cnt
FROM customer_orders_temp
GROUP BY 1
ORDER BY 2;


