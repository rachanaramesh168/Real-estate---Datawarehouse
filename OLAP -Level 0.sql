/* REPORT 1 */
/* WHICH ARE THE TOP 10 RAYWHITE OFFICES BASED ON GENDER COUNT FOR EACH GENDER*/
/********* DIN & ARSH */

SELECT * FROM agent_info_dim_l0;

select * from (
select dense_rank() over (order by a.gender desc) as default_Rank,
o.office_name,count(a.gender) as Gender_Count,
a.gender from agent_fact_l0 a, 
agent_office_bridge_dim_l0 ao, office_dim_l0 o, property_dim_l0 p
WHERE a.person_id = ao.person_id
AND ao.office_id = o.office_id
AND p.property_id = a.property_id
AND o.office_name Like '%Ray White%'
group by ( o.office_name,a.gender,p.state_code)
having p.state_code='VIC') 
where default_Rank <=10;

/* which ARE THE TOP 5 Luxurious RENTED IN VICTORIA */
/************ AMALA & RACH  */
/* Knowing the top 5 luxurious property types will help in understanding 
which property types are mostly preferred and could potentially help in planning the city 
by building most preferred houses*/
select distinct category from rent_fact_l0;
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

/* WHO ARE THE TOP 10 MALE AGENTS IN VICTORIA */
/******* PRADDY AND KICHU */

SELECT * FROM agent_fact_l0;
select * from agent_info_dim_l0;

SELECT * FROM (
SELECT a.PERSON_ID, a.GENDER, "Agent Name", sum("Total Worth") as "Total_worth",
RANK() OVER (ORDER BY SUM("Total Worth") desc) as total_worth_rank
from agent_fact_l0 a, property_dim_l0 p, agent_info_dim_l0 ai
where a.property_id = p.property_id
and p.state_code = 'VIC'
and a.gender = 'Male'
group by (a.PERSON_ID, a.GENDER, "Agent Name"))
where total_worth_rank <= 10;

/* REPORT 2 */
---------------Top 50% of the Average Salary of Raywhite agents in Victoria based on office name
/********** DIN & ARSH */
select * from (
select percent_rank() over (order by avg("Total Salary") desc) as default_Rank,
o.office_name,round(avg("Total Salary"),2) as Average_Salary from agent_fact_l0 a,
agent_info_dim_l0 ai, agent_office_bridge_dim_l0 ao, office_dim_l0 o, property_dim_l0 p 
WHERE a.person_id = ai.person_id
AND ai.person_id = ao.person_id
AND ao.office_id = o.office_id
AND p.property_id = a.property_id
AND o.office_name Like '%Ray White%'
group by( o.office_name,a.gender,p.state_code)
having p.state_code='VIC') 
where default_Rank <=0.5;

/* WHAT IS THE TOP 50% OF PROPERTIES RENTED IN VICTORIA BASED ON PROPERTY TYPE
 BASED ON THE NUMBER OF PROPERTIES IN EACH PROPERTY TYPE*/
 /******* praddy and kichu **/

select * from property_dim_l0;
select * from rent_fact_l0;
select * from (
select percent_rank() over (order by count("Total Number of Rent")desc) as property_rank,
p.state_code,
r.property_type
from rent_fact_l0 r, property_dim_l0 p
where p.property_id = r.property_id
and p.state_code = 'VIC'
group by (p.state_code,r.property_type))
where property_rank <=0.50;

/* IN WHICH MONTHS ARE 50% PROPERTIES ADVERTISED FOR RENT IN 2020 */
SELECT * FROM advertisement_fact_l0;
select * from advert_date_dim_l0;
SELECT * FROM (
SELECT PERCENT_RANK () OVER (ORDER BY SUM("Total number of Properties") desc) as advert_property_rank,
ad.month
from advertisement_fact_l0 a, advert_date_dim_l0 ad
where ad.date_id = a.date_id
group by (a.date_id, ad.month))
where advert_property_rank <=0.5;

/* REPORT 3 */
/* SHOW ALL FEATURES PREFERED BY LOW BUDGET CLIENTS */
/* Amala and Rachu */
SELECT * FROM client_fact_l0;
SELECT * FROM client_wishlist_dim_l0;
SELECT * FROM feature_dim_l0;

SELECT fd.feature_description, 
sum("Number of Clients") as Number_of_clients
from client_fact_l0 cf, client_wishlist_dim_l0 cw, feature_dim_l0 fd
where cf.person_id = cw.person_id
and cf.budget_type = 'Low'
and cw.feature_code = fd.feature_code
group by (fd.feature_description)
order by sum("Number of Clients") desc;

