{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='recommendation_id'
) }}

WITH 
recommendations AS ( SELECT * FROM {{ ref('fct_recommendations') }} ),

payments AS ( SELECT * FROM {{ ref('fct_payments') }} ),

subscriptions AS ( SELECT * FROM {{ ref('fct_subscriptions') }} ),

acquisition AS ( SELECT * FROM {{ ref('fct_customer_acquisition') }} ),

users AS ( SELECT * FROM {{ ref('dim_users') }} ),

content AS ( SELECT * FROM {{ ref('dim_content') }} ),

plans AS ( SELECT * FROM {{ ref('dim_subscription_plan') }} ),

marketing AS ( SELECT * FROM {{ ref('dim_marketing_channel') }} ),

recommendation_dates AS ( SELECT date_key, full_date FROM {{ ref('dim_date') }}),

payment_dates AS ( SELECT date_key, full_date FROM {{ ref('dim_date') }} ),

final AS (

SELECT

-- User
u.user_id,
u.first_name,
u.last_name,
u.gender,
u.customer_age,
u.country,
u.state,
u.city,
u.preferred_language,
u.signup_date,
u.account_status,
u.customer_segment,

-- Subscription
s.subscription_id,
s.subscription_status,
s.auto_renew,
s.subscription_duration_days,

p.plan_name,
p.plan_tier,
p.billing_cycle,
p.subscription_price,
p.annualized_price,

-- Payment
fp.payment_id,

pd.full_date AS payment_date,

fp.amount,
fp.currency,
fp.amount_usd,

fp.refund_amount,
fp.refund_amount_usd,

fp.net_revenue_usd,

fp.payment_status,
fp.payment_method,

fp.payment_delay_days,

fp.is_successful_payment,
fp.is_failed_payment,
fp.is_refunded,

-- Marketing
fa.acquisition_id,

m.acquisition_channel,
m.channel_group,

m.campaign_type,
m.device,
m.device_group,

fa.campaign_cost,
fa.signup_delay_days,

-- Recommendation
fr.recommendation_id,

rd.full_date AS recommendation_date,

fr.recommendation_type,
fr.recommendation_rank,
fr.recommendation_reason,
fr.recommendation_position,

fr.click_flag,
fr.watch_started_flag,
fr.completed_flag,

fr.watch_time_seconds,
fr.watch_completion_pct,
fr.rating,

-- Content
c.content_id,
c.title,
c.content_type,
c.genre,
c.language,
c.release_year,
c.duration_minutes,
c.imdb_rating,
c.country AS content_country,
c.director,
c.cast,

c.duration_bucket,
c.imdb_rating_category,
c.content_age_category,

-- Audit
CURRENT_TIMESTAMP() AS dbt_updated_at

FROM recommendations fr

LEFT JOIN users u
ON fr.user_id = u.user_id

LEFT JOIN content c
ON fr.content_key = c.content_key

LEFT JOIN payments fp
ON fr.user_id = fp.user_id

LEFT JOIN subscriptions s
ON fp.subscription_id = s.subscription_id

LEFT JOIN plans p
ON fp.plan_key = p.plan_key

LEFT JOIN acquisition fa
ON fr.user_id = fa.user_id

LEFT JOIN marketing m
ON fa.marketing_channel_key = m.marketing_channel_key

LEFT JOIN recommendation_dates rd
ON fr.recommendation_date_key = rd.date_key

LEFT JOIN payment_dates pd
ON fp.payment_date_key = pd.date_key

)

SELECT * FROM final