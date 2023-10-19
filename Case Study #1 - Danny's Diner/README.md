# Case Study #1 - Danny's Diner
<img src="https://8weeksqlchallenge.com/images/case-study-designs/1.png" alt="Case Study #1 - Danny's Diner Image" width="500" height="520">

## Business Task

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they've spent, and which menu items are their favorite.

Full Description: [Case Study #1 - Danny's Diner](https://8weeksqlchallenge.com/case-study-1/)

## Dataset

Danny has shared three key datasets for this case study:

- The `sales` table: Captures all `customer_id` level purchases with corresponding `order_date` and `product_id` information for when and what menu items were ordered.
- The `menu` table: Maps the `product_id` to the actual `product_name` and `price` of each menu item.
- The `members` table: Captures the `join_date` when a `customer_id` joined the beta version of the Danny’s Diner loyalty program.
  
![Entity Relationship Diagram](https://dbdiagram.io/d/Dannys-Diner-608d07e4b29a09603d12edbd?utm_source=dbdiagram_embed&utm_medium=bottom_open)


## Questions and Solutions

**Database Environment**: PostgreSQL v13 on [DB Fiddle](https://www.db-fiddle.com/f/2rM8RAnq7h5LLDTzZiRWcd/138)

### Case Study Questions

#### Question 1: What is the total amount each customer spent at the restaurant?

```sql
SELECT
  customer_id,
  SUM(price) total_spend
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu USING(product_id)
GROUP BY 1
ORDER BY 2 DESC;
```

**Output:**

| customer_id | total_spend |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

- Customer A spent $76.
- Customer B spent $74.
- Customer C spent $36.
---
  
#### Question 2: How many days has each customer visited the restaurant?

```sql
SELECT 
  customer_id,
  COUNT(DISTINCT order_date) cnt_visit
 FROM dannys_diner.sales
 GROUP BY 1
 ORDER BY 2 DESC;
```

**Output:**

| customer_id | cnt_visit |
| ----------- | --------- |
| B           | 6         |
| A           | 4         |
| C           | 2         |

- Customer B visited 6 times.
- Customer A visited 4 times.
- Customer C visited 2 times.
---

#### Question 3: What was the first item from the menu purchased by each customer?

1. I ranked the items ordered by each customer in a `purchase_rank_by_customer` CTE. I used `DENSE_RANK()` to handle cases where customers order more than one item in the same time.
2. I filtered rows with a rank of `1`, which represents the first row within each `customer_id` partition. It's worth noting that I used `SELECT DISTINCT` to avoid duplicate rows.
   
```sql
WITH purchase_rank_by_customer AS (
  SELECT
    customer_id,
    product_id,
    DENSE_RANK() OVER(
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS rn
  FROM dannys_diner.sales
)

SELECT DISTINCT 
  customer_id,
  product_name
FROM purchase_rank_by_customer 
INNER JOIN dannys_diner.menu USING(product_id)
WHERE rn = 1
ORDER BY 1;
```

**Output:**

| customer_id | product_name |
| ----------- | ------------ |
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |

- Customer A's first orders included both curry and sushi.
- Customer B's first order is curry.
- Customer C's first order is ramen.
---


#### Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?

Instead of using `ORDER BY COUNT(product_id) DESC` and `LIMIT 1`,  I used `RANK()` to ensure that all items with the highest purchase count are included in the result. 
   
```sql
WITH most_purchased_items AS (
  SELECT
    product_id,
    COUNT(1) AS cnt_ord,
    RANK() OVER(
      ORDER BY COUNT(1) DESC
    ) rk
  FROM dannys_diner.sales
  GROUP BY 1
)

SELECT 
  product_name,
  cnt_ord
FROM most_purchased_items
INNER JOIN dannys_diner.menu USING(product_id)
WHERE rk = 1;
```

**Output:**

| product_name | cnt_ord |
| ------------ | ------- |
| ramen        | 8       |

Ramen is the bestseller dish of Danny’s Diner restaurant with 8 purchases.

---


#### Question 5: Which item was the most popular for each customer?
   
```sql
WITH most_purchased_items_by_cus AS (
  SELECT
    customer_id,
    product_id,
    COUNT(1) AS cnt_ord,
    RANK() OVER(
      PARTITION BY customer_id
      ORDER BY COUNT(product_id) DESC) AS rk
  FROM dannys_diner.sales
  GROUP BY
      1,
      2
)

SELECT 
  customer_id,
  product_name,
  cnt_ord
FROM most_purchased_items_by_cus
INNER JOIN dannys_diner.menu USING(product_id)
WHERE rk = 1
ORDER BY 1;
```

**Output:**

| customer_id | product_name | cnt_ord |
| ----------- | ------------ | ------- |
| A           | ramen        | 3       |
| B           | sushi        | 2       |
| B           | curry        | 2       |
| B           | ramen        | 2       |
| C           | ramen        | 3       |

- Customer A and C's favourite item is ramen.
- Customer B enjoys all items on the menu.
---

#### Question 6: Which item was purchased first by the customer after they became a member?

1. I ranked each customer's orders based on the order date after they became a member in a `orders_after_mem` CTE, using `RANK()` to account for simultaneous orders.
2. I filtered for the first-order (rank 1) in each `customer_id` partition.
3. I joined with the `menu` table to fetch the `product_name`
   
```sql
WITH orders_after_mem AS (
  SELECT
      customer_id,
      product_id,
      RANK() OVER(
          PARTITION BY customer_id
          ORDER BY order_date
      ) AS rk
  FROM dannys_diner.members
  INNER JOIN dannys_diner.sales USING(customer_id)
  WHERE join_date < order_date
)

SELECT 
  customer_id,
  product_name
FROM orders_after_mem
INNER JOIN dannys_diner.menu USING(product_id)
WHERE rk = 1
ORDER BY 1;
```

**Output:**

| customer_id | product_name |
| ----------- | ------------ |
| A           | ramen        |
| B           | sushi        |

- Customer A's first order as a member is ramen.
- Customer B's first order as a member is sushi.
---

#### Question 7: Which item was purchased just before the customer became a member?
   
```sql
WITH orders_before_mem AS (
  SELECT
      customer_id,
      product_id,
      RANK() OVER(
          PARTITION BY customer_id
          ORDER BY order_date DESC
      ) AS rn
  FROM dannys_diner.members
  INNER JOIN dannys_diner.sales USING(customer_id)
  WHERE order_date < join_date
)

SELECT 
  customer_id,
  product_name
FROM orders_before_mem
INNER JOIN dannys_diner.menu USING(product_id)
WHERE rn = 1
ORDER BY 1;
```

**Output:**

| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| A           | curry        |
| B           | sushi        |

- Customer A's last orders before becoming a member are curry and sushi.
- Customer B's last orders before becoming a member is sushi.
---

#### Question 8: What is the total items and amount spent for each member before they became a member?
   
```sql
SELECT
  customer_id,
  COUNT(*) total_item,
  SUM(price) total_spend
FROM dannys_diner.members
INNER JOIN dannys_diner.sales USING(customer_id)
INNER JOIN dannys_diner.menu USING(product_id)
WHERE order_date < join_date
GROUP BY 1
ORDER BY 1;
```

**Output:**
| customer_id | total_item | total_spend |
| ----------- | ---------- | ----------- |
| A           | 2          | 25          |
| B           | 3          | 40          |

Before becoming members,
- Customer A spent $25 on 2 items.
- Customer B spent $40 on 3 items.
---

#### Question 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
   
```sql
WITH cus_points AS (
  SELECT
      customer_id,
      CASE
          WHEN product_name = 'sushi' THEN 2
          ELSE 1
      END * price * 10 AS points
  FROM dannys_diner.sales 
  INNER JOIN dannys_diner.menu USING(product_id)
)

SELECT 
  customer_id, 
  SUM(points) AS total_point
FROM cus_points
GROUP BY 1
ORDER BY 2 DESC;
```

**Output:**

| customer_id | total_point |
| ----------- | ----------- |
| B           | 940         |
| A           | 860         |
| C           | 360         |

- Customer B achieved the highest points, earning a total of 940 points, with their significant preference for sushi..
- Customer A closely follows with a total of 860 points.
- Customer C has a comparatively lower total of 360 points.
---

#### Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
1. I calculated points for member customers from the date of becoming a member until the end of January in a `cus_points_after_mem` CTE.
2. I calculated points for member customers before becoming a member in a `cus_points_before_mem` CTE.
3. I combine points from both periods using `UNION ALL`.
4. I fond total points for each member customer.

```sql
WITH cus_points_after_mem AS (
  SELECT
      customer_id,
      CASE
        WHEN join_date + INTERVAL '6 day' >= order_date THEN 2
        ELSE
          CASE
            WHEN product_name = 'sushi' THEN 2
            ELSE 1
          END 
      END * price * 10 AS points
  FROM dannys_diner.sales 
  INNER JOIN dannys_diner.members USING(customer_id)
  INNER JOIN dannys_diner.menu USING(product_id)
  WHERE order_date BETWEEN join_date AND MAKE_DATE(2021, 01, 31)
),

cus_points_before_mem AS (
 SELECT
      customer_id,
      CASE
          WHEN product_name = 'sushi' THEN 2
          ELSE 1
      END * price * 10 AS points
  FROM dannys_diner.sales 
  INNER JOIN dannys_diner.members USING(customer_id)
  INNER JOIN dannys_diner.menu USING(product_id)
  WHERE order_date < join_date
),

mem_points AS (
  SELECT 
    customer_id,
    points
  FROM cus_points_after_mem
  UNION ALL
  SELECT 
    customer_id,
    points
  FROM cus_points_before_mem
)

SELECT
	customer_id,
    SUM(points) AS total_point
FROM mem_points
GROUP BY 1
ORDER BY 2 DESC;
```

**Output:**

| customer_id | total_point |
| ----------- | ----------- |
| A           | 1370        |
| B           | 820         |

The promotion led to different levels of engagement and point accumulation for these customers:
- Customer A accumulated a significant total of 1020 points, taking advantage of the 2x points for all items.
- Customer B earned a total of 320 points, which is lower than Customer A's.
---

### Bonus Question

#### Join all the things

Create the table with: `customer_id`, `order_date`, `product_name`, `price`, `member` (Y/N)
   
```sql
SELECT
  customer_id,
  order_date,
  product_name,
  price,
  CASE 
    WHEN join_date <= order_date THEN 'Y'
    ELSE 'N'
  END member
FROM dannys_diner.sales 
LEFT JOIN dannys_diner.members USING(customer_id)
INNER JOIN dannys_diner.menu USING(product_id)
ORDER BY 1, 2;
```

**Output:**

| customer_id | order_date               | product_name | price | member |
| ----------- | ------------------------ | ------------ | ----- | ------ |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |

---

#### Question 3: Rank all the things

Expand the `ranking` field, assign `NULL` ranking values for the records when customers are not yet part of the loyalty program.
   
```sql
WITH cus_join_all AS (
  SELECT
    customer_id,
    order_date,
    product_name,
    price,
    CASE 
        WHEN join_date <= order_date THEN 'Y'
        ELSE 'N'
    END member
  FROM dannys_diner.sales 
  LEFT JOIN dannys_diner.members USING(customer_id)
  INNER JOIN dannys_diner.menu USING(product_id)
)

SELECT 
  *,
  CASE
    WHEN member = 'N' THEN NULL
    ELSE DENSE_RANk() OVER(
      PARTITION BY customer_id, member
      ORDER BY order_date)
  END ranking
FROM cus_join_all
ORDER BY 1, 2;
```

**Output:**

| customer_id | order_date               | product_name | price | member | ranking |
| ----------- | ------------------------ | ------------ | ----- | ------ | ------- |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | N      |         |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | Y      | 1       |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | N      |         |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | N      |         |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01T00:00:00.000Z | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |         |
| C           | 2021-01-01T00:00:00.000Z | ramen        | 12    | N      |         |
| C           | 2021-01-07T00:00:00.000Z | ramen        | 12    | N      |         |
---
