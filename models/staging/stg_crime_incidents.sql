with raw as (
    select *
    from {{ ref('landing') }}
),

-- Drop nulls in required columns and rows outside SF
clean_required as (
    select *
    from raw
    where "Incident Category" is not null
      and Latitude is not null
      and Longitude is not null
      and "Analysis Neighborhood" is not null
      and "Intersection" is not null
      and "Police District" != 'Out of SF'
      and "Incident Number" != '000000000'
),

-- Reformat datetime columns
clean_datetime as (
    select
        *,
        strptime("Incident Datetime", '%Y/%m/%d %I:%M:%S %p') as incident_datetime,
        strptime("Report Datetime", '%Y/%m/%d %I:%M:%S %p') as report_datetime
    from clean_required
),

-- Standardize incident category strings
clean_category as (
    select
        *,
        trim("Incident Category") as incident_category_raw,  -- keep original for fallback
        lower(trim("Incident Category")) as incident_category_norm  -- lowercase for matching
    from clean_datetime
),

-- map lowercase variants to canonical nice-case names
category_map as (
    select *,
        case
            when incident_category_norm = 'weapons offence' then 'Weapons Offense'
            when incident_category_norm = 'weapons carrying etc' then 'Weapons Carrying'
            when incident_category_norm = 'offences against the family and children' then 'Offences Against the Family and Children'
            when incident_category_norm in ('motor vehicle theft?', 'motor vehicle theif') then 'Motor Vehicle Theft'
            when incident_category_norm in ('suspicious occ', 'suspicious') then 'Suspicious'
            when incident_category_norm like 'human trafficking%' then 'Human Trafficking'
            when incident_category_norm = 'homicide' then 'Homicide'
            when incident_category_norm = 'rape' then 'Rape'
            when incident_category_norm = 'robbery' then 'Robbery'
            when incident_category_norm = 'assault' then 'Assault'
            when incident_category_norm = 'prostitution' then 'Prostitution'
            when incident_category_norm = 'arson' then 'Arson'
            when incident_category_norm = 'burglary' then 'Burglary'
            when incident_category_norm = 'motor vehicle theft' then 'Motor Vehicle Theft'
            when incident_category_norm = 'larceny theft' then 'Larceny Theft'
            when incident_category_norm = 'stolen property' then 'Stolen Property'
            when incident_category_norm = 'malicious mischief' then 'Malicious Mischief'
            when incident_category_norm = 'vandalism' then 'Vandalism'
            when incident_category_norm = 'fraud' then 'Fraud'
            when incident_category_norm = 'embezzlement' then 'Embezzlement'
            when incident_category_norm = 'forgery and counterfeiting' then 'Forgery and Counterfeiting'
            when incident_category_norm in ('drug offense', 'drug violation') then 'Drug Offense'
            when incident_category_norm = 'sex offense' then 'Sex Offense'

            else incident_category_raw
        end as incident_category
    from clean_category
)
      
select
    "Incident ID" as incident_id,
    "Incident Number" as incident_number,
    "Incident Code" as incident_code,
    incident_datetime,
    report_datetime,
    incident_category,
    "Incident Subcategory" as incident_subcategory,
    "Incident Description" as incident_description,
    "Analysis Neighborhood" as neighborhood,
    "Police District" as district,
    Latitude as latitude,
    Longitude as longitude,
    Resolution as resolution,
    "Intersection" as intersection,
    current_timestamp as dbt_loaded_at

from category_map