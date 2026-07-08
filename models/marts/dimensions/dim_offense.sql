{{ config(materialized='table') }}

with raw as (
    select distinct incident_code, incident_category, incident_subcategory, incident_description
    from {{ ref('int_latest_crime_incidents') }}
),
categorized as (
    select *,
        case 
            when incident_category in (
                'Homicide','Robbery','Assault','Prostitution','Offences Against the Family and Children',
                'Weapons Carrying','Weapons Offense'
            ) or incident_category like 'Human Trafficking%' then 'Violent'
            when incident_category in ('Arson','Burglary','Motor Vehicle Theft','Larceny Theft','Stolen Property','Malicious Mischief','Vandalism') then 'Property'
            when incident_category in ('Rape','Sex Offense') then 'Sexual'
            when incident_category in ('Fraud','Embezzlement','Forgery and Counterfeiting') then 'Fiscal/Fraud'
            when incident_category = 'Drug Offense' then 'Drug'
            else 'Other'
        end as incident_category_broad,
        case incident_category
            when 'Homicide' then 1
            when 'Rape' then 2
            when 'Sex Offense' then 3
            when 'Robbery' then 4
            when 'Human Trafficking' then 5
            when 'Assault' then 6
            when 'Prostitution' then 7
            when 'Offences Against the Family and Children' then 8
            when 'Arson' then 9
            when 'Burglary' then 10
            when 'Motor Vehicle Theft' then 11
            when 'Larceny Theft' then 12
            when 'Stolen Property' then 13
            when 'Malicious Mischief' then 14
            when 'Vandalism' then 15
            when 'Fraud' then 16
            when 'Embezzlement' then 17
            when 'Forgery and Counterfeiting' then 18
            when 'Drug Offense' then 19
            when 'Weapons Carrying' then 20
            when 'Weapons Offense' then 21
        end as severity_rank
    from raw
)

select   
{{ dbt_utils.generate_surrogate_key(['incident_code']) }} as offense_id,
incident_code,
incident_category as offense_category,
incident_category_broad as offense_category_broad,
incident_subcategory as offense_subcategory,
incident_description as offense_description,
severity_rank 
from categorized


