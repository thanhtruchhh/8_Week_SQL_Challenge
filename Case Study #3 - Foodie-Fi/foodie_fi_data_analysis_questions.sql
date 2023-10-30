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



