-- incremental load
{{config(materialized = 'incremental')}}

Select 
*
from {{ source('main', 'subscriptions') }}
    {% if is_incremental() %}
        where START_DATE >= coalesce((select max(START_DATE) from {{ this }}), '1900-01-01'::date)
    {% endif %}
    