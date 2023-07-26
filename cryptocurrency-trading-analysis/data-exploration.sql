--What is the earliest and latest market_date values?
--What was the historic all-time high and low values for the close_price and their dates?
--Which date had the most volume traded and what was the close_price for that day?
--How many days had a low_price price which was 10% less than the open_price?
--What percentage of days have a higher close_price than open_price?
--What was the largest difference between high_price and low_price and which date did it occur?
--If you invested $10,000 on the 1st January 2016 - how much is your investment worth in 1st of February 2021? Use the close_price for this calculation

SELECT * 
FROM trading.daily_btc
LIMIT 5; 

SELECT *
FROM trading.daily_btc
WHERE (
  open_price + high_price + low_price +
  close_price + adjusted_close_price + volume
) IS NULL;

--WHERE market_date IN (
  '2020-04-17',
  '2020-10-09',
  '2020-10-12',
  '2020-10-13'
)

--Fill in the NULLs 

SELECT
  market_date,
  open_price,
  LAG(open_price, 1) OVER (ORDER BY market_date) AS lag_open_price
FROM trading.daily_btc
WHERE market_date BETWEEN ('2020-04-17'::DATE - 1) AND ('2020-04-17'::DATE + 1);


--LEAD To perform same operation (Sorting the record in DESC order)

SELECT
  market_date,
  open_price,
  LAG(open_price) OVER (ORDER BY market_date) AS lag_open_price,
  LEAD(open_price) OVER (ORDER BY market_date DESC) AS lead_open_price
FROM trading.daily_btc
WHERE market_date BETWEEN ('2020-04-17'::DATE - 1) AND ('2020-04-17'::DATE + 1);


WITH april_17_data AS (
  SELECT
    market_date,
    open_price,
    LAG(open_price) OVER (ORDER BY market_date) AS lag_open_price
  FROM trading.daily_btc
  WHERE market_date BETWEEN ('2020-04-17'::DATE - 1) AND ('2020-04-17'::DATE + 1)
)
SELECT
  market_date,
  open_price,
  lag_open_price,
  COALESCE(open_price, lag_open_price) AS coalesce_open_price
FROM april_17_data;

DROP TABLE IF EXISTS updated_daily_btc;
CREATE TEMP TABLE updated_daily_btc AS
SELECT
  market_date,
  COALESCE(
    open_price,
    LAG(open_price) OVER (ORDER BY market_date)
  ) AS open_price,
  COALESCE(
    high_price,
    LAG(high_price) OVER (ORDER BY market_date)
  ) AS high_price,
  COALESCE(
    low_price,
    LAG(low_price) OVER (ORDER BY market_date)
  ) AS low_price,
  COALESCE(
    close_price,
    LAG(close_price) OVER (ORDER BY market_date)
  ) AS close_price,
  COALESCE(
    adjusted_close_price,
    LAG(adjusted_close_price) OVER (ORDER BY market_date)
  ) AS adjusted_close_price,
  COALESCE(
    volume,
    LAG(volume) OVER (ORDER BY market_date)
  ) AS volume
FROM trading.daily_btc;

-- test that our previously missing value dates are filled!
SELECT *
FROM updated_daily_btc
WHERE market_date IN (
  '2020-04-17',
  '2020-10-09',
  '2020-10-12',
  '2020-10-13'
);

SELECT
  market_date,
  open_price,
  LAG(open_price, 1, 6000::NUMERIC) OVER (ORDER BY market_date) AS lag_open_price
FROM trading.daily_btc
WHERE market_date BETWEEN ('2020-04-17'::DATE - 1) AND ('2020-04-17'::DATE + 1);


--LAG function with offset input

SELECT
  market_date,
  open_price,
  COALESCE(
    open_price,
    CASE
      WHEN market_date = '2020-10-13'
        THEN LAG(open_price, 2) OVER (ORDER BY market_date)
      ELSE LAG(open_price, 1) OVER (ORDER BY market_date)
      END
  ) AS adj_open_price
FROM trading.daily_btc
WHERE market_date BETWEEN '2020-10-10'::DATE AND '2020-10-13'::DATE;

SELECT
  market_date,
  open_price,
  COALESCE(
    open_price,
      LAG(open_price, 1) OVER (ORDER BY market_date),
      LAG(open_price, 2) OVER (ORDER BY market_date)
    )
  ) AS adj_open_price
FROM trading.daily_btc
WHERE market_date BETWEEN '2020-10-10'::DATE AND '2020-10-13'::DATE
;

--Update Base table with values 

DROP TABLE IF EXISTS testing_updated_daily_btc;
CREATE TEMP TABLE testing_updated_daily_btc AS
  TABLE updated_daily_btc;
 
UPDATE testing_updated_daily_btc
SET
  open_price           = LAG(open_price) OVER (ORDER BY market_date),
  high_price           = LAG(high_price) OVER (ORDER BY market_date),
  low_price            = LAG(low_price) OVER (ORDER BY market_date),
  close_price          = LAG(close_price) OVER (ORDER BY market_date),
  adjusted_close_price = LAG(adjusted_close_price) OVER (ORDER BY market_date),
  volume               = LAG(volume) OVER (ORDER BY market_date)
WHERE
  market_date = '2020-10-13'
-- show all updated rows as the query output
RETURNING *;
--This will not work 

