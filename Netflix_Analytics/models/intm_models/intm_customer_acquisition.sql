{{ config(
    materialized='incremental',
    unique_key='acquisition_id',
    incremental_strategy='merge'
) }}

WITH
final AS (

SELECT

m.acquisition_id,
m.user_id,
m.acquisition_date,

DATE_TRUNC('MONTH', m.acquisition_date) AS acquisition_month,
QUARTER(m.acquisition_date)             AS acquisition_quarter,
YEAR(m.acquisition_date)                AS acquisition_year,

m.acquisition_channel,
m.campaign_type,
m.campaign_cost,
m.device,
m.country,

u.first_name,
u.last_name,
u.gender,
u.date_of_birth,

DATEDIFF('YEAR', u.date_of_birth, CURRENT_DATE()) AS customer_age,

u.preferred_language,
u.signup_date,

DATEDIFF('DAY', m.acquisition_date, u.signup_date) AS signup_delay_days,

u.account_status,

CASE
WHEN UPPER(u.account_status) = 'ACTIVE' THEN TRUE
ELSE FALSE
END AS is_active_user,

u.country AS user_country,
u.state,
u.city

FROM {{ ref('stg_marketing_acquisition') }} m
INNER JOIN {{ ref('stg_users') }} u
ON m.user_id = u.user_id

)

SELECT *
FROM final

{% if is_incremental() %}

WHERE acquisition_id NOT IN (
    SELECT acquisition_id
    FROM {{ this }}
)

{% endif %}