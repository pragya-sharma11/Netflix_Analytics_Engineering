{{ config(
    materialized='incremental',
    unique_key='user_id'
) }}

SELECT
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
FROM {{ source('main', 'users') }}

{% if is_incremental() %}
WHERE signup_date >
(
    SELECT MAX(signup_date)
    FROM {{ this }}
)
{% endif %}