--AUTHORS
--AMALA RICHU ALBERT AROCKIARAJ 29949270
--RACHANA RAMESH 29905257
--FIT5195 MAJOR ASSIGNMENT
--OLAP QUERIES FOR VERSION 1 AND VERSION 2 SCHEMA


/*------------------------------------------LEVEL 2 AGGREGARION VERSION 1 ----------------------------*/
/* REPORT 1 */

/* WHAT ARE THE TOP 3 Luxurious RENTED properties IN VICTORIA */

select * from rent_fact_l2;

select * from (
select property_type,
state_code,
round(sum(total_rental_fee),2) as Total_rental_Fees,
RANK() OVER (ORDER BY sum(total_rental_fee) desc) as Total_rental_rank
from rent_fact_l2
where state_code = 'VIC'
and category = 'Luxurious'
group by (property_type, state_code))
where Total_rental_rank <= 3;

/* REPORT 2 */

/* IN WHICH MONTHS ARE 50% PROPERTIES ADVERTISED FOR RENT IN 2020 */

SELECT * FROM advertisement_fact_l2;
select * from property_advert_date_dim_l2;
SELECT * FROM (
SELECT PERCENT_RANK () OVER (ORDER BY SUM(Total_Properties) desc) as advert_property_rank,
ad.month
from advertisement_fact_l2 a, property_advert_date_dim_l2 ad
where ad.date_id = a.date_id
group by (a.date_id, ad.month))
where advert_property_rank <=0.5;

/* REPORT 3 */
/* SHOW ALL FEATURES PREFERED BY LOW BUDGET CLIENTS */
SELECT * FROM client_fact_l2;
SELECT * FROM client_wish_dim_l2;
SELECT * FROM feature_dim_l2;

SELECT fd.feature_desc, 
sum(total_clients) as Number_of_clients
from client_fact_l2 cf, client_wish_dim_l2 cw, feature_dim_l2 fd
where cf.client_person_id = cw.client_person_id
and cf.budget_ID = 'LOW'
and cw.feature_code = fd.feature_code
group by (fd.feature_desc)
order by sum(total_Clients) desc;

/************************************************/
/* Report 4 and 5 */
select * from rent_fact_l2;
-- Cube
select suburb, property_type, period_ID, 
    round(sum(Total_rental_fee),2) as Total_Rental_Fees
from rent_fact_l2 
group by cube(suburb, property_type, period_id)
order by suburb;

-- Partial Cube
select suburb, property_type, period_id, 
    round(sum(total_rental_fee),2) as Total_Rental_Fees
from rent_fact_l2 
group by suburb, cube(property_type, period_id)
order by suburb;

/**************************************/
/* Report 6 and 7 */
-- Sub total and total of sales from each statecode VIC and NSW, property type for each year

select * from SALE_FACT_L2;
select * from PROPERTY_DIM_L2;
--ROLL UP
select * from PROPERTY_FEATURE_DIM_L2;

select pd.state_code, s.property_type, s.sale_year, 
    round(sum(total_sales_price),2) as Total_Sales
from sale_fact_l2 s, property_dim_l2 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'NSW')
group by rollup(pd.state_code, s.property_type, s.sale_year)
order by pd.state_code;

-- PARTIAL ROLL UP
select pd.state_code, s.property_type, s.sale_year, 
    round(sum(total_sales_price),2) as Total_Sales
from sale_fact_l2 s, property_dim_l2 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'NSW')
group by pd.state_code, rollup(s.property_type, s.sale_year)
order by pd.state_code;


/* Report 8 - What is the total number of clients and cumulative number of clients
with a high budget in each year? */

select * from client_fact_l2;

select year, sum(total_clients) as Total_Number_of_Clients,
sum(sum(total_clients)) over 
(order by year rows unbounded preceding) as Cumulative_Number_of_Clients
from client_fact_l2
where budget_id like '%HIGH%'
group by (year);

/* Report 9 */
/* total rental fee and cumulative rental fee for each month for different years */
select * from rent_fact_l2;
select * from property_rent_scd_l2;

