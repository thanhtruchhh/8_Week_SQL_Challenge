-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/11/22

/* --------------------
   B. Customer Transactions
   --------------------*/

SET search_path = data_bank;

-- 1. What is the unique count and total amount for each transaction type?

SELECT
	txn_type,
	COUNT(1) AS unique_cnt,
	SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY 1;


-- 2. What is the average total historical deposit counts and amounts for all customers?

SELECT
	COUNT(1) / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) AS unique_cnt_avg,
	SUM(txn_amount)/ (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) AS total_amount_avg
FROM customer_transactions
WHERE txn_type = 'deposit';


-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

-- Count number of monthly transactions of each customer by transaction types
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

-- 4. What is the closing balance for each customer at the end of the month?

-- Get the end of the month and calculate balance basing on income/ outcome of each transaction
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

-- Calc transaction balance changes in seperate months
monthly_changes AS (
  SELECT
      customer_id,
      end_of_mth,
      SUM(txn_balance) AS monthly_change
  FROM txn_balances
  GROUP BY 1, 2
),

-- Create a table with customer_id and the ending date of each month from the minimum txn_date to the maximum txn_date
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
	) AS monthly_balance
FROM monthly_changes
FULL JOIN month_end_series USING (customer_id, end_of_mth)
WHERE customer_id IN ('1', '2', '3')
ORDER BY 1, 2;
