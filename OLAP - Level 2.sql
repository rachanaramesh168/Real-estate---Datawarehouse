/* REPORT 1 */
/* WHICH ARE THE TOP 10 RAYWHITE OFFICES BASED ON GENDER COUNT FOR EACH GENDER*/
/********* DIN & ARSH */

SELECT * FROM agent_fact_l2;
SELECT * FROM agent_office_bridge_dim_l2;
SELECT * FROM office_dim_l2;
SELECT * FROM property_dim_l2;

select * from (
select dense_rank() over (order by a.gender desc) as default_Rank,
o.office_name,count(a.gender) as Gender_Count,
a.gender from agent_fact_l2 a, 
agent_office_bridge_dim_l2 ao, office_dim_l2 o
WHERE a.person_id = ao.person_id
AND ao.office_id = o.office_id
AND o.office_name Like '%Ray White%'
group by ( o.office_name,a.gender,state_code)
having state_code='VIC') 
where default_Rank <=10;

/* WHAT ARE THE TOP 3 Luxurious RENTED properties IN VICTORIA */
/************ AMALA & RACH  */

select * from rent_fact_l2;

select * from (
select property_type,
state_code,
round(sum("Total Rental Fees"),2) as Total_rental_Fees,
RANK() OVER (ORDER BY sum("Total Rental Fees") desc) as Total_rental_rank
from rent_fact_l2
where state_code = 'VIC'
and category = 'Luxurious'
group by (property_type, state_code))
where Total_rental_rank <= 3;

/* WHO ARE THE TOP 10 MALE AGENTS IN VICTORIA */
/******* PRADDY AND KICHU */

SELECT * FROM agent_fact_l2;
select * from agent_info_dim_l2;
SELECT * FROM (
SELECT a.PERSON_ID, a.GENDER, "Agent Name", sum("Total Worth") as "Total_worth",
RANK() OVER (ORDER BY SUM("Total Worth") desc) as total_worth_rank
from agent_fact_l2 a, agent_info_dim_l2 ai
where state_code = 'VIC'
and a.gender = 'Male'
group by (a.PERSON_ID, a.GENDER, "Agent Name"))
where total_worth_rank <= 10;

