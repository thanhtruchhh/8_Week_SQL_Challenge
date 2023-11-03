# Case Study #3 - Foodie-Fi
<img src="https://8weeksqlchallenge.com/images/case-study-designs/3.png" alt="Case Study #3 - Foodie-Fi Image" width="500" height="520">

## Business Task

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.

Full Description: [Case Study #3 - Foodie-Fi](https://8weeksqlchallenge.com/case-study-3/)

Database Environment: PostgreSQL v13 on [DB Fiddle](https://www.db-fiddle.com/f/rHJhRrXy5hbVBNJ6F6b9gJ/16)

## Dataset

<img src="https://8weeksqlchallenge.com/images/case-study-3-erd.png" alt="Foodie-Fi entity relationship diagram">

## Questions and Solutions

### A. Customer Journey

Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

```sql
SELECT 
	customer_id,
	plan_name, 
	start_date,
	start_date - LAG(start_date) OVER(
		PARTITION BY customer_id
		ORDER BY start_date 
    ) AS date_diff
FROM foodie_fi.subscriptions 
INNER JOIN foodie_fi.plans USING(plan_id)
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)
ORDER BY 1, 3;
```

**Output:**

| customer_id | plan_name     | start_date               | date_diff|
| ----------- | ------------- | ------------------------ | -------- |
| 1           | trial         | 2020-08-01T00:00:00.000Z |          |
| 1           | basic monthly | 2020-08-08T00:00:00.000Z | 7        |
| 2           | trial         | 2020-09-20T00:00:00.000Z |          |
| 2           | pro annual    | 2020-09-27T00:00:00.000Z | 7        |
| 11          | trial         | 2020-11-19T00:00:00.000Z |          |
| 11          | churn         | 2020-11-26T00:00:00.000Z | 7        |
| 13          | trial         | 2020-12-15T00:00:00.000Z |          |
| 13          | basic monthly | 2020-12-22T00:00:00.000Z | 7        |
| 13          | pro monthly   | 2021-03-29T00:00:00.000Z | 97       |
| 15          | trial         | 2020-03-17T00:00:00.000Z |          |
| 15          | pro monthly   | 2020-03-24T00:00:00.000Z | 7        |
| 15          | churn         | 2020-04-29T00:00:00.000Z | 36       |
| 16          | trial         | 2020-05-31T00:00:00.000Z |          |
| 16          | basic monthly | 2020-06-07T00:00:00.000Z | 7        |
| 16          | pro annual    | 2020-10-21T00:00:00.000Z | 136      |
| 18          | trial         | 2020-07-06T00:00:00.000Z |          |
| 18          | pro monthly   | 2020-07-13T00:00:00.000Z | 7        |
| 19          | trial         | 2020-06-22T00:00:00.000Z |          |
| 19          | pro monthly   | 2020-06-29T00:00:00.000Z | 7        |
| 19          | pro annual    | 2020-08-29T00:00:00.000Z | 61       |

- Customer 1 started with a trial subscription and continued with a basic monthly subscription in 7 days after sign-up.
- Customer 2 started with a trial subscription and continued with a pro annual subscription in 7 days after sign-up.
- Customer 11 started with a trial subscription but churned in 7 days after sign-up.
- Customer 13 started with a trial subscription and purchased with a basic monthly subscription 7 days after sign-up and in 3 months later, they upgraded to a pro monthly subscription.
- Customer 15 started with a trial subscription, purchased a basic monthly subscription in 7 days after sign-up and has churned in a month.
- Customer 16 started with a trial subscription, purchased a basic monthly subscription in 7 days after sign-up and in 4 months after that has ugraded to a pro annual subscription.
- Customer 18 started with a trial subscription and continued with a pro annual subscription in 7 days after sign-up.
- Customer 19 started with a trial subscription and purchased with a pro monthly subscription 7 days after sign-up and in 2 months later, they upgraded to a pro annual subscription.

---

### B. Data Analysis Questions

#### 1. How many customers has Foodie-Fi ever had?

```sql
SELECT COUNT(DISTINCT customer_id) AS cus_cnt
FROM subscriptions;
```

**Output:**

| cus_cnt |
| ------- |
| 1000    |

The company has had 1000 customers.

---

#### 2. What is the monthly distribution of `trial` plan `start_date` values for our dataset 

*Use the start of the month as the group by value.*

```sql
SELECT
	DATE_TRUNC('month', start_date) AS start_month,
	COUNT(1) AS distribution
FROM subscriptions
INNER JOIN plans USING(plan_id)
WHERE plan_name = 'trial'
GROUP BY 1
ORDER BY 1;
```

**Output:**

| start_month              | distribution |
| ------------------------ | ------------ |
| 2020-01-01T00:00:00.000Z | 88           |
| 2020-02-01T00:00:00.000Z | 68           |
| 2020-03-01T00:00:00.000Z | 94           |
| 2020-04-01T00:00:00.000Z | 81           |
| 2020-05-01T00:00:00.000Z | 88           |
| 2020-06-01T00:00:00.000Z | 79           |
| 2020-07-01T00:00:00.000Z | 89           |
| 2020-08-01T00:00:00.000Z | 88           |
| 2020-09-01T00:00:00.000Z | 87           |
| 2020-10-01T00:00:00.000Z | 79           |
| 2020-11-01T00:00:00.000Z | 75           |
| 2020-12-01T00:00:00.000Z | 84           |

---

- Mar has the highest number of trial plans *(94)*.
- Feb has the lowest number of trial plans *(68)*.
  
#### 3. What plan `start_date` values occur after the year 2020 for our dataset? 

*Show the breakdown by count of events for each `plan_name`.*

```sql
SELECT 
	plan_id,
	plan_name,
	COUNT(1) AS no_events
FROM subscriptions
INNER JOIN plans USING(plan_id)
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY 1, 2
ORDER BY 1;

```

**Output:**

| plan_id | plan_name     | no_events |
| ------- | ------------- | --------- |
| 1       | basic monthly | 8         |
| 2       | pro monthly   | 60        |
| 3       | pro annual    | 63        |
| 4       | churn         | 71        |

There were following events with the start date after 2020:
- 8 basic monthly subscriptions purchased.
- 71 customer churned.
- 63 pro annual subscriptions purchased.
- 60 pro monthly subscriptions purchased.

---

#### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

```sql
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
```

**Output:**

| churn_cnt | churn_pct |
| --------- | --------- |
| 307       | 30.7      |

There were 307 churned customers, and churn rate is 30.7%.

---

#### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

```sql
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
```

**Output:**

| churn_cnt | churn_pct_to_all_cus | churn_pct_to_all_churn |
| --------- | -------------------- | ---------------------- |
| 92        | 9.2                  | 30.0                   |

There were 92 customers churning immediately after their initial free trial. It presents approximately 9.2% of the number of customers and accounts for 30% of the number of churned customers.

---

#### 6. What is the number and percentage of customer plans after their initial free trial?

```sql
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
```

**Output:**

| plan_id | plan_name     | cus_plan_cnt | cus_plan_pct |
| ------- | ------------- | ------------ | ------------ |
| 1       | basic monthly | 546          | 54.6         |
| 2       | pro monthly   | 325          | 32.5         |
| 3       | pro annual    | 37           | 3.7          |
| 4       | churn         | 92           | 9.2          |

Over 90% of customers chose paid plan with a majority opting for the basic monthly and pro monthly plans, likely due to the cheaper pricing.

---

#### 7. What is the customer count and percentage breakdown of all 5 `plan_name` values at `2020-12-31`?

```sql
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
```

**Output:**

| plan_id | plan_name     | cus_cnt | cus_pct |
| ------- | ------------- | ------- | ------- |
| 0       | trial         | 19      | 1.9     |
| 1       | basic monthly | 224     | 22.4    |
| 2       | pro monthly   | 326     | 32.6    |
| 3       | pro annual    | 195     | 19.5    |
| 4       | churn         | 236     | 23.6    |


---

#### 8. How many customers have upgraded to an annual plan in 2020?

```sql
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
```

**Output:**
| plan_id | plan_name  | cus_cnt |
| ------- | ---------- | ------- |
| 3       | pro annual | 195     |

195 customers have upgraded to an annual plan in 2020.

---

#### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

```sql
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
WHERE rn = 1
	AND s.start_date <= a.start_annual
	AND plan_name = 'trial';
```

**Output:**

| day_avg |
| ------- |
| 105     |

It takes 105 days on average for a customer upgrade to an annual plan.

---

#### 10. Can you further breakdown this average value into 30 day periods 

*(i.e. 0-30 days, 31-60 days etc)*

**Steps:**
1. Identify customers who have been on an annual plan by the `annual_cus` CTE.
2. Join the subscriptions table with the CTE annual_cus and the plans table.
3. Keep only the first annual subscription record for each customer *(`rn = 1`)* and customers on the `trial` plan and where the trial subscription `start_date` is before or equal to the annual subscription start date.
4. Group the result by 30-day period and apply aggregate function.
5. Order the result based on the start of the 30-day period.

```sql
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
  WHERE rn = 1
      AND s.start_date <= a.start_annual
      AND plan_name = 'trial'
  GROUP BY 1
) AS a
ORDER BY SPLIT_PART(day_period, '-', 1)::INT;
```

**Output:**

| day_period   | cus_cnt | day_avg |
| ------------ | ------- | ------- |
| 0-30 days    | 49      | 10      |
| 31-60 days   | 24      | 42      |
| 61-90 days   | 34      | 71      |
| 91-120 days  | 35      | 101     |
| 121-150 days | 42      | 133     |
| 151-180 days | 36      | 162     |
| 181-210 days | 26      | 191     |
| 211-240 days | 4       | 224     |
| 241-270 days | 5       | 257     |
| 271-300 days | 1       | 285     |
| 301-330 days | 1       | 327     |
| 331-360 days | 1       | 346     |

---

#### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```sql
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
```

**Output:**

| cus_cnt |
| ------- |
| 0       |

 There is no customer downgraded their plans from a pro monthly to a basic monthly plan in 2020.
 
---

### C. Challenge Payment Question

The Foodie-Fi team wants you to create a new `payments` table for the year 2020 that includes amounts paid by each customer in the `subscriptions` table with the following requirements:
- Monthly payments always occur on the same day of month as the original `start_date` of any monthly paid plan
- Upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- Upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- Once a customer churns they will no longer make payments

**Steps:**
1. Use `LEAD` to find the next subscription of each customer in 2020.
2. Use `GENERATE_SERIES` to calculate the `payment_date` based on specific conditions:
   - If the plan is pro annual, the `payment_date` is set to the `start_date`.
   - If a customer churns, the record is excluded.
   - If the plan is monthly and there is no activity for a customer until the end of 2020, payments are processed monthly from the `start_date` to the end of the year.
   - Otherwise, payments are processed monthly from the `start_date` to the day before the next new subscription starts.
3. Use `LAG` to find the previous payment information for each customer in 2020.
4. Calculate payment amount:
   - If the plan is pro annual and the previous plan is basic monthly with `payment_date` less than `prev_date` - 1 month, set the amount is current price - the previous price.
   - Otherwise, set the is the price.
   
```sql
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
```
**Output:**

| customer_id | plan_id | plan_name     | payment_date             | amount | row_number |
| ----------- | ------- | ------------- | ------------------------ | ------ | ---------- |
| 1           | 1       | basic monthly | 2020-08-08T00:00:00.000Z | 9.90   | 1          |
| 1           | 1       | basic monthly | 2020-09-08T00:00:00.000Z | 9.90   | 2          |
| 1           | 1       | basic monthly | 2020-10-08T00:00:00.000Z | 9.90   | 3          |
| 1           | 1       | basic monthly | 2020-11-08T00:00:00.000Z | 9.90   | 4          |
| 1           | 1       | basic monthly | 2020-12-08T00:00:00.000Z | 9.90   | 5          |
| 2           | 3       | pro annual    | 2020-09-27T00:00:00.000Z | 199.00 | 1          |
...
| 13          | 1       | basic monthly | 2020-12-22T00:00:00.000Z | 9.90   | 1          |
| 14          | 1       | basic monthly | 2020-09-29T00:00:00.000Z | 9.90   | 1          |
| 14          | 1       | basic monthly | 2020-10-29T00:00:00.000Z | 9.90   | 2          |
| 14          | 1       | basic monthly | 2020-11-29T00:00:00.000Z | 9.90   | 3          |
| 14          | 1       | basic monthly | 2020-12-29T00:00:00.000Z | 9.90   | 4          |
| 15          | 2       | pro monthly   | 2020-03-24T00:00:00.000Z | 19.90  | 1          |
| 15          | 2       | pro monthly   | 2020-04-24T00:00:00.000Z | 19.90  | 2          |
| 16          | 1       | basic monthly | 2020-06-07T00:00:00.000Z | 9.90   | 1          |
| 16          | 1       | basic monthly | 2020-07-07T00:00:00.000Z | 9.90   | 2          |
| 16          | 1       | basic monthly | 2020-08-07T00:00:00.000Z | 9.90   | 3          |
| 16          | 1       | basic monthly | 2020-09-07T00:00:00.000Z | 9.90   | 4          |
| 16          | 1       | basic monthly | 2020-10-07T00:00:00.000Z | 9.90   | 5          |
| 16          | 3       | pro annual    | 2020-10-21T00:00:00.000Z | 189.10 | 6          |
...
| 18          | 2       | pro monthly   | 2020-07-13T00:00:00.000Z | 19.90  | 1          |
| 18          | 2       | pro monthly   | 2020-08-13T00:00:00.000Z | 19.90  | 2          |
| 18          | 2       | pro monthly   | 2020-09-13T00:00:00.000Z | 19.90  | 3          |
| 18          | 2       | pro monthly   | 2020-10-13T00:00:00.000Z | 19.90  | 4          |
| 18          | 2       | pro monthly   | 2020-11-13T00:00:00.000Z | 19.90  | 5          |
| 18          | 2       | pro monthly   | 2020-12-13T00:00:00.000Z | 19.90  | 6          |
| 19          | 2       | pro monthly   | 2020-06-29T00:00:00.000Z | 19.90  | 1          |
| 19          | 2       | pro monthly   | 2020-07-29T00:00:00.000Z | 19.90  | 2          |
| 19          | 3       | pro annual    | 2020-08-29T00:00:00.000Z | 199.00 | 3          |

---

### D. Outside The Box Questions

#### 1. How would you calculate the rate of growth for Foodie-Fi?

Growth rate = (Current value - Previous value) / Previous value. In the below code, I will calculate MoM revenue growth.

**Steps:**
1. Use `LEAD` to find the next subscription of each customer, excluding trial subscriptions because they don't generate revenue.
3. Filter out churn subscriptions, then use `GENERATE_SERIES` to calculate the `payment_date` based on specific conditions:
   - Set the billing period based on the plan name *(annual, monthly)*.
   - If a customer has no activity until the maximum `start_date` in the table, proccess payments at regular intervals from the `start_date` to the max date.
   - Otherwise, payments are processed monthly from the `start_date` to the day before the next new subscription starts.
4. Use `LAG` to find the previous payment information for each record.
5. Calculate revenue by month:
   - If the plan is pro annual and the previous plan is basic monthly with `payment_date` less than `prev_date` - 1 month, set the amount is current price - the previous price.
   - Otherwise, set the is the price.
6. Calulate the MoM change.

```sql
WITH next_sub AS (
  SELECT
      customer_id,
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
  LEFT JOIN plans USING(plan_id)
  WHERE plan_name != 'trial'
),

max_date AS (
  SELECT MAX(start_date)
  FROM subscriptions
),

payment_dates AS (
  SELECT
      customer_id,
      plan_name,
      start_date,
      GENERATE_SERIES(
      start_date,
          CASE
              WHEN next_plan IS NULL THEN (SELECT * FROM max_date)
              ELSE next_start_date - INTERVAL '1 day'
          END,
          CASE
              WHEN plan_name = 'pro annual' THEN INTERVAL '1 year'
              ELSE INTERVAL '1 month'
          END
      ) AS payment_date,
      price
  FROM next_sub
  WHERE plan_name != 'churn'
)

,prev_payments AS (
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
  FROM payment_dates
),

monthly_revenue AS (
  SELECT
      DATE_TRUNC('month', payment_date) AS month,
      SUM(
        CASE
            WHEN plan_name = 'pro annual' AND prev_plan = 'basic monthly' AND payment_date < prev_date + INTERVAL '1 month' THEN price - prev_price
            ELSE price
        END 
      ) AS revenue
  FROM prev_payments
  GROUP BY 1
),

revenue_with_previous AS (
  SELECT
    *,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue
  FROM monthly_revenue
)

SELECT
  *,
  ROUND(
    (revenue - prev_month_revenue) * 100.0 / prev_month_revenue,
    2
  ) AS percentage_change
FROM revenue_with_previous
ORDER BY 1;
```

**Output:**

| month                    | revenue  | prev_month_revenue | percentage_change |
| ------------------------ | -------- | ------------------ | ----------------- |
| 2020-01-01T00:00:00.000Z | 1282.00  |                    |                   |
| 2020-02-01T00:00:00.000Z | 2772.70  | 1282.00            | 116.28            |
| 2020-03-01T00:00:00.000Z | 4153.90  | 2772.70            | 49.81             |
| 2020-04-01T00:00:00.000Z | 5764.40  | 4153.90            | 38.77             |
| 2020-05-01T00:00:00.000Z | 6967.00  | 5764.40            | 20.86             |
| 2020-06-01T00:00:00.000Z | 8318.90  | 6967.00            | 19.40             |
| 2020-07-01T00:00:00.000Z | 9781.20  | 8318.90            | 17.58             |
| 2020-08-01T00:00:00.000Z | 11511.50 | 9781.20            | 17.69             |
| 2020-09-01T00:00:00.000Z | 12407.00 | 11511.50           | 7.78              |
| 2020-10-01T00:00:00.000Z | 14208.50 | 12407.00           | 14.52             |
| 2020-11-01T00:00:00.000Z | 12247.10 | 14208.50           | -13.80            |
| 2020-12-01T00:00:00.000Z | 12804.10 | 12247.10           | 4.55              |
| 2021-01-01T00:00:00.000Z | 13870.00 | 12804.10           | 8.32              |
| 2021-02-01T00:00:00.000Z | 12568.00 | 13870.00           | -9.39             |
| 2021-03-01T00:00:00.000Z | 10738.50 | 12568.00           | -14.56            |
| 2021-04-01T00:00:00.000Z | 11664.80 | 10738.50           | 8.63              |

- The growth rate tends to decrease over time. 
- In November 2020 and in February and March 2021, the growth rate is negative.

---

#### 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
- Total revenue.
- #Active customers = #Customers - #Churned customers.
- #Paying customers = #Customers - #Churned customers - #Trial customers.
- #New customers = #Trial customers.
- Churn rate.
- Revenue growth rate, #Customers growth rate.
- #Active customers on date after their sign-up (cohort analysis: day 7, day 30).
- #Customers by plan &rarr; Understand customer preference.
- Average revenue by user = Total revenue / #Active customers.
- Average revenue by customer = Total revenue / #Paying customers.

#### 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?
- If a user become a customer or not after 7-day trial.
- What happend after the first purchase? Do they continue their subscribtion, upgrade, downgrade or churn?
- How long do they use Foodie-Fi before churning? What factors contribute to their churn—cost, user experience, lack of variety in films, or personal preferences?
- In addition, information about app usage time, frequency of use, and the categories users frequently watch is also very useful for this analysis.

#### 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

1. Why are you cancelling your subscribtion? (Select multiple choice)
   - The subscription cost is too high.
   - I am not satisfied with the quality of the content.
   - I found the variety of content to be limited.
   - I experienced technical issues while using the service.
   - The user interface and user experience (UI/UX) need improvement.
   - Limited variety in subscription plans, no family-friendly options.
   - Lack of child-appropriate content.
   - Limited diversity in subtitle languages.
   - Poor customer service.
   - Others (Please specify).
     
2. On a scale of 1 to 10, how satisfied were you with your Foodie-Fi subscription? (Select one)
   
3. What specific aspects of Foodie-Fi did you enjoy the most during your subscription? (Select one)
   - Enjoyed the unique and exclusive cooking shows available on Foodie-Fi.
   - Liked the wide range of cuisines and cooking styles featured on Foodie-Fi.
   - Appreciated the quality and uniqueness of the recipes presented in the content.
   - Enjoyed interactive features like recipe downloads, cooking tips, and user engagement.
   - Liked the regular updates and new content releases on the platform.
   - Appreciated the user-friendly platform and ease of finding and watching content.
   - Found the content recommendations and personalized playlists helpful.
   - Others (Please specify).
     
4. What aspects of Foodie-Fi could be improved to better meet your needs and expectations? (Optional)

#### 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?
Understand the reasons for customer churn first:
- For users who churn after a 7-day trial, it's essential to investigate whether they are precisely the target customers. If they are not, a review and adjustment of marketing strategies should be undertaken. If they are the target audience, it's advisable to re-engage them with reminders about Foodie-Fi through targeted advertising campaigns.
- If a paying user churns, we can inquire about the reasons.
	- If the primary reason for churn is cost, it's worth considering adjusting the service pricing or targeting higher-income segments. Alternatively, the company should explore the creation of flexible subscription packages, such as family monthly plans or basic annual plans.
 	- In the case of churn due to technical problems or interface issues, prompt resolution should be a priority.

- Validiation of effectiveness:
  - A/B testing.
  - Customer surveys.
  - Customer feedback analysis.
  - Tracking retetion metrics *(CLV, cohort analysis)*.