SELECT
  market_date,
  COALESCE(
    open_price,
    LAG(open_price, 1) OVER (ORDER BY market_date),
    LAG(open_price, 2) OVER (ORDER BY market_date)
  ) AS open_price,
  COALESCE(
    high_price,
    LAG(high_price, 1) OVER (ORDER BY market_date),
    LAG(high_price, 2) OVER (ORDER BY market_date)
  ) AS high_price,
  COALESCE(
    low_price,
    LAG(low_price, 1) OVER (ORDER BY market_date),
    LAG(low_price, 2) OVER (ORDER BY market_date)
  ) AS low_price,
  COALESCE(
    close_price,
    LAG(close_price, 1) OVER (ORDER BY market_date),
    LAG(close_price, 2) OVER (ORDER BY market_date)
  ) AS close_price,
  COALESCE(
    adjusted_close_price,
    LAG(adjusted_close_price, 1) OVER (ORDER BY market_date),
    LAG(adjusted_close_price, 2) OVER (ORDER BY market_date)
  ) AS adjusted_close_price,
  COALESCE(
    volume,
    LAG(volume, 1) OVER (ORDER BY market_date),
    LAG(volume, 2) OVER (ORDER BY market_date)
  ) AS volume
FROM trading.daily_btc
WHERE market_date = '2020-10-13';

--This will still give NULL values

WITH calculated_values AS (
SELECT
  market_date,
  COALESCE(
    open_price,
    LAG(open_price, 1) OVER (ORDER BY market_date),
    LAG(open_price, 2) OVER (ORDER BY market_date)
  ) AS open_price,
  COALESCE(
    high_price,
    LAG(high_price, 1) OVER (ORDER BY market_date),
    LAG(high_price, 2) OVER (ORDER BY market_date)
  ) AS high_price,
  COALESCE(
    low_price,
    LAG(low_price, 1) OVER (ORDER BY market_date),
    LAG(low_price, 2) OVER (ORDER BY market_date)
  ) AS low_price,
  COALESCE(
    close_price,
    LAG(close_price, 1) OVER (ORDER BY market_date),
    LAG(close_price, 2) OVER (ORDER BY market_date)
  ) AS close_price,
  COALESCE(
    adjusted_close_price,
    LAG(adjusted_close_price, 1) OVER (ORDER BY market_date),
    LAG(adjusted_close_price, 2) OVER (ORDER BY market_date)
  ) AS adjusted_close_price,
  COALESCE(
    volume,
    LAG(volume, 1) OVER (ORDER BY market_date),
    LAG(volume, 2) OVER (ORDER BY market_date)
  ) AS volume
FROM trading.daily_btc
WHERE market_date BETWEEN '2020-10-11'::DATE and '2020-10-13'::DATE
)
SELECT *
FROM calculated_values
WHERE market_date = '2020-10-13';

SELECT *
FROM testing_updated_daily_btc
WHERE market_date = '2020-10-12';

--FInal 
INSERT INTO testing_updated_daily_btc
WITH calculated_values AS (
SELECT
  market_date,
  COALESCE(
    open_price,
    LAG(open_price, 1) OVER (ORDER BY market_date),
    LAG(open_price, 2) OVER (ORDER BY market_date)
  ) AS open_price,
  COALESCE(
    high_price,
    LAG(high_price, 1) OVER (ORDER BY market_date),
    LAG(high_price, 2) OVER (ORDER BY market_date)
  ) AS high_price,
  COALESCE(
    low_price,
    LAG(low_price, 1) OVER (ORDER BY market_date),
    LAG(low_price, 2) OVER (ORDER BY market_date)
  ) AS low_price,
  COALESCE(
    close_price,
    LAG(close_price, 1) OVER (ORDER BY market_date),
    LAG(close_price, 2) OVER (ORDER BY market_date)
  ) AS close_price,
  COALESCE(
    adjusted_close_price,
    LAG(adjusted_close_price, 1) OVER (ORDER BY market_date),
    LAG(adjusted_close_price, 2) OVER (ORDER BY market_date)
  ) AS adjusted_close_price,
  COALESCE(
    volume,
    LAG(volume, 1) OVER (ORDER BY market_date),
    LAG(volume, 2) OVER (ORDER BY market_date)
  ) AS volume
FROM trading.daily_btc
WHERE market_date BETWEEN '2020-10-11'::DATE and '2020-10-13'::DATE
)
SELECT *
FROM calculated_values
WHERE market_date = '2020-10-13'
RETURNING *;

-----------------

--Window cloause simplification

--Harder to make mistakes because we only need to specify the window once
--Sticks to the DRY principle (DO NOT REPEAT YOURSELF!)
--Keeps the SELECT body of the SQL query very clean looking

DROP TABLE IF EXISTS updated_daily_btc;
CREATE TEMP TABLE updated_daily_btc AS
SELECT
  market_date,
  COALESCE(
    open_price,
    LAG(open_price, 1) OVER w,
    LAG(open_price, 2) OVER w
  ) AS open_price,
  COALESCE(
    high_price,
    LAG(high_price, 1) OVER w,
    LAG(high_price, 2) OVER w
  ) AS high_price,
  COALESCE(
    low_price,
    LAG(low_price, 1) OVER w,
    LAG(low_price, 2) OVER w
  ) AS low_price,
  COALESCE(
    close_price,
    LAG(close_price, 1) OVER w,
    LAG(close_price, 2) OVER w
  ) AS close_price,
  COALESCE(
    adjusted_close_price,
    LAG(adjusted_close_price, 1) OVER w,
    LAG(adjusted_close_price, 2) OVER w
  ) AS adjusted_close_price,
  COALESCE(
    volume,
    LAG(volume, 1) OVER w,
    LAG(volume, 2) OVER w
  ) AS volume
FROM trading.daily_btc
-- NOTE: checkout the syntax where I've included an unused window below!
WINDOW
  w AS (ORDER BY market_date),
  unused_window AS (ORDER BY market_date DESC);

-- inspect a few rows of the updated dataset for October
SELECT *
FROM updated_daily_btc
WHERE market_date BETWEEN '2020-10-08'::DATE AND '2020-10-15'::DATE;
