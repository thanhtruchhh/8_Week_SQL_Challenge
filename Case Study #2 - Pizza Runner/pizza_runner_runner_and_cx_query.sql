-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/10/22

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
   B. Runner and Customer Experience
   --------------------*/

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
  'Week ' || DIV(registration_date - MAKE_DATE(2021, 1, 1), 7) + 1 AS registration_week,
  COUNT(runner_id) AS runner_signup_cnt
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1;
 
 
-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

-- Get unique orders
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
WHERE pickup_time IS NOT NULL; -- Exclude cancellated orders


-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

-- Get unique orders and count number of items in each order
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
WHERE pickup_time IS NOT NULL -- Exclude cancellated orders
GROUP BY 1
ORDER BY 1;

    
-- 4. What was the average distance travelled for each customer?

-- Get unique orders and customer
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


-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) - MIN(duration) delivery_time_diff
FROM runner_orders_temp;


-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT 
  runner_id,
  distance,
  distance / duration * 60 AS avg_speed
FROM runner_orders_temp
WHERE cancellation IS NULL -- Exclude cancelled orders
ORDER BY 1, 2;


-- 7. What is the successful delivery percentage for each runner?

SELECT 
	runner_id,
	100 - ROUND(100 * COUNT(cancellation) / COUNT(runner_id), 2) successful_delivery_pct
FROM runner_orders_temp
GROUP BY 1
ORDER BY 1;

