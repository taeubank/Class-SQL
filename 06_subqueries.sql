-- 06_subqueries.sql
-- Subqueries: scalar, correlated, and derived tables

-- Scalar subquery: employees earning above the overall average salary
SELECT first_name, last_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;

-- Subquery with IN: employees assigned to at least one project
SELECT first_name, last_name
FROM employees
WHERE employee_id IN (
    SELECT DISTINCT employee_id
    FROM employee_projects
)
ORDER BY last_name;

-- Subquery with NOT IN: employees with no project assignments
SELECT first_name, last_name
FROM employees
WHERE employee_id NOT IN (
    SELECT DISTINCT employee_id
    FROM employee_projects
)
ORDER BY last_name;

-- Correlated subquery: employees whose salary is above their department average
SELECT
    e.first_name,
    e.last_name,
    e.salary,
    e.department_id
FROM employees e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.department_id = e.department_id
)
ORDER BY e.department_id, e.salary DESC;

-- Derived table (inline view): top earner per department
SELECT
    d.department_name,
    top.first_name,
    top.last_name,
    top.salary
FROM departments d
JOIN (
    SELECT
        department_id,
        first_name,
        last_name,
        salary,
        RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS rnk
    FROM employees
) top ON top.department_id = d.department_id
      AND top.rnk = 1
ORDER BY d.department_name;

-- EXISTS: departments that have at least one employee
SELECT department_name
FROM departments d
WHERE EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department_id = d.department_id
);
