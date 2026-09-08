/*
====================================================================
Title: Multi-Schema Enterprise & Revenue Analytics
Author: Sean Rivas
Tools: MySQL Workbench
Description: Analytical portfolio covering workforce compensation, 
             top product sales volumes, shipping logistics, and 
             Month-over-Month (MoM) revenue velocity.
Key Techniques: Common Table Expressions (CTEs), Window Functions 
               (LAG, OVER), Late Joins, Correlated Subqueries, DATEDIFF
====================================================================
*/

-- ====================================================================
-- SECTION 1: WORKFORCE & COMPENSATION (HR SCHEMA)
-- ====================================================================

USE hr;

SELECT  * FROM  departments WHERE  location_id = 1700;

SELECT  employee_id, first_name, last_name, department_id
FROM   employees
WHERE  department_id IN (1, 3, 9, 10, 11)
ORDER BY first_name, last_name;

SELECT   employee_id, first_name, last_name, department_id
FROM employees
WHERE department_id IN (SELECT department_id
        FROM      departments
        WHERE location_id = 1700)
ORDER BY first_name, last_name;

SELECT employee_id, first_name, last_name
FROM  employees
WHERE  department_id NOT IN (SELECT department_id
        FROM   departments
        WHERE location_id = 1700)
ORDER BY first_name , last_name;

SELECT employee_id, first_name, last_name, salary
FROM   employees
WHERE salary = (SELECT MAX(salary) FROM  employees)
ORDER BY first_name, last_name;

SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary)FROM employees);

SELECT department_name
FROM departments d
WHERE EXISTS ( SELECT * FROM employees e 
	WHERE salary > 10000 AND e.department_id = d.department_id)
ORDER BY department_name; 

SELECT department_name
FROM departments d
WHERE NOT EXISTS (SELECT * FROM employees e
        WHERE salary > 10000 AND e.department_id = d.department_id) ORDER BY department_name;  

SELECT AVG(salary) average_salary 
FROM employees GROUP BY department_id;

SELECT ROUND( AVG(average_salary), 0)
FROM  ( SELECT AVG(salary) as average_salary FROM employees   GROUP BY department_id) department_salary;

-- ====================================================================
-- SECTION 2: PRODUCT SALES & VOLUME (CLASSICMODELS SCHEMA)
-- ====================================================================

USE classicmodels;

SELECT productCode, ROUND(SUM(quantityOrdered * priceEach)) AS sales
FROM orderdetails
	INNER JOIN orders USING (orderNumber)
WHERE YEAR(shippedDate) = 2003
GROUP BY productCode
ORDER BY sales DESC
LIMIT 5;

-- Objective: Retrieve top 5 grossing products for 2003 with product descriptions
-- Technique: Derived table / nested subquery with inner join

SELECT productName, sales
FROM  (SELECT productCode, ROUND(SUM(quantityOrdered * priceEach)) AS sales
    FROM orderdetails  INNER JOIN orders USING (orderNumber)
    WHERE YEAR(shippedDate) = 2003
    GROUP BY productCode
    ORDER BY sales DESC
    LIMIT 5) as top5products2003
INNER JOIN products USING (productCode);

-- ====================================================================
-- SECTION 3: REVENUE VELOCITY & LOGISTICS (NORTHWIND SCHEMA)
-- ====================================================================

USE northwind;

SELECT custId, COUNT(orderId) AS order_count
FROM SalesOrder
GROUP BY custId
ORDER BY order_count DESC
LIMIT 5;

SELECT 
    c.custId,
    c.companyName,
    c.contactName,
    COUNT(so.orderId) AS total_orders
FROM 
    Customer c
JOIN 
    SalesOrder so ON c.custId = so.custId
GROUP BY 
    c.custId,
    c.companyName,
    c.contactName
ORDER BY 
    total_orders DESC
LIMIT 5;

-- Objective: Identify top 5 customers by order count
-- Technique: Late-join pattern to optimize aggregation before joining metadata

SELECT 
    c.custId,
    c.companyName,
    top_customers.order_count
FROM (
    SELECT 
        so.custId,
        COUNT(*) AS order_count
    FROM 
        SalesOrder so
    GROUP BY 
        so.custId
    ORDER BY 
        order_count DESC
    LIMIT 5
) AS top_customers
JOIN 
    Customer c ON top_customers.custId = c.custId
ORDER BY 
    top_customers.order_count DESC;



SELECT 
    c.categoryId,
    c.categoryName,
    COUNT(p.productId) AS total_products
FROM 
    Category c
LEFT JOIN 
    Product p ON c.categoryId = p.categoryId
GROUP BY 
    c.categoryId,
    c.categoryName
ORDER BY 
    total_products DESC;

 

SELECT 
    country,
    COUNT(custId) AS customer_count
FROM 
    Customer
GROUP BY 
    country
ORDER BY 
    customer_count DESC,
    country ASC;
    

    
    SELECT 
    s.shipperId,
    s.companyName,
    SUM(so.freight) AS total_freight
FROM 
    Shipper s
JOIN 
    SalesOrder so ON s.shipperId = so.shipperId
GROUP BY 
    s.shipperId,
    s.companyName
ORDER BY 
    total_freight DESC;
    
 
    
    SELECT 
    ROUND(AVG(TIMESTAMPDIFF(YEAR, hireDate, CURDATE())), 2) AS avg_tenure_completed_years,
    ROUND(AVG(DATEDIFF(CURDATE(), hireDate) / 365.25), 2) AS avg_tenure_exact_years
FROM 
    Employee;
   
    SELECT 
    shipCountry AS country,
    ROUND(SUM(freight), 2) AS total_freight,
    COUNT(orderId) AS total_orders,
    ROUND(AVG(freight), 2) AS avg_freight_per_order
FROM 
    SalesOrder
GROUP BY 
    shipCountry
ORDER BY 
    total_freight DESC;
    
-- Objective: Calculate Month-over-Month (MoM) sales velocity and percentage growth (2006-2007)
-- Technique: CTE combined with LAG() window function
    
    WITH MonthlySales AS (
    SELECT 
        DATE_FORMAT(so.orderDate, '%Y-%m') AS order_month,
        ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS total_sales
    FROM 
        SalesOrder so
    JOIN 
        OrderDetail od ON so.orderId = od.orderId
    WHERE 
        so.orderDate >= '2006-01-01' AND so.orderDate < '2008-01-01'
    GROUP BY 
        DATE_FORMAT(so.orderDate, '%Y-%m')
)
SELECT 
    order_month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY order_month) AS previous_month_sales,
    ROUND(
        total_sales - LAG(total_sales) OVER (ORDER BY order_month), 
        2
    ) AS mom_growth_amount,
    ROUND(
        ((total_sales - LAG(total_sales) OVER (ORDER BY order_month)) 
        / LAG(total_sales) OVER (ORDER BY order_month)) * 100, 
        2
    ) AS mom_growth_percentage
FROM 
    MonthlySales
ORDER BY 
    order_month;