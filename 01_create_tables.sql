-- 01_create_tables.sql
-- DDL: Create the schema used throughout this repository

CREATE TABLE departments (
    department_id   INT          PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    location        VARCHAR(100)
);

CREATE TABLE employees (
    employee_id     INT          PRIMARY KEY,
    first_name      VARCHAR(50)  NOT NULL,
    last_name       VARCHAR(50)  NOT NULL,
    email           VARCHAR(100) UNIQUE NOT NULL,
    hire_date       DATE         NOT NULL,
    salary          DECIMAL(10, 2),
    department_id   INT,
    CONSTRAINT fk_emp_dept FOREIGN KEY (department_id)
        REFERENCES departments (department_id)
);

CREATE TABLE projects (
    project_id      INT          PRIMARY KEY,
    project_name    VARCHAR(100) NOT NULL,
    start_date      DATE,
    end_date        DATE,
    budget          DECIMAL(15, 2)
);

CREATE TABLE employee_projects (
    employee_id     INT NOT NULL,
    project_id      INT NOT NULL,
    role            VARCHAR(50),
    PRIMARY KEY (employee_id, project_id),
    CONSTRAINT fk_ep_emp  FOREIGN KEY (employee_id) REFERENCES employees (employee_id),
    CONSTRAINT fk_ep_proj FOREIGN KEY (project_id)  REFERENCES projects  (project_id)
);
