/* TODO: Implement once fct tables grow too large
{{ config(
    materialized='incremental',
    unique_key='incident_id'
) }}
*/

select 
stg.incidentNumber,
stg.latitude,
stg.longitude,
c.category_id

from {{ ref('stg_crime_incidents') }} stg left join {{ ref('dim_category') }} c --- testing for null dimensions for now
on stg.incidentCategory = c.incidentCategory 

/* left join {{ ref('dim_date') }} d 
left join {{ ref('dim_date') }} dd_incident on dd_incident.date_id = cast(strftime(date_trunc('day', stg.incidentDatetime), '%Y%m%d') as int)
left join {{ ref('dim_time') }} dt_incident on dt_incident.time_id = cast(extract(hour from stg.incidentDatetime) as int)
left join {{ ref('dim_date') }} dd_report on dd_report.date_id = cast(strftime(date_trunc('day', stg.reportDatetime), '%Y%m%d') as int)
left join {{ ref('dim_time') }} dt_report on dt_report.time_id = dt_report.time_id = cast(extract(hour from stg.reportDatetime) as int)

    on stg.intersection = g.intersection                      
    and stg.neighborhood = g.neighborhood                      
    and stg.district = g.district        

*/