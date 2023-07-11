select 
measure, 
COUNT(*) as counts
from HEALTH.USER_LOGS 
group by MEASURE 
order by COUNTS desc; 

select 
measure, 
ROUND(AVG(MEASURE_VALUE), 2) as average, 
COUNT(*) as counts
from HEALTH.USER_LOGS 
group by MEASURE 
order by COUNTS desc; 


WITH sample_data (example_values) AS (
 VALUES
 (82), (51), (144), (84), (120), (148), (148), (108), (160), (86)
)
SELECT 
 AVG(example_values) AS mean_value,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY example_values) AS median_value,
  MODE() WITHIN GROUP (ORDER BY example_values) as mode_value
from sample_data;

Select 
--	avg(MEASURE_VALUE) as mean_value, 
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY MEASURE_VALUE) as median_value
--	MODE() WITHIN GROUP (ORDER BY MEASURE_VALUE) as mode_value
from HEALTH.USER_LOGS 
where MEASURE = 'weight'; 

-- Spread (Variance & Standard deviation)

WITH min_max_values AS (
  SELECT
    MIN(measure_value) AS minimum_value,
    MAX(measure_value) AS maximum_value
  FROM health.user_logs
  WHERE measure = 'weight'
)
SELECT
  minimum_value,
  maximum_value,
  maximum_value - minimum_value AS range_value
FROM min_max_values;

WITH sample_data (example_values) AS (
 VALUES
 (82), (51), (144), (84), (120), (148), (148), (108), (160), (86)
)
SELECT
  ROUND(VARIANCE(example_values), 2) AS variance_value,
  ROUND(STDDEV(example_values), 2) AS standard_dev_value,
  ROUND(AVG(example_values), 2) AS mean_value,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY example_values) AS median_value,
  MODE() WITHIN GROUP (ORDER BY example_values) AS mode_value
FROM sample_data;

--variance_value - 1340.99
--standard_dev_value - 36.62
--Mean value - 113.10
--median_value - 114
--mode_value - 148

--What is the average, median and mode values of blood glucose values to 2 decimal places?

select * from HEALTH.USER_LOGS limit 10;
select 
	ROUND(avg(measure_value), 2) as mean_value, 
	ROUND(CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (order by measure_value) AS NUMERIC), 2) as median_value, 
	ROUND(MOD() WITHIN GROUP (order by MEASURE_VALUE) 2) a mode_value
from HEALTH.USER_LOGS 
where MEASURE = 'blood_glucose'; 

--What is the most frequently occuring measure_value value for all blood glucose measurements?
select 
ROUND(MOD() within group (order by measure_value), 2) as most_freequent_value
from HEALTH.USER_LOGS 
where MEASURE = 'blood_glucose';


--compare with 

SELECT
  measure_value,
  COUNT(*) AS frequency
FROM health.user_logs
WHERE measure = 'blood_glucose'
GROUP BY 1
ORDER BY 2 DESC
-- it's always best practice to not just look at the top value
-- we can better sense check our outputs this way!
LIMIT 10;


--Calculate the 2 Pearson Coefficient of Skewness for blood glucose measures given the following formulas:
--Coefficient1:ModeSkewness= (Mean−Mode ) / StandardDeviation
--Coefficient2:MedianSkewness= 3∗ (Mean−Median) / StandardDeviation

WITH cte_blood_glucose_stats AS (
  SELECT
    AVG(measure_value) AS mean_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY measure_value) AS median_value,
    MODE() WITHIN GROUP (ORDER BY measure_value) AS mode_value,
    STDDEV(measure_value) AS stddev_value
  FROM health.user_logs
  WHERE measure = 'blood_glucose'
)
SELECT
  ( mean_value - mode_value ) / stddev_value AS pearson_corr_1,
  3 * ( mean_value - median_value ) / stddev_value AS pearson_corr_2
FROM cte_blood_glucose_stats;

