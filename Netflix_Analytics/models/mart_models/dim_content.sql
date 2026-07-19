{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='content_id'
) }}

WITH content AS (
SELECT * FROM {{ ref('stg_content_catalog') }}
),

final AS (
SELECT
-- Business Key
content_id,
{{ dbt_utils.generate_surrogate_key(
    ['content_id']
) }} as content_key,
-- Basic Content Information
title,
content_type,
genre,
language,

-- Release Information
release_year,
date_added_to_platform,

-- Content Attributes
duration_minutes,
maturity_rating,
imdb_rating,
country,
director,
cast,
is_available,

-- Derived Columns
CASE
WHEN duration_minutes < 30 THEN 'Short'
WHEN duration_minutes < 90 THEN 'Medium'
WHEN duration_minutes < 150 THEN 'Long'
ELSE 'Very Long'
END AS duration_bucket,

CASE
WHEN imdb_rating >= 8.5 THEN 'Excellent'
WHEN imdb_rating >= 7.5 THEN 'Very Good'
WHEN imdb_rating >= 6.5 THEN 'Good'
WHEN imdb_rating >= 5.5 THEN 'Average'
ELSE 'Below Average'
END AS imdb_rating_category,

CASE
WHEN release_year >= YEAR(CURRENT_DATE()) - 1 THEN 'New Release'
WHEN release_year >= YEAR(CURRENT_DATE()) - 5 THEN 'Recent'
WHEN release_year >= YEAR(CURRENT_DATE()) - 15 THEN 'Modern'
ELSE 'Classic'
END AS content_age_category,

CASE
WHEN content_type = 'Movie' THEN 1
ELSE 0
END AS is_movie,

CASE WHEN content_type = 'TV Show' THEN 1 ELSE 0 END AS is_tv_show,
CURRENT_TIMESTAMP() AS dbt_updated_at
from content
)

SELECT *
from final;