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
