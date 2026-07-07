with raw as (
    select *
    from {{ ref('stg_crime_incidents') }}
),


/*
If the incident has a resolution - use the latest report that led to Arrest, Exceptional clearance, or unfounded: not 'Open or Active'
If the incident has no resolution - use the latest report

*/




