-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/10/19

/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT
  customer_id,
  SUM(price) total_spend
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu USING(product_id)
GROUP BY 1
ORDER BY 2 DESC;


-- 2. How many days has each customer visited the restaurant?

SELECT 
  customer_id,
  COUNT(DISTINCT order_date) cnt_visit
 FROM dannys_diner.sales
 GROUP BY 1
 ORDER BY 2 DESC;


-- 3. What was the first item from the menu purchased by each customer?

-- Calc the rank of each product purchase within each customer's order history.
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


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

-- Calc the total number of times each menu item has been purchased and rank.
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


-- 5. Which item was the most popular for each customer?

-- Calc the most popular item for each customer.
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


-- 6. Which item was purchased first by the customer after they became a member?

-- Rank orders of each customer by time after he became a member.
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


-- 7. Which item was purchased just before the customer became a member?

-- Rank orders of each customer by time before he became a member.
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


-- 8. What is the total items and amount spent for each member before they became a member?

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


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- Cacl points for each customer.
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


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Calc points earned by mem customers at the end of Jan.
WITH cus_points_in_Jan AS (
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
)

SELECT 
  customer_id,
  SUM(points) AS total_point
FROM cus_points_in_Jan
GROUP BY 1
ORDER BY 2 DESC;


/* --------------------
   Bonus Questions
   --------------------*/
   
-- Join All The Things

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


-- Rank All The Things

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


