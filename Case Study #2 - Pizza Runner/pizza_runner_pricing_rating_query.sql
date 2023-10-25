-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/10/25

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
   D. Pricing and Ratings
   --------------------*/

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

-- Calculate total sales of each kind of pizza in sucessful orders.
WITH pizza_sales AS (
  SELECT
      pizza_id,
      pizza_name,
      COUNT(1) *
      CASE
          WHEN pizza_name = 'Meatlovers' THEN 12
          WHEN pizza_name = 'Vegetarian' THEN 10
      END AS total_sales
  FROM customer_orders_temp
  INNER JOIN runner_orders_temp USING(order_id)
  INNER JOIN pizza_runner.pizza_names USING(pizza_id)
  WHERE cancellation IS NULL
  GROUP BY 1, 2
)

SELECT SUM(total_sales) AS total_sales
FROM pizza_sales;


-- 2. What if there was an additional $1 charge for any pizza extras? 

-- Calculate total sales for each order line.
WITH pizza_topping_sales AS (
  SELECT 
      order_id,
      CASE
          WHEN pizza_name = 'Meatlovers' THEN 12
          WHEN pizza_name = 'Vegetarian' THEN 10
      END + 
      CASE 
          WHEN extras IS NOT NULL THEN ARRAY_LENGTH(STRING_TO_ARRAY(extras, ', '), 1)
          ELSE 0
      END * 1 AS total_sales
  FROM customer_orders_temp
  INNER JOIN pizza_runner.pizza_names USING(pizza_id)
)

SELECT SUM(total_sales) AS total_sales
FROM pizza_topping_sales
INNER JOIN runner_orders_temp USING(order_id)
WHERE cancellation IS NULL;


-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

DROP TABLE IF EXISTS runner_rating;
CREATE TABLE runner_rating (
  "rating_id" SERIAL PRIMARY KEY,
  "order_id" INTEGER,
  "rating" INTEGER,
  "review" VARCHAR(100),
  "rating_time" TIMESTAMP
);
INSERT INTO runner_rating
	("order_id", "rating", "review", "rating_time")
VALUES
  ('1', '4', null, '2020-01-01 21:30:15'),
  ('2', '5', 'Good experience', '2020-01-02 10:15:42'),
  ('4', '2', 'Could be better', '2020-01-04 14:30:10'),
  ('5', '5', 'Fantastic!', '2020-01-08 21:45:33'),
  ('3', '3', 'Decent service', '2020-01-03 01:20:18'),
  ('7', '4', null, '2020-01-08 22:10:15'),
  ('8', '3', 'Not bad', '2020-01-10 00:45:27'),
  ('10', '5', null, '2020-01-11 19:30:05');

SELECT * FROM pizza_runner.runner_rating;


-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?

    -- customer_id
    -- order_id
    -- runner_id
    -- rating
    -- order_time
    -- pickup_time
    -- Time between order and pickup
    -- Delivery duration
    -- Average speed
    -- Total number of pizzas
    
-- By using an inner join between customer_orders_temp and runner_rating, I filter out canceled orders since runner_rating only contains information about successful orders.
WITH order_rating AS (
  SELECT 
      order_id,
      customer_id,
      order_time,
      rating,
      COUNT(pizza_id) AS pizza_cnt
  FROM customer_orders_temp
  INNER JOIN pizza_runner.runner_rating USING(order_id)
  GROUP BY 1, 2, 3, 4
)

SELECT 
	customer_id,
	order_id,
	runner_id,
	rating,
	order_time,
	pickup_time,
	EXTRACT(MINUTE FROM pickup_time - order_time) AS prepare_time,
	duration,
	distance / duration * 60 avg_speed,
	pizza_cnt
FROM order_rating
INNER JOIN runner_orders_temp USING(order_id)
ORDER BY order_time;


-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

-- Calculate total sales for each order line.
WITH pizza_sales AS (
  SELECT 
      order_id,
      SUM(
      CASE
          WHEN pizza_name = 'Meatlovers' THEN 12
          WHEN pizza_name = 'Vegetarian' THEN 10
      END) AS total_sales
  FROM customer_orders_temp
  INNER JOIN pizza_runner.pizza_names USING(pizza_id)
  GROUP BY 1
)

SELECT SUM(total_sales - distance * 0.3) total_revenue
FROM pizza_sales
INNER JOIN runner_orders_temp USING(order_id)
WHERE cancellation IS NULL;

