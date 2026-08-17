-- E-Commerce Sales & Customer Analytics
-- Section 04: Customer Retention Analysis
-- Database: MySQL



# 1. Monthly Active Customers
-- Business Question:
-- How many unique customers completed at least
-- one purchase in each month?


SELECT
    SUBSTRING(order_date, 1, 7) AS month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM orders
WHERE status = 'completed'
GROUP BY SUBSTRING(order_date, 1, 7)
ORDER BY month;


# 2. Month-over-Month Active Customer Growth
-- Business Question:
-- How is the number of active customers changing
-- compared with the previous month?

WITH monthly_active_customers AS (
    SELECT
        SUBSTRING(order_date, 1, 7) AS month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM orders
    WHERE status = 'completed'
    GROUP BY SUBSTRING(order_date, 1, 7)
),

previous_month_customers AS (
    SELECT
        month,
        active_customers,
        LAG(active_customers) OVER (
            ORDER BY month
        ) AS previous_month_customers
    FROM monthly_active_customers
)

SELECT
    month,
    active_customers,
    previous_month_customers,
    ROUND(
        (active_customers - previous_month_customers)
        / previous_month_customers * 100,
        2
    ) AS customer_growth_percentage
FROM previous_month_customers
ORDER BY month;


# 3. New vs Returning Customers
-- Business Question:
-- How many active customers each month are new
-- customers versus returning customers?
--
-- New Customer:
-- First completed order occurred in the current month.
--
-- Returning Customer:
-- Customer completed an order in a previous month
-- and purchased again.

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),

monthly_customer_activity AS (
    SELECT
        SUBSTRING(order_date, 1, 7) AS month,
        customer_id
    FROM orders
    WHERE status = 'completed'
    GROUP BY
        SUBSTRING(order_date, 1, 7),
        customer_id
),

customer_months AS (
    SELECT
        m.month,
        m.customer_id,
        f.first_order_date
    FROM monthly_customer_activity m
    JOIN first_purchase f
        ON m.customer_id = f.customer_id
),

classified_customers AS (
    SELECT
        month,
        customer_id,
        CASE
            WHEN SUBSTRING(first_order_date, 1, 7) = month
                THEN 'New Customer'
            ELSE 'Returning Customer'
        END AS customer_type
    FROM customer_months
)

SELECT
    month,
    SUM(
        CASE
            WHEN customer_type = 'New Customer' THEN 1
            ELSE 0
        END
    ) AS new_customers,
    SUM(
        CASE
            WHEN customer_type = 'Returning Customer' THEN 1
            ELSE 0
        END
    ) AS returning_customers
FROM classified_customers
GROUP BY month
ORDER BY month;


# 4. Monthly Repeat Purchase Rate
-- Business Question:
-- What percentage of active customers each month
-- are returning customers?
--
-- Repeat Purchase Rate =
-- Returning Customers / Total Active Customers

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),

monthly_customer_activity AS (
    SELECT
        SUBSTRING(order_date, 1, 7) AS month,
        customer_id
    FROM orders
    WHERE status = 'completed'
    GROUP BY
        SUBSTRING(order_date, 1, 7),
        customer_id
),

customer_months AS (
    SELECT
        m.month,
        m.customer_id,
        f.first_order_date
    FROM monthly_customer_activity m
    JOIN first_purchase f
        ON m.customer_id = f.customer_id
),

classified_customers AS (
    SELECT
        month,
        customer_id,
        CASE
            WHEN SUBSTRING(first_order_date, 1, 7) = month
                THEN 'New Customer'
            ELSE 'Returning Customer'
        END AS customer_type
    FROM customer_months
),

monthly_retention AS (
    SELECT
        month,
        SUM(
            CASE
                WHEN customer_type = 'New Customer' THEN 1
                ELSE 0
            END
        ) AS new_customers,
        SUM(
            CASE
                WHEN customer_type = 'Returning Customer' THEN 1
                ELSE 0
            END
        ) AS returning_customers,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM classified_customers
    GROUP BY month
)

SELECT
    month,
    new_customers,
    returning_customers,
    active_customers,
    ROUND(
        returning_customers / active_customers * 100,
        2
    ) AS repeat_purchase_rate
FROM monthly_retention
ORDER BY month;
