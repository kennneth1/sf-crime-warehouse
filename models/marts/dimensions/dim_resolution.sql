{{ config(materialized='table') }}

with raw as (
    select distinct resolution
    from {{ ref('int_latest_crime_incidents') }}
    where resolution is not null
)

select
    row_number() over (order by resolution) as resolution_id,
    resolution


