-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/11/21

/* --------------------
   Explore data
   --------------------*/
SET search_path = data_bank;

-- REGION TABLES

-- Check if there are null values

SELECT COUNT(1)
FROM regions
WHERE region_id IS NULL OR region_name IS NULL;


-- CUSTOMER NODES TABLE

-- Check if there are null values

SELECT COUNT(1)
FROM customer_nodes
WHERE 
	region_id IS NULL 
	OR customer_id IS NULL 
	OR node_id IS NULL 
	OR start_date IS NULL 
	OR end_date IS NULL;
    
-- Check max, min date

SELECT 
	MIN(start_date), 
	MAX(start_date),
 	MIN(end_date), 
	MAX(end_date)
FROM customer_nodes;
-- The maximum end date is set to 9999-12-31. This may indicate that these records represent the latest allocation.


-- CUSTOMER TRANSACTIONS TABLE

-- Check if there are any null values

SELECT COUNT(1)
FROM customer_transactions
WHERE 
	customer_id IS NULL
	OR txn_date IS NULL
	OR txn_type IS NULL
	OR txn_amount IS NULL;

-- Find min, max values of the txn_amount column and txn_date

SELECT
	MIN(txn_amount),
	MAX(txn_amount),
	MIN(txn_date),
	MAX(txn_date)
FROM customer_transactions;

-- Get unique values in the txn_type column

SELECT DISTINCT txn_type
FROM customer_transactions;

