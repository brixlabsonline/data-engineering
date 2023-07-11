select * from DVD_RENTALS.RENTAL limit 10;

select 
count(distinct INVENTORY_ID) 
from DVD_RENTALS.RENTAL; 
--4580

select 
inventory_id, 
COUNT(inventory_id) as inventory_count
from DVD_RENTALS.RENTAL 
group by inventory_id
order by inventory_count desc; 

select count(distinct INVENTORY_ID)
from DVD_RENTALS.INVENTORY ;
--4581

--There are multiple rows per inventory_id value on dvd_rentals.rental table 

with cte AS (
select 
inventory_id, 
COUNT(inventory_id) as inventory_count
from DVD_RENTALS.RENTAL 
group by inventory_id
)
select 
inventory_count, 
count(inventory_id)
from cte 
group by inventory_count;



select 
inventory_id, 
COUNT(inventory_id) as inventory_count
from DVD_RENTALS.INVENTORY 
group by inventory_id
order by inventory_count; 

select 
inventory_id, 
COUNT(film_id) as film_count
from DVD_RENTALS.INVENTORY 
group by inventory_id
order by film_count asc; 

--There will be multiple inventory for unique film_id 
select 
film_id, 
count(DISTINCT inventory_id) as film_count
from DVD_RENTALS.INVENTORY 
group by film_id; 

--how many film_id fall into each film count
--there are multiple unitque inventory_id per film_id value in the dvd_rentals.inventory table
--eg: 4 films has 8 inventory

with cte as (
select 
film_id, 
count(DISTINCT inventory_id) as film_inventory_count
from DVD_RENTALS.INVENTORY 
group by film_id
) 
select 
film_inventory_count,
count(film_id) as film_count
from cte 
group by film_inventory_count
;


--rental distribution analysis on inventory_id foreign key 

with cte as ( 
select
inventory_id,
count(*) as foreign_key_count
from DVD_RENTALS.RENTAL 
group by inventory_id 
)
select 
foreign_key_count, 
count(*) as freequency
from cte 
group by foreign_key_count 


--inventory distribution analysis on inventory_id foreign key 
with cte as (
select 
inventory_id, 
count(*) as foreign_key_count
from DVD_RENTALS.INVENTORY 
group by inventory_id
)
select 
foreign_key_count, 
count(inventory_id) as freequency
from cte
group by foreign_key_count;


--1. Which foreign keys only exists in rental table 

select 
count(distinct rental.inventory_id)
from DVD_RENTALS.RENTAL rental 
where not exists (
select inventory_id 
from DVD_RENTALS.INVENTORY inventory 
where rental.inventory_id = inventory.inventory_id 
); --0 

--1. Which foreign keys only exists in inventory table

select 
count(distinct inventory_id)
from DVD_RENTALS.INVENTORY inventory
where not exists (
select 
inventory_id 
from DVD_RENTALS.RENTAL rental
where rental.inventory_id = inventory.inventory_id
); --1

--inspect further for the record that is only exists in inventory table 

select 
* 
from DVD_RENTALS.INVENTORY inventory 
where not exists (
select inventory_id
from DVD_RENTALS.RENTAL rental 
where rental.inventory_id = inventory.inventory_id)
--inventory_id = 5, film_id = 1, store_id = 2 

--Summary - There is no diffarace running LEFT or INNER Join 

select 
count(distinct rental.inventory_id)
from DVD_RENTALS.RENTAL rental 
where exists (
select inventory_id 
from DVD_RENTALS.INVENTORY inventory 
where rental.inventory_id = inventory.inventory_id
); --4580


DROP TABLE IF EXISTS left_rental_join; 
CREATE TEMP TABLE left_rental_join AS 
(
select 
rental.customer_id,
rental.inventory_id,
inventory.film_id 
from DVD_RENTALS.RENTAL rental 
LEFT JOIN DVD_RENTALS.INVENTORY inventory 
ON rental.inventory_id = inventory.inventory_id
);

