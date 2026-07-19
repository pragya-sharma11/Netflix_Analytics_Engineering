{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='subscription_id'
) }}

WITH subscriptions AS (
SELECT *
from {{ ref('intm_users_subscriptions') }}
),

subscription_plan AS (
SELECT
plan_key,
plan_name,
billing_cycle,
subscription_price,
currency
from {{ ref('dim_subscription_plan') }}
),

start_date AS (
SELECT date_key, full_date from {{ ref('dim_date') }}
),

end_date AS (
SELECT date_key, full_date FROM {{ ref('dim_date') }}
),

final AS (

SELECT

-- Business Keys
s.subscription_id,
s.user_id,

-- Dimension Keys
sp.plan_key,

sd.date_key AS subscription_start_date_key,

ed.date_key AS subscription_end_date_key,

-- Subscription Details
s.subscription_status,
s.auto_renew,

-- Measures
s.subscription_price,

-- Derived Metrics
DATEDIFF( DAY,s.start_date,COALESCE(s.end_date, CURRENT_DATE())) AS subscription_duration_days,
CASE WHEN s.subscription_status = 'Active' THEN TRUE ELSE FALSE END AS is_active_subscription,
CASE WHEN s.auto_renew THEN TRUE ELSE FALSE END AS is_auto_renew,

-- Audit
CURRENT_TIMESTAMP() AS dbt_updated_at

FROM subscriptions s

LEFT JOIN subscription_plan sp
ON s.plan_name = sp.plan_name
AND s.billing_cycle = sp.billing_cycle

LEFT JOIN start_date sd
ON s.start_date = sd.full_date

LEFT JOIN end_date ed
ON s.end_date = ed.full_date

)

SELECT *
FROM final;