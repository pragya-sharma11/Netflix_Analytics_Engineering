-- incremental load
{{config(materialized = 'incremental', UNIQUE_KEY = 'payment_id')}}

Select 
payment_id,        
subscription_id,
user_id,
TO_TIMESTAMP_NTZ(original_due_date / 1000000)::date as original_due_date,
TO_TIMESTAMP_NTZ(payment_date / 1000000)::date as payment_date,
amount,
currency,
payment_method,
payment_status,
payment_failure_reason,
refund_amount,    
renewal_number
from {{ source('main', 'payments') }}
    {% if is_incremental() %}
        where TO_TIMESTAMP_NTZ(payment_date / 1000000)::date >= coalesce((select max(TO_TIMESTAMP_NTZ(payment_date / 1000000)::date) from {{ source('main', 'payments') }}), '1900-01-01'::date)
    {% endif %}
    