--https://miguelduarte.medium.com/reduce-your-snowflake-costs-by-accurately-estimating-the-costs-of-each-sql-statement-b65f5143402f
-- clone table
use warehouse benchmark;
create schema if not exists cost.mduarte;
use schema cost.mduarte;
create or replace table query_history_backup as 
select * 
from snowflake.account_usage.query_history 
limit 0;

-- copy the data incrementally
insert into query_history_backup
    select qh.* 
    from snowflake.account_usage.query_history qh
    where qh.end_time > (
        select coalesce(max(end_time), '2000-01-01'::timestamp_ntz) 
        from query_history_backup
    )
    order by start_time;


show warehouses;
create or replace table warehouses as select * from table(result_scan(last_query_id()));

create or replace table warehouse_metering_history_backup as select * from snowflake.account_usage.warehouse_metering_history limit 0;

insert into warehouse_metering_history_backup
    select wmh.* 
    from snowflake.account_usage.warehouse_metering_history wmh
    where wmh.end_time > (
        select coalesce(max(end_time), '2000-01-01'::timestamp_ntz) 
        from warehouse_metering_history_backup
    )
    order by start_time;

    create or replace table warehouse_costs_md as
with wh_etl as (
    select qhb.query_id,
           qhb.query_tag,
           qhb.user_name,
           qhb.role_name,
           qhb.start_time,
           qhb.end_time, 
           min(qhb.start_time) over ( -- see explanation below
                partition by qhb.warehouse_name, qhb.warehouse_size, qhb.cluster_number 
                order by end_time desc 
                rows between unbounded preceding and current row
           ) as min_start,
           qhb.warehouse_name,
           qhb.warehouse_size,
           qhb.warehouse_type,
           qhb.cluster_number,
           qhb.total_elapsed_time,
           qhb.credits_used_cloud_services,
           qhb.query_parameterized_hash,
           w."auto_suspend" as auto_suspend
    from query_history_backup qhb  
         inner join warehouses w     
         on (qhb.warehouse_name = w."name") 
    where warehouse_size is not null -- if warehouse size is null compute costs are 0
),
queries as (
    select criteria,
            match_nr,
            warehouse_name,
            cluster_number,
            warehouse_size,
            warehouse_type
            query_id,
            query_parameterized_hash,
            query_tag,
            user_name,
            role_name,
            start_time,
            end_time,
            min_start,
            active_start,
            active_end,
            activity,
            total_activity,
            credits_used_cloud_services,
            total_elapsed_time,
            billable_time,
            case
                when warehouse_size is null then 0
                else (activity / total_activity) * billable_time end
            as execution_share,
            case when warehouse_type = 'STANDARD' then 1
                 when warehouse_type = 'SNOWPARK-OPTIMIZED' then 1.5
                 else null
            end as cost_multiplier,
            execution_share / 3600 *
            case
                when warehouse_size = 'X-Small'  then 1
                when warehouse_size = 'Small'    then 2
                when warehouse_size = 'Medium'   then 4
                when warehouse_size = 'Large'    then 8
                when warehouse_size = 'X-Large'  then 16
                when warehouse_size = '2X-Large' then 32
                when warehouse_size = '3X-Large' then 64
                when warehouse_size = '4X-Large' then 128
                when warehouse_size = '5X-Large' then 256
                when warehouse_size = '6X-Large' then 512
            else
                null
            end * cost_multiplier as estimated_credits
    from wh_etl match_recognize (
        partition by warehouse_name,warehouse_size, cluster_number
        order by end_time desc
        measures
            final min(min_start) as active_start,
            final max(timestampadd('seconds', auto_suspend, end_time)) as active_end,
            total_elapsed_time as activity,
            final sum(total_elapsed_time) as total_activity,
            match_number() as match_nr,
            classifier as criteria
        all rows per match
        pattern (warehouse_end warehouse_continue*)
        define
            warehouse_end as true,
            warehouse_continue as end_time >= timestampadd(second, -auto_suspend, lag(min_start) )
    ) as matchr, 
    lateral (
        select timestampdiff(second, active_start, active_end) as diff,
               case when warehouse_size is null then 0
                    when diff < 60 then 60
                    else diff end as billable_time
        )
)
select *
from queries
order by start_time;

with compare as (
select time, 
    warehouse_name, 
    sum(query_count) as query_count,
    round(sum(estimated_credits),2) as estimated, 
    round(sum(credits_used_compute),2) as warehouse_metering,
    round(sum(estimated_credits) - sum(credits_used_compute),2)  as diff, 
    case when sum(credits_used_compute) = 0 then null else 
     round((sum(estimated_credits) - sum(credits_used_compute))  / sum(credits_used_compute),2) end
    as relative_diff
from (
select substring(end_time,1,7) as time, warehouse_name, 
       1 as query_count, 
       estimated_credits as estimated_credits, 
       0 as credits_used_compute
from warehouse_costs_md
union all
select substring(end_time,1,7) as time, warehouse_name, 0, 0, credits_used_compute
from warehouse_metering_history_backup
where  end_time between 
             (select min(end_time) from warehouse_costs_md) 
             and 
             (select max(end_time) from warehouse_costs_md)
)
group by 1,2
)
select *
from compare
order by 4 desc;

with top_queries as (
select query_parameterized_hash, 
       count(*) as cnt, 
       sum(estimated_credits) as total_credits, 
       round(sum(estimated_credits) /  (
        select sum(x.estimated_credits)  
        from warehouse_costs_md x 
        where start_time > '2024-01-01')*100,2) as credits_share_pct
from warehouse_costs_md wc 
where start_time > '2024-01-01'
group by 1
order by 3 desc
limit 100
)
select 
       max(cnt) as execution_count,
       max(total_credits) as total_credits,
       max(credits_share_pct) as credits_share_pct,
       max(query_text) as sql_sample
from top_queries tq inner join query_history_backup qh on (tq.query_parameterized_hash = qh.query_parameterized_hash)
where qh.start_time > '2024-01-01'
group by tq.query_parameterized_hash
order by 2 desc;

select substring(start_time, 1, 10) as day, user_name, sum(estimated_credits)
from warehouse_costs_md
where start_time > '2024-01-01'
group by 1,2
order by 1 asc; 