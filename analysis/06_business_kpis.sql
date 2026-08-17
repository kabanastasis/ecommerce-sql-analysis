-- E-Commerce Sales & Customer Analytics
-- Section 06: Monthly Business KPI Report
-- Database: MySQL


-- Monthly Business KPI Report
-- Business Question:
-- How is the overall business performing each month?
--
-- KPIs:
-- Revenue
-- Total Orders
-- Completed Orders
-- Active Customers
-- Average Order Value
-- Cancelled Orders
-- Cancellation Rate

WITH completed_metrics AS (
    SELECT
        SUBSTRING(o.order_date, 1, 7) AS month,
        SUM(oi.unit_price * oi.quantity) AS monthly_revenue,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        COUNT(DISTINCT o.customer_id) AS active_customers
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY SUBSTRING(o.order_date, 1, 7)
),

order_metrics AS (
    SELECT
        SUBSTRING(order_date, 1, 7) AS month,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(
            CASE
                WHEN status = 'cancelled' THEN 1
                ELSE 0
            END
        ) AS cancelled_orders
    FROM orders
    GROUP BY SUBSTRING(order_date, 1, 7)
)

SELECT
    c.month,
    ROUND(c.monthly_revenue, 2) AS monthly_revenue,
    o.total_orders,
    c.completed_orders,
    c.active_customers,
    ROUND(
        c.monthly_revenue / c.completed_orders,
        2
    ) AS average_order_value,
    o.cancelled_orders,
    ROUND(
        o.cancelled_orders / o.total_orders * 100,
        2
    ) AS cancellation_rate
FROM completed_metrics c
JOIN order_metrics o
    ON c.month = o.month
ORDER BY c.month;
