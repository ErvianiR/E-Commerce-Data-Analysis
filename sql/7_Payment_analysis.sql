-- Payment Analysis
-- 1. Payment method distribution
SELECT
	payment_type,
	COUNT(*) AS total_payment_records,
	COUNT(DISTINCT order_id) AS total_orders,
	ROUND(SUM(payment_value), 2) AS total_payment_value,
	ROUND(AVG(payment_value), 2) AS average_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- 2. Revenue contribution (by payment method)
WITH payment_summary AS (
	SELECT
		payment_type,
		SUM(payment_value) AS total_payment_revenue
	FROM order_payments
	GROUP BY payment_type
)

SELECT
	payment_type,
	ROUND(total_payment_revenue, 2) AS total_payment_value,
	ROUND(total_payment_revenue * 100 / NULLIF(SUM(total_payment_revenue) OVER(), 0), 2) AS revenue_contribution_percentage
FROM payment_summary
ORDER BY total_payment_value DESC;


-- 3. Installment distribution
SELECT
	payment_installments,
	COUNT(*) AS total_payment_records,
	COUNT(DISTINCT order_id) AS total_orders,
	ROUND(SUM(payment_value), 2) AS total_payment_value,
	ROUND(AVG(payment_value), 2) AS average_payment_value
FROM order_payments
GROUP BY payment_installments
ORDER BY payment_installments;


-- 4. Average installment 
SELECT
	payment_type,
	COUNT(DISTINCT order_id) AS total_orders,
	ROUND(AVG(payment_installments), 2) AS average_installments,
	MAX(payment_installments) AS maximum_installments,
	ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY average_installments DESC;


-- 5. Order-level payment
WITH order_payment_summary AS (
	SELECT
		order_id,
		SUM(payment_value) AS total_order_payment,
		COUNT(*) AS payment_record_count,
		MAX(payment_installments) AS maximum_installments
	FROM order_payments
	GROUP BY order_id
)

SELECT
	COUNT(*) AS total_orders,
	ROUND(SUM(total_order_payment),2) AS total_payment,
	ROUND(AVG(total_order_payment),2) AS average_order_payment,
	ROUND(MIN(total_order_payment),2) AS minimum_order_payment,
	ROUND(MAX(total_order_payment),2) AS maximum_order_payment,
	ROUND(AVG(payment_record_count), 2) AS average_payment_record_per_order
FROM order_payment_summary;


-- 6. Monthly payment trends for delivered orders
WITH delivered_order_payments AS (
	SELECT
		o.order_id,
		DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS purchase_month,
		SUM(p.payment_value) AS total_payment_value
	FROM orders o
	INNER JOIN order_payments p
		ON o.order_id = p.order_id
	WHERE LOWER(TRIM(o.order_status)) = 'delivered'
	GROUP BY 
		o.order_id,
		DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
)

SELECT
	purchase_month,
	COUNT(*) AS total_orders,
	ROUND(SUM(total_payment_value), 2) AS monthly_payment_value,
	ROUND(AVG(total_payment_value), 2) AS average_payment_per_order
FROM delivered_order_payments
GROUP BY purchase_month
ORDER BY purchase_month;


-- 7. Payment data quality check
SELECT
	COUNT(*) AS total_payment_record,
	COUNT(*) FILTER(WHERE payment_value <= 0) AS non_positive_payment_records,
	COUNT(*) FILTER(WHERE payment_value < 1) AS invalid_installment_records,
	COUNT(*) FILTER(WHERE payment_value IS NULL OR TRIM(payment_type) ='') AS missing_payment_types
FROM order_payments;