/*what is the total number of properties advertised for sale 
based on advertisement name */
/***** Praddy and kichu */
select * from advertisement_fact_l0;
select * from property_advert_bridge_dim_l0;
select * from advert_dim_l0;


select ad.advert_name, sum("Total number of Properties") as "Total_number_of_properties"
from advertisement_fact_l0 af, property_advert_bridge_dim_l0 pa, advert_dim_l0 ad
where af.property_id = pa.property_id
and pa.advert_id = ad.advert_id
and ad.advert_name like 'Sale%'
group by (ad.advert_name)
order by sum("Total number of Properties") desc;

/*what is the total number of properties advertised in the month of March 
based on advertisement name */
select * from advert_date_dim_l0;

select ad.advert_name, sum("Total number of Properties") as "Total_number_of_properties"
from advertisement_fact_l0 af, property_advert_bridge_dim_l0 pa, 
advert_dim_l0 ad, advert_date_dim_l0 addate
where af.property_id = pa.property_id
and pa.advert_id = ad.advert_id
and af.date_id = addate.date_id
and addate.month like '%March%'
group by (ad.advert_name)
order by sum("Total number of Properties") desc;

/* Report 4 and 5 */
select * from rent_fact_l0;
-- Cube
select pd.suburb, r.property_type, r.period, 
    round(sum("Total Rental Fees"),2) as Total_Rental_Fees
from rent_fact_l0 r, property_dim_l0 pd
where pd.property_id = r.property_id
group by cube(pd.suburb, r.property_type, r.period)
order by pd.suburb;

-- Partial Cube
select pd.suburb, r.property_type, r.period, 
    round(sum("Total Rental Fees"),2) as Total_Rental_Fees
from rent_fact_l0 r, property_dim_l0 pd
where pd.property_id = r.property_id
group by pd.suburb, cube(r.property_type, r.period)
order by pd.suburb;

/**************************************/
/* Report 6 and 7 */
-- Sub total and total of sales from each property type for states VIC and NSW for each year
/*********** AMALA & RACH */
select * from sale_fact_l0;
select * from property_dim_l0;
--ROLL UP
select * from property_feature_dim_l0;
select pd.state_code, s.property_type, s.sale_year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l0 s, property_dim_l0 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'NSW')
group by rollup(pd.state_code, s.property_type, s.sale_year)
order by pd.state_code;

-- PARTIAL ROLL UP
select pd.state_code, s.property_type, s.sale_year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l0 s, property_dim_l0 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'NSW')
group by pd.state_code, rollup(s.property_type, s.sale_year)
order by pd.state_code;

-- Sub total and total sales from each property type for states VIC and SA for each year
/********* PRADDY AND KICHU */
--ROLL UP
select pd.state_code, s.property_type, s.sale_year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l0 s, property_dim_l0 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'SA')
group by rollup(pd.state_code, s.property_type, s.sale_year)
order by pd.state_code;

-- PARTIAL ROLLUP
select pd.state_code, s.property_type, s.sale_year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l0 s, property_dim_l0 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'SA')
group by pd.state_code, rollup(s.property_type, s.sale_year)
order by pd.state_code;

-- Sub total and total sales from each property type for states NSW and SA for each year
/*************** DIN & ARSH */
--ROLLUP
select pd.state_code, s.property_type, s.sale_year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l0 s, property_dim_l0 pd
where pd.property_id = s.property_id
and pd.state_code in ('NSW', 'SA')
group by rollup(pd.state_code, s.property_type, s.sale_year)
order by pd.state_code;


-- Partial ROLLUP
select pd.state_code, s.property_type, s.sale_year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l0 s, property_dim_l0 pd
where pd.property_id = s.property_id
and pd.state_code in ('NSW', 'SA')
group by pd.state_code, rollup(s.property_type, s.sale_year)
order by pd.state_code;

/* Report 8 - What is the total number of clients and cumulative number of clients
with a high budget in each year? */

select * from client_fact_l0;

select year, sum("Number of Clients") as Total_Number_of_Clients,
sum(sum("Number of Clients")) over 
(order by year rows unbounded preceding) as Cumulative_Number_of_Clients
from client_fact_l0
where budget_type like '%High%'
group by (year);

/* Report 9 */
/* total number of visits and cumulative number of visits for each month in every year */
select * from client_visit_dim_scd_l0;
select * from visit_fact_l0;

