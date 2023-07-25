DROP TABLE IF EXISTS customer_sales;
CREATE TEMP TABLE customer_sales AS
WITH input_data (customer_id, sales) AS (
 VALUES
 ('A', 300),
 ('A', 150),
 ('B', 100),
 ('B', 200)
)
SELECT * FROM input_data;

-- Group By Sum
-- Note that the ORDER BY is only for output sorting purposes!

SELECT * FROM customer_sales;

SELECT
  customer_id,
  SUM(sales) AS sum_sales
FROM customer_sales
GROUP BY customer_id
ORDER BY customer_id;

-- Sum Window Function
SELECT
  customer_id,
  sales,
  SUM(sales) OVER (
    PARTITION BY customer_id
  ) AS sum_sales
FROM customer_sales;

--Multi-level 

-- we remove that existing customer_sales table first!
DROP TABLE IF EXISTS customer_sales;
CREATE TEMP TABLE customer_sales AS
WITH input_data (customer_id, sale_id, sales) AS (
 VALUES
 ('A', 1, 300),
 ('A', 1, 150),
 ('A', 2, 100),
 ('B', 3, 200)
)
SELECT * FROM input_data;

-- Sum Window Function with 2 columns in PARTITION BY
SELECT
  customer_id,
  sales,
  SUM(sales) OVER (
    PARTITION BY
      customer_id,
      sale_id
  ) AS sum_sales
FROM customer_sales;


SELECT
  customer_id,
  sale_id,
  sales,
  SUM(sales) OVER (
    PARTITION BY
      customer_id,
      sale_id
  ) AS sum_sales,
  SUM(SALES) OVER (
    PARTITION BY customer_id
  ) AS customer_sales,
  SUM(SALES) OVER () AS total_sales
FROM customer_sales;


--Ordered Window Functions

-- we remove any existing customer_sales table first!
DROP TABLE IF EXISTS customer_sales;
CREATE TEMP TABLE customer_sales AS
WITH input_data (customer_id, sales_date, sales) AS (
 VALUES
 ('A', '2021-01-01'::DATE, 300),
 ('A', '2021-01-02'::DATE, 150),
 ('B', '2021-01-03'::DATE, 100),
 ('B', '2021-01-02'::DATE, 200)
)
SELECT * FROM input_data;

-- RANK Window Function with default ORDER BY
SELECT
  customer_id,
  sales_date,
  sales,
  RANK() OVER (
    PARTITION BY customer_id
    ORDER BY sales_date
  ) AS sales_date_rank
FROM customer_sales;

-- RANK Window Function with descending ORDER BY
SELECT
  customer_id,
  sales_date,
  sales,
  RANK() OVER (
    PARTITION BY customer_id
    ORDER BY sales_date DESC
  ) AS sales_date_rank
FROM customer_sales;

-- RANK Window Function with descending ORDER BY and empty PARTITION BY
SELECT
  customer_id,
  sales_date,
  sales,
  RANK() OVER (
    ORDER BY sales_date DESC
  ) AS sales_date_rank
FROM customer_sales;

-- Other RANK functions 

SELECT
  measure,
  measure_value
FROM health.user_logs
WHERE measure = 'weight'
LIMIT 10;


SELECT 
	measure_value, 
	RANK() OVER ( ORDER BY measure_value ) AS _rank, 
	DENSE_RANK() OVER ( ORDER BY measure_value ) AS _dense_rank, 
	ROW_NUMBER() OVER ( ORDER BY measure_value ) AS _row_rumber
FROM health.user_logs
WHERE measure = 'weight'
;
	 
--All in one

DROP TABLE IF EXISTS ordered_window_metrics;
CREATE TEMP TABLE ordered_window_metrics AS
SELECT
  measure_value,
  ROW_NUMBER() OVER (ORDER BY measure_value DESC) AS _row_number,
  RANK() OVER (ORDER BY measure_value DESC) AS _rank,
  DENSE_RANK() OVER (ORDER BY measure_value DESC) AS _dense_rank,
  /* ---
  To succesfully round the following metrics to 5 decimal places
  we need to explicitly cast the window function output
  from a double data type to numeric type
  --- */
  ROUND(
    (PERCENT_RANK() OVER (ORDER BY measure_value DESC))::NUMERIC,
    5
  ) AS _percent_rank,
  ROUND(
    (CUME_DIST() OVER (ORDER BY measure_value DESC))::NUMERIC,
    5
  ) AS _cume_dist,
  NTILE(100) OVER (ORDER BY measure_value DESC) AS _ntile
FROM health.user_logs
WHERE measure = 'weight';

SELECT *
FROM ordered_window_metrics
ORDER BY measure_value DESC
LIMIT 10;


DROP TABLE IF EXISTS ordered_window_metrics_desc;
CREATE TEMP TABLE ordered_window_metrics_desc AS
SELECT
  measure,
  measure_value,
  ROW_NUMBER() OVER (
    PARTITION BY measure
    ORDER BY measure_value DESC
  ) AS _row_number,
  RANK() OVER (
    PARTITION BY measure
    ORDER BY measure_value DESC
  ) AS _rank,
  DENSE_RANK() OVER (
    PARTITION BY measure
    ORDER BY measure_value DESC
  ) AS _dense_rank,
  /* ---
  To succesfully round the following metrics to 5 decimal places
  we need to explicitly cast the window function output
  from a double data type to numeric type
  --- */
  ROUND(
    (
      PERCENT_RANK() OVER (
        PARTITION BY measure
        ORDER BY measure_value DESC
      )
    )::NUMERIC,
    5
  ) AS _percent_rank,
  ROUND(
    (
      CUME_DIST() OVER (
        PARTITION BY measure
        ORDER BY measure_value DESC
      )
    )::NUMERIC,
    5
  ) AS _cume_dist,
  NTILE(100) OVER (
    PARTITION BY measure
    ORDER BY measure_value DESC
  ) AS _ntile
FROM health.user_logs;

--Combined Ascending & Descending 
--Top 3 or bottom 3 

DROP TABLE IF EXISTS combined_row_numbers;
CREATE TEMP TABLE combined_row_numbers AS
SELECT
  measure,
  measure_value,
  ROW_NUMBER() OVER (
    PARTITION BY measure
    ORDER BY measure_value
  ) AS ascending,
  ROW_NUMBER() OVER (
    PARTITION BY measure
    ORDER BY measure_value DESC
  ) AS descending
FROM health.user_logs;

SELECT *,
  CASE
    WHEN ascending <= 3 THEN 'Bottom 3'
    WHEN descending <= 3 THEN 'Top 3'
    END AS value_ranking
FROM combined_row_numbers
WHERE
  ascending <= 3 OR
  descending <= 3
ORDER BY
  measure,
  measure_value;
