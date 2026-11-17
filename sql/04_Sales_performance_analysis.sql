-- Sales Performance Analysis
-- 1. Overall sales KPIs
SELECT
	COUNT(DISTINCT order_id) AS total_delivered_orders,
	COUNT(DISTINCT customer_unique_id) AS unique_customers,
	COUNT(*) AS total_items_sold,
	ROUND(SUM(product_revenue), 2) AS total_product_revenue,
	ROUND(SUM(freight_value), 2) AS total_freight_value,
	ROUND(SUM(item_total_value), 2) AS total_sales_including_freight,
	ROUND(SUM(product_revenue)/NULLIF(COUNT(DISTINCT order_id), 0), 2) AS average_order_value
FROM delivered_sales_vw;

-- 2. Monthly sales analysis
SELECT
	purchase_month,
	COUNT(DISTINCT order_id) AS total_order,
	COUNT(*) AS total_items_sold,
	ROUND(SUM(product_revenue), 2) AS monthly_product_revenue,
	ROUND(SUM(freight_value), 2) AS monthly_freight_revenue,
	ROUND(SUM(product_revenue)/NULLIF(COUNT(DISTINCT order_id), 0), 2) AS average_order_value
FROM delivered_sales_vw
GROUP BY purchase_month
ORDER BY purchase_month;

-- 3. Month-over-month revenue growth
WITH monthly_sales AS(
	SELECT
		purchase_month,
		SUM(product_revenue) AS monthly_revenue
	FROM delivered_sales_vw
	GROUP BY purchase_month
),

sales_with_previous_month AS(
	SELECT
		purchase_month,
		monthly_revenue,
		LAG(monthly_revenue) OVER(ORDER BY purchase_month) AS previous_month_revenue
	FROM monthly_sales
)

SELECT
	purchase_month,
	ROUND(monthly_revenue, 2) AS monthly_revenue,
	ROUND(previous_month_revenue, 2) AS previous_month_revenue,
	ROUND(((monthly_revenue - previous_month_revenue)/NULLIF(previous_month_revenue, 0))*100, 2) AS revenue_growth_percentage
FROM sales_with_previous_month
ORDER BY purchase_month;

-- 4. Sales performance by state
SELECT
	c.customer_state,
	COUNT(DISTINCT s.order_id) AS total_orders,
	COUNT(DISTINCT s.customer_unique_id) AS unique_customers,
	ROUND(SUM(s.product_revenue), 2) AS total_product_revenue,
	ROUND(SUM(s.product_revenue)/NULLIF(COUNT(DISTINCT s.order_id), 0), 2) AS average_order_value
FROM delivered_sales_vw s

LEFT JOIN clean_customers_vw c
	ON s.customer_id = c.customer_id

GROUP BY c.customer_state
ORDER BY total_product_revenue DESC;

-- 5. State's revenue contribution
WITH state_sales AS(
	SELECT
		c.customer_state,
		SUM(s.product_revenue) AS state_revenue
	FROM delivered_sales_vw s

	LEFT JOIN clean_customers_vw c
		ON s.customer_id = c.customer_id

	GROUP BY c.customer_state
)

SELECT 
	customer_state,
	ROUND(state_revenue, 2) AS total_revenue,
	ROUND(state_revenue * 100 / NULLIF(SUM(state_revenue) OVER(), 0), 2) AS revenue_contribution_percentage
FROM state_sales
ORDER BY state_revenue DESC;

-- 6. Top 10 cities analysis
SELECT
	c.customer_city,
	c.customer_state,
	COUNT(DISTINCT s.order_id) AS total_orders,
	ROUND(SUM(s.product_revenue), 2) AS total_revenue
FROM delivered_sales_vw s

LEFT JOIN clean_customers_vw c
	ON s.customer_id = c.customer_id

GROUP BY 
	c.customer_city,
	c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;

-- 7. Order value distribution
WITH order_value AS(
	SELECT
		order_id,
		SUM(product_revenue) AS order_revenue
	FROM delivered_sales_vw
	GROUP BY order_id
)

SELECT
	CASE
		WHEN order_revenue < 50 THEN 'Under 50'
		WHEN order_revenue < 100 THEN '50 - 99.99'
		WHEN order_revenue < 250 THEN '100 - 249.99'
		WHEN order_revenue < 500 THEN '300 - 499.99'
		ELSE '500 and above'
	END AS order_value_category,

	COUNT(*) AS total_orders,
	ROUND(SUM(order_revenue), 2) AS total_revenue
FROM order_value
GROUP BY
	CASE
		WHEN order_revenue < 50 THEN 'Under 50'
		WHEN order_revenue < 100 THEN '50 - 99.99'
		WHEN order_revenue < 250 THEN '100 - 249.99'
		WHEN order_revenue < 500 THEN '300 - 499.99'
		ELSE '500 and above'
	END 
	
ORDER BY MIN(order_revenue);
	
	
