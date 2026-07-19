---------------------------------------------------------------------------------------
-- create DB
---------------------------------------------------------------------------------------
Create or replace DATABASE NETFLIX;

---------------------------------------------------------------------------------------
-- create Schema
---------------------------------------------------------------------------------------
CREATE or REPLACE SCHEMA NETFLIX.MAIN;

---------------------------------------------------------------------------------------
-- create stage
---------------------------------------------------------------------------------------
create or replace stage netflix_stage
url = 's3://<bucket>'
CREDENTIALS=(aws_key_id = <aws_key>, aws_secret_key = <aws_secret>);

-- validate stage
show stages;
list @netflix_stage;

---------------------------------------------------------------------------------------
-- Create Tables
---------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE USERS (
    user_id                 VARCHAR NOT NULL,
    first_name              VARCHAR,
    last_name               VARCHAR,
    email                   VARCHAR,
    phone_number            VARCHAR,
    date_of_birth           DATE,
    gender                  VARCHAR,
    country                 VARCHAR,
    state                   VARCHAR,
    city                    VARCHAR,
    preferred_language      VARCHAR,
    signup_date             DATE,
    account_status          VARCHAR,

    CONSTRAINT PK_USERS PRIMARY KEY (user_id)

);

CREATE OR REPLACE TABLE CONTENT_CATALOG (

    content_id                  VARCHAR NOT NULL,
    title                       VARCHAR,
    content_type                VARCHAR,
    genre                       VARCHAR,
    language                    VARCHAR,
    release_year                NUMBER(4,0),
    duration_minutes            NUMBER(5,0),
    maturity_rating             VARCHAR,
    imdb_rating                 NUMBER(3,1),
    country                     VARCHAR,
    director                    VARCHAR,
    cast                        VARCHAR,
    date_added_to_platform      DATE,
    is_available                BOOLEAN,

    CONSTRAINT PK_CONTENT PRIMARY KEY (content_id)

);
DROP Table SUBSCRIPTIONS;
CREATE OR REPLACE TABLE SUBSCRIPTIONS (

    subscription_id         VARCHAR NOT NULL,
    user_id                 VARCHAR,
    plan_name               VARCHAR,
    subscription_price      NUMBER(10,2),
    currency                VARCHAR,
    billing_cycle           VARCHAR,
    start_date              Date,
    end_date                Date,
    auto_renew              BOOLEAN,
    subscription_status     VARCHAR,

    CONSTRAINT PK_SUBSCRIPTIONS PRIMARY KEY (subscription_id)

);

CREATE OR REPLACE TABLE PAYMENTS (

    payment_id                  VARCHAR NOT NULL,
    subscription_id             VARCHAR,
    user_id                     VARCHAR,
    original_due_date           BIGINT,
    payment_date                BIGINT,
    amount                      NUMBER(10,2),
    currency                    VARCHAR,
    payment_method              VARCHAR,
    payment_status              VARCHAR,
    payment_failure_reason      VARCHAR,
    refund_amount               NUMBER(10,2),
    renewal_number              NUMBER(4,0),

    CONSTRAINT PK_PAYMENTS PRIMARY KEY (payment_id)

);

CREATE OR REPLACE TABLE MARKETING_ACQUISITION (

    acquisition_id          VARCHAR NOT NULL,
    user_id                 VARCHAR,
    acquisition_date        DATE,
    acquisition_channel     VARCHAR,
    campaign_type           VARCHAR,
    campaign_cost           NUMBER(10,2),
    device                  VARCHAR,
    country                 VARCHAR,

    CONSTRAINT PK_MARKETING PRIMARY KEY (acquisition_id)

);

CREATE OR REPLACE TABLE RECOMMENDATION_LOGS (

    recommendation_id           VARCHAR NOT NULL,
    user_id                     VARCHAR,
    content_id                  VARCHAR,
    recommendation_timestamp    BIGINT,
    recommendation_type         VARCHAR,
    recommendation_rank         NUMBER(2,0),
    recommendation_reason       VARCHAR,
    device                      VARCHAR,
    clicked                     BOOLEAN,
    watch_started               BOOLEAN,
    watch_time_seconds          NUMBER(8,0),
    completed                   BOOLEAN,
    rating                      NUMBER(2,0),

    CONSTRAINT PK_RECOMMENDATIONS PRIMARY KEY (recommendation_id)

);