select to_char(v.visit_date, 'Month') as Month,
to_char(v.visit_date, 'YYYY') as Year,
sum("Total number of Visits") as Total_number_of_visits,
sum(sum("Total number of Visits")) over 
(order by to_char(v.visit_date, 'Month'), to_char(v.visit_date, 'YYYY')
rows unbounded preceding) as Cumulative_number_of_visits
from visit_fact_l0, client_visit_dim_scd_l0 v
group by (to_char(v.visit_date, 'Month'), to_char(v.visit_date, 'YYYY'));

/* total rental fee and cumulative rental fee for each month for different years */
select * from rent_fact_l0;
select * from property_rent_scd_l0;

select to_char(r.rent_start_date,'Month') as Month,
to_char(r.rent_start_date,'YYYY') as Year,
round(sum("Total Rental Fees"),2) as Total_rental_fees,
round(sum(sum("Total Rental Fees")) over
(order by to_char(r.rent_start_date,'Month') rows unbounded preceding),2) 
as Cumulative_rental_fees
from rent_fact_l0 rf, property_rent_scd_l0 r
where rf.property_id = r.property_id
group by (to_char(r.rent_start_date,'Month'),to_char(r.rent_start_date,'YYYY'));

/* total and cumulative sales for each year */
select count(*) from sale_fact_l0;
select sale_year, sum("Number of Sales") as Total_Number_of_Sales,
sum(sum("Number of Sales")) over 
(order by sale_year rows unbounded preceding) as Cumulative_Number_of_Sales
from sale_fact_l0
group by (sale_year);


/* Report 10 */
/* Total number of visits and moving aggregate of visits for each day of the week */

select to_char(v.visit_date, 'Day') as day,
sum("Total number of Visits") as Total_number_of_visits,
round(avg(sum("Total number of Visits")) over
(order by to_char(v.visit_date, 'Day') rows 2 preceding),2) as Moving_Aggregate_of_visits
from client_visit_dim_scd_l0 v, visit_fact_l0
group by to_char(v.visit_date, 'Day');


/* TOTAL RENTAL AND MOVING AGGREGATE OF RENTAL FEE FOR EACH MONTH OF DIFFERENT YEARS */

select to_char(r.rent_start_date,'Month') as Month,
to_char(r.rent_start_date,'YYYY') as Year,
round(sum("Total Rental Fees"),2) as Total_rental_fees,
round(avg(sum("Total Rental Fees")) over
(order by to_char(r.rent_start_date,'Month') rows 2 preceding),2) 
as moving_aggregate_rental_fees
from rent_fact_l0 rf, property_rent_scd_l0 r
where rf.property_id = r.property_id
group by (to_char(r.rent_start_date,'Month'),to_char(r.rent_start_date,'YYYY'));

/* Report 11 */

-- assumption: total sale is based on total price
select s.property_type, s.sale_year,
sum("Total Price"),
rank() over (partition by s.property_type
order by sum("Total Price") desc) as rank_by_property_type,
rank() over (partition by p.state_code
order by sum("Total Price") desc) as rank_by_state
from sale_fact_l0 s, property_dim_l0 p
where s.property_id = p.property_id
group by (s.property_type, s.sale_year, p.state_code);

/* Report 12 */
 -- Kichu and Praddy
-- RANK OF PROPERTY TYPES PARTITIONED BY YEARS BASED ON AVERAGE RENT 

select * from rent_fact_l0;

select property_type, years,
    round(avg("Total Rental Fees"),2) as average_rent,
    rank() over (partition by years 
    order by avg("Total Rental Fees") desc)as rank_by_property_type
    from rent_fact_l0
    group by (years, property_type)
    ORDER by years;

--- Din and Arsh
-- Ranking of average salary of agents having greater than 190,000 based on gender AND OFFICE TYPE

select * from agent_fact_l0 ;

select gender,office_type, round(avg("Total Salary"),2) AS AVERAGE_SALARY,
    rank() over (partition by gender
    order by avg("Total Salary") desc) as rank_by_gender
    from agent_fact_l0
    group by (gender,office_type);

-- Rank of property scale based on the number of properties rented --- Amala and Rachu

select * from rent_fact_l0;

select property_type, category, scale_type, period,
    sum("Total Number of Rent") as Total_number_of_rent,
    rank() over (partition by scale_type 
    order by sum("Total Number of Rent") desc)as rank_by_scale_type
    from rent_fact_l0
    group by (property_type, category, scale_type, period);
