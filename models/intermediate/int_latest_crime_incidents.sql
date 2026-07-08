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
        partition by incidentNumber, incidentCode
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
            reportDatetime desc,
            incidentId desc

    ) as rn
    from raw
)

SELECT
    incidentNumber,
    incidentCode,
    incidentDatetime,
    reportDatetime,
    incidentCategory,
    incidentSubcategory,
    incidentDescription,
    neighborhood,
    district,
    latitude,
    longitude,
    resolution,
    intersection

FROM ranked
WHERE rn = 1 