/* REPORT 2 */
---------------Top 50% of the Average Salary of Raywhite agents in Victoria based on office name
/********** DIN & ARSH */
select * from (
select percent_rank() over (order by avg("Total Salary") desc) as default_Rank,
o.office_name,round(avg("Total Salary"),2) as Average_Salary from agent_fact_l2 a,
agent_info_dim_l2 ai, agent_office_bridge_dim_l2 ao, office_dim_l2 o, property_dim_l2 p 
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

select * from property_dim_l2;
select * from rent_fact_l2;
select * from (
select percent_rank() over (order by sum("Total Number of Rent")desc) as property_rank,
state_code,
property_type
from rent_fact_l2
where state_code = 'VIC'
group by (state_code,property_type))
where property_rank <=0.50;

/* IN WHICH MONTHS ARE 50% PROPERTIES ADVERTISED FOR RENT IN 2020 */
/********* Amala & Rach */
SELECT * FROM advertisement_fact_l2;
select * from advert_date_dim_l2;
SELECT * FROM (
SELECT PERCENT_RANK () OVER (ORDER BY SUM("Total number of Properties") desc) as advert_property_rank,
ad.month
from advertisement_fact_l2 a, advert_date_dim_l2 ad
where ad.date_id = a.date_id
group by (a.date_id, ad.month))
where advert_property_rank <=0.5;

/* REPORT 3 */
/* SHOW ALL FEATURES PREFERED BY LOW BUDGET CLIENTS */
/* Amala and Rachu */
SELECT * FROM client_fact_l2;
SELECT * FROM client_wishlist_dim_l2;
SELECT * FROM feature_dim_l2;

SELECT fd.feature_description, 
sum("Number of Clients") as Number_of_clients
from client_fact_l2 cf, client_wishlist_dim_l2 cw, feature_dim_l2 fd
where cf.person_id = cw.person_id
and cf.budget_type = 'Low'
and cw.feature_code = fd.feature_code
group by (fd.feature_description)
order by sum("Number of Clients") desc;

/*what is the total number of properties advertised for sale 
based on advertisement name */
/***** Praddy and kichu */
select * from advertisement_fact_l2;

select * from advert_dim_l2;


select ad.advert_name, sum("Total number of Properties") as "Total_number_of_properties"
from advertisement_fact_l2 af, advert_dim_l2 ad
where af.advert_id = ad.advert_id
and ad.advert_name like 'Sale%'
group by (ad.advert_name)
order by sum("Total number of Properties") desc;

/*what is the total number of properties advertised in the month of March 
based on advertisement name */
/******** Din & Arsh */

select * from advert_date_dim_l2;

select ad.advert_name, sum("Total number of Properties") as "Total_number_of_properties"
from advertisement_fact_l2 af, advert_dim_l2 ad, advert_date_dim_l2 addate
where af.advert_id = ad.advert_id
and af.date_id = addate.date_id
and addate.month like '%March%'
group by (ad.advert_name)
order by sum("Total number of Properties") desc;


/************************************************/
/* Report 4 and 5 */
select * from rent_fact_l2;
-- Cube
select suburb, property_type, period, 
    round(sum("Total Rental Fees"),2) as Total_Rental_Fees
from rent_fact_l2 
group by cube(suburb, property_type, period)
order by suburb;

-- Partial Cube
select suburb, property_type, period, 
    round(sum("Total Rental Fees"),2) as Total_Rental_Fees
from rent_fact_l2 
group by suburb, cube(property_type, period)
order by suburb;

/**************************************/
/* Report 6 and 7 */
-- Sub total and total of sales from each statecode VIC and NSW, property type for each year
/*********** AMALA & RACH */
select * from sale_fact_l2;
select * from property_dim_l2;
--ROLL UP
select * from property_feature_dim_l2;
--ROLL UP
select * from property_feature_dim_l2;
select pd.state_code, s.property_type, s.sale_year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l2 s, property_dim_l2 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'NSW')
group by rollup(pd.state_code, s.property_type, s.sale_year)
order by pd.state_code;

-- PARTIAL ROLL UP
select pd.state_code, s.property_type, s.sale_year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l2 s, property_dim_l2 pd
where pd.property_id = s.property_id
and pd.state_code in ('VIC', 'NSW')
group by pd.state_code, rollup(s.property_type, s.sale_year)
order by pd.state_code;

-- Sub total and total sales from each suburb, property type with feature 'Built in wardrobes' and 
-- 'Close to shops'
/********* PRADDY AND KICHU */
--ROLL UP
select state_code, property_type, year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l2 
where state_code in ('VIC', 'SA')
group by rollup(state_code, property_type, year)
order by state_code;

-- PARTIAL ROLLUP
select state_code, property_type, year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l2 
where state_code in ('VIC', 'SA')
group by state_code, rollup(property_type, year)
order by state_code;

-- Sub total and total sales from each suburb, property type with feature 'Swimming Pool' and 
-- 'Secure Parking'
/*************** DIN & ARSH */
--ROLL UP
select state_code, property_type, year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l2 
where state_code in ('NSW', 'SA')
group by rollup(state_code, property_type, year)
order by state_code;

-- PARTIAL ROLLUP
select state_code, property_type, year, 
    round(sum("Total Price"),2) as Total_Sales
from sale_fact_l2 
where state_code in ('NSW', 'SA')
group by state_code, rollup(property_type, year)
order by state_code;

/* Report 8 - What is the total number of clients and cumulative number of clients
with a high budget in each year? */

select * from client_fact_l2;

select year, sum("Number of Clients") as Total_Number_of_Clients,
sum(sum("Number of Clients")) over 
(order by year rows unbounded preceding) as Cumulative_Number_of_Clients
from client_fact_l2
where budget_type like '%High%'
group by (year);

/* Report 9 */
/* total number of visits and cumulative number of visits for each month in every year */
select * from client_visit_dim_scd_l2;
select * from visit_fact_l2;

