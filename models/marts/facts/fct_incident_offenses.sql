select 
stg.incidentNumber,
stg.incidentCode,
stg.latitude,
stg.longitude,
c.offense_category_id,
dd_incident.date_id as incident_date_id,
dt_incident.time_id as incident_time_id,
dd_report.date_id as report_date_id,
dt_report.time_id as report_time_id,
g.geo_id

from {{ ref('int_latest_crime_incidents') }} stg left join {{ ref('dim_category') }} c --- testing for null dimensions for now
on stg.incidentCategory = c.offenseCategory 
left join {{ ref('dim_date') }} dd_incident on dd_incident.date_id = cast(strftime(date_trunc('day', stg.incidentDatetime), '%Y%m%d') as int)
left join {{ ref('dim_time') }} dt_incident on dt_incident.time_id = cast(extract(hour from stg.incidentDatetime) as int)
left join {{ ref('dim_date') }} dd_report on dd_report.date_id = cast(strftime(date_trunc('day', stg.reportDatetime), '%Y%m%d') as int)
left join {{ ref('dim_time') }} dt_report on dt_report.time_id = cast(extract(hour from stg.reportDatetime) as int)
left join {{ ref('dim_geo')}} g
    on stg.intersection = g.intersection                      
    and stg.neighborhood = g.neighborhood                      
    and stg.district = g.district        

