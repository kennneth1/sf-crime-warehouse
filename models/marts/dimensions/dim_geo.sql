{{ config(materialized='table') }}

with distinct_geo as (
    select distinct
        intersection,
        neighborhood,
        district
    from {{ ref('int_latest_crime_incidents') }}
)

--- fct_crime_incidents must join on intersection, neighborhood, district to obtain the proper FK without fan-out
select
    {{ dbt_utils.generate_surrogate_key(['intersection', 'neighborhood', 'district']) }} as geo_id,
    intersection,
    neighborhood,
    district
from distinct_geo