-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/10/29

/* --------------------
   A. Customer Journey
   --------------------*/
   
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

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

