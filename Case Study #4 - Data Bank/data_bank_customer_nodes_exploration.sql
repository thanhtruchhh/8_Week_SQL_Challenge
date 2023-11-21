-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/11/21

/* --------------------
   A. Customer Nodes Exploration
   --------------------*/

SET search_path = data_bank;

-- 1. How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT node_id) AS unique_node_cnt
FROM customer_nodes;


-- 2. What is the number of nodes per region?

SELECT 
	region_id,
	region_name,
 	COUNT(DISTINCT node_id) AS unique_node_cnt
FROM customer_nodes
LEFT JOIN regions USING(region_id)
GROUP BY 1, 2
ORDER BY 1;


-- 3. How many customers are allocated to each region?

SELECT 
	region_id,
	region_name,
 	COUNT(DISTINCT customer_id) AS unique_cus_cnt
FROM customer_nodes
LEFT JOIN regions USING(region_id)
GROUP BY 1, 2
ORDER BY 1;


-- 4. How many days on average are customers reallocated to a different node?

-- Merge consecutive allocations with the same node ID
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


-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

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
