{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='payment_id'
) }}

WITH payment_revenue AS (
SELECT * FROM {{ ref('intm_payments_revenue') }}
),

subscription_plan AS (
SELECT
plan_key,
plan_name,
billing_cycle,
subscription_price,
currency
FROM {{ ref('dim_subscription_plan') }}

),

payment_date AS (
SELECT
date_key,
full_date
FROM {{ ref('dim_date') }}
),

due_date AS (
SELECT
date_key,
full_date
FROM {{ ref('dim_date') }}
),

final AS (

SELECT
-- Business Keys
p.payment_id,
p.subscription_id,
p.user_id,

-- Dimension Keys
sp.plan_key,

pd.date_key AS payment_date_key,

dd.date_key AS due_date_key,

-- Measures
p.amount,
p.currency,
p.amount_usd,

p.refund_amount,
p.refund_amount_usd,

p.net_revenue_usd,

-- Payment Details
p.payment_status,
p.payment_method,
p.payment_failure_reason,

p.renewal_number,

-- KPIs
p.payment_delay_days,

p.is_successful_payment,
p.is_failed_payment,
p.is_refunded,

-- Audit
CURRENT_TIMESTAMP() AS dbt_updated_at

FROM payment_revenue p

LEFT JOIN subscription_plan sp
ON p.plan_name = sp.plan_name
AND p.billing_cycle = sp.billing_cycle

LEFT JOIN payment_date pd
ON p.payment_date = pd.full_date

LEFT JOIN due_date dd
ON p.original_due_date = dd.full_date

)

SELECT *
FROM final