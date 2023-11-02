-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/11/02

/* --------------------
   C. Challenge Payment Question
   --------------------*/
   
SET search_path = foodie_fi;

-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

--     monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
--     upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
--     upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
--     once a customer churns they will no longer make payments

-- Get next subcription of each cus in 2020
WITH next_sub AS (
  SELECT 
      customer_id,
      plan_id,
      plan_name,
      start_date,
      price,
      LEAD(plan_name) OVER(
      	PARTITION BY customer_id
      	ORDER BY start_date
      ) AS next_plan,
      LEAD(start_date) OVER(
      	PARTITION BY customer_id
      	ORDER BY start_date
      ) AS next_start_date
  FROM subscriptions
  INNER JOIN plans USING(plan_id)
  WHERE plan_name != 'trial'
      AND EXTRACT(YEAR FROM start_date) = 2020
),

-- Get payment date
payments AS (
  SELECT
      customer_id,
      plan_id,
      plan_name,
      GENERATE_SERIES(
          start_date,
          CASE
              WHEN plan_name = 'pro annual' THEN start_date
              WHEN plan_name = 'churn' THEN NULL
              WHEN next_plan IS NULL THEN MAKE_DATE(2020, 12, 31)
              ELSE next_start_date - INTERVAL '1 day'
          END, 
      '1 month') AS payment_date,
      price
  FROM next_sub
),

-- Get previous payment info
prev_payments AS (
  SELECT
      *,
      LAG(plan_name) OVER(
          PARTITION BY customer_id
          ORDER BY payment_date
      ) AS prev_plan,
      LAG(payment_date) OVER(
          PARTITION BY customer_id
          ORDER BY payment_date
      ) AS prev_date,
      LAG(price) OVER(
          PARTITION BY customer_id
          ORDER BY payment_date
      ) AS prev_price
  FROM payments
)

SELECT
	customer_id,
	plan_id,
	plan_name,
	payment_date,
	CASE
		WHEN plan_name = 'pro annual' AND prev_plan = 'basic monthly' AND payment_date < prev_date + INTERVAL '1 month' THEN price - prev_price
 		ELSE price
	END AS amount,
	ROW_NUMBER() OVER(
		PARTITION BY customer_id
		ORDER BY payment_date
    )
FROM prev_payments
ORDER BY 1, 4;
