use warehouse benchmark;
create schema if not exists cost.selectdev;
CREATE OR REPLACE TABLE cost.selectdev.selectdev as
WITH
filtered_queries AS (
    SELECT
        query_id,
        query_text AS original_query_text,

        -- First, we remove comments enclosed by /* <comment text> */
        REGEXP_REPLACE(query_text, '(/\*.*\*/)') AS _cleaned_query_text,
        -- Next, removes single line comments starting with --
        -- and either ending with a new line or end of string
        REGEXP_REPLACE(_cleaned_query_text, '(--.*$)|(--.*\n)') AS cleaned_query_text,
        warehouse_id,
        TIMEADD(
            'millisecond',
            queued_overload_time + compilation_time +
            queued_provisioning_time + queued_repair_time +
            list_external_files_time,
            start_time
        ) AS execution_start_time,
        end_time
    FROM snowflake.account_usage.query_history AS q
    WHERE TRUE
        AND warehouse_size IS NOT NULL
        AND start_time >= DATEADD('day', -30, DATEADD('day', -1, CURRENT_DATE))
),
-- 1 row per hour from 30 days ago until the end of today
hours_list AS (
    SELECT
        DATEADD(
            'hour',
            '-' || row_number() over (order by null),
            DATEADD('day', '+1', CURRENT_DATE)
        ) as hour_start,
        DATEADD('hour', '+1', hour_start) AS hour_end
    FROM TABLE(generator(rowcount => (24*31))) t
),
-- 1 row per hour a query ran
query_hours AS (
    SELECT
        hl.hour_start,
        hl.hour_end,
        queries.*
    FROM hours_list AS hl
    INNER JOIN filtered_queries AS queries
        ON hl.hour_start >= DATE_TRUNC('hour', queries.execution_start_time)
        AND hl.hour_start < queries.end_time
),
query_seconds_per_hour AS (
    SELECT
        *,
        DATEDIFF('millisecond', GREATEST(execution_start_time, hour_start), LEAST(end_time, hour_end)) AS num_milliseconds_query_ran,
        SUM(num_milliseconds_query_ran) OVER (PARTITION BY warehouse_id, hour_start) AS total_query_milliseconds_in_hour,
        num_milliseconds_query_ran/total_query_milliseconds_in_hour AS fraction_of_total_query_time_in_hour,
        hour_start AS hour
    FROM query_hours
),
credits_billed_per_hour AS (
    SELECT
        start_time AS hour,
        warehouse_id,
        credits_used_compute
    FROM snowflake.account_usage.warehouse_metering_history
),
query_cost AS (
    SELECT
        query.*,
        credits.credits_used_compute*2.28 AS actual_warehouse_cost,
        credits.credits_used_compute*fraction_of_total_query_time_in_hour*2.28 AS query_allocated_cost_in_hour
    FROM query_seconds_per_hour AS query
    INNER JOIN credits_billed_per_hour AS credits
        ON query.warehouse_id=credits.warehouse_id
        AND query.hour=credits.hour
),
cost_per_query AS (
    SELECT
        query_id,
        ANY_VALUE(MD5(cleaned_query_text)) AS query_signature,
        SUM(query_allocated_cost_in_hour) AS query_cost,
        ANY_VALUE(original_query_text) AS original_query_text,
        ANY_VALUE(warehouse_id) AS warehouse_id,
        SUM(num_milliseconds_query_ran) / 1000 AS execution_time_s
    FROM query_cost
    GROUP BY 1
)

SELECT
    query_signature,
    COUNT(*) AS num_executions,
    AVG(query_cost) AS avg_cost_per_execution,
    SUM(query_cost) AS total_cost_last_30d,
    ANY_VALUE(original_query_text) AS sample_query_text
FROM cost_per_query
GROUP BY 1;

select * from cost.selectdev.selectdev;