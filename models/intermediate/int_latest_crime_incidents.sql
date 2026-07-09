/*
If the incident has a resolution - use the latest report that led to Arrest, Exceptional clearance, or unfounded: not 'Open or Active'
If the incident has no resolution - use the latest report

*/

with raw as (
    select *
    from {{ ref('stg_crime_incidents') }}
),
ranked as (
    select *,
    row_number() over (
        partition by incident_number, incident_code
        order by
            case
                when resolution in (
                    'Cite or Arrest Adult',
                    'Exceptional Adult',
                    'Unfounded'
                )
                then 1
                else 0
            end desc,
            report_datetime desc,
            incident_id desc

    ) as rn
    from raw
)

SELECT
    incident_number,
    incident_code,
    incident_datetime,
    report_datetime,
    incident_category,
    incident_subcategory,
    incident_description,
    neighborhood,
    district,
    latitude,
    longitude,
    resolution,
    intersection,
    _loaded_at

FROM ranked
WHERE rn = 1 
