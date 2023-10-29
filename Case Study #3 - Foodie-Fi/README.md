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

