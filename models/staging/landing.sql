{{ config(materialized='table') }}

with raw as (
    select *
    from read_csv_auto('sf_crime_incremental_test.csv')
)

select *
from raw