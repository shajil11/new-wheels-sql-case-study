/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/

-- 1) ANS:

SELECT * FROM customer_t;
SELECT state, 
		count(customer_id) AS customer_count 
	FROM customer_t
GROUP BY state
ORDER BY customer_count DESC;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */

-- 2) ANS:

SELECT * FROM order_t;
WITH rating AS (
	SELECT customer_feedback, quarter_number,
		CASE
			WHEN customer_feedback = 'Very Bad' THEN 1
			WHEN customer_feedback = 'Bad' THEN 2
			WHEN customer_feedback = 'Okay' THEN 3
			WHEN customer_feedback = 'Good' THEN 4
			WHEN customer_feedback = 'Very Good' THEN 5
		END AS rating_assigned
	FROM order_t)

/* Select * from rating; (includes customer_feedback, quarter_number and rating_assigned columns)*/

SELECT quarter_number, 
		ROUND(AVG(rating_assigned),2) AS average_rating
	FROM rating
GROUP BY quarter_number
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback. */
  
 -- 3) ANS: 

SELECT * FROM order_t; 
WITH customer_feedback_category AS (
	SELECT customer_feedback, quarter_number, 
			count(customer_feedback) AS customer_feedback_count
		FROM order_t
    GROUP BY customer_feedback, quarter_number
	), 
    customer_feedback_count AS (
    SELECT quarter_number, 
			count(customer_feedback) AS feedback_count
		FROM order_t
    GROUP BY quarter_number)
	
SELECT feed_category.quarter_number, 
		feed_category.customer_feedback, 
			ROUND((feed_category.customer_feedback_count / feed_count.feedback_count) *100, 2) AS feedback_percentage
        
FROM customer_feedback_category AS feed_category,
	customer_feedback_count AS feed_count
WHERE feed_category.quarter_number = feed_count.quarter_number
ORDER BY feed_category.quarter_number, feed_category.customer_feedback;
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

-- 4) ANS:

SELECT * FROM product_t; 
SELECT vehicle_maker, 
		count(DISTINCT(customer_id)) AS customer_count
	FROM product_t AS pt
LEFT JOIN 
	order_t AS ot ON ot.product_id = pt.product_id
GROUP BY vehicle_maker
ORDER BY customer_count DESC
LIMIT 5;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

-- 5) ANS:

SELECT * FROM order_t; 
WITH ranking AS (
SELECT state, vehicle_maker, 
    count(DISTINCT(ot.customer_id)) AS customer_count,
		RANK() OVER (PARTITION BY state ORDER BY count(DISTINCT(ct.customer_id)) DESC) AS rnk
	FROM order_t AS ot
    
    LEFT JOIN 
		product_t AS pt USING (product_id)
	LEFT JOIN 
		customer_t AS ct USING (customer_id)
GROUP BY state, vehicle_maker
ORDER BY state, customer_count DESC)
    
SELECT state, vehicle_maker, 
		customer_count
	FROM ranking
WHERE rnk =1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

-- 6) ANS:

SELECT * FROM order_t; 
SELECT quarter_number, 
		count(DISTINCT(order_id)) AS order_count
	FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
 
-- 7) ANS:

SELECT * FROM order_t;
 With quarterwise_revenue AS (
 SELECT quarter_number, 
		ROUND(SUM(vehicle_price * quantity - ((discount/100) * vehicle_price)), 2) AS total_revenue
	FROM order_t
 GROUP BY 1
 ORDER BY 1 )
 
 SELECT quarter_number, total_revenue,
	LAG(total_revenue) OVER (ORDER BY quarter_number) AS previous_revenue,
		ROUND(((total_revenue - LAG(total_revenue) OVER (ORDER BY quarter_number)) / 
	LAG(total_revenue) OVER (ORDER BY quarter_number)) * 100 ,2) AS revenue_change_percent
	FROM quarterwise_revenue;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

-- 8) ANS:

SELECT * FROM order_t; 
 SELECT quarter_number, 
		count(order_id) AS order_count,
		ROUND(SUM(vehicle_price * quantity - ((discount/100) * vehicle_price)), 2) AS total_revenue
	FROM order_t
 GROUP BY 1
 ORDER BY 1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

-- 9) ANS:

SELECT * FROM order_t; 
SELECT customer_t.credit_card_type, 
		Round(AVG((discount/100) * order_t.vehicle_price),2) AS average_discount
	FROM order_t
INNER JOIN 
	customer_t USING (customer_id)
INNER JOIN 
	product_t USING (product_id)
GROUP BY 1
ORDER BY 2 DESC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

-- 10) ANS:

SELECT * FROM order_t; 
SELECT quarter_number,
		ROUND(AVG(DATEDIFF(ship_date, order_date)), 2) AS average_shipping_days
	FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;


-- ----------------------------------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------

-- QUARTERLY REPORT questions:

-- i) TOTAL REVENUE

SELECT 
		ROUND(SUM(vehicle_price * quantity - ((discount/100) * vehicle_price)), 2) AS total_revenue
	FROM order_t;


-- ii) TOTAL ORDERS

SELECT 
		COUNT(order_id) AS total_order_count
	FROM order_t;


-- iii) TOTAL CUSTOMERS

SELECT 
		COUNT(DISTINCT(customer_id)) AS total_customer_count
	FROM customer_t;


-- iv) AVERAGE RATING
SELECT * FROM order_t;
WITH rating AS (
	SELECT customer_feedback, quarter_number,
		CASE
			WHEN customer_feedback = 'Very Bad' THEN 1
			WHEN customer_feedback = 'Bad' THEN 2
			WHEN customer_feedback = 'Okay' THEN 3
			WHEN customer_feedback = 'Good' THEN 4
			WHEN customer_feedback = 'Very Good' THEN 5
		END AS rating_assigned
	FROM order_t)

SELECT 
		ROUND(AVG(rating_assigned),2) AS average_rating
	FROM rating;


-- v) LAST QUARTER REVENUE

SELECT * FROM order_t; 
 SELECT quarter_number, 
		ROUND(SUM(vehicle_price * quantity - ((discount/100) * vehicle_price)), 2) AS Q4_total_revenue
	FROM order_t
 WHERE quarter_number = 4;


-- vi) LAST QUARTER ORDERS

SELECT * FROM order_t; 
 SELECT quarter_number, 
		count(DISTINCT(order_id)) AS Q4_order_count
	FROM order_t
 WHERE quarter_number = 4;
 

-- vii) AVERAGE DAYS TO SHIP

SELECT
		ROUND(AVG(DATEDIFF(ship_date, order_date)), 2) AS average_shipping_days
	FROM order_t;


-- viii) % GOOD FEEDBACK

SELECT * FROM order_t; 
WITH customer_feedback_category AS (
	SELECT customer_feedback, 
			count(customer_feedback) AS customer_feedback_count
		FROM order_t
    GROUP BY customer_feedback
	), 
    customer_feedback_count AS (
    SELECT 
			count(customer_feedback) AS feedback_count
		FROM order_t)
	
SELECT 
		feed_category.customer_feedback, 
			ROUND((feed_category.customer_feedback_count / feed_count.feedback_count) *100, 2) AS feedback_percentage
        
FROM customer_feedback_category AS feed_category,
	customer_feedback_count AS feed_count
WHERE feed_category.customer_feedback = 'Good'
ORDER BY feed_category.customer_feedback;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------