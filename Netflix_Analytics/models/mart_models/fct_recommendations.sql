{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='recommendation_id'
) }}

WITH recommendations AS (
SELECT * FROM {{ ref('intm_recommendation_performance') }}
),

content AS (
SELECT
content_id,
content_key
FROM {{ ref('dim_content') }}
),

dates AS (

SELECT
date_key,
full_date
FROM {{ ref('dim_date') }}
),

final AS (

SELECT

-- Business Keys
r.recommendation_id,
r.user_id,

-- Dimension Keys
c.content_key,

d.date_key AS recommendation_date_key,

-- Recommendation Information
r.recommendation_type,
r.recommendation_rank,
r.recommendation_reason,
r.recommendation_position,

-- Measures
r.watch_time_seconds,
r.watch_time_minutes,
r.watch_completion_pct,
r.rating,

-- KPI Flags
r.click_flag,
r.watch_started_flag,
r.completed_flag,

-- Audit
CURRENT_TIMESTAMP() AS dbt_updated_at

FROM recommendations r

LEFT JOIN content c
ON r.content_id = c.content_id

LEFT JOIN dates d
ON r.recommendation_date = d.full_date

)

SELECT *
FROM final