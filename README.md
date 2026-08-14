# E-Commerce Sales & Customer Analytics Using SQL

## Project Overview

An end-to-end SQL analysis of a synthetic e-commerce dataset using MySQL.

The project analyzes sales performance, product performance, customer behavior, retention, cohort trends, and key business KPIs.

The dataset and SQL queries are included in the repository so the analysis can be reproduced.

## SQL Skills Demonstrated

- JOINs
- CTEs
- Window Functions
- LAG()
- ROW_NUMBER()
- CASE Statements
- Conditional Aggregation
- GROUP BY / HAVING
- Customer Segmentation
- Cohort Analysis
- Pareto Analysis
- Month-over-Month Growth

## Project Structure

- `README.md`
- `database/ecommerce_database.sql`
- `analysis/01_sales_performance.sql`
- `analysis/02_product_analysis.sql`
- `analysis/03_customer_analysis.sql`
- `analysis/04_customer_retention.sql`
- `analysis/05_cohort_analysis.sql`
- `analysis/06_business_kpis.sql`

## Key Business Insights

- December 2025 recorded the highest monthly revenue at approximately **€114K**.
- Electronics generated **50.13% of total revenue**, showing strong revenue concentration in one category.
- Smartphone X was the highest-revenue product, generating approximately **€158.6K**.
- **51.41%** of segmented customers were classified as High Value.
- The monthly repeat purchase rate increased from **39.60%** to approximately **94%** by mid-2026.
- New customer acquisition declined from **139 customers in January 2025** to **14 in July 2026**.
- Cancellation rates increased to **17.32% in June 2026** and **16.46% in July 2026**.

## Business Recommendations

- Investigate the increase in order cancellations.
- Reduce revenue dependence on Electronics by developing other product categories.
- Maintain retention strategies for returning customers.
- Investigate the decline in new customer acquisition.

## Dataset

The synthetic dataset contains:

- 900 customers
- 7,200 orders
- 12,000+ order items
- 50 products
- 8 categories
- Transaction data from January 2025 to July 2026

Dataset file: `database/ecommerce_database.sql`

## How to Run

1. Run `database/ecommerce_database.sql` in MySQL Workbench.
2. Select the database with `USE ecommerce_analytics;`
3. Run the SQL files inside the `analysis` folder.

## Tools Used

- MySQL
- MySQL Workbench
- GitHub
