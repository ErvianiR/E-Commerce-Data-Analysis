-- Customer Behavior and RFM Analysis 
-- 1. Overall customer performance
CREATE OR REPLACE VIEW customer_order_summary_vw AS
SELECT 
	customer_unique_id,
	order_id,
	MIN(purchase_date) AS purchase_date,
	SUM(product_revenue) AS order_revenue
FROM delivered_sales_vw
WHERE  customer_unique_id IS NOT NULL
GROUP BY 
	customer_unique_id,
	order_id;

SELECT *
FROM customer_order_summary_vw
LIMIT 10;

SELECT 
	COUNT(DISTINCT customer_unique_id) AS total_customers,
	COUNT(DISTINCT order_id) AS total_order,
	ROUND(SUM(order_revenue), 2) AS total_revenue,
	ROUND(AVG(order_revenue), 2) AS average_order_value,
	ROUND(COUNT(DISTINCT order_id)::NUMERIC / NULLIF(COUNT(DISTINCT customer_unique_id), 0), 2) AS orders_per_customer,
	ROUND(SUM(order_revenue) / NULLIF(COUNT(DISTINCT customer_unique_id), 0), 2) AS average_revenue_per_customer
FROM customer_order_summary_vw;


-- 2. Repeat customer analysis
WITH customer_orders AS (
	SELECT
		customer_unique_id,
		COUNT(DISTINCT order_id) AS total_orders
	FROM customer_order_summary_vw
	GROUP BY customer_unique_id
)

SELECT
	COUNT(*) AS total_customers,
	COUNT(*) FILTER (WHERE total_orders = 1) AS one_time_customers,
	COUNT(*) FILTER (WHERE total_orders > 1) AS repeat_customers,
	ROUND(COUNT(*) FILTER (WHERE total_orders > 1) * 100 / NULLIF(COUNT(*), 0), 2) AS repeat_customer_percentage
FROM customer_orders;	


-- 3. Purchase frequency
SELECT
	total_orders,
	COUNT(*) AS total_customers
FROM(
	SELECT 
		customer_unique_id,
		COUNT(DISTINCT order_id) AS total_orders
	FROM customer_order_summary_vw
	GROUP BY customer_unique_id
) customer_frequency
GROUP BY total_orders
ORDER BY total_orders;


-- 4. TOP customers
SELECT 
	customer_unique_id,
	COUNT(DISTINCT order_id) AS total_orders,
	ROUND(SUM(order_revenue), 2) AS total_customer_revenue,
	ROUND(AVG(order_revenue), 2) AS average_order_revenue,
	MIN(purchase_date) AS first_purchase_date,
	MAX(purchase_date) AS most_recent_purchase_date
FROM customer_order_summary_vw
GROUP BY customer_unique_id
ORDER BY total_customer_revenue DESC
LIMIT 10;

	
-- 5. Spending distribution
WITH customer_spending AS(
	SELECT 
		customer_unique_id,
		SUM(order_revenue) AS total_spending
	FROM customer_order_summary_vw
	GROUP BY customer_unique_id
)

SELECT
	CASE
		WHEN total_spending < 100 THEN 'Under 100'
        WHEN total_spending < 250 THEN '100 - 249.99'
        WHEN total_spending < 500 THEN '250 - 499.99'
        WHEN total_spending < 1000 THEN '500 - 999.99'
        ELSE '1000 and above'
    END AS spending_category,
	
	COUNT(*) AS total_customers,
	ROUND(SUM(total_spending), 2) AS total_revenue,
	ROUND(AVG(total_spending), 2) AS average_customer_spending
FROM customer_spending
GROUP BY
	CASE
		WHEN total_spending < 100 THEN 'Under 100'
        WHEN total_spending < 250 THEN '100 - 249.99'
        WHEN total_spending < 500 THEN '250 - 499.99'
        WHEN total_spending < 1000 THEN '500 - 999.99'
        ELSE '1000 and above'
    END
ORDER BY MIN(total_spending);


-- 6. RFM scoring
WITH reference_date AS(
	SELECT
		MAX(purchase_date) + 1 AS analysis_date
	FROM customer_order_summary_vw
), 

