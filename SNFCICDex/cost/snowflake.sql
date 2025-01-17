-- https://docs.snowflake.com/user-guide/cost-attributing#label-query-cost-attribution

WITH wh_bill AS (
   SELECT SUM(credits_used_compute) AS compute_credits
     FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
     WHERE start_time >= DATE_TRUNC('MONTH', CURRENT_DATE)
     AND start_time < CURRENT_DATE
),
user_credits AS (
   SELECT user_name, SUM(credits_attributed_compute) AS credits
     FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
     WHERE start_time >= DATE_TRUNC('MONTH', CURRENT_DATE)
     AND start_time < CURRENT_DATE
     GROUP BY user_name
),
total_credit AS (
   SELECT SUM(credits) AS sum_all_credits
     FROM user_credits
)
SELECT u.user_name,
       u.credits / t.sum_all_credits * w.compute_credits AS attributed_credits
  FROM user_credits u, total_credit t, wh_bill w
  ORDER BY attributed_credits DESC;