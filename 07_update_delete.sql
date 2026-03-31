-- 07_update_delete.sql
-- DML: Updating and deleting rows safely

-- Give all Engineering employees a 10% raise
UPDATE employees
SET salary = salary * 1.10
WHERE department_id = (
    SELECT department_id
    FROM departments
    WHERE department_name = 'Engineering'
);

-- Update a single employee's department
UPDATE employees
SET department_id = 2
WHERE employee_id = 9;

-- Update multiple columns at once
UPDATE employees
SET
    email     = 'a.smith@example.com',
    last_name = 'Smith-Johnson'
WHERE employee_id = 1;

-- Delete employees hired before 2018 who are not assigned to any project
DELETE FROM employees
WHERE hire_date < '2018-01-01'
  AND employee_id NOT IN (
      SELECT DISTINCT employee_id
      FROM employee_projects
  );

-- Remove all assignments for a specific project before deleting the project
DELETE FROM employee_projects
WHERE project_id = 4;

DELETE FROM projects
WHERE project_id = 4;

-- Rollback-safe pattern (wrap in a transaction)
BEGIN;

UPDATE employees
SET salary = salary + 5000
WHERE department_id = 3;

-- Verify before committing
SELECT employee_id, first_name, last_name, salary
FROM employees
WHERE department_id = 3;

-- COMMIT to save, or ROLLBACK to undo
COMMIT;
-- ROLLBACK;
