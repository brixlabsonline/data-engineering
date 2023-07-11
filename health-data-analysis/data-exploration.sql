--Identifying Duplicate Records
--Health Data

select * from HEALTH.USER_LOGS limit 10; 

select 
LOG_DATE,
COUNT(*)	
from HEALTH.USER_LOGS 
group by LOG_DATE 
order by LOG_DATE DESC; 

with cte as SELECT 
	id,
	COUNT(id) as rec_count
FROM HEALTH.USER_LOGS 
GROUP BY id;
select *
from cte; 

select count(*)
from HEALTH.USER_LOGS ; --43891

SELECT COUNT(DISTINCT id)
from HEALTH.USER_LOGS ; --554

select 
measure,
count(*) as freequency, 
ROUND(
     100 * count(*) / SUM(COUNT(*)) over (), 2) as percentage
from HEALTH.USER_LOGS 
group by MEASURE
order by 2 DESC ; 

select 
id, 
count(*) AS freequency, 
ROUND( 100 * count(*) / SUM(count(*)) over (), 2) as percentage
from HEALTH.USER_LOGS 
group by id
order by FREEQUENCY desc
limit 10; 

select 
MEASURE_VALUE,
count(*) as freequency
from HEALTH.USER_LOGS 
group by MEASURE_VALUE 
order by 2 DESC ;

select
SYSTOLIC, 
count(*) as freequency
from HEALTH.USER_LOGS 
group by 1
order by 2 desc; 

select
DIASTOLIC , 
count(*) as freequency
from HEALTH.USER_LOGS 
group by 1
order by 2 desc;

select * from HEALTH.USER_LOGS limit 10; 

select 
measure, 
count(*)
from HEALTH.USER_LOGS 
where MEASURE_VALUE = 0
group by 1; 

select * 
from HEALTH.USER_LOGS 
where MEASURE_VALUE = 0 and MEASURE = 'blood_pressure'
limit 10; 

select * 
from HEALTH.USER_LOGS 
where MEASURE_VALUE != 0 and MEASURE = 'blood_pressure'
limit 10; 


select count(* )
from HEALTH.USER_LOGS 
where SYSTOLIC = 0; 

select * 
from HEALTH.USER_LOGS 
where SYSTOLIC = 0
limit 10; 

select 
measure, 
COUNT(*)
from HEALTH.USER_LOGS 
where SYSTOLIC is null
group by MEASURE;


select * 
from HEALTH.USER_LOGS 
where SYSTOLIC != 0
limit 10; 

select count(* )
from HEALTH.USER_LOGS 
where DIASTOLIC = 0; 

select *
from HEALTH.USER_LOGS 
where DIASTOLIC = 0
limit 10; 

select 
measure,
count(*)
from HEALTH.USER_LOGS 
where DIASTOLIC is null
group by MEASURE; 

-- This result confirms that systolic and diastolic only has non-null records when measure = 'blood_pressure'

select count(*) from HEALTH.USER_LOGS; 

--subquery way
select count(*) from (select DISTINCT * from HEALTH.USER_LOGS) as non_dup;

--43890 - 31004

--cte_way
with deduplicated_logs as 
(select DISTINCT *
  from HEALTH.USER_LOGS ) 
select count(*) from deduplicated_logs; 

--temp_table way
drop table if exists deduplicated_user_logs;
create temp table deduplicated_user_logs AS
 select distinct * from HEALTH.USER_LOGS;

select count(*) from deduplicated_user_logs; 


select 
*,
count(*) as freequency
from HEALTH.USER_LOGS 
group by id, LOG_DATE, MEASURE , MEASURE_VALUE, SYSTOLIC, DIASTOLIC
having count(*) > 1; 


--cte

with group_by_counts as (
select *,
count(*) as freequency
from HEALTH.USER_LOGS 
group by id, LOG_DATE, MEASURE , MEASURE_VALUE, SYSTOLIC, DIASTOLIC
)
select 
id, 
sum(FREEQUENCY) as total_duplicate_rows
from group_by_counts
where FREEQUENCY > 1
group by id 
order by total_duplicate_rows DESC
limit 10; 


select * from HEALTH.USER_LOGS limit 10;

--Which measure_value had the most occurences in the health.user_logs value when measure = 'weight'?
select 
measure_value, 
count(*) as measure_count
from HEALTH.USER_LOGS 
where MEASURE = 'weight'
group by MEASURE_VALUE 
order by 2 desc
limit 1; 

--How many single duplicated rows exist when measure = 'blood_pressure' in the health.user_logs? How about the total number of duplicate records in the same table?
--140 and 301
select count(*) from HEALTH.USER_LOGS where MEASURE = 'blood_pressure';

with duplicate_count as (
select *, 
count(*) as freequency
from HEALTH.USER_LOGS 
where MEASURE = 'blood_pressure'
group by id, LOG_DATE, MEASURE , MEASURE_VALUE, SYSTOLIC, DIASTOLIC
)
select 
count(*) as total_single_duplicated_rows,
sum(FREEQUENCY) as total_duplicate_records
from DUPLICATE_COUNT
where freequency > 1;

--What percentage of records measure_value = 0 when measure = 'blood_pressure' in the health.user_logs table? How many records are there also for this same condition?
--562 total records for that condition

WITH all_measure_values AS (
  SELECT
    measure_value,
    COUNT(*) AS total_records,
    SUM(COUNT(*)) OVER () AS overall_total
  FROM health.user_logs
  WHERE measure = 'blood_pressure'
  GROUP BY 1
)
SELECT
  measure_value,
  total_records,
  overall_total,
  ROUND(100 * total_records::NUMERIC / overall_total, 2) AS percentage
FROM all_measure_values
WHERE measure_value = 0;

--What percentage of records are duplicates in the health.user_logs table?

WITH groupby_counts AS (
  SELECT
    id,
    log_date,
    measure,
    measure_value,
    systolic,
    diastolic,
    COUNT(*) AS frequency
  FROM health.user_logs
  GROUP BY
    id,
    log_date,
    measure,
    measure_value,
    systolic,
    diastolic
)
SELECT
  -- Need to subtract 1 from the frequency to count actual duplicates!
  -- Also don't forget about the integer floor division!
  ROUND(
    100 * SUM(CASE
        WHEN frequency > 1 THEN frequency - 1
        ELSE 0 END
    )::NUMERIC / SUM(frequency),
    2
  ) AS duplicate_percentage
FROM groupby_counts;

--OR 
--Total Distinct Records = (Total Row Count - Distinct Row Count) / Total Row Count

WITH deduped_logs AS (
  SELECT DISTINCT *
  FROM health.user_logs
)
SELECT
  ROUND(
    100 * (
      (SELECT COUNT(*) FROM health.user_logs) -
      (SELECT COUNT(*) FROM deduped_logs)
    )::NUMERIC /
    (SELECT COUNT(*) FROM health.user_logs),
    2
  ) AS duplicate_percentage;
 