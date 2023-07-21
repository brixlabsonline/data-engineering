--category_name: The name of the top 2 ranking categories
--rental_count: How many total films have they watched in this category
--average_comparison: How many more films has the customer watched compared to the average DVD Rental Co customer
--percentile: How does the customer rank in terms of the top X% compared to all other customers in this film category?
--category_percentage: What proportion of total films watched does this category make up?

--customer_id	,category_ranking	,category_name	,rental_count	,average_comparison	percentile	,category_percentage 
--FYI : category_percentage are actually dependent on all of the category counts and not just the top 2 ranked categories.

--Final Dataset 

DROP TABLE IF EXISTS complete_joint_dataset; 
CREATE TEMP TABLE complete_joint_dataset AS
SELECT 
    rental.customer_id, 
    film.film_id, 
    film.title, 
    rental.rental_date,
    category.name as category_name 
FROM dvd_rentals.rental rental
INNER JOIN dvd_rentals.inventory inventory 
  ON rental.inventory_id = inventory.inventory_id 
INNER JOIN dvd_rentals.film film 
  ON inventory.film_id = film.film_id 
INNER JOIN dvd_rentals.film_category film_category 
  ON film.film_id = film_category.film_id
INNER JOIN dvd_rentals.category category 
  ON film_category.category_id = category.category_id; 
 
--SELECT * FROM complete_joint_dataset; 

SELECT 
complete_joint_dataset.customer_id,
complete_joint_dataset.category_name,
COUNT(complete_joint_dataset.film_id) as rental_count
FROM complete_joint_dataset
GROUP BY complete_joint_dataset.customer_id, complete_joint_dataset.category_name
ORDER BY complete_joint_dataset.customer_id, rental_count DESC;

SELECT 
complete_joint_dataset.customer_id,
complete_joint_dataset.category_name,
COUNT(complete_joint_dataset.film_id) as rental_count,
RANK() OVER rental_count (GROUP BY complete_joint_dataset.category_name)
FROM complete_joint_dataset
GROUP BY complete_joint_dataset.customer_id, complete_joint_dataset.category_name
ORDER BY complete_joint_dataset.customer_id, rental_count DESC;


--adding rental_date to deal with ties (rental_count / category)
--Eventhough we have a specific criteria, we may have to consider A/B tests or “champion vs challenger” or customer survey to determine what is their preferance for the recomendation. 

SELECT 
complete_joint_dataset.customer_id,
complete_joint_dataset.category_name,
COUNT(complete_joint_dataset.film_id) as rental_count,
MAX(complete_joint_dataset.rental_date) as latest_rental_date
FROM complete_joint_dataset
GROUP BY 
	complete_joint_dataset.customer_id,
	complete_joint_dataset.category_name
ORDER BY 
	complete_joint_dataset.customer_id,
	rental_count DESC,
	latest_rental_date DESC;
	

--Average on top 2 categories - test
DROP TABLE IF EXISTS top_2_category_rental_count;
CREATE TEMP TABLE top_2_category_rental_count AS
WITH input_data (customer_id, category_name, rental_count) AS (
 VALUES
 (1, 'Classics', 6),
 (1, 'Comedy', 5),
 (2, 'Sports', 5),
 (2, 'Classics', 4),
 (3, 'Action', 4),
 (3, 'Sci-Fi', 3)
)
SELECT * FROM input_data;

-- check output
SELECT * FROM top_2_category_rental_count;

--For example, for Category - Classics, the average is heavily skewed to only customers who have classics as on of their top 2 categories

WITH aggregated_rental_count AS (
  SELECT
    customer_id,
    category_name,
    COUNT(*) AS rental_count
  FROM complete_joint_dataset
  WHERE customer_id in (1, 2, 3)
  GROUP BY
    customer_id,
    category_name
  /* -- we remove this order by because we don't need it here!
     ORDER BY
     customer_id,
     rental_count DESC
  */
)
SELECT
  category_name,
  -- round out large decimals to just 1 decimal point
  ROUND(AVG(rental_count), 1) AS avg_rental_count
FROM aggregated_rental_count
GROUP BY
  category_name
