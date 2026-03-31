-- 08_indexes_views.sql
-- Performance: indexes; and reusable query logic: views

-- Index on a frequently filtered column
CREATE INDEX idx_employees_department
    ON employees (department_id);

-- Composite index for lookups by department and salary
CREATE INDEX idx_employees_dept_salary
    ON employees (department_id, salary DESC);

-- Index on the foreign-key column of employee_projects
CREATE INDEX idx_ep_project
    ON employee_projects (project_id);

-- -------------------------------------------------------
-- Views
-- -------------------------------------------------------

-- View: employee details with department name
CREATE VIEW vw_employee_details AS
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    e.email,
    e.hire_date,
    e.salary,
    d.department_name,
    d.location
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- Query the view like a table
SELECT * FROM vw_employee_details ORDER BY department_name, last_name;

-- View: project summary with headcount and total salary commitment
CREATE VIEW vw_project_summary AS
SELECT
    p.project_id,
    p.project_name,
    p.budget,
    COUNT(ep.employee_id)    AS num_employees,
    SUM(e.salary)            AS total_salary_commitment
FROM projects p
LEFT JOIN employee_projects ep ON p.project_id  = ep.project_id
LEFT JOIN employees         e  ON ep.employee_id = e.employee_id
GROUP BY p.project_id, p.project_name, p.budget;

-- Query the view
SELECT * FROM vw_project_summary ORDER BY num_employees DESC;

-- Drop a view when it is no longer needed
-- DROP VIEW vw_project_summary;
-- DROP VIEW vw_employee_details;