CREATE OR REPLACE TABLE US_EXCHANGE_RATES (

    CURRENCY           VARCHAR NOT NULL,
    EXCHANGE_RATES      DOUBLE,

    CONSTRAINT PK_CURRENCY PRIMARY KEY (CURRENCY)

);


---------------------------------------------------------------------------------------
-- FILE FORMATS
---------------------------------------------------------------------------------------
CREATE OR REPLACE FILE FORMAT PARQUET_FORMAT
TYPE = PARQUET;
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
TYPE = CSV
FIELD_OPTIONALLY_ENCLOSED_BY='"'
SKIP_HEADER = 1;
---------------------------------------------------------------------------------------
-- copy data from stage files to tables
---------------------------------------------------------------------------------------
copy into NETFLIX.MAIN.USERS from @NETFLIX.MAIN.NETFLIX_STAGE
file_format= (FORMAT_NAME = CSV_FORMAT)
files = ('users.csv');
copy into NETFLIX.MAIN.CONTENT_CATALOG from @NETFLIX.MAIN.NETFLIX_STAGE
file_format= (FORMAT_NAME = PARQUET_FORMAT)
files = ('content_catalog.parquet')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
copy into NETFLIX.MAIN.SUBSCRIPTIONS from @NETFLIX.MAIN.NETFLIX_STAGE
file_format= (FORMAT_NAME = PARQUET_FORMAT)
files = ('subscriptions.parquet')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
copy into NETFLIX.MAIN.PAYMENTS from @NETFLIX.MAIN.NETFLIX_STAGE
file_format= (FORMAT_NAME = PARQUET_FORMAT)
files = ('payments.parquet')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
copy into NETFLIX.MAIN.MARKETING_ACQUISITION from @NETFLIX.MAIN.NETFLIX_STAGE
file_format= (FORMAT_NAME = PARQUET_FORMAT)
files = ('marketing_acquisition.parquet')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
copy into NETFLIX.MAIN.RECOMMENDATION_LOGS from @NETFLIX.MAIN.NETFLIX_STAGE
file_format= (FORMAT_NAME = PARQUET_FORMAT)
files = ('recommendation_logs.parquet')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
copy into NETFLIX.MAIN.US_EXCHANGE_RATES from @NETFLIX.MAIN.NETFLIX_STAGE
file_format= (FORMAT_NAME = PARQUET_FORMAT)
files = ('us_exchange_rates.parquet')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

---------------------------------------------------------------------------------------
-- Validate Data Load
---------------------------------------------------------------------------------------
Select * from NETFLIX.MAIN.USERS limit 10;
Select * from NETFLIX.MAIN.CONTENT_CATALOG limit 10;
Select * from NETFLIX.MAIN.SUBSCRIPTIONS limit 10;
Select * from NETFLIX.MAIN.PAYMENTS limit 10;
Select * from NETFLIX.MAIN.MARKETING_ACQUISITION limit 10;
Select * from NETFLIX.MAIN.RECOMMENDATION_LOGS limit 1000;
SELECT * from NETFLIX.MAIN.US_EXCHANGE_RATES ;
desc table NETFLIX.MAIN.RECOMMENDATION_LOGS;
select TO_TIMESTAMP_NTZ(recommendation_timestamp / 1000000) from NETFLIX.MAIN.RECOMMENDATION_LOGS limit 10;

select 
TO_TIMESTAMP_NTZ(ORIGINAL_DUE_DATE / 1000000) as due_date, 
TO_TIMESTAMP_NTZ(PAYMENT_DATE / 1000000) as due_date,
from NETFLIX.MAIN.PAYMENTS limit 10;

select distinct currency from payments;


SELECT
    *
FROM @NETFLIX.MAIN.NETFLIX_STAGE/payments.parquet
(FILE_FORMAT => 'PARQUET_FORMAT')
LIMIT 10;


---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------