-- this will sort our output in alphabetical order
ORDER BY
  category_name;

 --Now average on top 2 categories to compare with above 
 
 SELECT
  category_name,
  -- round out large decimals to just 1 decimal point
  ROUND(AVG(rental_count), 1) AS avg_rental_count
FROM top_2_category_rental_count
GROUP BY
  category_name
-- this will sort our output in alphabetical order
ORDER BY
  category_name;
  
 
 
--combining two to see the skew
 
WITH aggregated_rental_count AS (
  SELECT
    customer_id,
    category_name,
    COUNT(*) AS rental_count
  FROM complete_joint_dataset
  WHERE customer_id in (1, 2, 3)
  GROUP BY
    customer_id,
    category_name
),
all_categories AS (
  SELECT
    category_name,
    -- round out large decimals to just 1 decimal point
    ROUND(AVG(rental_count), 1) AS all_category_average
  FROM aggregated_rental_count
  GROUP BY
    category_name
),
-- use a new CTE here with raw data entries just for completeness
top_2_category_rental_count (customer_id, category_name, rental_count) AS (
 VALUES
 (1, 'Classics', 6),
 (1, 'Comedy', 5),
 (2, 'Sports', 5),
 (2, 'Classics', 4),
 (3, 'Action', 4),
 (3, 'Sci-Fi', 3)
),
top_2_categories AS (
SELECT
  category_name,
  -- round out large decimals to just 1 decimal point
  ROUND(AVG(rental_count), 1) AS top_2_average
FROM top_2_category_rental_count
GROUP BY
  category_name
-- this will sort our output in alphabetical order
ORDER BY
  category_name
)
-- final select statement for output
SELECT
  top_2_categories.category_name,
  top_2_categories.top_2_average,
  all_categories.all_category_average
FROM top_2_categories
LEFT JOIN all_categories
  ON top_2_categories.category_name = all_categories.category_name
ORDER BY
  top_2_categories.category_name;
  
 
--This same issue will definitely impact the percentile value - how can we compare a specific customer’s ranking percentage compared to other customers if we don’t have the rental count for other customers for a specific category
--And finally the category_percentage calculation is actually only relative to a single customer’s rental behaviour - but how can we count the total rentals if we only have the top 2 categories
--Solution is to use entire dataset before isolating the first 2 categories for final output. 


DROP TABLE IF EXISTS category_rental_counts;
CREATE TEMP TABLE category_rental_counts AS
SELECT
  customer_id,
  category_name,
  COUNT(*) AS rental_count,
  MAX(rental_date) AS latest_rental_date
FROM complete_joint_dataset
GROUP BY
  customer_id,
  category_name;
-- profile just customer_id = 1 values sorted by desc rental_count
SELECT *
FROM category_rental_counts
WHERE customer_id = 1
ORDER BY
  rental_count DESC;
 
 