DROP TABLE IF EXISTS inner_rental_join; 
CREATE TEMP TABLE inner_rental_join AS 
(
select 
rental.customer_id,
rental.inventory_id,
inventory.film_id 
from DVD_RENTALS.RENTAL rental 
INNER JOIN DVD_RENTALS.INVENTORY inventory 
ON rental.inventory_id = inventory.inventory_id
);

(
select 
'left_join' as join_type, 
count(*) as record_count,
count(DISTINCT inventory_id) as unique_key_values
from left_rental_join
)
UNION 
(
select 
'right_join' as join_type, 
count(*) as record_count,
count(DISTINCT inventory_id) as unique_key_values
from inner_rental_join
);

--We have 1 -to-many relationship for film_id foreign key in dvd_rentals.inventory_table 
WITH base_counts AS (
SELECT
  film_id,
  COUNT(*) AS record_count
FROM dvd_rentals.inventory
GROUP BY film_id
)
SELECT
  record_count,
  COUNT(DISTINCT film_id) as unique_film_id_values
FROM base_counts
GROUP BY record_count
ORDER BY record_count;


SELECT
  film_id,
  COUNT(*) AS record_count
FROM dvd_rentals.film
GROUP BY film_id
ORDER BY record_count DESC
LIMIT 5;

-- how many foreign keys only exist in the inventory table
SELECT
  COUNT(DISTINCT inventory.film_id)
FROM dvd_rentals.inventory
WHERE NOT EXISTS (
  SELECT film_id
  FROM dvd_rentals.film
  WHERE film.film_id = inventory.film_id
); --0 

-- how many foreign keys only exist in the film table
SELECT
  COUNT(DISTINCT film.film_id)
FROM dvd_rentals.film
WHERE NOT EXISTS (
  SELECT film_id
  FROM dvd_rentals.inventory
  WHERE film.film_id = inventory.film_id
); --42

--We will be expecting a total distinct count of film_id values of 958 once we perform the final join between 2 tables.
SELECT
  COUNT(DISTINCT film_id)
FROM dvd_rentals.inventory
WHERE EXISTS (
  SELECT film_id
  FROM dvd_rentals.film
  WHERE film.film_id = inventory.film_id
); --958


DROP TABLE IF EXISTS left_join_part_2;
CREATE TEMP TABLE left_join_part_2 AS
SELECT
  inventory.inventory_id,
  inventory.film_id,
  film.title
FROM dvd_rentals.inventory
LEFT JOIN dvd_rentals.film
  ON film.film_id = inventory.film_id;

DROP TABLE IF EXISTS inner_join_part_2;
CREATE TEMP TABLE inner_join_part_2 AS
SELECT
  inventory.inventory_id,
  inventory.film_id,
  film.title
FROM dvd_rentals.inventory
INNER JOIN dvd_rentals.film
  ON film.film_id = inventory.film_id;

(
  SELECT
    'left join' AS join_type,
    COUNT(*) AS record_count,
    COUNT(DISTINCT film_id) AS unique_key_values
  FROM left_join_part_2
)
-- we can use UNION ALL here because we do not need UNION for distinct values!
UNION ALL
(
  SELECT
    'inner join' AS join_type,
    COUNT(*) AS record_count,
    COUNT(DISTINCT film_id) AS unique_key_values
  FROM inner_join_part_2
);


DROP TABLE IF EXISTS join_parts_1_and_2; 
CREATE TEMP TABLE join_parts_1_and_2 AS 
SELECT 
 rental.customer_id, 
 film.film_id, 
 film.title
FROM dvd_rentals.rental rental 
INNER JOIN dvd_rentals.inventory inventory
 ON rental.inventory_id = inventory.inventory_id 
INNER JOIN dvd_rentals.film film 
 ON inventory.film_id = film.film_id; 
 

--Final Dataset 

DROP TABLE IF EXISTS complete_joint_dataset; 
CREATE TEMP TABLE complete_joint_dataset AS
SELECT 
    rental.customer_id, 
    film.film_id, 
    film.title, 
    film_category.category_id,
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
 
SELECT * FROM complete_joint_dataset; 