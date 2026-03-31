-- 05_aggregations.sql
-- Aggregate functions: COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING

-- Count all employees
SELECT COUNT(*) AS total_employees
FROM employees;

-- Total salary budget
SELECT SUM(salary) AS total_salary_budget
FROM employees;

-- Average, min, and max salary
SELECT
    AVG(salary) AS avg_salary,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary
FROM employees;

-- Headcount and average salary per department
SELECT
    d.department_name,
    COUNT(e.employee_id) AS headcount,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY avg_salary DESC;

-- HAVING: only departments with average salary above 80,000
SELECT
    d.department_name,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM departments d
JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_name
HAVING AVG(e.salary) > 80000
ORDER BY avg_salary DESC;

-- Number of employees assigned to each project
SELECT
    p.project_name,
    COUNT(ep.employee_id) AS num_employees
FROM projects p
LEFT JOIN employee_projects ep ON p.project_id = ep.project_id
GROUP BY p.project_name
ORDER BY num_employees DESC;

-- Salary quartiles using NTILE window function
SELECT
    first_name,
    last_name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS salary_quartile
FROM employees
ORDER BY salary DESC;

-- Running total of salaries ordered by hire date
SELECT
    first_name,
    last_name,
    hire_date,
    salary,
    SUM(salary) OVER (ORDER BY hire_date) AS running_total
FROM employees
ORDER BY hire_date;
