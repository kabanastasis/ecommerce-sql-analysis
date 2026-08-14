-- =====================================================
-- E-Commerce Sales & Customer Analytics
-- Section 01: Sales Performance
-- Database: MySQL
-- =====================================================


-- -----------------------------------------------------
-- 1. Total Orders
-- Business Question:
-- How many orders have been placed in total,
-- regardless of order status?
-- -----------------------------------------------------

SELECT 
    COUNT(*) AS total_orders
FROM orders;


-- -----------------------------------------------------
-- 2. Total Revenue
-- Business Question:
-- How much revenue has been generated from
-- completed orders?
-- -----------------------------------------------------

SELECT 
    ROUND(SUM(oi.unit_price * oi.quantity), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'completed';


-- -----------------------------------------------------
-- 3. Average Order Value
-- Business Question:
-- What is the average value of a completed order?
--
-- AOV = Total Revenue / Number of Completed Orders
-- -----------------------------------------------------

SELECT 
    ROUND(
        SUM(oi.unit_price * oi.quantity)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'completed';


-- -----------------------------------------------------
-- 4. Monthly Revenue
-- Business Question:
-- How much revenue was generated each month
-- from completed orders?
-- -----------------------------------------------------

SELECT
    SUBSTRING(o.order_date, 1, 7) AS month,
    ROUND(
        SUM(oi.unit_price * oi.quantity),
        2
    ) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY SUBSTRING(o.order_date, 1, 7)
ORDER BY month;


-- -----------------------------------------------------
-- 5. Month-over-Month Revenue Growth
-- Business Question:
-- How is revenue changing compared with
-- the previous month?
-- -----------------------------------------------------

WITH monthly_sales AS (
    SELECT
        SUBSTRING(o.order_date, 1, 7) AS month,
        SUM(oi.unit_price * oi.quantity) AS monthly_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY SUBSTRING(o.order_date, 1, 7)
),

previous_month_sales AS (
    SELECT
        month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            ORDER BY month
        ) AS previous_month_revenue
    FROM monthly_sales
)

SELECT
    month,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        (monthly_revenue - previous_month_revenue)
        / previous_month_revenue * 100,
        2
    ) AS revenue_growth_percentage
FROM previous_month_sales
ORDER BY month;
