{{ config(
    materialized='incremental',
    unique_key='payment_id',
    incremental_strategy='merge'
) }}


with payments as (
SELECT
p.*,
ex.exchange_rates as exchange_rate_to_usd,
round(coalesce(ex.exchange_rates,1) * p.amount, 4) as amount_usd,
round(coalesce(ex.exchange_rates,1) * p.refund_amount, 4) as refund_amount_usd,
round(coalesce(ex.exchange_rates,1) * (coalesce(p.amount,0) - coalesce(p.refund_amount,0)), 4) as net_revenue_usd,
DATEDIFF(day, original_due_date, payment_date) as payment_delay_days,
case when p.payment_status='SUCCESS' then 1 else 0 end as is_successful_payment,
case when p.payment_status='FAILED' then 1 else 0 end as is_failed_payment,
case when p.refund_amount > 0 then 1 else 0 end as is_refunded,
DATE_TRUNC('month', p.payment_date) as payment_month,
YEAR(p.payment_date) as payment_year,
QUARTER(p.payment_date) as payment_quarter,
CAST(p.payment_date AS DATE) as payment_day,
s.plan_name,
s.billing_cycle
from {{ref('stg_payments')}} as p 
LEFT JOIN {{ref('stg_subscriptions')}} as s on s.subscription_id = p.subscription_id
{{ exchange_rate_join() }}= p.currency
)
SELECT

payment_id             ,
subscription_id        ,
user_id                ,
original_due_date      ,
payment_date           ,
payment_day            ,
payment_month          ,
payment_quarter        ,
payment_year           ,
renewal_number         ,
payment_status         ,
payment_method         ,
payment_failure_reason ,
amount                 ,
currency               ,
exchange_rate_to_usd   ,
amount_usd             ,
refund_amount          ,
refund_amount_usd      ,
net_revenue_usd        ,
payment_delay_days     ,
is_successful_payment  ,
is_failed_payment      ,
is_refunded            ,
plan_name              ,
billing_cycle          ,

from payments
{% if is_incremental() %}

WHERE payment_id NOT IN (
    SELECT payment_id
    FROM {{ this }}
)

{% endif %}