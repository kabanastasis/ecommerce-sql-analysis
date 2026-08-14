-- =====================================================
-- E-Commerce Sales & Customer Analytics
-- Section 02: Product & Category Analysis
-- Database: MySQL
-- =====================================================


-- -----------------------------------------------------
-- 1. Top 10 Products by Revenue
-- Business Question:
-- Which products generate the highest revenue
-- from completed orders?
-- -----------------------------------------------------

SELECT
    oi.product_id,
    pr.product_name,
    ROUND(SUM(oi.unit_price * oi.quantity), 2) AS product_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products pr
    ON oi.product_id = pr.product_id
WHERE o.status = 'completed'
GROUP BY
    oi.product_id,
    pr.product_name
ORDER BY product_revenue DESC
LIMIT 10;


-- -----------------------------------------------------
-- 2. Top 10 Products by Units Sold
-- Business Question:
-- Which products sold the highest number of units?
-- -----------------------------------------------------

SELECT
    oi.product_id,
    pr.product_name,
    SUM(oi.quantity) AS units_sold
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products pr
    ON oi.product_id = pr.product_id
WHERE o.status = 'completed'
GROUP BY
    oi.product_id,
    pr.product_name
ORDER BY units_sold DESC
LIMIT 10;


-- -----------------------------------------------------
-- 3. Category Performance
-- Business Question:
-- How does each product category perform in terms
-- of revenue, units sold, orders and AOV?
-- -----------------------------------------------------

SELECT
    c.category_id,
    c.category_name,
    ROUND(SUM(oi.unit_price * oi.quantity), 2) AS revenue,
    SUM(oi.quantity) AS total_units,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(
        SUM(oi.unit_price * oi.quantity)
        / COUNT(DISTINCT oi.order_id),
        2
    ) AS average_order_value
FROM categories c
JOIN products p
    ON c.category_id = p.category_id
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY
    c.category_id,
    c.category_name
ORDER BY revenue DESC;


-- -----------------------------------------------------
-- 4. Best Product Within Each Category
-- Business Question:
-- Which product generates the most revenue
-- within each category?
-- -----------------------------------------------------

WITH revenue_per_product AS (
    SELECT
        c.category_id,
        c.category_name,
        p.product_id,
        p.product_name,
        SUM(oi.unit_price * oi.quantity) AS revenue
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY
        c.category_id,
        c.category_name,
        p.product_id,
        p.product_name
),

product_ranks AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY category_id
            ORDER BY revenue DESC
        ) AS row_num
    FROM revenue_per_product
)

SELECT
    category_id,
    category_name,
    product_id,
    product_name,
    ROUND(revenue, 2) AS revenue
FROM product_ranks
WHERE row_num = 1
ORDER BY revenue DESC;


-- -----------------------------------------------------
-- 5. Category Revenue Share
-- Business Question:
-- What percentage of total revenue is generated
-- by each product category?
-- -----------------------------------------------------

WITH category_revenue AS (
    SELECT
        c.category_id,
        c.category_name,
        SUM(oi.unit_price * oi.quantity) AS revenue
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY
        c.category_id,
        c.category_name
),

category_totals AS (
    SELECT
        *,
        SUM(revenue) OVER () AS total_revenue
    FROM category_revenue
)

SELECT
    category_id,
    category_name,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue / total_revenue * 100, 2) AS revenue_share_percentage
FROM category_totals
ORDER BY revenue DESC;


-- -----------------------------------------------------
-- 6. Top Revenue Category by Month
-- Business Question:
-- Which category generated the most revenue
-- in each month?
-- -----------------------------------------------------

WITH monthly_category_revenue AS (
    SELECT
        SUBSTRING(o.order_date, 1, 7) AS month,
        c.category_id,
        c.category_name,
        SUM(oi.unit_price * oi.quantity) AS monthly_revenue
    FROM categories c
    JOIN products p
        ON c.category_id = p.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY
        SUBSTRING(o.order_date, 1, 7),
        c.category_id,
        c.category_name
),

ranked_categories AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY month
            ORDER BY monthly_revenue DESC
        ) AS row_num
    FROM monthly_category_revenue
)

SELECT
    month,
    category_id,
    category_name,
    ROUND(monthly_revenue, 2) AS monthly_revenue
FROM ranked_categories
WHERE row_num = 1
ORDER BY month;


-- -----------------------------------------------------
-- 7. Products With Declining Revenue
-- Business Question:
-- Which products experienced negative revenue growth
-- in their latest available month?
-- -----------------------------------------------------

WITH product_monthly_revenue AS (
    SELECT
        SUBSTRING(o.order_date, 1, 7) AS month,
        oi.product_id,
        pr.product_name,
        SUM(oi.unit_price * oi.quantity) AS product_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products pr
        ON oi.product_id = pr.product_id
    WHERE o.status = 'completed'
    GROUP BY
        SUBSTRING(o.order_date, 1, 7),
        oi.product_id,
        pr.product_name
),

previous_product_revenue AS (
    SELECT
        *,
        LAG(product_revenue) OVER (
            PARTITION BY product_id
            ORDER BY month
        ) AS previous_revenue
    FROM product_monthly_revenue
),

product_growth AS (
    SELECT
        *,
        ROUND(
            (product_revenue - previous_revenue)
            / previous_revenue * 100,
            2
        ) AS growth_percentage,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY month DESC
        ) AS row_num
    FROM previous_product_revenue
)

SELECT
    product_id,
    product_name,
    month,
    ROUND(product_revenue, 2) AS product_revenue,
    ROUND(previous_revenue, 2) AS previous_revenue,
    growth_percentage
FROM product_growth
WHERE row_num = 1
  AND growth_percentage < 0
ORDER BY growth_percentage;


-- -----------------------------------------------------
-- 8. Pareto Analysis
-- Business Question:
-- Which products account for approximately 80%
-- of total revenue?
-- -----------------------------------------------------

WITH product_revenue AS (
    SELECT
        pr.product_id,
        pr.product_name,
        SUM(oi.unit_price * oi.quantity) AS product_revenue
    FROM products pr
    JOIN order_items oi
        ON pr.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY
        pr.product_id,
        pr.product_name
),

cumulative_revenue AS (
    SELECT
        *,
        SUM(product_revenue) OVER (
            ORDER BY product_revenue DESC
        ) AS cumulative_revenue,
        SUM(product_revenue) OVER () AS total_revenue
    FROM product_revenue
),

pareto_analysis AS (
    SELECT
        *,
        ROUND(
            cumulative_revenue / total_revenue * 100,
            2
        ) AS cumulative_percentage,
        ROW_NUMBER() OVER (
            ORDER BY product_revenue DESC
        ) AS product_rank
    FROM cumulative_revenue
)

SELECT
    MIN(product_rank) AS products_to_reach_80_percent
FROM pareto_analysis
WHERE cumulative_percentage >= 80;
