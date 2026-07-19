{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='user_id'
) }}

WITH users AS (
Select * from {{ ref('stg_users') }}
),

final AS (
Select
-- Key
user_id,

-- Personal Information
first_name,
last_name,
email,
phone_number,
gender,
date_of_birth,

-- Demographics
country,
state,
city,
preferred_language,

-- Account Information
signup_date,
account_status,

-- Derived Columns
DATEDIFF(YEAR,date_of_birth,CURRENT_DATE()) AS customer_age,
DATEDIFF(DAY,signup_date,CURRENT_DATE()) AS customer_tenure_days,
CASE WHEN UPPER(account_status) = 'ACTIVE' THEN TRUE ELSE FALSE END AS is_active_user,
CASE
WHEN DATEDIFF(DAY, signup_date, CURRENT_DATE()) <= 30 THEN 'New Customer'
WHEN DATEDIFF(DAY, signup_date, CURRENT_DATE()) <= 180 THEN 'Growing Customer'
WHEN DATEDIFF(DAY, signup_date, CURRENT_DATE()) <= 365 THEN 'Established Customer'
ELSE 'Loyal Customer'
END AS customer_segment,

DATE_TRUNC('MONTH', signup_date) AS signup_month,

YEAR(signup_date) AS signup_year,

CURRENT_TIMESTAMP() AS dbt_updated_at

from users

)

Select *
from final;