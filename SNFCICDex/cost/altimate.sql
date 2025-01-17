-- https://blog.altimate.ai/bigger-is-faster-and-cheaper-the-surprising-economics-of-snowflake-virtual-warehouses

use role sysadmin;
create warehouse if not exists benchmark;
use warehouse benchmark;
create database if not exists cost;
create schema if not exists cost.altimate;
create table if not exists cost.altimate.store_sales as
select *
from snowflake_sample_data.tpcds_sf10tcl.store_sales;

alter warehouse benchmark suspend;
