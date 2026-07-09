{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['incident_number','incident_code']
) }}

select 
base.incident_number,
base.incident_code,
r.resolution_id,
c.offense_id,
dd_incident.date_id as incident_date_id,
dt_incident.time_id as incident_time_id,
dd_report.date_id as report_date_id,
dt_report.time_id as report_time_id,
g.geo_id,
base._loaded_at,
1 as offense_count

from {{ ref('int_latest_crime_incidents') }} base left join {{ ref('dim_offense') }} c --- testing for null dimensions for now
on base.incident_code = c.incident_code 
left join {{ ref('dim_date') }} dd_incident on dd_incident.date_id = cast(strftime(date_trunc('day', base.incident_datetime), '%Y%m%d') as int)
left join {{ ref('dim_time') }} dt_incident on dt_incident.time_id = cast(extract(hour from base.incident_datetime) as int)
left join {{ ref('dim_date') }} dd_report on dd_report.date_id = cast(strftime(date_trunc('day', base.report_datetime), '%Y%m%d') as int)
left join {{ ref('dim_time') }} dt_report on dt_report.time_id = cast(extract(hour from base.report_datetime) as int)
left join {{ ref('dim_geo')}} g
    on base.latitude = g.latitude and base.longitude = g.longitude
    and base.intersection = g.intersection
    and base.district = g.district
    and base.neighborhood = g.neighborhood
left join {{ ref('dim_resolution') }} r on base.resolution = r.resolution