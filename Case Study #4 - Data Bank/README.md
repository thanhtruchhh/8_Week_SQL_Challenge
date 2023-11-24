# Case Study #4 - Data Bank
<img src="https://8weeksqlchallenge.com/images/case-study-designs/4.png" alt="Case Study #4 - Data Bank Image" width="500" height="520">

## Business Task

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.

Full Description: [Case Study #4 - Data Bank](https://8weeksqlchallenge.com/case-study-4/)

Database Environment: PostgreSQL v13 on [DB Fiddle](https://www.db-fiddle.com/f/2GtQz4wZtuNNu7zXH5HtV4/3)

## Dataset

<img src="https://8weeksqlchallenge.com/images/case-study-4-erd.png" alt="Data Bank entity relationship diagram">


## Questions and Solutions

### Explore data

```sql
SELECT 
	MIN(start_date), 
	MAX(start_date),
 	MIN(end_date), 
	MAX(end_date)
FROM customer_nodes;
```

**Output**

| min | max  | min                      | max                      |
| --- | ---- | ------------------------ | ------------------------ |
| 0   | 1000 | 2020-01-01T00:00:00.000Z | 2020-04-28T00:00:00.000Z |

The maximum end date is set to 9999-12-31. This may indicate that these records represent the latest allocation.

### A. Customer Nodes Exploration

#### 1. How many unique nodes are there on the Data Bank system?

```sql
SELECT COUNT(DISTINCT node_id) AS unique_node_cnt
FROM customer_nodes;
```

**Output**

| unique_node_cnt |
| --------------- |
| 5               |

---
    
#### 2. What is the number of nodes per region?

```sql
SELECT 
	region_id,
	region_name,
 	COUNT(DISTINCT node_id) AS unique_node_cnt
FROM customer_nodes
LEFT JOIN regions USING(region_id)
GROUP BY 1, 2
ORDER BY 1;
```

**Output**

| region_id | region_name | unique_node_cnt |
| --------- | ----------- | --------------- |
| 1         | Australia   | 5               |
| 2         | America     | 5               |
| 3         | Africa      | 5               |
| 4         | Asia        | 5               |
| 5         | Europe      | 5               |

---

#### 3. How many customers are allocated to each region?

```sql
SELECT 
	region_id,
	region_name,
 	COUNT(DISTINCT customer_id) AS unique_cus_cnt
FROM customer_nodes
LEFT JOIN regions USING(region_id)
GROUP BY 1, 2
ORDER BY 1;
```

**Output**

| region_id | region_name | unique_cus_cnt |
| --------- | ----------- | -------------- |
| 1         | Australia   | 110            |
| 2         | America     | 105            |
| 3         | Africa      | 102            |
| 4         | Asia        | 95             |
| 5         | Europe      | 88             |

---

#### 4. How many days on average are customers reallocated to a different node?

**Steps**

1. Mark allocations whose next allocation having the same node ID.
2. Calculate the duration for each allocation: `end_date - start_date + 1`.
3. Sum up all the durations.
4. Count the number of allocations to a different node.
5. Divide the total duration by the number of merged allocations to get the average.
   
```sql
WITH next_node AS (
  SELECT *,
      LEAD(node_id) OVER(
          PARTITION BY customer_id, region_id
          ORDER BY start_date
      ) AS next_node_id
  FROM customer_nodes
  WHERE end_date != '9999-12-31' 
)

SELECT 
	SUM(end_date - start_date + 1) * 1.0/
	SUM(
		CASE
			WHEN next_node_id IS NOT NULL AND next_node_id = node_id THEN 0
			ELSE 1
		END) AS days_avg
FROM next_node;
```

**Output**

| days_avg            |
| ------------------- |
| 18.8285828984343637 |

---

#### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

```sql
WITH days_in_node AS (
  SELECT 
      *,
      end_date - start_date + 1 AS day_cnt
  FROM customer_nodes
  WHERE end_date != '9999-12-31' 
)

SELECT
    region_id,
	region_name,
	PERCENTILE_CONT(0.50) WITHIN GROUP(ORDER BY day_cnt) AS median,
    PERCENTILE_CONT(0.80) WITHIN GROUP(ORDER BY day_cnt) AS p_8,
    PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY day_cnt) AS p_95
FROM days_in_node
LEFT JOIN regions USING(region_id)
GROUP BY 1, 2;
```

**Output**

| region_id | region_name | median | p_8 | p_95 |
| --------- | ----------- | ------ | --- | ---- |
| 1         | Australia   | 16     | 24  | 29   |
| 2         | America     | 16     | 24  | 29   |
| 3         | Africa      | 16     | 25  | 29   |
| 4         | Asia        | 16     | 24  | 29   |
| 5         | Europe      | 16     | 25  | 29   |

---

### B. Customer Transactions
#### 1. What is the unique count and total amount for each transaction type?

```sql
SELECT
	txn_type,
	COUNT(1) AS unique_cnt,
	SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY 1;
```

**Output:***
| txn_type   | unique_cnt | total_amount |
| ---------- | ---------- | ------------ |
| purchase   | 1617       | 806537       |
| deposit    | 2671       | 1359168      |
| withdrawal | 1580       | 793003       |
---

#### 2. What is the average total historical deposit counts and amounts for all customers?

```sql
SELECT
	COUNT(1) / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) AS unique_cnt_avg,
	SUM(txn_amount)/ (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) AS total_amount_avg
FROM customer_transactions
WHERE txn_type = 'deposit';
```

**Output:***
| unique_cnt_avg | total_amount_avg |
| -------------- | ---------------- |
| 5              | 2718             |
---

#### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

```sql
WITH monthly_txn AS (
  SELECT DISTINCT
      TO_CHAR(txn_date, 'yyyy-mm') AS mth,
      customer_id,
      SUM(
  		CASE
  			WHEN txn_type = 'deposit' THEN 1
  			ELSE 0
  		END) AS deposit_cnt,
      SUM(
  		CASE
  			WHEN txn_type = 'purchase' THEN 1
  			ELSE 0
  		END) AS purchase_cnt,
      SUM(
  		CASE
  			WHEN txn_type = 'withdrawal' THEN 1
  			ELSE 0
  		END) AS withdrawal_cnt
  FROM customer_transactions
  GROUP BY 1, 2
)

SELECT
	mth,
	COUNT(customer_id) AS cus_cnt
FROM monthly_txn
WHERE 
	deposit_cnt > 1
	AND (purchase_cnt >= 1 OR withdrawal_cnt >= 1)
GROUP BY 1
ORDER BY 1;
```

**Output:***
| mth     | cus_cnt |
| ------- | ------- |
| 2020-01 | 168     |
| 2020-02 | 181     |
| 2020-03 | 192     |
| 2020-04 | 70      |
---

#### 4. What is the closing balance for each customer at the end of the month?

Firstly, I create a temp table to calculate the closing balance for each customer at the end of the month. Then, it'll be used in query 4 and 5.
```sql
CREATE TEMP TABLE customer_monthly_balance AS (
  WITH txn_balances AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', txn_date) + INTERVAL '1 month - 1 day' AS end_of_mth,
        CASE
            WHEN txn_type = 'deposit' THEN txn_amount
            ELSE -txn_amount
        END AS txn_balance
    FROM customer_transactions
  ),

  monthly_changes AS (
    SELECT
        customer_id,
        end_of_mth,
        SUM(txn_balance) AS monthly_change
    FROM txn_balances
    GROUP BY 1, 2
  ),

  month_end_series AS (
  SELECT 
      customer_id,
      DATE_TRUNC('month', GENERATE_SERIES(MIN(txn_date), MAX(txn_date), INTERVAL '1 month')) + INTERVAL '1 month - 1 day' AS end_of_mth
  FROM customer_transactions
  GROUP BY 1
  )

  SELECT 
      customer_id,
      end_of_mth,
      SUM(monthly_change) OVER(
          PARTITION BY customer_id
          ORDER BY end_of_mth
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS closing_balance
  FROM monthly_changes
  FULL JOIN month_end_series USING (customer_id, end_of_mth)
);
```

I show the result for customer 1, 2, 3 only.

```sql
SELECT *
FROM customer_monthly_balance
WHERE customer_id IN ('1', '2', '3')
ORDER BY 1, 2;
```

**Output:***
| customer_id | end_of_mth               | monthly_balance |
| ----------- | ------------------------ | --------------- |
| 1           | 2020-01-31T00:00:00.000Z | 312             |
| 1           | 2020-02-29T00:00:00.000Z | 312             |
| 1           | 2020-03-31T00:00:00.000Z | -640            |
| 2           | 2020-01-31T00:00:00.000Z | 549             |
| 2           | 2020-02-29T00:00:00.000Z | 549             |
| 2           | 2020-03-31T00:00:00.000Z | 610             |
| 3           | 2020-01-31T00:00:00.000Z | 144             |
| 3           | 2020-02-29T00:00:00.000Z | -821            |
| 3           | 2020-03-31T00:00:00.000Z | -1222           |
| 3           | 2020-04-30T00:00:00.000Z | -729            |
---

#### 5. What is the percentage of customers who increase their closing balance by more than 5%?
- The % change should be calculated based on the assumption of either growth or decline, irrespective of the direction of the increase/decrease in the variable. Therefore, I use the absolute value to ensure that the sign of closing balance does not affect the result of the % change.
- To avoid division by 0 and to ensure that the % change is well-defined, I add a very small number but non-zero number *(like 0.0000000000000001)* to both the balance of the current month and the balance of the previous month.

`% change = (Balance of Current Month - Balance of Previous Month) / ABS(Balance of Previous Month + 0.0000000000000001) * 100`

```sql
WITH prev_month_balance AS (
  SELECT 
      *,
      LAG(closing_balance) OVER(
          PARTITION BY customer_id
          ORDER BY end_of_mth
      ) AS prev_closing_balance
  FROM customer_monthly_balance
),

monthly_change AS (
  SELECT 
      customer_id,
      end_of_mth,
      (closing_balance - prev_closing_balance) * 100.0 / ABS(prev_closing_balance + 0.0000000000000001) AS change_pct
  FROM prev_month_balance
)

SELECT
	ROUND(
		100.0 * COUNT(DISTINCT customer_id) / (SELECT COUNT (DISTINCT customer_id) FROM customer_monthly_balance),
	2) AS pct_more_than_5
FROM monthly_change
WHERE change_pct > 5;
```

**Output:**

| pct_more_than_5 |
| ----- |
| 67.40 |

---