select to_char(r.rent_start_date,'Month') as Month,
to_char(r.rent_start_date,'YYYY') as Year,
round(sum(Total_Rental_Fee),2) as Total_rental_fees,
round(sum(sum(Total_Rental_Fee)) over
(order by to_char(r.rent_start_date,'Month') rows unbounded preceding),2) 
as Cumulative_rental_fees
from rent_fact_l2 rf, property_rent_scd_l2 r
where rf.property_id = r.property_id
group by (to_char(r.rent_start_date,'Month'),to_char(r.rent_start_date,'YYYY'));

/* Report 10 */
/* Total number of visits and moving aggregate of visits for each day of the week */
select * from visit_fact_l2;
select to_char(v.visit_date, 'Day') as day,
sum(total_visits) as Total_number_of_visits,
round(avg(sum(total_visits)) over
(order by to_char(v.visit_date, 'Day') rows 2 preceding),2) as Moving_Aggregate_of_visits
from client_visit_dim_scd_l2 v, visit_fact_l2
group by to_char(v.visit_date, 'Day');


/* Report 11 */

select * from sale_fact_l2;
select * from property_dim_l2;
-- assumption: total sale is based on total price
select s.property_type, s.sale_year,
sum(Total_sales_price),
rank() over (partition by s.property_type
order by sum(Total_sales_price) desc) as rank_by_property_type,
rank() over (partition by p.state_code
order by sum(Total_sales_price) desc) as rank_by_state
from sale_fact_l2 s, property_dim_l2 p
where s.property_id = p.property_id
group by (s.property_type, s.sale_year, p.state_code);

/* Report 12 */
-- Rank of property scale based on the number of properties rented 

select * from rent_fact_l2;

select property_type, category, scale_id, period_id,
    sum(total_rent) as Total_number_of_rent,
    rank() over (partition by scale_id 
    order by sum(total_rent) desc)as rank_by_scale_type
    from rent_fact_l2
    group by (property_type, category, scale_id, period_id);
    
    
/*----------------------------- LEVEL 0 AGGREGATION VERSION 2------------------------------*/

/* REPORT 1 */

/* WHICH ARE THE TOP 3 LUXURIOUS PROPERPY TYPES IRENTED IN VICTORIA */

select distinct category from RENT_FACT_L0;
select * from (
select r.property_type,
p.state_code,
round(sum("Total Rental Fees"),2) as Total_rental_Fees,
RANK() OVER (ORDER BY sum("Total Rental Fees") desc) as Total_rental_rank
from rent_fact_l0 r, property_dim_l0 p
where p.state_code = 'VIC'
and p.property_id = r.property_id
and category = 'Luxurious'
group by (r.property_type, p.state_code))
where Total_rental_rank <= 3;


/* REPORT 2 */

/* IN WHICH MONTHS ARE 50% PROPERTIES ADVERTISED FOR RENT IN 2020 */
SELECT * FROM ADVERTISEMENT_FACT_L0;
select * from PROPERTY_ADVERT_DATE_DIM_L0;
SELECT * FROM (
SELECT PERCENT_RANK () OVER (ORDER BY SUM(total_properties) desc) as advert_property_rank,
ad.month
from ADVERTISEMENT_FACT_L0 a, PROPERTY_ADVERT_DATE_DIM_L0 ad
where ad.date_id = a.date_id
group by (a.date_id, ad.month))
where advert_property_rank <=0.5;

/* REPORT 3 */

/* SHOW ALL FEATURES PREFERED BY LOW BUDGET CLIENTS */

SELECT * FROM CLIENT_FACT_L0;
SELECT * FROM CLIENT_WISH_DIM_L0;
SELECT * FROM FEATURE_DIM_L0;

SELECT fd.feature_desc, 
sum(TOTAL_CLIENTS) as Number_of_clients
from CLIENT_FACT_L0 cf, CLIENT_WISH_DIM_L0 cw, FEATURE_DIM_L0 fd
where cf.client_person_id = cw.client_person_id
and cf.budget_id = 'LOW'
and cw.feature_code = fd.feature_code
group by (fd.feature_desc)
order by sum(TOTAL_CLIENTS) desc;


