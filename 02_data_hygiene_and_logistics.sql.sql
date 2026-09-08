/*
====================================================================
Title: Supply Chain Data Hygiene & Order Fulfillment Pipeline
Author: Sean Rivas
Tools: MySQL Workbench
Description: Focuses on data cleaning, string normalization, date arithmetic 
             for delivery SLA tracking, and temporal aggregations.
Key Techniques: String Replacement (REPLACE), Date Variance (DATEDIFF), 
               Date Formatting (DATE_FORMAT), Conditional Aggregations
====================================================================
*/
USE classicmodels;
    
-- ====================================================================
-- SECTION 1: DATA CLEANING & TEXT NORMALIZATION
-- ====================================================================

-- Objective: Audit and remediate data entry typos within product catalogs
SET SQL_SAFE_UPDATES = 0;

UPDATE products 
SET 
    productDescription = REPLACE(productDescription,
        'abuot',
        'about');

SET SQL_SAFE_UPDATES = 1;

-- Objective: Standardize and format employee names for clean reporting presentation
SELECT 
    firstName AS raw_first_name,
    LPAD(firstName, 10, 'kk') as lpad_formatted,
    LPAD(firstName, 5, 'kk') as lpad_trimmed_check
FROM employees;

-- ====================================================================
-- SECTION 2: ORDER FULFILLMENT & LOGISTICS SLA AUDITING
-- ====================================================================

-- Objective: Calculate remaining days/variance between required delivery and actual shipment
SELECT 
    orderNumber AS order_id, 
    DATEDIFF(requiredDate, shippedDate) AS days_variance_from_required
FROM orders
WHERE shippedDate IS NOT NULL
ORDER BY days_variance_from_required DESC;

-- Objective: Track active order backlogs and delivery countdowns for in-process orders
SELECT 
    orderNumber AS order_id,
    DATEDIFF(requiredDate, orderDate) AS remaining_days_to_fulfillment
FROM orders
WHERE status = 'In Process'
ORDER BY remaining_days_to_fulfillment ASC;
        
-- Objective: Convert fulfillment windows into fractional business weeks and months for KPI reporting
SELECT 
    orderNumber AS order_id,
    ROUND(DATEDIFF(requiredDate, orderDate) / 7, 2) AS processing_weeks,
    ROUND(DATEDIFF(requiredDate, orderDate) / 30, 2) AS processing_months
FROM orders
WHERE status = 'In Process';

-- ====================================================================
-- SECTION 3: DATE TRANSFORMATION & STANDARDIZATION
-- ====================================================================

-- Objective: Transform raw timestamps into human-readable standard and long-text formats
SELECT 
    orderNumber AS order_id,
    DATE_FORMAT(orderDate, '%Y-%m-%d') AS formatted_order_date,
    DATE_FORMAT(requiredDate, '%a %D %b %Y') AS formatted_required_date,
    DATE_FORMAT(shippedDate, '%W %D %M %Y') AS formatted_shipped_date
FROM orders
WHERE shippedDate IS NOT NULL
ORDER BY shippedDate ASC;

-- ====================================================================
-- SECTION 4: TRANSACTIONAL AGGREGATIONS & VOLUME TRENDS
-- ====================================================================

-- Objective: Analyze yearly order fulfillment volume trends
SELECT 
    YEAR(shippedDate) AS shipping_year, 
    COUNT(orderNumber) AS total_orders_shipped
FROM orders
WHERE shippedDate IS NOT NULL
GROUP BY YEAR(shippedDate)
ORDER BY shipping_year ASC;

-- Objective: Track daily order intake density for a specific high-volume year (2004)
SELECT 
    DAY(orderDate) AS day_of_month, 
    COUNT(*) AS total_orders
FROM orders
WHERE YEAR(orderDate) = 2004
GROUP BY day_of_month
ORDER BY day_of_month ASC;

-- Objective: Aggregate monthly sales activity periods for seasonality tracking
SELECT 
    DATE_FORMAT(orderDate, '%Y-%m') AS period_year_month, 
    COUNT(*) AS total_orders
FROM orders 
GROUP BY period_year_month
ORDER BY period_year_month ASC;

-- Objective: Audit item-level order quantities to classify fulfillment batch types (Odd vs. Even)
SELECT 
    orderNumber AS order_id,
    SUM(quantityOrdered) AS total_quantity_ordered,
    IF(MOD(SUM(quantityOrdered), 2), 'Odd', 'Even') AS batch_type_parity
FROM orderdetails
GROUP BY orderNumber
ORDER BY orderNumber ASC;

-- Objective: Calculate average item value per product code to monitor inventory pricing tiers
SELECT 
    productCode AS product_code,
    ROUND(AVG(quantityOrdered * priceEach), 2) AS avg_order_item_value
FROM orderdetails
GROUP BY productCode
ORDER BY avg_order_item_value DESC;