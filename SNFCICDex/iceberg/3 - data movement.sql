CREATE OR REPLACE EXTERNAL VOLUME iceberg_external_volume
   STORAGE_LOCATIONS =
      (
         (
            NAME = 'my-s3-us-west-2'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://bidutch-sf-iceberg/'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::947622342661:role/bidutch-sf-iceberg-role'
            STORAGE_AWS_EXTERNAL_ID = 'bidutch-sf-iceberg-external-id'
         )
      );

DESC EXTERNAL VOLUME iceberg_external_volume;
      
USE ROLE accountadmin;
USE DATABASE iceberg_lab;
USE SCHEMA iceberg_lab;
CREATE OR REPLACE ICEBERG TABLE customer_iceberg (
    c_custkey INTEGER,
    c_name STRING,
    c_address STRING,
    c_nationkey INTEGER,
    c_phone STRING,
    c_acctbal INTEGER,
    c_mktsegment STRING,
    c_comment STRING
)  
    CATALOG='SNOWFLAKE'
    EXTERNAL_VOLUME='iceberg_external_volume'
    BASE_LOCATION='';


   INSERT INTO customer_iceberg
  SELECT * FROM snowflake_sample_data.tpch_sf1.customer;

 USE DATABASE iceberg_lab;
USE SCHEMA iceberg_lab;
CREATE OR REPLACE ICEBERG TABLE order_iceberg (
    O_ORDERKEY INTEGER,
    O_CUSTKEY INTEGER,
    O_ORDERSTATUS STRING,
    O_TOTALPRICE NUMBER (38,2),
    O_ORDERDATE TIMESTAMP,
    O_ORDERPRIORITY STRING,
    O_CLERK STRING,
    O_SHIPPRIORITY NUMBER (38,2),
    O_COMMENT STRING
)  
    CATALOG='SNOWFLAKE'
    EXTERNAL_VOLUME='iceberg_external_volume'
    BASE_LOCATION='';
  
, , , , , , , , 


  SELECT
    n.n_name, avg(c.c_acctbal) acctbal
FROM customer_iceberg c
INNER JOIN snowflake_sample_data.tpch_sf1.nation n
    ON c.c_nationkey = n.n_nationkey
    group by all;



    INSERT INTO order_iceberg
    SELECT
        *
    FROM snowflake_sample_data.tpch_sf1.orders;


SELECT
    count(*) AS after_row_count,
    before_row_count
FROM customer_iceberg
JOIN (
        SELECT count(*) AS before_row_count
        FROM customer_iceberg BEFORE(statement => LAST_QUERY_ID())
    )
    ON 1=1
GROUP BY 2;

select * from order_iceberg;