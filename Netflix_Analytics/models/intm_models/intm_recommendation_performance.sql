{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='recommendation_id'
) }}

WITH recommendation_logs AS (

    SELECT *
    FROM {{ ref('stg_recommendation_logs') }}

),

content_catalog AS (

    SELECT *
    FROM {{ ref('stg_content_catalog') }}

),

final AS (

SELECT

r.recommendation_id,
r.user_id,
r.content_id,

r.recommendation_timestamp,
CAST(r.recommendation_timestamp AS DATE)        AS recommendation_date,
DATE_TRUNC('MONTH', r.recommendation_timestamp) AS recommendation_month,
YEAR(r.recommendation_timestamp)                AS recommendation_year,

r.recommendation_type,
r.recommendation_rank,
r.recommendation_reason,

r.device,

r.clicked,
r.watch_started,
r.completed,

r.watch_time_seconds,
ROUND(r.watch_time_seconds / 60.0, 2) AS watch_time_minutes,

r.rating,

c.title,
c.content_type,
c.genre,
c.language,
c.release_year,
c.duration_minutes,
c.maturity_rating,
c.imdb_rating,
c.country,
c.director,
c.cast,
c.is_available,

CASE
WHEN c.duration_minutes > 0 THEN
    ROUND((r.watch_time_seconds / (c.duration_minutes * 60.0)) * 100, 2)
END AS watch_completion_pct,

CASE
WHEN r.recommendation_rank <= 5 THEN 'Top 5'
WHEN r.recommendation_rank <= 10 THEN 'Top 10'
ELSE 'Others'
END AS recommendation_position,

IFF(r.clicked, 1, 0)        AS click_flag,
IFF(r.watch_started, 1, 0)  AS watch_started_flag,
IFF(r.completed, 1, 0)      AS completed_flag

FROM recommendation_logs r
LEFT JOIN content_catalog c
ON r.content_id = c.content_id

)

SELECT *
FROM final
{% if is_incremental() %}

WHERE recommendation_id NOT IN (
    SELECT recommendation_id
    FROM {{ this }}
)

{% endif %}