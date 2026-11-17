-- FINAL ANALYTICAL VIEW
-- 1. Sales Overview — One Row per Order
CREATE OR REPLACE VIEW sales_orders_vw AS

WITH order_freight AS (
	SELECT
		order_id,
		SUM(freight_value) AS total_freight,
		COUNT(*) AS total_items
	FROM delivered_sales_vw
	GROUP BY order_id
)

SELECT
	 s.order_id,
	 s. customer_unique_id,
	 o.customer_id,
	 c.customer_state,
	 c.customer_city,
	 o.purchase_date,
	 o.purchase_month,
	 s.order_revenue AS product_revenue,
	 COALESCE(f.total_freight, 0) AS freight_value,
	 s.order_revenue + COALESCE(f.total_freight, 0) AS total_sales,
	 COALESCE(f.total_items, 0) AS total_items
FROM customer_order_summary_vw s

INNER JOIN clean_orders_vw o
	ON s.order_id = o.order_id

INNER JOIN clean_customers_vw c
	ON o.customer_id = c.customer_id

LEFT JOIN order_freight f
	ON s.order_id = f.order_id;


SELECT *
FROM sales_orders_vw
LIMIT 10;


-- 2. Monthly Sales Performance
CREATE OR REPLACE VIEW monthly_sales_vw AS

