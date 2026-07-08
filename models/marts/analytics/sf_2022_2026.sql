select
f.incident_number,
f.incident_code,
f.offense_count,
id.calendar_date as incident_date,
id.week_ending,
id.week_ending_label,
it.time_of_day_bucket,
rd.calendar_date as report_date,
c.severity_rank,
c.offense_broad,
g.district,
g.intersection,
g.neighborhood,
g.latitude,
g.longitude,
r.resolution


from fct_incident_offenses f
join dim_date id on f.incident_date_id = id.date_id
join dim_date rd on f.report_date_id = rd.date_id
join dim_time it on f.incident_time_id = it.time_id
join dim_offense c on f.offense_id = c.offense_id
join dim_geo g on f.geo_id = g.geo_id
join dim_resolution r on f.resolution_id = r.resolution_id

where id.year>=2022 and c.offense_broad != 'Other'
order by f.incident_number, f.incident_code, rd.calendar_date