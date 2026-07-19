-- incremental load
{{config(materialized = 'incremental')}}

Select 
*
from {{ source('main', 'marketing_acquisition') }}
    {% if is_incremental() %}
        where ACQUISITION_DATE >= coalesce((select max(ACQUISITION_DATE) from {{ this }}), '1900-01-01'::date)
    {% endif %}
    