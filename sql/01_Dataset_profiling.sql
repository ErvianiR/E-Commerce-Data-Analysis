-- A. Database Profiling

-- 1.Check imported dataset
SELECT
	table_name
FROM information_schema.tables
WHERE table_schema = 'public'
	AND table_type = 'BASE TABLE'
ORDER BY table_name ASC;

-- 2. Number of records
SELECT 'customers' AS table_name, COUNT(*) AS total_records
FROM customers

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'payments', COUNT(*)
FROM order_payments

UNION ALL

SELECT 'reviews', COUNT(*)
FROM order_reviews

UNION ALL

SELECT 'sellers', COUNT(*)
FROM sellers

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM geolocation

UNION ALL

SELECT 'category', COUNT(*)
FROM product_category_name_translation;


-- 3. Order status distribution
SELECT 
	order_status,
	COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- 4. Order date range
SELECT 
	MIN(order_purchase_timestamp) AS first_order,
	MAX(order_purchase_timestamp) AS last_order
FROM orders;


-- 5. Customer location
SELECT
	customer_state,
	COUNT(*) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC;


-- 6. Product category
SELECT 
	product_category_name,
	COUNT(*) AS total_products
FROM products
GROUP BY product_category_name
ORDER BY total_products DESC;


-- 7. Payment method
SELECT 
	payment_type,
	COUNT(*) AS total_transactions,
	ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- 8. Review score
SELECT
	review_score,
	COUNT(*) AS total_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY total_reviews DESC;