{{ config(
    materialized='incremental',
    unique_key='subscription_id',
    incremental_strategy='merge'
) }}

with user_subs as (
SELECT 
u.user_id as userid,
u.*, 
datediff('year', u.date_of_birth, CURRENT_DATE) as customer_age,
s.*, 
coalesce(ex.exchange_rates,1) * s.SUBSCRIPTION_PRICE as subscription_price_usd ,
datediff('day', u.signup_date, CURRENT_DATE) as customer_tenure_days,
datediff('day', s.start_date, coalesce(s.end_date, CURRENT_DATE)) as subscription_duration_days,
case when s.SUBSCRIPTION_STATUS='ACTIVE' then TRUE else FALSE end as is_active_subscription,
case when s.PLAN_NAME='Premium' then TRUE else FALSE end as is_premium_plan
from {{ref('stg_users')}} as u 
LEFT JOIN {{ref('stg_subscriptions')}} as s on u.user_id = s.user_id
{{ exchange_rate_join() }}= s.currency
)

SELECT 
subscription_id,
userid as user_id,

first_name,
last_name,
gender,
date_of_birth,
customer_age,

preferred_language,
country,
state,
city,

signup_date,
customer_tenure_days,
account_status,

plan_name,
subscription_price,
currency,
subscription_price_usd,
billing_cycle,

start_date,
end_date,
subscription_duration_days,

auto_renew,
subscription_status,
is_active_subscription,
is_premium_plan

from user_subs
{% if is_incremental() %}

WHERE subscription_id NOT IN (
    SELECT subscription_id
    FROM {{ this }}
)

{% endif %}