use role public;
select * from snowflake.account_usage.query_history;

use role accountadmin;
grant usage on warehouse compute_wh to role public;
grant monitor on warehouse compute_wh to role public;
revoke imported privileges on database snowflake from role public;
revoke database role snowflake.USAGE_VIEWER from role public;
revoke database role snowflake.GOVERNANCE_VIEWER from role public;
revoke monitor usage on account from role public;

use role accountadmin;
grant imported privileges on database snowflake to role public;
grant database role snowflake.USAGE_VIEWER to role public;
grant database role snowflake.GOVERNANCE_VIEWER to role public;
grant monitor usage on account to role public;