select to_char(v.visit_date, 'Month') as Month,
to_char(v.visit_date, 'YYYY') as Year,
sum("Total number of Visits") as Total_number_of_visits,
sum(sum("Total number of Visits")) over 
(order by to_char(v.visit_date, 'Month'), to_char(v.visit_date, 'YYYY')
rows unbounded preceding) as Cumulative_number_of_visits
from visit_fact_l2, client_visit_dim_scd_l2 v
group by (to_char(v.visit_date, 'Month'), to_char(v.visit_date, 'YYYY'));

/* total rental fee and cumulative rental fee for each month for different years */
select * from rent_fact_l2;
select * from property_rent_scd_l2;

select to_char(r.rent_start_date,'Month') as Month,
to_char(r.rent_start_date,'YYYY') as Year,
round(sum("Total Rental Fees"),2) as Total_rental_fees,
round(sum(sum("Total Rental Fees")) over
(order by to_char(r.rent_start_date,'Month') rows unbounded preceding),2) 
as Cumulative_rental_fees
from rent_fact_l2 rf, property_rent_scd_l2 r
where rf.property_id = r.property_id
group by (to_char(r.rent_start_date,'Month'),to_char(r.rent_start_date,'YYYY'));

/* total and cumulative sales for each year */
select count(*)  from sale_fact_l2;
select year, sum("Number of Sales") as Total_Number_of_Sales,
sum(sum("Number of Sales")) over 
(order by year rows unbounded preceding) as Cumulative_Number_of_Sales
from sale_fact_l2
group by (year);

/* Report 10 */
/* Total number of visits and moving aggregate of visits for each day of the week */

select to_char(v.visit_date, 'Day') as day,
sum("Total number of Visits") as Total_number_of_visits,
round(avg(sum("Total number of Visits")) over
(order by to_char(v.visit_date, 'Day') rows 2 preceding),2) as Moving_Aggregate_of_visits
from client_visit_dim_scd_l2 v, visit_fact_l2
group by to_char(v.visit_date, 'Day');

/* TOTAL RENTAL AND MOVING AGGREGATE OF RENTAL FEE FOR EACH MONTH OF DIFFERENT YEARS */

select to_char(r.rent_start_date,'Month') as Month,
to_char(r.rent_start_date,'YYYY') as Year,
round(sum("Total Rental Fees"),2) as Total_rental_fees,
round(avg(sum("Total Rental Fees")) over
(order by to_char(r.rent_start_date,'Month') rows 2 preceding),2) 
as moving_aggregate_rental_fees
from rent_fact_l2 rf, property_rent_scd_l2 r
where rf.property_id = r.property_id
group by (to_char(r.rent_start_date,'Month'),to_char(r.rent_start_date,'YYYY'));

/* Report 11 */
select s.property_type, s.sale_year,
sum("Total Price"),
rank() over (partition by s.property_type
order by sum("Total Price") desc) as rank_by_property_type,
rank() over (partition by p.state_code
order by sum("Total Price") desc) as rank_by_state
from sale_fact_l2 s, property_dim_l2 p
where s.property_id = p.property_id
group by (s.property_type, s.sale_year, p.state_code);

/* Report 12 */
-- Kichu and Praddy
-- RANK OF PROPERTY TYPES PARTITIONED BY YEARS BASED ON AVERAGE RENT 

select * from rent_fact_l2;

select property_type, years,
    round(avg("Total Rental Fees"),2) as average_rent,
    rank() over (partition by years 
    order by avg("Total Rental Fees") desc)as rank_by_property_type
    from rent_fact_l2
    group by (years, property_type)
    ORDER by years;

--- Din and Arsh
-- Ranking of average salary of agents having greater than 190,000 based on gender AND OFFICE TYPE

select * from agent_fact_l2;

select gender,office_type, round(avg("Total Salary"),2) AS AVERAGE_SALARY,
    rank() over (partition by gender
    order by avg("Total Salary") desc) as rank_by_gender
    from agent_fact_l2
    group by (gender,office_type);

-- Rank of property scale based on the number of properties rented --- Amala and Rachu

select * from rent_fact_l2;

select property_type, category, scale_type, period,
    sum("Total Number of Rent") as Total_number_of_rent,
    rank() over (partition by scale_type 
    order by sum("Total Number of Rent") desc)as rank_by_scale_type
    from rent_fact_l2
    group by (property_type, category, scale_type, period);