--Total Customer Rentals
--In order to generate category_percentage (What proportion of each customer's total films watched does this count make) ..
--We will need to get the total rentals per customer 

DROP TABLE IF EXISTS customer_total_rentals;
CREATE TEMP TABLE customer_total_rentals AS
SELECT
  customer_id,
  SUM(rental_count) AS total_rental_count
FROM category_rental_counts
GROUP BY customer_id;

-- show output for first 5 customer_id values
SELECT *
FROM customer_total_rentals
WHERE customer_id <= 5
ORDER BY customer_id;

--Average Category Rental Counts 
--with all of our category records for all customers to calculate the true average rental count for each category.

DROP TABLE IF EXISTS average_category_rental_counts;
CREATE TEMP TABLE average_category_rental_counts AS
SELECT
  category_name,
  AVG(rental_count) AS avg_rental_count
FROM category_rental_counts
GROUP BY
  category_name;

-- output the entire table by desc avg_rental_count
SELECT *
FROM average_category_rental_counts
ORDER BY
  avg_rental_count DESC;
 
 
UPDATE average_category_rental_counts
SET avg_rental_count = FLOOR(avg_rental_count)
RETURNING *;


--PERCENTILE VALUE 

SELECT
  customer_id,
  category_name,
  rental_count,
  PERCENT_RANK() OVER (
    PARTITION BY category_name
    ORDER BY rental_count DESC
  ) AS percentile
FROM category_rental_counts
ORDER BY customer_id, rental_count DESC
LIMIT 14;

SELECT *
FROM average_category_rental_counts
WHERE category_name = 'Classics';

--You’ve watched 6 Classics films, that’s 4 more than the DVD Rental Co average and puts you in the top 0% of Classics gurus!

SELECT
  customer_id,
  category_name,
  rental_count,
  -- use ceiling to round up to nearest integer after multiplying by 100
  CEILING(
    100 * PERCENT_RANK() OVER (
      PARTITION BY category_name
      ORDER BY rental_count DESC
    )
  ) AS percentile
FROM category_rental_counts
ORDER BY customer_id, rental_count DESC
LIMIT 2;
--You’ve watched 6 Classics films, that’s 4 more than the DVD Rental Co average and puts you in the top 1% of Classics gurus!

DROP TABLE IF EXISTS customer_category_percentiles;
CREATE TEMP TABLE customer_category_percentiles AS
SELECT
  customer_id,
  category_name,
  -- use ceiling to round up to nearest integer after multiplying by 100
  CEILING(
    100 * PERCENT_RANK() OVER (
      PARTITION BY category_name
      ORDER BY rental_count DESC
    )
  ) AS percentile
FROM category_rental_counts;

-- inspect top 2 records for customer_id = 1 sorted by ascending percentile
SELECT *
FROM customer_category_percentiles
WHERE customer_id = 1
ORDER BY customer_id, percentile
LIMIT 2;

DROP TABLE IF EXISTS customer_category_joint_table;
CREATE TEMP TABLE customer_category_joint_table AS
SELECT
  t1.customer_id,
  t1.category_name,
  t1.rental_count,
  t2.total_rental_count,
  t3.avg_rental_count,
  t4.percentile
FROM category_rental_counts AS t1
INNER JOIN customer_total_rentals AS t2
  ON t1.customer_id = t2.customer_id
INNER JOIN average_category_rental_counts AS t3
  ON t1.category_name = t3.category_name
INNER JOIN customer_category_percentiles AS t4
  ON t1.customer_id = t4.customer_id
  AND t1.category_name = t4.category_name;

-- inspect customer_id = 1 rows sorted by percentile
SELECT *
FROM customer_category_joint_table
WHERE customer_id = 1
ORDER BY percentile;

--Adding calculated fields 

DROP TABLE IF EXISTS customer_category_joint_table;
CREATE TEMP TABLE customer_category_joint_table AS
SELECT
  t1.customer_id,
  t1.category_name,
  t1.rental_count,
  t1.latest_rental_date,
  t2.total_rental_count,
  t3.avg_rental_count,
  t4.percentile,
  t1.rental_count - t3.avg_rental_count AS average_comparison,
  -- round to nearest integer for percentage after multiplying by 100
  ROUND(100 * t1.rental_count / t2.total_rental_count) AS category_percentage
FROM category_rental_counts AS t1
INNER JOIN customer_total_rentals AS t2
  ON t1.customer_id = t2.customer_id
INNER JOIN average_category_rental_counts AS t3
  ON t1.category_name = t3.category_name
INNER JOIN customer_category_percentiles AS t4
  ON t1.customer_id = t4.customer_id
  AND t1.category_name = t4.category_name;

-- inspect customer_id = 1 top 5 rows sorted by percentile
SELECT *
FROM customer_category_joint_table
WHERE customer_id = 1
ORDER BY percentile
limit 5;

--Ordering and Filtering Rows with ROW_NUMBER

DROP TABLE IF EXISTS top_categories_information;

-- Note that you need an extra pair of (brackets) when you create tables
-- with CTEs inside the SQL statement!
CREATE TEMP TABLE top_categories_information AS (
-- use a CTE with the ROW_NUMBER() window function implemented
WITH ordered_customer_category_joint_table AS (
  SELECT
    customer_id,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY rental_count DESC, latest_rental_date DESC
    ) AS category_ranking,
    category_name,
    rental_count,
    average_comparison,
    percentile,
    category_percentage
  FROM customer_category_joint_table
)
-- filter out top 2 rows from the CTE for final output
SELECT *
FROM ordered_customer_category_joint_table
WHERE category_ranking <= 2
);

SELECT *
FROM top_categories_information
WHERE customer_id in (1, 2, 3)
ORDER BY customer_id, category_ranking;