customer_rfm AS (
	SELECT
		customer_unique_id,
		(SELECT analysis_date FROM reference_date) - MAX(purchase_date) AS recency_days,
		
		COUNT(DISTINCT order_id) AS frequency,
		SUM(order_revenue) AS monetary
	FROM customer_order_summary_vw
	GROUP BY customer_unique_id
),

rfm_scores AS (
	SELECT 
		customer_unique_id,
		recency_days,
		frequency,
		monetary,

		NTILE(5) OVER(ORDER BY recency_days ASC) AS recency_score,
		NTILE(5) OVER(ORDER BY frequency ASC) AS frequency_score,
		NTILE(5) OVER(ORDER BY monetary ASC) AS monetary_score
	FROM customer_rfm
)

SELECT
	customer_unique_id,
	recency_days,
	frequency,
	ROUND(monetary, 2) AS monetary,

	recency_score,
	frequency_score,
	monetary_score,

	CONCAT(
		recency_score,
		frequency_score,
		monetary_score
	) AS rfm_score
FROM rfm_scores
ORDER BY
	recency_score DESC,
	frequency_score DESC,
	monetary_score DESC;


-- 7. RFM segmentation
WITH reference_date AS(
	SELECT
		MAX(purchase_date) + 1 AS analysis_date
	FROM customer_order_summary_vw
), 

customer_rfm AS (
	SELECT
		customer_unique_id,
		(SELECT analysis_date FROM reference_date) - MAX(purchase_date) AS recency_days,
		
		COUNT(DISTINCT order_id) AS frequency,
		SUM(order_revenue) AS monetary
	FROM customer_order_summary_vw
	GROUP BY customer_unique_id
),

rfm_scores AS (
	SELECT 
		customer_unique_id,
		recency_days,
		frequency,
		monetary,

		NTILE(5) OVER(ORDER BY recency_days ASC) AS recency_score,
		NTILE(5) OVER(ORDER BY frequency ASC) AS frequency_score,
		NTILE(5) OVER(ORDER BY monetary ASC) AS monetary_score
	FROM customer_rfm
	
),

customer_segments AS (
	SELECT *,
		CASE
			WHEN recency_score >= 4
			AND frequency_score >= 4
			AND monetary_score >= 4
				THEN 'Champions'
				
			WHEN frequency_score >= 4
				THEN 'Loyal Customers'

			WHEN monetary_score = 5
				THEN 'Big Spenders'

			WHEN recency_score <= 2
			AND frequency_score >= 3
				THEN 'At Risk'

			WHEN recency_score <= 2
			AND frequency_score <= 2
				THEN 'Hibernating'

			WHEN recency_score >= 4
			AND frequency_score >= 2
				THEN 'Potential Loyalists'

			WHEN recency_score = 5
			AND frequency_score = 1
				THEN 'Recent Customers'

			ELSE 'Others'
		END AS customer_segment
	FROM rfm_scores
)

SELECT
	customer_segment,
	COUNT(*) AS total_customers,
	ROUND(COUNT(*) * 100 / NULLIF(SUM(COUNT(*)) OVER(), 0), 2) AS customer_percentage,
	ROUND(SUM(monetary), 2) AS total_revenue,
	ROUND(AVG(monetary), 2) AS average_customer_revenue
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_revenue DESC;

-- 8. New vs Returning customer by month
WITH customer_first_purchase AS (
	SELECT
		customer_unique_id,
		MIN(purchase_date) AS first_purchase_date
	FROM customer_order_summary_vw
	GROUP BY customer_unique_id
),

monthly_customer_activity AS (
	SELECT DISTINCT
		customer_unique_id,
		DATE_TRUNC('month', purchase_date)::DATE AS purchase_month
	FROM customer_order_summary_vw
)

SELECT
	m.purchase_month,
	COUNT(*) FILTER (
		WHERE m.purchase_month = DATE_TRUNC('month', f.first_purchase_date):: DATE) AS new_customers,
	COUNT(*) FILTER (
		WHERE m.purchase_month > DATE_TRUNC('month', f.first_purchase_date):: DATE) AS returning_customer
FROM monthly_customer_activity m
JOIN customer_first_purchase f
	ON m.customer_unique_id = f.customer_unique_id
GROUP BY m.purchase_month
ORDER BY m.purchase_month;
		
