-- 03_select_queries.sql
-- Basic SELECT statements, filtering, sorting, and limiting results

-- All employees
SELECT * FROM employees;

-- Specific columns
SELECT first_name, last_name, salary
FROM employees;

-- Filter with WHERE
SELECT first_name, last_name, salary
FROM employees
WHERE salary > 80000;

-- Multiple conditions (AND / OR)
SELECT first_name, last_name, salary, department_id
FROM employees
WHERE salary > 70000
  AND department_id = 1;

-- Pattern matching with LIKE
SELECT first_name, last_name, email
FROM employees
WHERE email LIKE '%@example.com';

-- NULL check
SELECT first_name, last_name
FROM employees
WHERE department_id IS NOT NULL;

-- Sorting results
SELECT first_name, last_name, salary
FROM employees
ORDER BY salary DESC;

-- Limit rows returned
SELECT first_name, last_name, salary
FROM employees
ORDER BY salary DESC
LIMIT 3;

-- Column aliases
SELECT
    first_name || ' ' || last_name AS full_name,
    salary                         AS annual_salary
FROM employees
ORDER BY annual_salary DESC;

-- DISTINCT values
SELECT DISTINCT department_id
FROM employees
ORDER BY department_id;

-- IN operator
SELECT first_name, last_name, department_id
FROM employees
WHERE department_id IN (1, 3);

-- BETWEEN operator
SELECT first_name, last_name, hire_date
FROM employees
WHERE hire_date BETWEEN '2019-01-01' AND '2021-12-31';
