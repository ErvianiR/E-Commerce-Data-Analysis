-- Data Cleaning and Analytical View
-- 1. Clean order view

CREATE OR REPLACE VIEW clean_orders_vw AS 
SELECT 
	order_id,
	customer_id,
	LOWER(TRIM(order_status)) AS order_status,
	order_purchase_timestamp,
	order_approved_at,
	order_delivered_carrier_date,
	order_delivered_customer_date,
	order_estimated_delivery_date,

	-- Purchase date
	order_purchase_timestamp::DATE AS purchase_date,

	-- Purchase month
	DATE_TRUNC('month', order_purchase_timestamp)::DATE AS purchase_month,

	-- Delivery duration in days
	CASE
		WHEN order_delivered_customer_date IS NOT NULL
		THEN ROUND(
			(EXTRACT
				(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp))/ 86400
			)::NUMERIC,2
		)
	END AS delivery_days,

	-- Late delivery indicator
	CASE
		WHEN order_delivered_customer_date IS NOT NULL
		AND order_estimated_delivery_date IS NOT NULL
		AND order_delivered_customer_date > order_estimated_delivery_date
		THEN TRUE
		ELSE FALSE
	END AS late_delivery

FROM orders;

SELECT*
FROM clean_orders_vw
LIMIT 10;

-- 2. Clean order items view
CREATE OR REPLACE VIEW clean_order_items_vw AS
SELECT
	order_id,
	order_item_id,
	product_id,
	seller_id,
	shipping_limit_date,
	price,
	freight_value,

	-- Product revenue
	price AS product_revenue,

	-- Product price plus freight
	price + freight_value AS item_total_value
FROM order_items
WHERE price >= 0
	AND freight_value >= 0;

SELECT*
FROM clean_order_items_vw
LIMIT 10;

-- 3. Clean products view
CREATE OR REPLACE VIEW clean_products_vw AS
SELECT 
	p.product_id,
	p.product_category_name,
	COALESCE( 
		NULLIF(
			TRIM(t.product_category_name_english), ''
		), 'unknown'
	) AS product_category_english,
	p.product_name_lenght,
	p.product_description_lenght,
	p.product_photos_qty,
	p.product_weight_g,
	p.product_length_cm,
	p.product_height_cm,
	p.product_width_cm
FROM products p
LEFT JOIN product_category_name_translation t
	ON p.product_category_name = t.product_category_name;

SELECT*
FROM clean_products_vw
LIMIT 10;

-- 4. Clean customer view
CREATE OR REPLACE VIEW clean_customers_vw AS
SELECT 
	customer_id,
	customer_unique_id,
	customer_zip_code_prefix,
	INITCAP(TRIM(customer_city)) AS customer_city,
	UPPER(TRIM(customer_state)) AS customer_state
FROM customers;

SELECT*
FROM clean_customers_vw
LIMIT 10;

-- 5. Order-Level payment view
CREATE OR REPLACE VIEW order_payments_vw AS
SELECT
	order_id,
	COUNT(*) AS payment_records,
	SUM(payment_value) AS total_payment_value,
	SUM(payment_installments) AS total_payment_installments,
	STRING_AGG(
		DISTINCT payment_type, 
		', '
		ORDER BY payment_type
	) AS payment_method
FROM order_payments
GROUP BY order_id;

SELECT*
FROM order_payments_vw
LIMIT 10;

-- 6. Order-Level review view
CREATE OR REPLACE VIEW order_reviews_vw AS
SELECT
	order_id,
	COUNT(*) AS review_count,
	ROUND(AVG(review_score)::NUMERIC, 2) AS average_review_scores
FROM order_reviews
WHERE review_score BETWEEN 1 AND 5
GROUP BY order_id;

SELECT*
FROM order_reviews_vw
LIMIT 10;

-- 7. Delivered sales view
CREATE OR REPLACE VIEW delivered_sales_vw AS
SELECT
	o.order_id,
	o.customer_id,
	c.customer_unique_id,

	o.purchase_date,
	o.purchase_month,
	o.order_status,

	oi.order_item_id,
	oi.product_id,
	oi.seller_id,

	oi.price,
	oi.freight_value,
	oi.product_revenue,
	oi.item_total_value,

	p.product_category_english,

	o.delivery_days,
	o.late_delivery
FROM clean_orders_vw o
INNER JOIN clean_order_items_vw oi
	ON o.order_id = oi.order_id

LEFT JOIN clean_customers_vw c
	ON o.customer_id = c.customer_id

LEFT JOIN clean_products_vw p
	ON oi.product_id = p.product_id

WHERE o.order_status = 'delivered';

SELECT*
FROM delivered_sales_vw
LIMIT 10;

-- 8. Validate the delivered data
SELECT
	COUNT(DISTINCT order_id) AS delivered_orders,
	COUNT(DISTINCT customer_unique_id) AS unique_customers,
	COUNT(*) AS total_items_sold,
	ROUND(SUM(product_revenue), 2) AS total_product_revenue,
	ROUND(SUM(freight_value), 2) AS total_freight_value,
	ROUND(SUM(item_total_value), 2) AS total_sales_including_freight
FROM delivered_sales_vw;
