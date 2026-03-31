-- 02_insert_data.sql
-- DML: Populate tables with sample data

INSERT INTO departments (department_id, department_name, location) VALUES
    (1, 'Engineering',  'New York'),
    (2, 'Marketing',    'San Francisco'),
    (3, 'Finance',      'Chicago'),
    (4, 'Human Resources', 'New York');

INSERT INTO employees (employee_id, first_name, last_name, email, hire_date, salary, department_id) VALUES
    (1,  'Alice',   'Smith',   'alice.smith@example.com',   '2019-03-15', 95000.00, 1),
    (2,  'Bob',     'Jones',   'bob.jones@example.com',     '2020-07-01', 72000.00, 2),
    (3,  'Carol',   'White',   'carol.white@example.com',   '2018-11-20', 88000.00, 1),
    (4,  'David',   'Brown',   'david.brown@example.com',   '2021-01-10', 65000.00, 3),
    (5,  'Eva',     'Davis',   'eva.davis@example.com',     '2017-05-05', 110000.00, 1),
    (6,  'Frank',   'Miller',  'frank.miller@example.com',  '2022-09-30', 58000.00, 4),
    (7,  'Grace',   'Wilson',  'grace.wilson@example.com',  '2020-03-22', 77000.00, 2),
    (8,  'Henry',   'Moore',   'henry.moore@example.com',   '2019-08-14', 82000.00, 3),
    (9,  'Irene',   'Taylor',  'irene.taylor@example.com',  '2023-02-01', 61000.00, 4),
    (10, 'James',   'Anderson','james.anderson@example.com','2016-06-17', 105000.00, 1);

INSERT INTO projects (project_id, project_name, start_date, end_date, budget) VALUES
    (1, 'Website Redesign',  '2023-01-01', '2023-06-30', 150000.00),
    (2, 'Data Migration',    '2023-03-01', '2023-12-31', 200000.00),
    (3, 'Mobile App',        '2023-05-01', NULL,         350000.00),
    (4, 'Annual Campaign',   '2023-04-01', '2023-09-30',  80000.00);

INSERT INTO employee_projects (employee_id, project_id, role) VALUES
    (1, 1, 'Lead Developer'),
    (1, 2, 'Developer'),
    (3, 1, 'Developer'),
    (3, 3, 'Lead Developer'),
    (5, 2, 'Architect'),
    (5, 3, 'Architect'),
    (2, 4, 'Campaign Manager'),
    (7, 4, 'Designer'),
    (10, 3, 'Developer');
