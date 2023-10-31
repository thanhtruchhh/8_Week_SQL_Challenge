-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/11/01

/* --------------------
   B. Data Analysis Questions
   --------------------*/

SET search_path = foodie_fi;

-- 1. How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT customer_id) AS cus_cnt
FROM subscriptions;


-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value.

SELECT
	DATE_TRUNC('month', start_date) AS start_month,
	COUNT(1) AS distribution
FROM subscriptions
INNER JOIN plans USING(plan_id)
WHERE plan_name = 'trial'
GROUP BY 1
ORDER BY 1;


-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

SELECT 
	plan_id,
	plan_name,
	COUNT(1) AS no_events
FROM subscriptions
INNER JOIN plans USING(plan_id)
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY 1, 2
ORDER BY 1;


-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT
	COUNT(DISTINCT customer_id) AS churn_cnt,
	ROUND(
		100.0 * COUNT(DISTINCT customer_id) / (
			SELECT COUNT(DISTINCT customer_id)
			FROM subscriptions
	), 1) AS churn_pct
FROM subscriptions
INNER JOIN plans USING(plan_id)
WHERE plan_name = 'churn';


-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

-- Find the pre plan and pre start date 
WITH prev_sub AS (
  SELECT 
      *,
      LAG(plan_name) OVER(
          PARTITION BY customer_id
          ORDER BY start_date
      ) AS prev_plan,
      start_date - LAG(start_date) OVER(
          PARTITION BY customer_id
          ORDER BY start_date
      ) AS date_diff
  FROM subscriptions
  INNER JOIN plans USING(plan_id)
)

SELECT
	COUNT(1) AS churn_cnt,
	ROUND(
		100.0 * COUNT(1) / (
			SELECT COUNT(DISTINCT customer_id)
			FROM subscriptions
	), 1) AS churn_pct_to_all_cus,
	ROUND(
		100.0 * COUNT(1) / (
			SELECT COUNT(DISTINCT customer_id)
			FROM subscriptions
			INNER JOIN plans USING(plan_id)
			WHERE plan_name = 'churn'
	), 1) AS churn_pct_to_all_churn
FROM prev_sub
WHERE plan_name = 'churn'
      AND prev_plan = 'trial'
      AND date_diff = 7;


-- 6. What is the number and percentage of customer plans after their initial free trial?

-- Find the pre plan of each sub

WITH prev_sub AS (
  SELECT 
      *,
      LAG(plan_name) OVER(
          PARTITION BY customer_id
          ORDER BY start_date
      ) AS prev_plan
  FROM subscriptions
  INNER JOIN plans USING(plan_id)
)

SELECT 
	plan_id,
	plan_name,
	COUNT(1) AS cus_plan_cnt,
	ROUND(
      COUNT(1) * 100.0 / (
          SELECT COUNT(1)
          FROM prev_sub
          WHERE prev_plan = 'trial'
     ), 1) AS cus_plan_pct
FROM prev_sub
WHERE prev_plan = 'trial'
GROUP BY 1, 2
ORDER BY 1;


-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

-- Create a ranked list of subscription plans for each customer based on the latest start_date
WITH cur_plan AS (
  SELECT 
      plan_id,
      ROW_NUMBER() OVER(
          PARTITION BY customer_id
          ORDER BY start_date DESC
      ) rn
  FROM subscriptions
  WHERE start_date <= MAKE_DATE(2020, 12, 31)
)

SELECT 
	plan_id,
	plan_name,
	COUNT(1) AS cus_cnt,
	ROUND(
		COUNT(1) * 100.0 / (
			SELECT COUNT(1)
			FROM cur_plan
			WHERE rn = 1
		), 1) AS cus_pct
FROM cur_plan
INNER JOIN plans USING(plan_id)
WHERE  rn = 1
GROUP BY 1, 2
ORDER BY 1;


-- 8. How many customers have upgraded to an annual plan in 2020?

SELECT 
	plan_id,
	plan_name,
	COUNT(DISTINCT customer_id) AS cus_cnt
FROM subscriptions
INNER JOIN plans USING(plan_id)
WHERE EXTRACT(YEAR FROM start_date) = 2020
	AND plan_name LIKE '%annual%'
GROUP BY 1, 2
ORDER BY 1;


-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

-- Get customers who have chosen an annual plan.
WITH annual_cus AS (
  SELECT 
      customer_id,
      start_date AS start_annual,
      ROW_NUMBER() OVER(
      	PARTITION BY customer_id
      	ORDER BY start_date
      ) AS rn
  FROM subscriptions
  INNER JOIN plans USING(plan_id)
  WHERE plan_name LIKE '%annual%'
)

SELECT ROUND(AVG(start_annual - start_date)) day_avg
FROM subscriptions s
INNER JOIN annual_cus a USING(customer_id)
INNER JOIN plans USING(plan_id)
WHERE rn = 1 --  Ensure only considering the 1st annual subscription for each customer
	AND s.start_date <= a.start_annual
	AND plan_name = 'trial';


-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

-- Get customers who have chosen an annual plan.
WITH annual_cus AS (
  SELECT 
      customer_id,
      start_date AS start_annual,
      ROW_NUMBER() OVER(
      	PARTITION BY customer_id
      	ORDER BY start_date
      ) AS rn
  FROM subscriptions
  INNER JOIN plans USING(plan_id)
  WHERE plan_name LIKE '%annual%'
)

SELECT *
FROM (
  SELECT 
      CASE
          WHEN (start_annual - start_date)  <= 30 THEN '0-30 days'
          ELSE (((start_annual - start_date - 31) / 30 + 1)  * 30 + 1)::TEXT || '-' || (((start_annual - start_date - 31) / 30 + 1) * 30 + 30)::TEXT || ' days'
      END AS day_period,
      COUNT(1) AS cus_cnt,
      ROUND(AVG(start_annual - start_date)) AS day_avg
  FROM subscriptions s
  INNER JOIN annual_cus a USING(customer_id)
  INNER JOIN plans USING(plan_id)
  WHERE rn = 1 --  Ensure only considering the 1st annual subscription for each customer
      AND s.start_date <= a.start_annual
      AND plan_name = 'trial'
  GROUP BY 1
) AS a
ORDER BY SPLIT_PART(day_period, '-', 1)::INT;


-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

-- Get customers who subscribed to the basic monthly plan in 2020
WITH cus_basic AS (
  SELECT 
      customer_id,
      start_date AS basic_date
  FROM subscriptions
  INNER JOIN plans USING(plan_id)
  WHERE EXTRACT(YEAR FROM start_date) = 2020
      AND plan_name = 'basic monthly'
)

SELECT COUNT(1) AS cus_cnt
FROM subscriptions s
INNER JOIN cus_basic c ON s.customer_id = c.customer_id AND s.start_date < c.basic_date
INNER JOIN plans USING(plan_id)
WHERE plan_name = 'pro monthly';

