-- DELIVERY AND LOGISTIC ANALYSIS
-- 1. Overall Delivery Performance
SELECT
	COUNT(DISTINCT order_id) AS total_delivered_orders,
	ROUND(AVG(delivery_days), 2) AS average_delivery_days,
	MIN(delivery_days) AS minimum_delivery_days,
	MAX(delivery_days) AS maximum_delivery_days,
	COUNT(*) FILTER(WHERE late_delivery = TRUE) AS late_delivered_orders,
	COUNT(*) FILTER(WHERE late_delivery = FALSE) AS on_time_delivered_orders,
	ROUND(COUNT(*) FILTER(WHERE late_delivery =TRUE) * 100 / NULLIF(COUNT(*), 0), 2) AS late_delivery_percentage
FROM clean_orders_vw
WHERE order_status = 'delivered'
	AND delivery_days IS NOT NULL;


-- 2. On-Time VS Late Delivery Distribution
SELECT
	CASE
		WHEN late_delivery = TRUE THEN 'Late Delivery'
		WHEN late_delivery = FALSE THEN 'On-Time Delivery'
		ELSE 'Unknown'
	END AS delivery_status,

	COUNT(*) AS total_orders,
	ROUND(COUNT(*) * 100 / NULLIF(SUM(COUNT(*)) OVER(), 0), 2) AS percentage_of_orders
FROM clean_orders_vw
WHERE order_status = 'delivered'
GROUP BY
	CASE
		WHEN late_delivery = TRUE THEN 'Late Delivery'
		WHEN late_delivery = FALSE THEN 'On-Time Delivery'
		ELSE 'Unknown'
	END
ORDER BY total_orders DESC;


-- 3. Monthly Delivery Performance
SELECT
	purchase_month,
	COUNT(DISTINCT order_id) AS total_delivered_orders,
	ROUND(AVG(delivery_days), 2) AS average_delivery_days,
	COUNT(*) FILTER (WHERE late_delivery = TRUE) AS late_delivered_orders,
	ROUND(COUNT(*) FILTER (WHERE late_delivery = TRUE) * 100 / NULLIF(COUNT(*), 0), 2) AS late_delivery_percentage
FROM clean_orders_vw
WHERE order_status = 'delivered'
	AND delivery_days IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;


-- 4. Delivery Performance by Customer State
SELECT 
	c.customer_state,
	COUNT(DISTINCT o.order_id) AS total_delivered_orders,
	ROUND(AVG(o.delivery_days), 2) AS average_delivery_days,
	COUNT(*) FILTER (WHERE o.late_delivery = TRUE) AS late_delivered_orders,
	ROUND(COUNT(*) FILTER (WHERE o.late_delivery = TRUE) * 100 / NULLIF(COUNT(*), 0), 2) AS late_delivery_percentage
FROM clean_orders_vw o

INNER JOIN clean_customers_vw c
	ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'
	AND o.delivery_days IS NOT NULL

GROUP BY c.customer_state
ORDER BY late_delivery_percentage DESC;


-- 5. Actual vs Estimated Delivery Time
SELECT
    order_id,
	purchase_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    delivery_days,
    ROUND(EXTRACT(EPOCH FROM (order_estimated_delivery_date - order_purchase_timestamp)) / 86400, 2) 
		AS estimated_delivery_days,
    ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp)) / 86400, 2) 
    	AS actual_delivery_days,
    ROUND(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_estimated_delivery_date)) / 86400, 2) 
    	AS days_difference
FROM vw_clean_orders

WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL

ORDER BY days_difference DESC;


-- 6. Delivery Delay VS Review Scores
WITH review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS average_review_score
    FROM order_reviews
    WHERE review_score IS NOT NULL
    GROUP BY order_id
)

SELECT
    CASE
        WHEN o.late_delivery = TRUE THEN 'Late Delivery'
        WHEN o.late_delivery = FALSE THEN 'On-Time Delivery'
        ELSE 'Unknown'
    END AS delivery_status,

    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(r.average_review_score), 2) AS average_review_score,
    COUNT(*) FILTER (WHERE r.average_review_score IS NOT NULL) AS orders_with_reviews

FROM clean_orders_vw o

LEFT JOIN review_summary r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'

GROUP BY
    CASE
        WHEN o.late_delivery = TRUE THEN 'Late Delivery'
        WHEN o.late_delivery = FALSE THEN 'On-Time Delivery'
        ELSE 'Unknown'
    END
	
ORDER BY average_review_score DESC;


-- 7. Delivery Time Distribution
SELECT
    CASE
        WHEN delivery_days <= 7 THEN '0-7 Days'
        WHEN delivery_days <= 14 THEN '8-14 Days'
        WHEN delivery_days <= 21 THEN '15-21 Days'
        ELSE 'More than 21 Days'
    END AS delivery_time_category,

    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100 / NULLIF(SUM(COUNT(*)) OVER (), 0), 2) AS percentage_of_orders,
    ROUND(AVG(delivery_days), 2) AS average_delivery_days
FROM clean_orders_vw

WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL
  AND delivery_days >= 0

GROUP BY
    CASE
        WHEN delivery_days <= 7 THEN '0-7 Days'
        WHEN delivery_days <= 14 THEN '8-14 Days'
        WHEN delivery_days <= 21 THEN '15-21 Days'
        ELSE 'More than 21 Days'
    END

ORDER BY MIN(delivery_days);


-- 8. Delivery Data Quality Check
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL)
    	AS missing_delivery_dates,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL)
    	AS missing_estimated_dates,
    COUNT(*) FILTER (WHERE delivery_days IS NULL)
    	AS missing_delivery_days,
    COUNT(*) FILTER (WHERE delivery_days < 0)
    	AS negative_delivery_days,
    COUNT(*) FILTER (WHERE late_delivery IS NULL)
    	AS missing_late_delivery_flags

FROM clean_orders_vw
WHERE order_status = 'delivered';