-- B. Data Quality Assessment

-- 1. Missing Value
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS missing_unique_id,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS missing_city,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS missing_state
FROM customers;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS missing_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS missing_purchase_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS missing_delivery_date
FROM orders;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS missing_seller_id,
    COUNT(*) FILTER (WHERE price IS NULL) AS missing_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS missing_freight
FROM order_items;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS missing_category,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS missing_weight
FROM products;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS missing_payment_type,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS missing_payment_value
FROM order_payments;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE review_id IS NULL) AS missing_review_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS missing_review_score
FROM order_reviews;


-- 2. Duplicate records
SELECT 
	customer_id,
	COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


SELECT 
	order_id,
	COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


SELECT 
	product_id,
	COUNT(*) AS duplicate_count
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;


SELECT 
	seller_id,
	COUNT(*) AS duplicate_count
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


SELECT 
	order_id,
	order_item_id,
	COUNT(*) AS duplicate_count
FROM order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


SELECT 
	order_id,
	payment_sequential,
	COUNT(*) AS duplicate_count
FROM order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;


-- 3. Invalid business values
-- Invalid review scores
SELECT *
FROM order_reviews
WHERE review_score NOT BETWEEN 1 AND 5
   OR review_score IS NULL;

-- Negative and invalid prices
SELECT *
FROM order_items
WHERE price < 0
	OR freight_value < 0;

-- Invalid payment values
SELECT *
FROM order_payments
WHERE payment_value < 0;

-- Invalid order date
SELECT *
FROM orders
WHERE order_purchase_timestamp IS NULL
	OR (
		order_approved_at IS NOT NULL
		AND order_approved_at < order_purchase_timestamp
	)
	OR (
		order_delivered_customer_date IS NOT NULL
		AND order_delivered_customer_date < order_purchase_timestamp
	);


-- 4. Check relationship between tables
-- Orders without matching customers
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Order items without matching orders
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Order items without matching products
SELECT COUNT(*) AS orphan_products
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Order items without matching sellers
SELECT COUNT(*) AS orphan_sellers
FROM order_items oi
LEFT JOIN sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;
