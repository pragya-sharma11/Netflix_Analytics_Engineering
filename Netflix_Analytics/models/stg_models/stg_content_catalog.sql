-- incremental load
{{config(materialized = 'incremental', UNIQUE_KEY = 'content_id')}}

Select 
*
from {{ source('main', 'content_catalog') }}
    {% if is_incremental() %}
        where DATE_ADDED_TO_PLATFORM > coalesce((select max(DATE_ADDED_TO_PLATFORM) from {{ this }}), '1900-01-01')
    {% endif %}
    