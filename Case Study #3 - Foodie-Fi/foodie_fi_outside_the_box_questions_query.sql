-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/11/03

/* --------------------
   D. Outside The Box Questions
   --------------------*/

SET
  search_path = foodie_fi;

-- 1. How would you calculate the rate of growth for Foodie-Fi?
-- Find the next subscription of each record
WITH next_sub AS (
  SELECT
      customer_id,
      plan_name,
      start_date,
      price,
      LEAD(plan_name) OVER(
          PARTITION BY customer_id
          ORDER BY start_date
      ) AS next_plan,
      LEAD(start_date) OVER(
          PARTITION BY customer_id
          ORDER BY start_date
      ) AS next_start_date
  FROM subscriptions
  LEFT JOIN plans USING(plan_id)
  WHERE plan_name != 'trial'
),

-- Find max date in start_date
max_date AS (
  SELECT MAX(start_date)
  FROM subscriptions
),

-- Find payment date
payment_dates AS (
  SELECT
      customer_id,
      plan_name,
      start_date,
      GENERATE_SERIES(
      start_date,
          CASE
              WHEN next_plan IS NULL THEN (SELECT * FROM max_date)
              ELSE next_start_date - INTERVAL '1 day'
          END,
          CASE
              WHEN plan_name = 'pro annual' THEN INTERVAL '1 year'
              ELSE INTERVAL '1 month'
          END
      ) AS payment_date,
      price
  FROM next_sub
  WHERE plan_name != 'churn'
)

-- Find prev plan and prev price
,prev_payments AS (
  SELECT
      *,
      LAG(plan_name) OVER(
          PARTITION BY customer_id
          ORDER BY payment_date
      ) AS prev_plan,
      LAG(payment_date) OVER(
          PARTITION BY customer_id
          ORDER BY payment_date
      ) AS prev_date,
      LAG(price) OVER(
          PARTITION BY customer_id
          ORDER BY payment_date
      ) AS prev_price
  FROM payment_dates
),

-- Calculate revenue by month
monthly_revenue AS (
  SELECT
      DATE_TRUNC('month', payment_date) AS month,
      SUM(
        CASE
            WHEN plan_name = 'pro annual' AND prev_plan = 'basic monthly' AND payment_date < prev_date + INTERVAL '1 month' THEN price - prev_price
            ELSE price
        END 
      ) AS revenue
  FROM prev_payments
  GROUP BY 1
),

-- Find previous month revenue
revenue_with_previous AS (
  SELECT
    *,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue
  FROM monthly_revenue
)

SELECT
  *,
  ROUND(
    (revenue - prev_month_revenue) * 100.0 / prev_month_revenue,
    2
  ) AS percentage_change
FROM revenue_with_previous
ORDER BY 1;


-- 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

--     Total revenue.
--     #Active customers = #Customers - #Churned customers.
--     #Paying customers = #Customers - #Churned customers - #Trial customers.
--     #New customers = #Trial customers.
--     Churn rate.
--     Revenue growth rate, #Customers growth rate.
--     #Active customers on date after their sign-up (cohort analysis: day 7, day 30).
--     #Customers by plan → Understand customer preference.
--     Average revenue by user = Total revenue / #Active customers.
--     Average revenue by customer = Total revenue / #Paying customers.


-- 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?

--     If a user become a customer or not after 7-day trial.
--     What happend after the first purchase? Do they continue their subscribtion, upgrade, downgrade or churn?
--     How long do they use Foodie-Fi before churning? What factors contribute to their churn—cost, user experience, lack of variety in films, or personal preferences?
--     In addition, information about app usage time, frequency of use, and the categories users frequently watch is also very useful for this analysis.


-- 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

--     Why are you cancelling your subscribtion? (Select multiple choice)
--         The subscription cost is too high.
--         I am not satisfied with the quality of the content.
--         I found the variety of content to be limited.
--         I experienced technical issues while using the service.
--         The user interface and user experience (UI/UX) need improvement.
--         Limited variety in subscription plans, no family-friendly options.
--         Lack of child-appropriate content.
--         Limited diversity in subtitle languages.
--         Poor customer service.
--         Others (Please specify).

--     On a scale of 1 to 10, how satisfied were you with your Foodie-Fi subscription? (Select one)

--     What specific aspects of Foodie-Fi did you enjoy the most during your subscription? (Select one)
--         Enjoyed the unique and exclusive cooking shows available on Foodie-Fi.
--         Liked the wide range of cuisines and cooking styles featured on Foodie-Fi.
--         Appreciated the quality and uniqueness of the recipes presented in the content.
--         Enjoyed interactive features like recipe downloads, cooking tips, and user engagement.
--         Liked the regular updates and new content releases on the platform.
--         Appreciated the user-friendly platform and ease of finding and watching content.
--         Found the content recommendations and personalized playlists helpful.
--         Others (Please specify).

--     What aspects of Foodie-Fi could be improved to better meet your needs and expectations? (Optional)


-- 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

-- Understand the reasons for customer churn first:

--     For users who churn after a 7-day trial, it's essential to investigate whether they are precisely the target customers. If they are not, a review and adjustment of marketing strategies should be undertaken. If they are the target audience, it's advisable to re-engage them with reminders about Foodie-Fi through targeted advertising campaigns.

--     If a paying user churns, we can inquire about the reasons.
--         If the primary reason for churn is cost, it's worth considering adjusting the service pricing or targeting higher-income segments. Alternatively, the company should explore the creation of flexible subscription packages, such as family monthly plans or basic annual plans.
--         In the case of churn due to technical problems or interface issues, prompt resolution should be a priority.

--     Validiation of effectiveness:
--         A/B testing.
--         Customer surveys.
--         Customer feedback analysis.
--         Tracking retetion metrics (CLV, cohort analysis).

