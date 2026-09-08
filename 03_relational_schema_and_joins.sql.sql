/*
====================================================================
Title: Relational Database Architecture & Multi-Table Joins
Author: Sean Rivas
Tools: MySQL Workbench
Description: Focuses on relational database design, mapping primary-to-foreign 
             key relationships, self-referencing employee hierarchies, 
             and multi-tier inner/left joins.
Key Techniques: Inner Joins, Left Joins, Recursive Self-Joins, 
               Pattern Matching (RLIKE), Unique Value Distinct Filtering
====================================================================
*/

USE banking;

-- ====================================================================
-- SECTION 1: PRODUCT CATALOG & CATEGORY MAPPING
-- ====================================================================

-- Objective: Join product catalogs to their high-level product types to audit inventory categorizations
SELECT 
    p.NAME AS product_name, 
    pt.NAME AS product_type
FROM product AS p 
INNER JOIN product_type AS pt
    ON p.product_type_cd = pt.product_type_cd;

-- ====================================================================
-- SECTION 2: BRANCH OPERATIONS & EMPLOYEE ASSIGNMENTS
-- ====================================================================

-- Objective: Map employees to their assigned operational bank branches to review staffing distributions
SELECT 
    b.NAME AS branch_name, 
    b.CITY AS city, 
    e.LAST_NAME AS last_name, 
    e.TITLE AS title 
FROM branch AS b 
INNER JOIN employee AS e 
    ON b.BRANCH_ID = e.ASSIGNED_BRANCH_ID;

-- Objective: Audit distinct employee job titles across the organization to understand structural roles
SELECT DISTINCT 
    TITLE AS job_title 
FROM employee;

-- ====================================================================
-- SECTION 3: ORGANIZATIONAL HIERARCHIES (SELF-JOINS)
-- ====================================================================

-- Objective: Model reporting structures by linking employees to their respective managers/supervisors
SELECT 
    e.LAST_NAME AS employee_last_name, 
    e.TITLE AS employee_title, 
    m.LAST_NAME AS manager_last_name, 
    m.TITLE AS manager_title
FROM employee AS e 
LEFT JOIN employee AS m
    ON e.SUPERIOR_EMP_ID = m.EMP_ID;

-- ====================================================================
-- SECTION 4: MULTI-TABLE COMPLEX JOINS & ACCOUNT AUDITING
-- ====================================================================

-- Objective: Trace account balances back to specific financial products and individual account holders
SELECT 
    p.NAME AS product_name, 
    a.AVAIL_BALANCE AS available_balance, 
    i.LAST_NAME AS customer_last_name 
FROM account AS a
INNER JOIN product AS p 
    ON a.PRODUCT_CD = p.PRODUCT_CD
LEFT JOIN customer AS c 
    ON a.CUST_ID = c.CUST_ID
LEFT JOIN individual AS i 
    ON c.CUST_ID = i.CUST_ID;

-- Objective: Filter transaction audit logs for specific account holders using regular expression pattern matching (LastName starting with 'T')
SELECT 
    ac.TXN_ID AS transaction_id,
    ac.AMOUNT AS transaction_amount,
    ac.TXN_DATE AS transaction_date,
    i.LAST_NAME AS customer_last_name 
FROM acc_transaction AS ac
INNER JOIN account AS a 
    ON ac.ACCOUNT_ID = a.ACCOUNT_ID
INNER JOIN customer AS c 
    ON a.CUST_ID = c.CUST_ID
INNER JOIN individual AS i 
    ON c.CUST_ID = i.CUST_ID
WHERE i.LAST_NAME RLIKE '^T';