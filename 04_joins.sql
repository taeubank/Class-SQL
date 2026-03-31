-- 04_joins.sql
-- Joining tables: INNER, LEFT, RIGHT, FULL OUTER, and CROSS joins

-- INNER JOIN: employees with their department name
SELECT
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;

-- LEFT JOIN: all employees, including those without a department
SELECT
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- RIGHT JOIN: all departments, including those with no employees
SELECT
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.department_id;

-- FULL OUTER JOIN: all employees and all departments
SELECT
    e.first_name,
    e.last_name,
    d.department_name
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.department_id;

-- Multi-table JOIN: employees, their department, and their projects
SELECT
    e.first_name,
    e.last_name,
    d.department_name,
    p.project_name,
    ep.role
FROM employees e
JOIN departments      d  ON e.department_id = d.department_id
JOIN employee_projects ep ON e.employee_id = ep.employee_id
JOIN projects          p  ON ep.project_id = p.project_id
ORDER BY e.last_name, p.project_name;

-- Self JOIN: find employees hired in the same year
SELECT
    a.first_name || ' ' || a.last_name AS employee_1,
    b.first_name || ' ' || b.last_name AS employee_2,
    EXTRACT(YEAR FROM a.hire_date)     AS hire_year
FROM employees a
JOIN employees b ON EXTRACT(YEAR FROM a.hire_date) = EXTRACT(YEAR FROM b.hire_date)
               AND a.employee_id < b.employee_id
ORDER BY hire_year;
