{{ config(materialized='table') }}

with distinct_geo as (
    select distinct
        intersection,
        neighborhood,
        district,
        latitude,
        longitude
    from {{ ref('int_latest_crime_incidents') }}
)

select
    {{ dbt_utils.generate_surrogate_key([
        'latitude',
        'longitude',
        'intersection',
        'neighborhood',
        'district'
    ]) }} as geo_id,
    intersection,
    neighborhood,
    district,
    latitude,
    longitude
from distinct_geo


