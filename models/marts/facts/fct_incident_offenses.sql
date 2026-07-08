{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['incident_number','incident_code']
) }}

select 
stg.incident_number,
stg.incident_code,
r.resolution_id,
c.offense_id,
dd_incident.date_id as incident_date_id,
dt_incident.time_id as incident_time_id,
dd_report.date_id as report_date_id,
dt_report.time_id as report_time_id,
g.geo_id,
1 as offense_count

from {{ ref('int_latest_crime_incidents') }} stg left join {{ ref('dim_offense') }} c --- testing for null dimensions for now
on stg.incident_code = c.incident_code 
left join {{ ref('dim_date') }} dd_incident on dd_incident.date_id = cast(strftime(date_trunc('day', stg.incident_datetime), '%Y%m%d') as int)
left join {{ ref('dim_time') }} dt_incident on dt_incident.time_id = cast(extract(hour from stg.incident_datetime) as int)
left join {{ ref('dim_date') }} dd_report on dd_report.date_id = cast(strftime(date_trunc('day', stg.report_datetime), '%Y%m%d') as int)
left join {{ ref('dim_time') }} dt_report on dt_report.time_id = cast(extract(hour from stg.report_datetime) as int)
left join {{ ref('dim_geo')}} g
    on stg.latitude = g.latitude and stg.longitude = g.longitude
    and stg.intersection = g.intersection
    and stg.district = g.district
    and stg.neighborhood = g.neighborhood
left join {{ ref('dim_resolution') }} r on stg.resolution = r.resolution