-- Solved on PostgreSQL v13 by Duong Le Thanh Truc
-- Date: 2023/10/19

/* --------------------
   E. Bonus Questions
   --------------------*/

-- Insert new pizza.

INSERT INTO
  pizza_names ("pizza_id", "pizza_name")
VALUES
  (3, 'Supreme');
  
INSERT INTO
  pizza_recipes ("pizza_id", "toppings")
VALUES
  (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

-- Check how our tables look like.

SELECT * 
FROM pizza_runner.pizza_names;

SELECT *
FROM pizza_runner.pizza_recipes;