SELECT
	purchase_month,
	COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT customer_unique_id) AS total_customers,
	SUM(total_items) AS total_items_sold,
	ROUND(SUM(product_revenue), 2) AS product_revenue,
	ROUND(SUM(freight_value), 2) AS total_freight,
	ROUND(SUM(total_sales), 2) AS total_sales,
	ROUND(SUM(product_revenue) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS average_order_value
FROM sales_orders_vw
GROUP BY purchase_month
ORDER BY purchase_month;
SELECT*
FROM monthly_sales_vw;


SELECT *
FROM monthly_sales_vw
LIMIT 10;


-- 3. Product Category Performance
CREATE OR REPLACE VIEW category_performance_vw AS

SELECT
	product_category_english,
	COUNT(*) AS total_items_sold,
	COUNT(DISTINCT order_id) AS total_orders,
	COUNT(DISTINCT product_id) AS unique_products,
	ROUND(SUM(product_revenue), 2) AS product_revenue,
	ROUND(SUM(freight_value), 2) AS total_freight,
	ROUND(AVG(product_revenue), 2) AS average_item_price
FROM delivered_sales_vw
GROUP BY product_category_english;


SELECT *
FROM category_performance_vw
LIMIT 10;


-- 4. Payment Method Performance
CREATE OR REPLACE VIEW payment_method_vw AS

SELECT
	p.payment_type,
	COUNT(*) AS total_payment_records,
	COUNT(DISTINCT p.order_id) AS total_orders,
	ROUND(SUM(p.payment_value), 2) AS total_payment_value,
	ROUND(AVG(p.payment_value), 2) AS average_payment_value,
	ROUND(AVG(p.payment_installments), 2) AS average_installments
FROM order_payments p

INNER JOIN clean_orders_vw o
	ON p.order_id = o.order_id

WHERE o.order_status = 'delivered'
GROUP BY p.payment_type;


SELECT *
FROM payment_method_vw
LIMIT 10;


-- 5. Customer RFM Segmentation
CREATE OR REPLACE VIEW customer_rfm_vw AS

WITH reference_date AS (
	SELECT
		MAX(purchase_date) + 1 AS analysis_date
	FROM customer_order_summary_vw
),

customer_rfm AS (
	SELECT
		customer_unique_id,
		(SELECT analysis_date FROM reference_date) - MAX(purchase_date)
			AS recency_days,
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

		NTILE(5) OVER(ORDER BY recency_days ASC) AS r_score,
		NTILE(5) OVER(ORDER BY frequency ASC) AS f_score,
		NTILE(5) OVER(ORDER BY monetary ASC) AS m_score
	FROM customer_rfm
	
),

customer_segments AS (
	SELECT 
		customer_unique_id,
		recency_days,
		frequency,
		monetary,
		r_score,
		f_score,
		m_score,
		CONCAT(r_score, f_score, m_score) AS rfm_score,
		
		CASE
			WHEN r_score >= 4
			AND f_score >= 4
			AND m_score >= 4
				THEN 'Champions'
				
			WHEN f_score >= 4
				THEN 'Loyal Customers'

			WHEN m_score = 5
				THEN 'Big Spenders'

			WHEN r_score <= 2
			AND f_score >= 3
				THEN 'At Risk'

			WHEN r_score <= 2
			AND f_score <= 2
				THEN 'Hibernating'

			WHEN r_score >= 4
			AND f_score >= 2
				THEN 'Potential Loyalists'

			WHEN r_score = 5
			AND f_score = 1
				THEN 'Recent Customers'

			ELSE 'Others'
		END AS customer_segment
	FROM rfm_scores
)

SELECT
	customer_unique_id,
	recency_days,
	frequency,
	ROUND(monetary, 2) AS monetary,
	r_score,
	f_score,
	m_score,
	rfm_score,
	customer_segment
FROM customer_segments;


SELECT *
FROM customer_rfm_vw
LIMIT 10;


-- 6. Delivery Performance by Order
CREATE OR REPLACE VIEW delivery_orders_vw AS

SELECT
	o.order_id,
	o.customer_id,
	c.customer_state,
	c.customer_city,
	o.purchase_date,
	o.purchase_month,
	o.order_delivered_customer_date,
	o.order_estimated_delivery_date,
	o.delivery_days,
	o.late_delivery,

	CASE
		WHEN o.late_delivery = TRUE
			THEN 'Late Delivery'

		WHEN o.late_delivery = FALSE
			THEN 'On-Time Delivery'

		ELSE 'Unknown'
	END AS delivery_status
FROM clean_orders_vw o

INNER JOIN clean_customers_vw c
	ON o.customer_id = c.customer_id 

WHERE order_status = 'delivered';


SELECT *
FROM delivery_orders_vw
LIMIT 10;


-- 7. Customer Review Performance
CREATE OR REPLACE VIEW order_review_vw AS

WITH review_summary AS (
	SELECT
		order_id,
		COUNT(*) AS total_reviews,
		AVG(review_score) AS average_review_score
	FROM order_reviews
	WHERE review_score IS NOT NULL
	GROUP BY order_id
)

SELECT
	o.order_id,
	o.purchase_date,
	o.purchase_month,
	o.customer_id,
	r.total_reviews,
	ROUND(r.average_review_score, 2) AS average_review_score,

	CASE
		WHEN r.average_review_score >= 4
			THEN 'Positive'

		WHEN r.average_review_score <= 4
			THEN 'Negative'

		ELSE 'Neutral'
	END AS review_category
FROM review_summary r

INNER JOIN clean_orders_vw o
	ON r.order_id = o.order_id

WHERE o.order_status = 'delivered';


SELECT *
FROM order_review_vw
LIMIT 10;

-- 8. Validate All Views
SELECT
	'sales_orders_vw' AS view_name,
	COUNT(*) AS total_records
FROM sales_orders_vw

UNION ALL

SELECT
	'monthly_sales_vw',
	COUNT(*)
FROM monthly_sales_vw

UNION ALL

SELECT
	'category_performance_vw',
	COUNT(*)
FROM category_performance_vw

UNION ALL

SELECT
	'payment_method_vw',
	COUNT(*)
FROM payment_method_vw

UNION ALL

SELECT
	'customer_rfm_vw',
	COUNT(*)
FROM customer_rfm_vw

UNION ALL

SELECT
	'delivery_orders_vw',
	COUNT(*)
FROM delivery_orders_vw

UNION ALL

SELECT
	'order_review_vw',
	COUNT(*)
FROM order_review_vw

ORDER BY view_name;



