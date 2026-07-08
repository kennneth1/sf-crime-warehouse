{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2015-01-01' as date)",
        end_date="cast('2030-12-31' as date)"
    ) }}
),

final as (
    select
        date_day as calendar_date,
        extract(year from date_day) as year,
        extract(month from date_day) as month,
        strftime(date_day, '%B') as month_name,
        extract(week from date_day) as week,
        strftime(date_day, '%A') as day_of_week,

        case
            when extract(dow from date_day) in (0, 6) then true
            else false
        end as is_weekend,

        'Q' || extract(quarter from date_day) as quarter,

        date_trunc(
            'day',
            date_day + (6 - extract(dow from date_day)) * interval '1 day' 
        )::date as week_ending

    from date_spine
),

final_with_label as (
    select
        *,
        'Week ending ' || strftime(week_ending, '%Y-%m-%d') as week_ending_label
    from final
)

select
    cast(strftime(calendar_date, '%Y%m%d') as int) as date_id,
    calendar_date,
    year,
    month,
    month_name,
    week,
    day_of_week,
    is_weekend,
    quarter,
    week_ending,
    week_ending_label
from final_with_label