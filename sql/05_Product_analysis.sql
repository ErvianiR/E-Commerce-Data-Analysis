-- Product Performance Analysis
-- 1. Category performance
SELECT
	product_category_english,
	COUNT(*) AS total_items_sold,
	COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT product_id) AS unique_products,
	ROUND(SUM(product_revenue), 2) AS total_product_revenue,
	ROUND(AVG(product_revenue), 2) AS average_item_price
FROM delivered_sales_vw
GROUP BY product_category_english
ORDER BY total_product_revenue DESC;

	
-- 2. TOP 10 categories
SELECT
	product_category_english,
	COUNT(*) AS total_items_sold,
	ROUND(SUM(product_revenue), 2) AS total_product_revenue
FROM delivered_sales_vw
GROUP BY product_category_english
ORDER BY total_product_revenue DESC
LIMIT 10;


-- 3. Revenue contribution
WITH category_sales AS (
	SELECT 
		product_category_english,
		SUM(product_revenue) AS category_revenue
	FROM delivered_sales_vw
	GROUP BY product_category_english
)

SELECT
	product_category_english,
	ROUND(category_revenue, 2) AS category_revenue,
	ROUND(category_revenue * 100 / NULLIF(SUM(category_revenue) OVER(), 0), 2) AS revenue_contribution_percentage 
FROM category_sales
ORDER BY category_revenue DESC;


-- 4. TOP products by revenue
SELECT
	product_id,
	product_category_english,
	COUNT(*) AS total_items_sold,
	COUNT(DISTINCT order_id) AS total_order,
	ROUND(SUM(product_revenue), 2) AS total_revenue,
	ROUND(AVG(product_revenue), 2) AS average_selling_price
FROM delivered_sales_vw
GROUP BY 
	product_id,
	product_category_english
ORDER BY total_revenue DESC
LIMIT 10;

	
-- 5. TOP products by volume
SELECT
	product_id,
	product_category_english,
	COUNT(*) AS total_items_sold,
	COUNT(DISTINCT order_id) AS total_order,
	ROUND(SUM(product_revenue), 2) AS total_revenue
FROM delivered_sales_vw
GROUP BY 
	product_id,
	product_category_english
ORDER BY total_items_sold DESC
LIMIT 10;


-- 6. Monthly category performance
SELECT
	purchase_month,
	product_category_english,
	COUNT(*) AS total_items_sold,
	ROUND(SUM(product_revenue), 2) AS monthly_revenue
FROM delivered_sales_vw
GROUP BY 
	purchase_month,
	product_category_english
ORDER BY 
	purchase_month,
	monthly_revenue DESC;

	
-- 7. Average performance
SELECT
	product_category_english,
	COUNT(*) AS total_items_sold,
	ROUND(SUM(product_revenue), 2) AS total_revenue,
	ROUND(AVG(product_revenue), 2) AS average_item_price,
	ROUND(SUM(product_revenue)/NULLIF(COUNT(*), 0), 2) AS revenue_per_item
FROM delivered_sales_vw
GROUP BY product_category_english
ORDER BY average_item_price DESC;


-- 8. Freight analysis
SELECT
	product_category_english,
	COUNT(*) AS total_items_sold,
	ROUND(SUM(freight_value), 2) AS total_freight_value,
	ROUND(AVG(freight_value), 2) AS average_freight_per_item,
	ROUND(AVG(product_revenue), 2) AS average_product_price
FROM delivered_sales_vw
GROUP BY product_category_english
ORDER BY total_freight_value DESC;