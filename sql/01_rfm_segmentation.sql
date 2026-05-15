-- ============================================================
-- Query 1: RFM Customer Segmentation
-- Segments customers by Recency, Frequency, and Monetary value
-- ============================================================

WITH rfm_base AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)                    AS last_purchase,
        COUNT(DISTINCT o.order_id)                         AS frequency,
        SUM(p.payment_value)                               AS monetary
    FROM customers c
    JOIN orders o      ON c.customer_id      = o.customer_id
    JOIN order_payments p ON o.order_id      = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT *,
        CURRENT_DATE - last_purchase::date                 AS recency_days,
        NTILE(5) OVER (ORDER BY last_purchase DESC)        AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)             AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)              AS m_score
    FROM rfm_base
),

rfm_segments AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4              THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3              THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2              THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 3              THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2              THEN 'Lost'
            ELSE                                                 'Needs Attention'
        END AS segment
    FROM rfm_scores
)

SELECT
    segment,
    COUNT(*)                                               AS num_customers,
    ROUND(AVG(monetary)::NUMERIC, 2)                       AS avg_spend,
    ROUND(AVG(frequency)::NUMERIC, 2)                      AS avg_orders,
    ROUND(AVG(recency_days)::NUMERIC, 0)                   AS avg_days_since_purchase
FROM rfm_segments
GROUP BY segment
ORDER BY avg_spend DESC;

