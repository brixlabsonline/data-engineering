--=========Creating reusable data asset 

-- employee
DROP TABLE IF EXISTS temp_employee;
CREATE TABLE temp_employee AS
SELECT * FROM employees.employee;

-- temp department employee
DROP TABLE IF EXISTS temp_department;
CREATE TEMP TABLE temp_department AS
SELECT * FROM employees.department;

-- temp department employee
DROP TABLE IF EXISTS temp_department_employee;
CREATE TEMP TABLE temp_department_employee AS
SELECT * FROM employees.department_employee;

-- department manager
DROP TABLE IF EXISTS temp_department_manager;
CREATE TEMP TABLE temp_department_manager AS
SELECT * FROM employees.department_manager;

-- salary
DROP TABLE IF EXISTS temp_salary;
CREATE TEMP TABLE temp_salary AS
SELECT * FROM employees.salary;

-- title
DROP TABLE IF EXISTS temp_title;
CREATE TEMP TABLE temp_title AS
SELECT * FROM employees.title;


---------------------------------------------------
----TEMP TABLE method------------------------------
---------------------------------------------------

-- update temp_employee
UPDATE temp_employee
SET hire_date = hire_date + INTERVAL '18 YEARS';

UPDATE temp_employee
SET birth_date = birth_date + INTERVAL '18 YEARS';

-- update temp_department_employee
-- ??? Why don't we need to check the date = '9999-01-01' for this column
UPDATE temp_department_employee SET
from_date = from_date + INTERVAL '18 YEARS';

UPDATE temp_department_employee
SET to_date = to_date + INTERVAL '18 YEARS'
WHERE to_date <> '9999-01-01';

-- update temp_department_manager
UPDATE temp_department_manager
SET from_date = from_date + INTERVAL '18 YEARS';

UPDATE temp_department_manager
SET to_date = to_date + INTERVAL '18 YEARS'
WHERE to_date <> '9999-01-01';

-- update temp_salary
UPDATE temp_salary
SET from_date = from_date + INTERVAL '18 YEARS';

UPDATE temp_salary
SET to_date = to_date + INTERVAL '18 YEARS'
WHERE to_date <> '9999-01-01';

-- update temp_title
UPDATE temp_title
SET from_date = from_date + INTERVAL '18 YEARS';

UPDATE temp_title
SET to_date = to_date + INTERVAL '18 YEARS'
WHERE to_date <> '9999-01-01';


-------------------------------------------------------
-------------NEW SCHEMA method-------------------------
-------------------------------------------------------

DROP SCHEMA IF EXISTS adjusted_employees CASCADE;
CREATE SCHEMA adjusted_employees;

-- employee
DROP TABLE IF EXISTS adjusted_employees.employee;
CREATE TABLE adjusted_employees.employee AS
SELECT * FROM employees.employee;

-- department employee
DROP TABLE IF EXISTS adjusted_employees.department;
CREATE TABLE adjusted_employees.department AS
SELECT * FROM employees.department;

-- department employee
DROP TABLE IF EXISTS adjusted_employees.department_employee;
CREATE TABLE adjusted_employees.department_employee AS
SELECT * FROM employees.department_employee;

-- department manager
DROP TABLE IF EXISTS adjusted_employees.department_manager;
CREATE TABLE adjusted_employees.department_manager AS
SELECT * FROM employees.department_manager;

-- salary
DROP TABLE IF EXISTS adjusted_employees.salary;
CREATE TABLE adjusted_employees.salary AS
SELECT * FROM employees.salary;

-- title
DROP TABLE IF EXISTS adjusted_employees.title;
CREATE TABLE adjusted_employees.title AS
SELECT * FROM employees.title;

-- update employee
UPDATE adjusted_employees.employee
SET hire_date = hire_date + INTERVAL '18 YEARS';

UPDATE adjusted_employees.employee
SET birth_date = birth_date + INTERVAL '18 YEARS';

-- update adjusted_employees.department_employee
UPDATE adjusted_employees.department_employee SET
from_date = from_date + INTERVAL '18 YEARS';

UPDATE adjusted_employees.department_employee
SET to_date = to_date + INTERVAL '18 YEARS'
WHERE to_date <> '9999-01-01';

-- update department_manager
UPDATE adjusted_employees.department_manager
SET from_date = from_date + INTERVAL '18 YEARS';

UPDATE adjusted_employees.department_manager
SET to_date = to_date + INTERVAL '18 YEARS'
WHERE to_date <> '9999-01-01';

