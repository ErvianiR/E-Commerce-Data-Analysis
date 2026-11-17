-- CUSTOMER REVIEW AND SATISFACTION ANALYSIS
-- 1. Overall Review Score Distribution
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER (), 0), 2)
		AS review_percentage
FROM order_reviews
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score;


-- 2. Overall Customer Satisfaction KPIs
SELECT
    COUNT(*) AS total_review_records,
    ROUND(AVG(review_score), 2) AS average_review_score,
    COUNT(*) FILTER (WHERE review_score >= 4) AS positive_reviews,
    COUNT(*) FILTER (WHERE review_score <= 2) AS negative_reviews,
    ROUND(COUNT(*) FILTER (WHERE review_score >= 4) * 100 / NULLIF(COUNT(*) FILTER (
		WHERE review_score IS NOT NULL), 0), 2) AS positive_review_percentage,
    ROUND(COUNT(*) FILTER (WHERE review_score <= 2) * 100 / NULLIF(COUNT(*) FILTER (
            WHERE review_score IS NOT NULL), 0), 2) AS negative_review_percentage
FROM order_reviews;


-- 3. Monthly Customer Satisfaction Trends
WITH order_review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS average_review_score
    FROM order_reviews
    WHERE review_score IS NOT NULL
    GROUP BY order_id
)

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE AS purchase_month,
    COUNT(DISTINCT o.order_id) AS reviewed_orders,
    ROUND(AVG(r.average_review_score), 2) AS average_review_score
FROM clean_orders_vw o

INNER JOIN order_review_summary r
    ON o.order_id = r.order_id

GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE

ORDER BY purchase_month;


-- 4. Customer Satisfaction by State
WITH order_review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS average_review_score
    FROM order_reviews
    WHERE review_score IS NOT NULL
    GROUP BY order_id
)

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS reviewed_orders,
    ROUND(AVG(r.average_review_score), 2) AS average_review_score,
    COUNT(*) FILTER (WHERE r.average_review_score <= 2) AS negative_review_orders,
    ROUND(COUNT(*) FILTER (WHERE r.average_review_score <= 2) * 100 / NULLIF(COUNT(*), 0), 2)
    	AS negative_review_percentage

FROM clean_orders_vw o

INNER JOIN clean_customers_vw c
    ON o.customer_id = c.customer_id

INNER JOIN order_review_summary r
    ON o.order_id = r.order_id

GROUP BY c.customer_state
ORDER BY average_review_score ASC;


-- 5. Review Scores by Product Category
WITH order_review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS average_review_score
    FROM order_reviews
    WHERE review_score IS NOT NULL
    GROUP BY order_id
)

SELECT
    p.product_category_english,
    COUNT(*) AS total_items,
    COUNT(DISTINCT s.order_id) AS total_orders,
    ROUND(AVG(r.average_review_score), 2) AS average_review_score,
    COUNT(*) FILTER (WHERE r.average_review_score <= 2) AS negative_review_items
FROM delivered_sales_vw s

INNER JOIN clean_products_vw p
    ON s.product_id = p.product_id

INNER JOIN order_review_summary r
    ON s.order_id = r.order_id

GROUP BY p.product_category_english

ORDER BY average_review_score ASC;


-- 6. Review Scores VS Delivery Performance
WITH order_review_summary AS (
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
    COUNT(*) FILTER (WHERE r.average_review_score >= 4) AS positive_review_orders,
    COUNT(*) FILTER (WHERE r.average_review_score <= 2) AS negative_review_orders
FROM clean_orders_vw o

INNER JOIN order_review_summary r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'

GROUP BY
    CASE
        WHEN o.late_delivery = TRUE THEN 'Late Delivery'
        WHEN o.late_delivery = FALSE THEN 'On-Time Delivery'
        ELSE 'Unknown'
    END

ORDER BY average_review_score DESC;

-- 7. Review Comment Analysis
SELECT
    COUNT(*) AS total_review_records,
    COUNT(*) FILTER (WHERE review_comment_message IS NOT NULL
          AND TRIM(review_comment_message) <> '') AS reviews_with_comments,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL
          OR TRIM(review_comment_message) = '') AS reviews_without_comments,
    ROUND(COUNT(*) FILTER (WHERE review_comment_message IS NOT NULL
         AND TRIM(review_comment_message) <> '') * 100.0 / NULLIF(COUNT(*), 0), 2)
		AS comment_submission_percentage
FROM order_reviews;

-- 8. Review Scores VS Written Feedback
SELECT
    CASE
        WHEN review_comment_message IS NOT NULL
         AND TRIM(review_comment_message) <> ''
        THEN 'With Written Comment'
        ELSE 'Without Written Comment'
    END AS comment_status,

    COUNT(*) AS total_reviews,
    ROUND(AVG(review_score), 2) AS average_review_score,
    COUNT(*) FILTER (WHERE review_score <= 2) AS negative_reviews,
    COUNT(*) FILTER (WHERE review_score >= 4) AS positive_reviews
FROM order_reviews
WHERE review_score IS NOT NULL
GROUP BY
    CASE
        WHEN review_comment_message IS NOT NULL
         AND TRIM(review_comment_message) <> ''
        THEN 'With Written Comment'
        ELSE 'Without Written Comment'
    END
ORDER BY average_review_score DESC;


-- 9. Review Data Quality Check
SELECT
    COUNT(*) AS total_review_records,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS missing_review_scores,
    COUNT(*) FILTER (WHERE review_score < 1 OR review_score > 5) AS invalid_review_scores,
    COUNT(*) FILTER (WHERE review_id IS NULL) AS missing_review_ids,
    COUNT(*) - COUNT(DISTINCT review_id)AS duplicate_review_id_count
FROM order_reviews;