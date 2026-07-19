{{ config(
materialized='table'
) }}

WITH marketing AS (
SELECT DISTINCT
acquisition_channel,
campaign_type,
device,
country
from {{ ref('stg_marketing_acquisition') }}

),

final AS (

SELECT

-- Surrogate Key
ROW_NUMBER() OVER (
ORDER BY
    acquisition_channel,
    campaign_type,
    device,
    country
) AS marketing_channel_key,

-- Business Attributes
acquisition_channel,
campaign_type,
device,
country,

-- Derived Attributes
CASE
WHEN LOWER(acquisition_channel) IN ('google ads','facebook ads','instagram ads','linkedin ads') THEN 'Paid'
WHEN LOWER(acquisition_channel) IN ('organic search','seo') THEN 'Organic'
WHEN LOWER(acquisition_channel) = 'referral' THEN 'Referral'
WHEN LOWER(acquisition_channel) = 'affiliate' THEN 'Affiliate'
WHEN LOWER(acquisition_channel) = 'email' THEN 'Owned'
ELSE 'Other'
END AS channel_group,

CASE
WHEN LOWER(device) IN ('mobile','android','ios') THEN 'Mobile'
WHEN LOWER(device) = 'web' THEN 'Desktop'
WHEN LOWER(device) = 'tablet' THEN 'Tablet'
WHEN LOWER(device) = 'tv' THEN 'TV'
ELSE 'Other'
END AS device_group,

CURRENT_TIMESTAMP() AS dbt_updated_at

from marketing

)

SELECT *
from final;