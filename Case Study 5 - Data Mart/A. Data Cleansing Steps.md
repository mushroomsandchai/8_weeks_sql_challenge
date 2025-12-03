# A. Data Cleansing Steps
```sql
drop table if exists sales;
create table sales(
    "date" date,
    "week" int,
    "month" int,
    "year" int,
    "region" varchar(13),
    "platform" varchar(7), 
    "segment" varchar(4), 
    "age_band" varchar(12), 
    "demographic" varchar(8),
    "customer_type" varchar(8), 
    "transactions" int, 
    "sales" int, 
    "avg_transaction" float
);
with cleaned as (
    select
        to_date(week_date, 'DD/MM/YY') as date,  -- Added leading zero if needed
        region,
        platform,
        segment,
        customer_type,
        transactions::int,
        sales::int
    from weekly_sales
)
insert into sales
select 
    date,
    ceil(extract(doy from date) / 7) as week,
    extract(month from date) as month,
    extract(year from date) as year,
    region,
    platform,
    segment,
    case right(segment, 1)
        when '1' then 'Young Adults'
        when '2' then 'Middle Aged'
        when '3' then 'Retirees' 
        when '4' then 'Retirees'
        else null
    end as age_band,
    case lower(left(segment, 1))
        when 'c' then 'Couples'
        when 'f' then 'Families'
        else null
    end as demographic,
    case 
        when lower(customer_type) in ('null', 'unknown', '') then null
        else customer_type
    end as customer_type,
    transactions,
    sales,
    round(sales * 1.0 / transactions, 2) as avg_transaction
from cleaned;
```