--Cumulative Distribution Functions
--This function takes a value and retuns us the percentile (the probability) of any value between the minimum value of our dataset X and the value V

SELECT
  measure_value,
  NTILE(100) OVER (
    ORDER BY
      measure_value
  ) AS percentile
FROM health.user_logs
WHERE measure = 'weight'

--Bucket Calculations

WITH percentile_values AS (
  SELECT
    measure_value,
    NTILE(100) OVER (
      ORDER BY
        measure_value
    ) AS percentile
  FROM health.user_logs
  WHERE measure = 'weight'
)
SELECT
  percentile,
  MIN(measure_value) AS floor_value,
  MAX(measure_value) AS ceiling_value,
  COUNT(*) AS percentile_counts
FROM percentile_values
GROUP BY percentile
ORDER BY percentile;

--Looking first and last row, 28 values lie between 0 and 29KG   and 27 Values lie between 136.53KG and 39,642,120KG 

--Large outliers (Percentaile = 100)

WITH percentile_values AS (
  SELECT
    measure_value,
    NTILE(100) OVER (
      ORDER BY
        measure_value
    ) AS percentile
  FROM health.user_logs
  WHERE measure = 'weight'
)
SELECT
  measure_value,
  -- these are examples of window functions below
  ROW_NUMBER() OVER (ORDER BY measure_value DESC) as row_number_order,
  RANK() OVER (ORDER BY measure_value DESC) as rank_order,
  DENSE_RANK() OVER (ORDER BY measure_value DESC) as dense_rank_order
FROM percentile_values
WHERE percentile = 100
ORDER BY measure_value DESC;

--Small outlier (percentile = 1)

WITH percentile_values AS (
  SELECT
    measure_value,
    NTILE(100) OVER (
      ORDER BY
        measure_value
    ) AS percentile
  FROM health.user_logs
  WHERE measure = 'weight'
)
SELECT
  measure_value,
  ROW_NUMBER() OVER (ORDER BY measure_value) as row_number_order,
  RANK() OVER (ORDER BY measure_value) as rank_order,
  DENSE_RANK() OVER (ORDER BY measure_value) as dense_rank_order
FROM percentile_values
WHERE percentile = 1
ORDER BY measure_value;

--Remove Outliers

DROP TABLE IF EXISTS clean_weight_logs;
CREATE TEMP TABLE clean_weight_logs AS (
  SELECT *
  FROM health.user_logs
  WHERE measure = 'weight'
    AND measure_value > 0
    AND measure_value < 201
);

--Calculate summary statistics on this new temp table with clean data

SELECT
  ROUND(MIN(measure_value), 2) AS minimum_value,
  ROUND(MAX(measure_value), 2) AS maximum_value,
  ROUND(AVG(measure_value), 2) AS mean_value,
  ROUND(
    -- this function actually returns a float which is incompatible with ROUND!
    -- we use this cast function to convert the output type to NUMERIC
    CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY measure_value) AS NUMERIC),
    2
  ) AS median_value,
  ROUND(
    MODE() WITHIN GROUP (ORDER BY measure_value),
    2
  ) AS mode_value,
  ROUND(STDDEV(measure_value), 2) AS standard_deviation,
  ROUND(VARIANCE(measure_value), 2) AS variance_value
FROM clean_weight_logs;

--1.81	200.49	80.76	75.98	68.49	26.91	724.29
--comared to origninal
--0.00	39642120.00	28786.85	75.98	68.49	1062759.55	1129457862383.41


--New cumulative distribution function with treated data 

WITH percentile_values AS (
  SELECT
    measure_value,
    NTILE(100) OVER (
      ORDER BY
        measure_value
    ) AS percentile
  FROM clean_weight_logs
)
SELECT
  percentile,
  MIN(measure_value) AS floor_value,
  MAX(measure_value) AS ceiling_value,
  COUNT(*) AS percentile_counts
FROM percentile_values
GROUP BY percentile
ORDER BY percentile;