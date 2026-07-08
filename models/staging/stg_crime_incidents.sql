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
        strptime("Incident Datetime", '%Y/%m/%d %I:%M:%S %p') as incidentDatetime,
        strptime("Report Datetime", '%Y/%m/%d %I:%M:%S %p') as reportDatetime
    from clean_required
),

-- Standardize incident category strings
clean_category as (
    select
        *,
        trim("Incident Category") as incidentCategoryRaw,  -- keep original for fallback
        lower(trim("Incident Category")) as incidentCategoryNorm  -- lowercase for matching
    from clean_datetime
),

-- map lowercase variants to canonical nice-case names
category_map as (
    select *,
        case
            when incidentCategoryNorm = 'weapons offence' then 'Weapons Offense'
            when incidentCategoryNorm = 'weapons carrying etc' then 'Weapons Carrying'
            when incidentCategoryNorm = 'offences against the family and children' then 'Offences Against the Family and Children'
            when incidentCategoryNorm in ('motor vehicle theft?', 'motor vehicle theif') then 'Motor Vehicle Theft'
            when incidentCategoryNorm in ('suspicious occ', 'suspicious') then 'Suspicious'
            when incidentCategoryNorm like 'human trafficking%' then 'Human Trafficking'
            when incidentCategoryNorm = 'homicide' then 'Homicide'
            when incidentCategoryNorm = 'rape' then 'Rape'
            when incidentCategoryNorm = 'robbery' then 'Robbery'
            when incidentCategoryNorm = 'assault' then 'Assault'
            when incidentCategoryNorm = 'prostitution' then 'Prostitution'
            when incidentCategoryNorm = 'arson' then 'Arson'
            when incidentCategoryNorm = 'burglary' then 'Burglary'
            when incidentCategoryNorm = 'motor vehicle theft' then 'Motor Vehicle Theft'
            when incidentCategoryNorm = 'larceny theft' then 'Larceny Theft'
            when incidentCategoryNorm = 'stolen property' then 'Stolen Property'
            when incidentCategoryNorm = 'malicious mischief' then 'Malicious Mischief'
            when incidentCategoryNorm = 'vandalism' then 'Vandalism'
            when incidentCategoryNorm = 'fraud' then 'Fraud'
            when incidentCategoryNorm = 'embezzlement' then 'Embezzlement'
            when incidentCategoryNorm = 'forgery and counterfeiting' then 'Forgery and Counterfeiting'
            when incidentCategoryNorm in ('drug offense', 'drug violation') then 'Drug Offense'
            when incidentCategoryNorm = 'sex offense' then 'Sex Offense'

            else incidentCategoryRaw
        end as incidentCategory
    from clean_category
)
      
select
    "Incident ID" as incidentId,
    "Incident Number" as incidentNumber,
    "Incident Code" as incidentCode,
    incidentDatetime,
    reportDatetime,
    incidentCategory,
    "Analysis Neighborhood" as neighborhood,
    "Police District" as district,
    Latitude as latitude,
    Longitude as longitude,
    Resolution as resolution,
    "Intersection" as intersection

from category_map