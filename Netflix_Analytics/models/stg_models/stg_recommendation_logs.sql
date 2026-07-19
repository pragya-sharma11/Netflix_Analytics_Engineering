-- incremental load
{{config(materialized = 'incremental')}}

Select 
recommendation_id,
    user_id,
    content_id,
    TO_TIMESTAMP_NTZ(recommendation_timestamp/ 1000000)::date as recommendation_timestamp,
    recommendation_type,
    recommendation_rank,
    recommendation_reason,
    device,
    clicked,
    watch_started,
    watch_time_seconds,
    completed,
    rating                 
from {{ source('main', 'recommendation_logs') }}
    {% if is_incremental() %}
        TO_TIMESTAMP_NTZ(recommendation_timestamp/ 1000000)::date >= coalesce((select max(TO_TIMESTAMP_NTZ(recommendation_timestamp/ 1000000)::date) from {{ source('main', 'recommendation_logs') }}), '1900-01-01'::date)
    {% endif %}
    