{{ config(
    materialized='table'
) }}

WITH plans AS (

SELECT DISTINCT
plan_name,
billing_cycle,
subscription_price,
currency
from {{ ref('stg_subscriptions') }}
),

final AS (

SELECT
-- Surrogate Key
ROW_NUMBER() OVER (
    ORDER BY
        plan_name,
        billing_cycle,
        currency
) AS plan_key,

-- Business Attributes
plan_name,
billing_cycle,
subscription_price,
currency,

-- Derived Attributes
CASE
WHEN LOWER(plan_name) LIKE '%basic%' THEN 'Entry'
WHEN LOWER(plan_name) LIKE '%standard%' THEN 'Mid'
WHEN LOWER(plan_name) LIKE '%premium%' THEN 'Premium'
WHEN LOWER(plan_name) LIKE '%ultra%' THEN 'Premium'
ELSE 'Other'
END AS plan_tier,

CASE
WHEN LOWER(billing_cycle) = 'monthly' THEN 12
WHEN LOWER(billing_cycle) = 'annual' THEN 1
ELSE NULL
END AS payments_per_year,

CASE
WHEN LOWER(billing_cycle) = 'monthly'
THEN subscription_price * 12
WHEN LOWER(billing_cycle) = 'annual'
THEN subscription_price
ELSE NULL
END AS annualized_price,

CURRENT_TIMESTAMP() AS dbt_updated_at

from plans

)

SELECT *
from final