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

```

**Output:**

---

#### 8. How many customers have upgraded to an annual plan in 2020?

```sql

```

**Output:**

---

#### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

```sql

```

**Output:**

---

#### 10. Can you further breakdown this average value into 30 day periods 

*(i.e. 0-30 days, 31-60 days etc)*

```sql

```

**Output:**

---

#### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

```sql

```

**Output:**

---
