{{ config(
    materialized='table'
) }}

WITH date_spine AS (
-- 20 years data
SELECT
DATEADD( DAY, ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1, '2015-01-01' ) AS full_date
from TABLE(GENERATOR(ROWCOUNT => 7305))   
),

final AS (

SELECT
-- Date Key (YYYYMMDD)
TO_NUMBER(TO_CHAR(full_date, 'YYYYMMDD')) AS date_key,

-- Calendar Date
full_date,

-- Day Attributes
DAY(full_date) AS day_of_month,
DAYOFWEEK(full_date) AS day_of_week_number,
DAYNAME(full_date) AS day_name,
DAYOFYEAR(full_date) AS day_of_year,

-- Week Attributes
WEEK(full_date) AS week_number,

-- Month Attributes
MONTH(full_date) AS month_number,
MONTHNAME(full_date) AS month_name,

-- Quarter Attributes
QUARTER(full_date) AS quarter,

-- Year Attributes
YEAR(full_date) AS year,

-- Weekend Flag
CASE
WHEN DAYOFWEEK(full_date) IN (1,7)
THEN TRUE
ELSE FALSE
END AS is_weekend,

-- Month Start / End
DATE_TRUNC('MONTH', full_date) AS month_start_date,
LAST_DAY(full_date) AS month_end_date,

-- Quarter Start / End
DATE_TRUNC('QUARTER', full_date) AS quarter_start_date,
LAST_DAY(DATE_TRUNC('QUARTER', full_date), 'QUARTER') AS quarter_end_date,

-- Year Start / End
DATE_TRUNC('YEAR', full_date) AS year_start_date,
LAST_DAY(DATE_TRUNC('YEAR', full_date), 'YEAR') AS year_end_date,

-- Financial Year (Apr-Mar)
CASE
WHEN MONTH(full_date) >= 4
THEN CONCAT(YEAR(full_date), '-', YEAR(full_date)+1)
ELSE CONCAT(YEAR(full_date)-1, '-', YEAR(full_date))
END AS financial_year,

-- Audit
CURRENT_TIMESTAMP() AS dbt_updated_at

FROM date_spine

)

SELECT *
FROM final;