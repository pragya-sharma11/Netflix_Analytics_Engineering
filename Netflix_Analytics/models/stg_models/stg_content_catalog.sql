-- incremental load
{{config(materialized = 'incremental')}}

Select 
*
from {{ source('main', 'content_catalog') }}
    {% if is_incremental() %}
        DATE_ADDED_TO_PLATFORM >= coalesce((select max(DATE_ADDED_TO_PLATFORM) from {{ this }}), '1900-01-01')
    {% endif %}
    