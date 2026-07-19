-- incremental load
{{config(materialized = 'incremental')}}

Select 
user_id,
first_name,
last_name,
email,
phone_number,
date_of_birth,
gender,
country,
state,
city,
preferred_language,
signup_date,
account_status
from {{ source('main', 'users') }}
    {% if is_incremental() %}
        signup_date >= coalesce((select max(signup_date) from {{ this }}), '1900-01-01')
    {% endif %}
    