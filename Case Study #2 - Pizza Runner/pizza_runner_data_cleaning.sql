-- Add temp tables to clean data and use for queries -> Make sure the schemas clean and tidy.
-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/10/19

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


