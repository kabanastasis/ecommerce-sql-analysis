-- =====================================================
-- E-Commerce Sales & Customer Analytics
-- Section 05: Cohort Retention Analysis
-- Database: MySQL
-- =====================================================


-- -----------------------------------------------------
-- Cohort Retention Analysis
-- Business Question:
-- For customers acquired in each month, what percentage
-- remained active in the following months?
--
-- Cohort Month:
-- The month of a customer's first completed order.
--
-- Months Since Acquisition:
-- 0 = acquisition month
-- 1 = one month after acquisition
-- 2 = two months after acquisition
-- etc.
-- -----------------------------------------------------

WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),

customer_cohorts AS (
    SELECT
        customer_id,
        first_order_date,
        SUBSTRING(first_order_date, 1, 7) AS cohort_month
    FROM first_purchase
),

monthly_activity AS (
    SELECT
        customer_id,
        SUBSTRING(order_date, 1, 7) AS activity_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY
        customer_id,
        SUBSTRING(order_date, 1, 7)
),

cohort_activity AS (
    SELECT
        c.cohort_month,
        a.customer_id,
        a.activity_month
    FROM customer_cohorts c
    JOIN monthly_activity a
        ON c.customer_id = a.customer_id
),

cohort_periods AS (
    SELECT
        cohort_month,
        customer_id,
        activity_month,
        TIMESTAMPDIFF(
            MONTH,
             STR_TO_DATE(CONCAT(cohort_month, '-01'), '%Y-%m-%d'),
			 STR_TO_DATE(CONCAT(activity_month, '-01'), '%Y-%m-%d')
        ) AS months_since_acquisition
    FROM cohort_activity
),

active_customers_by_period AS (
    SELECT
        cohort_month,
        months_since_acquisition,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_periods
    GROUP BY
        cohort_month,
        months_since_acquisition
),

cohort_sizes AS (
    SELECT
        *,
        MAX(
            CASE
                WHEN months_since_acquisition = 0
                    THEN active_customers
            END
        ) OVER (
            PARTITION BY cohort_month
        ) AS cohort_size
    FROM active_customers_by_period
)

SELECT
    cohort_month,
    months_since_acquisition,
    active_customers,
    cohort_size,
    ROUND(
        active_customers / cohort_size * 100,
        2
    ) AS retention_rate
FROM cohort_sizes
ORDER BY
    cohort_month,
    months_since_acquisition;