-- update salary
UPDATE adjusted_employees.salary
SET from_date = from_date + INTERVAL '18 YEARS';

UPDATE adjusted_employees.salary
SET to_date = to_date + INTERVAL '18 YEARS'
WHERE to_date <> '9999-01-01';

-- update title
UPDATE adjusted_employees.title
SET from_date = from_date + INTERVAL '18 YEARS';

UPDATE adjusted_employees.title
SET to_date = to_date + INTERVAL '18 YEARS'
WHERE to_date <> '9999-01-01';


----------------------------------------------------
-----------VIEWS method-----------------------------
----------------------------------------------------

DROP SCHEMA IF EXISTS v_employees CASCADE;
CREATE SCHEMA v_employees;

-- department
DROP VIEW IF EXISTS v_employee.department;
CREATE VIEW v_employees.department AS
SELECT * FROM employees.department;

-- department employee
DROP VIEW IF EXISTS v_employees.department_employee;
CREATE VIEW v_employees.department_employee AS
SELECT
  employee_id,
  department_id,
  from_date + interval '18 years' AS from_date,
  CASE
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date
    END AS to_date
FROM employees.department_employee;

-- department manager
DROP VIEW IF EXISTS v_employees.department_manager;
CREATE VIEW v_employees.department_manager AS
SELECT
  employee_id,
  department_id,
  from_date + interval '18 years' AS from_date,
  CASE
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date
    END AS to_date
FROM employees.department_manager;

-- employee
DROP VIEW IF EXISTS v_employees.employee;
CREATE VIEW v_employees.employee AS
SELECT
  id,
  birth_date + interval '18 years' AS birth_date,
  first_name,
  last_name,
  gender,
  hire_date + interval '18 years' AS hire_date
FROM employees.employee;

-- salary
DROP VIEW IF EXISTS v_employees.salary;
CREATE VIEW v_employees.salary AS
SELECT
  employee_id,
  amount,
  from_date + interval '18 years' AS from_date,
  CASE
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date
    END AS to_date
FROM employees.salary;

-- title
DROP VIEW IF EXISTS v_employees.title;
CREATE VIEW v_employees.title AS
SELECT
  employee_id,
  title,
  from_date + interval '18 years' AS from_date,
  CASE
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date
    END AS to_date
FROM employees.title;


----------------------------------------------------
-----------Materialized VIEWS method----------------
----------------------------------------------------

DROP SCHEMA IF EXISTS mv_employees CASCADE;
CREATE SCHEMA mv_employees;

-- department
DROP MATERIALIZED VIEW IF EXISTS v_employee.department;
CREATE MATERIALIZED VIEW mv_employees.department AS
SELECT * FROM employees.department;

-- department employee
DROP MATERIALIZED VIEW IF EXISTS mv_employees.department_employee;
CREATE MATERIALIZED VIEW mv_employees.department_employee AS
SELECT
  employee_id,
  department_id,
  from_date + interval '18 years' AS from_date,
  CASE
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date
    END AS to_date
FROM employees.department_employee;

-- department manager
DROP MATERIALIZED VIEW IF EXISTS mv_employees.department_manager;
CREATE MATERIALIZED VIEW mv_employees.department_manager AS
SELECT
  employee_id,
  department_id,
  from_date + interval '18 years' AS from_date,
  CASE
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date
    END AS to_date
FROM employees.department_manager;

-- employee
DROP MATERIALIZED VIEW IF EXISTS mv_employees.employee;
CREATE MATERIALIZED VIEW mv_employees.employee AS
SELECT
  id,
  birth_date + interval '18 years' AS birth_date,
  first_name,
  last_name,
  gender,
  hire_date + interval '18 years' AS hire_date
FROM employees.employee;

-- salary
DROP MATERIALIZED VIEW IF EXISTS mv_employees.salary;
CREATE MATERIALIZED VIEW mv_employees.salary AS
SELECT
  employee_id,
  amount,
  from_date + interval '18 years' AS from_date,
  CASE
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date
    END AS to_date
FROM employees.salary;

-- title
DROP MATERIALIZED VIEW IF EXISTS mv_employees.title;
CREATE MATERIALIZED VIEW mv_employees.title AS
SELECT
  employee_id,
  title,
  from_date + interval '18 years' AS from_date,
  CASE
    WHEN to_date <> '9999-01-01' THEN to_date + interval '18 years'
    ELSE to_date
    END AS to_date
FROM employees.title;
