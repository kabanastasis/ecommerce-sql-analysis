-- E-Commerce Sales & Customer Analytics
-- Section 03: Customer Analysis
-- Database: MySQL



# 1. Unique Customers With Orders
-- Business Question:
-- How many unique customers have placed at least one order?

SELECT
    COUNT(DISTINCT customer_id) AS unique_customers
FROM orders;


# 2. Top 20 Customers by Spending
-- Business Question:
-- Which customers generated the highest revenue
-- from completed orders?

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.unit_price * oi.quantity), 2) AS total_spent,
    ROUND(
        SUM(oi.unit_price * oi.quantity)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC
LIMIT 20;


# 3. One-Time Customers
-- Business Question:
-- Which customers have completed exactly one order?

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.unit_price * oi.quantity), 2) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
HAVING COUNT(DISTINCT o.order_id) = 1
ORDER BY total_spent DESC;


# 4. Repeat Customer Rate
-- Business Question:
-- What percentage of customers with completed orders
-- have made at least two completed purchases?

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
)

SELECT
    COUNT(
        CASE
            WHEN total_orders >= 2 THEN 1
        END
    ) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(
            CASE
                WHEN total_orders >= 2 THEN 1
            END
        ) / COUNT(*) * 100,
        2
    ) AS repeat_customer_rate
FROM customer_orders;


# 5. Simplified Customer Lifetime Value
-- Business Question:
-- How much completed-order revenue has each customer
-- generated over their lifetime?
--
-- Customers without completed orders are retained
-- with CLV equal to zero.

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(
        ROUND(SUM(oi.unit_price * oi.quantity), 2),
        0
    ) AS clv
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
    AND o.status = 'completed'
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY clv DESC
LIMIT 20;


# 6. Customer Segmentation
-- Business Question:
-- How can customers be segmented based on
-- their total completed-order spending?
--
-- High Value   >= 1000
-- Medium Value >= 500 and < 1000
-- Low Value    < 500

WITH customer_spending AS (
    SELECT
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        SUM(oi.unit_price * oi.quantity) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
)

SELECT
    customer_id,
    customer_name,
    ROUND(total_spent, 2) AS total_spent,
    CASE
        WHEN total_spent >= 1000 THEN 'High Value'
        WHEN total_spent >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_spending
ORDER BY total_spent DESC;


# 7. Customer Segment Distribution
-- Business Question:
-- How many customers belong to each value segment,
-- and what percentage of customers does each represent?

WITH customer_spending AS (
    SELECT
        c.customer_id,
        SUM(oi.unit_price * oi.quantity) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY c.customer_id
),

customer_segments AS (
    SELECT
        customer_id,
        CASE
            WHEN total_spent >= 1000 THEN 'High Value'
            WHEN total_spent >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer_spending
),

segment_counts AS (
    SELECT
        customer_segment,
        COUNT(*) AS customers
    FROM customer_segments
    GROUP BY customer_segment
)

SELECT
    customer_segment,
    customers,
    ROUND(
        customers / SUM(customers) OVER () * 100,
        2
    ) AS percentage_of_customers
FROM segment_counts
ORDER BY customers DESC;


# 8. Average Order Value by Customer Segment
-- Business Question:
-- How do revenue, order volume and AOV differ
-- between High, Medium and Low Value customers?

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        SUM(oi.unit_price * oi.quantity) AS total_spent,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY c.customer_id
),

customer_segments AS (
    SELECT
        *,
        CASE
            WHEN total_spent >= 1000 THEN 'High Value'
            WHEN total_spent >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer_metrics
),

segment_metrics AS (
    SELECT
        customer_segment,
        COUNT(*) AS customers,
        SUM(total_spent) AS total_revenue,
        SUM(total_orders) AS total_orders
    FROM customer_segments
    GROUP BY customer_segment
)

SELECT
    customer_segment,
    customers,
    ROUND(total_revenue, 2) AS total_revenue,
    total_orders,
    ROUND(
        total_revenue / total_orders,
        2
    ) AS average_order_value
FROM segment_metrics
ORDER BY total_revenue DESC;
