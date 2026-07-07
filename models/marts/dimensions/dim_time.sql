{{ config(materialized='table') }}

with time_spine as (
    select cast(n as integer) as hour
    from (
        select unnest(generate_series(0, 23)) as n
    ) t
),

final as (
    select
        hour,
        case
            when hour between 5 and 11 then 'Morning'
            when hour between 12 and 16 then 'Afternoon'
            when hour between 17 and 20 then 'Evening'
            else 'Night'
        end as time_of_day_bucket
    from time_spine
)

select
    {{ dbt_utils.generate_surrogate_key(['hour']) }} as time_id,
    hour,
    time_of_day_bucket
from final