/* Report 4 and 5 */
select * from RENT_FACT_L0;
select * from PROPERTY_DIM_L0;
-- Cube
select pd.suburb, r.property_type, r.period_id, 
    round(sum("Total Rental Fees"),2) as Total_Rental_Fees
from RENT_FACT_L0 r, PROPERTY_DIM_L0 pd
where pd.property_id = r.property_id
group by cube(pd.suburb, r.property_type, r.period_id)
order by pd.suburb;

-- Partial Cube
select pd.suburb, r.property_type, r.period_id, 
    round(sum("Total Rental Fees"),2) as Total_Rental_Fees
from RENT_FACT_L0 r, PROPERTY_DIM_L0 pd
where pd.property_id = r.property_id
group by pd.suburb, cube(r.property_type, r.period_id)
order by pd.suburb;


/**************************************/
/* Report 6 and 7 */
-- Sub total and total of sales from each property type for states VIC and NSW for each year

select * from SALE_FACT_L0;
select * from PROPERTY_DIM_L0;
--ROLL UP
select * from PROPERTY_FEATURE_DIM_L0;

select pd.state_code, s.property_type, s.sale_year, 
    round(sum(total_sales_price),2) as Total_Sales
from sale_fact_l0 s, property_dim_l0 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'NSW')
group by rollup(pd.state_code, s.property_type, s.sale_year)
order by pd.state_code;

-- PARTIAL ROLL UP
select pd.state_code, s.property_type, s.sale_year, 
    round(sum(total_sales_price),2) as Total_Sales
from sale_fact_l0 s, property_dim_l0 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'NSW')
group by pd.state_code, rollup(s.property_type, s.sale_year)
order by pd.state_code;


/* Report 8 - What is the total number of clients and cumulative number of clients
with a high budget in each year? */

select * from client_fact_l0;

select year, sum(total_clients) as Total_Number_of_Clients,
sum(sum(total_clients)) over 
(order by year rows unbounded preceding) as Cumulative_Number_of_Clients
from client_fact_l0
where budget_ID like '%HIGH%'
group by (year);

/* Report 9 */

/* total rental fee and cumulative rental fee for each month for different years */
select * from rent_fact_l0;
select * from RENT_PROPERTY_SCD_DIM_L0;

select to_char(r.rent_start_date,'Month') as Month,
to_char(r.rent_start_date,'YYYY') as Year,
round(sum("Total Rental Fees"),2) as Total_rental_fees,
round(sum(sum("Total Rental Fees")) over
(order by to_char(r.rent_start_date,'Month') rows unbounded preceding),2) 
as Cumulative_rental_fees
from rent_fact_l0 rf, RENT_PROPERTY_SCD_DIM_L0 r
where rf.property_id = r.property_id
group by (to_char(r.rent_start_date,'Month'),to_char(r.rent_start_date,'YYYY'));


/* Report 10 */
/* Total number of visits and moving aggregate of visits for each day of the week */
select to_char(v.visit_date, 'Day') as day,
sum(total_visits) as Total_number_of_visits,
round(avg(sum(total_visits)) over
(order by to_char(v.visit_date, 'Day') rows 2 preceding),2) as Moving_Aggregate_of_visits
from client_visit_dim_scd_l0 v, visit_fact_l0
group by to_char(v.visit_date, 'Day');


/* Report 11 */

select * from sale_fact_l0;
-- assumption: total sale is based on total price
select s.property_type, s.sale_year,
sum(Total_sales_price),
rank() over (partition by s.property_type
order by sum(Total_sales_price) desc) as rank_by_property_type,
rank() over (partition by p.state_code
order by sum(Total_sales_price) desc) as rank_by_state
from sale_fact_l0 s, property_dim_l0 p
where s.property_id = p.property_id
group by (s.property_type, s.sale_year, p.state_code);

/* Report 12 */

select * from rent_fact_l0;

-- Rank of property scale based on the number of properties rented 

select * from rent_fact_l0;

select property_type, category, scale_id, period_id,
    sum("Total Number of Rent") as Total_number_of_rent,
    rank() over (partition by scale_id 
    order by sum("Total Number of Rent") desc)as rank_by_scale_type
    from rent_fact_l0
    group by (property_type, category, scale_id, period_id);
