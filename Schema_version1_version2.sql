--AUTHORS
--AMALA RICHU ALBERT AROCKIARAJ 29949270
--RACHANA RAMESH 29905257
--FIT5195 MAJOR ASSIGNMENT
--SQL STATEMENTS FOR VERSION 1 AND VERSION 2 SCHEMA

/*---------------------------------------------LEVEL 2 AGGREGATION VERSION 1------------------------------------------------*/



/*------------------------------VISIT--------------------------------*/

/*DROPPING VISIT DIMENSION TABLES*/
drop table SEASON_DIM_L2;
drop table VISIT_CLIENT_DIM_SCD_L2;

/*DROPPING VISIT FACT TABLES*/
drop table TEMP_VISIT_FACT_L2;
drop table VISIT_FACT_L2;

/*Creating table SEASON DIMENSION */
CREATE TABLE SEASON_DIM_L2(
season_id VARCHAR(10),
season_desc VARCHAR(20)
);

INSERT INTO SEASON_DIM_L2 VALUES('Autumn', 'Mar, Apr, May');
INSERT INTO SEASON_DIM_L2 VALUES('Winter', 'Jun, Jul, Aug');
INSERT INTO SEASON_DIM_L2 VALUES('Spring', 'Sep, Oct, Nov');
INSERT INTO SEASON_DIM_L2 VALUES('Summer', 'Dec, Jan, Feb');

/*Creating table VISIT CLIENT SCD DIMENSION */
CREATE TABLE VISIT_CLIENT_DIM_SCD_L2 
AS SELECT client_person_id, property_id, visit_date FROM VISIT;

/*Creating table TEMP VISIT FACT TABLE */
CREATE TABLE TEMP_VISIT_FACT_L2 
AS SELECT v.client_person_id, p.property_id, v.visit_date from visit v join property p
on p.property_id = v.property_id;
/*Altering table temp visit fact level-0 */
ALTER TABLE TEMP_VISIT_FACT_L2 add season_id varchar(10);

UPDATE TEMP_VISIT_FACT_L2 set season_id =
CASE  
      WHEN to_char(visit_date,'mm') IN (12,1,2) THEN 'SUMMER'
      WHEN to_char(visit_date,'mm') IN (3,4,5)  THEN 'AUTUMN'
      WHEN to_char(visit_date,'mm') IN (6,7,8)  THEN 'WINTER'
      WHEN to_char(visit_date,'mm') IN (9,10,11)THEN 'SPRING'
END;


/*creating a Visit Fact Level-2 */
CREATE TABLE VISIT_FACT_L2 
AS SELECT  property_id, season_id, count(visit_date) as total_visits
FROM TEMP_VISIT_FACT_L2
GROUP BY  property_id, season_id;

/*------------------------------CLIENT--------------------------------*/

/*DROPPING CLIENT DIMENSION TABLES*/
drop table CLIENT_DIM_L2;
drop table CLIENT_YEAR_DIM_L2;
drop table BUDGET_DIM_L2;
drop table CLIENT_WISH_DIM_L2;
drop table FEATURE_DIM_L2;

/*DROPPING CLIENT FACT TABLES*/
drop table TEMP_CLIENT_FACT_L2;
drop table CLIENT_FACT_L2;

/*CREATING CLIENT DIMENSION*/
CREATE TABLE CLIENT_DIM_L2 
AS SELECT DISTINCT person_id as client_person_id FROM CLIENT;



/*CREATING CLIENT YEAR DIMENSION*/
CREATE TABLE CLIENT_YEAR_DIM_L2 AS
SELECT DISTINCT year FROM (
SELECT to_char(rent_start_date,'yyyy') AS year FROM rent
UNION
SELECT to_char(sale_date,'yyyy') AS year FROM sale
UNION
SELECT to_char(visit_date,'yyyy') AS year FROM visit
)
WHERE NOT year IS NULL;

/*CREATING BUDGET DIMENSION*/
CREATE TABLE BUDGET_DIM_L2 (
budget_id VARCHAR(20),
budget_desc VARCHAR(20));
INSERT INTO BUDGET_DIM_L2 VALUES('LOW', '$0 TO $1000');
INSERT INTO BUDGET_DIM_L2 VALUES('MEDIUM', '$1001 TO $100000');
INSERT INTO BUDGET_DIM_L2 Values('HIGH', '$100001 TO $10000000');

/*CREATING FEATURE DIMENSION*/
CREATE TABLE FEATURE_DIM_L2 
AS SELECT feature_code as feature_code, feature_description as feature_desc 
FROM FEATURE;

/*CREATING CLIENT_WISHLIST DIMENSION*/
CREATE TABLE CLIENT_WISH_DIM_L2 
AS SELECT person_id as client_person_id, feature_code  FROM CLIENT_WISH;

/*CREATING TEMP_CLIENT_FACT_L0 DIMENSION*/
CREATE TABLE TEMP_CLIENT_FACT_L2 
AS
SELECT person_id, max_budget, MIN(year) as year FROM(
SELECT person_id, max_budget, to_char(rent_start_date,'yyyy') AS year FROM client c JOIN rent r ON c.person_id=r.client_person_id
UNION
SELECT person_id, max_budget, to_char(sale_date,'yyyy')  AS year FROM client c JOIN sale s ON c.person_id=s.client_person_id
UNION
SELECT person_id, max_budget, to_char(visit_date,'yyyy') AS year FROM client c JOIN visit v ON c.person_id=v.client_person_id)
GROUP BY  person_id, max_budget;



ALTER TABLE TEMP_CLIENT_FACT_L2 
ADD budget_id VARCHAR(10);
UPDATE TEMP_CLIENT_FACT_L2 SET budget_id='LOW' WHERE max_budget BETWEEN 0 AND 1000;
UPDATE TEMP_CLIENT_FACT_L2 SET budget_id='MEDIUM' WHERE max_budget BETWEEN 1001 AND 100000;
UPDATE TEMP_CLIENT_FACT_L2 SET budget_id='HIGH' WHERE max_budget BETWEEN 100001 And 10000000;

/*CREATING CLIENT_FACT DIMENSION*/
CREATE TABLE CLIENT_FACT_L2 
AS SELECT DISTINCT(person_id) as client_person_id, budget_id, year, COUNT(person_id) as Total_Clients 
FROM TEMP_CLIENT_FACT_L2
GROUP BY person_id, budget_id, year;


/*------------------------------RENT--------------------------------*/

/*DROPPING RENT DIMENSION TABLES*/
drop table RENTED_YEAR_DIM_L2;
drop table RENT_TIME_PERIOD_DIM_L2;
drop table PROPERTY_FEATURE_CATEGORY_DIM_L2;
drop table PROPERTY_SCALE_DIM_L2;
drop table PROPERTY_DIM_L2;
drop table RENT_PROPERTY_SCD_DIM_L2;
drop table PROPERTY_TYPE_DIM_L2;
drop table LOCATION_DIM_L2;


/*DROPPING RENT FACT TABLES*/
drop table TEMP_RENT_FACT_L2;
drop table RENT_FACT_L2;

/*CREATING PROPERTY_SCALE_DIMENSION*/
CREATE TABLE PROPERTY_SCALE_DIM_L2 
(scale_id VARCHAR2(40), scale_type_desc VARCHAR2(50));
INSERT INTO PROPERTY_SCALE_DIM_L2 VALUES('EXTRA SMALL','<=1 Bedrooms');
INSERT INTO PROPERTY_SCALE_DIM_L2 VALUES('SMALL','2-3 Bedrooms');
INSERT INTO PROPERTY_SCALE_DIM_L2 VALUES('MEDIUM','3-6 Bedrooms');
INSERT INTO PROPERTY_SCALE_DIM_L2 VALUES('LARGE','6-10 Bedrooms');
INSERT INTO PROPERTY_SCALE_DIM_L2 VALUES('EXTRA LARGE','>10 Bedrooms');

/*CREATING RENT_TIME_PERIOD_DIMENSION*/
CREATE TABLE RENT_TIME_PERIOD_DIM_L2 
(period_id VARCHAR2(50), period_desc VARCHAR2(50));

INSERT INTO RENT_TIME_PERIOD_DIM_L2 VALUES('SHORT','<6 months');
INSERT INTO RENT_TIME_PERIOD_DIM_L2 VALUES('MEDIUM','6-12 months');
INSERT INTO RENT_TIME_PERIOD_DIM_L2 VALUES('LONG','>12 months');

/*CREATING RENTED_YEAR_DIMENSION*/
CREATE TABLE RENTED_YEAR_DIM_L2 
AS SELECT DISTINCT to_char(rent_start_date,'yyyy') AS year FROM RENT 
WHERE NOT (to_char(rent_start_date,'yyyy')) is NULL;


/*CREATING PROPERTY_FEATURE_CATEGORY_DIMENSION*/
CREATE TABLE PROPERTY_FEATURE_CATEGORY_DIM_L2 
(category_id VARCHAR2(40), category_desc VARCHAR(50));
INSERT INTO PROPERTY_FEATURE_CATEGORY_DIM_L2 VALUES('VERY BASIC','<10 Features');
INSERT INTO PROPERTY_FEATURE_CATEGORY_DIM_L2 VALUES('STANDARD','10-20 Features');
INSERT INTO PROPERTY_FEATURE_CATEGORY_DIM_L2 Values('LUXURIOUS','>20 Features');

/*CREATING LOCATION DIMENSION*/
CREATE TABLE LOCATION_dIM_L2 
AS SELECT a.suburb,p.state_code FROM address a 
JOIN postcode p ON a.postcode=p.postcode;


/*CREATING PROPERTY_TYPE_DIMENSION*/
CREATE TABLE PROPERTY_TYPE_DIM_L2 
AS SELECT DISTINCT property_type FROM PROPERTY;

/*CREATING PROPERTY_DIMENSION*/
CREATE TABLE PROPERTY_DIM_L2 
AS SELECT pr.property_id,a.suburb,p.state_code 
FROM property pr
JOIN address a ON pr.address_id=a.address_id
JOIN postcode p ON a.postcode=p.postcode;

/*CREATING RENT PROPERTY SCD_DIMENSION*/    
CREATE TABLE RENT_PROPERTY_SCD_DIM_L2
AS SELECT rent_start_date, rent_end_date, property_id, price 
FROM rent WHERE NOT rent_start_date IS NULL;

/*CREATING TEMP RENT FACT*/ 

create table TEMP_RENT_FACT_L2 AS 
    select rent_id, r.property_id, COUNT(feature_code) AS "Feature count", property_type, floor(months_between(TO_DATE(rent_end_date,'dd-mm-yyyy'),TO_DATE(rent_start_date,'dd-mm-yyyy'))) AS Months,
    to_char(rent_start_date,'yyyy') AS years, ad.suburb, pc.state_code, price*((TO_DATE(rent_end_date,'dd-mm-yyyy')-TO_DATE(rent_start_date,'dd-mm-yyyy'))/7) AS price, p.property_no_of_bedrooms    from rent r 
    join property p ON r.property_id=p.property_id 
    join property_feature pf ON p.property_id=pf.property_id 
    join address ad ON ad.address_id=p.address_id 
    join postcode pc ON ad.postcode=pc.postcode
    where NOT r.rent_start_date IS NULL
    group by (rent_id, r.property_id, property_type, months_between(TO_DATE(rent_end_date,'dd-mm-yyyy'),TO_DATE(rent_start_date,'dd-mm-yyyy')),
        TO_CHAR(rent_start_date,'yyyy'), price*((TO_DATE(rent_end_date,'dd-mm-yyyy')-TO_DATE(rent_start_date,'dd-mm-yyyy'))/7), p.property_no_of_bedrooms,ad.suburb, pc.state_code);
        
alter table TEMP_RENT_FACT_L2 ADD category varchar(20); 

update TEMP_RENT_FACT_L2 SET category='Very basic' where "Feature count"<10;
update TEMP_RENT_FACT_L2 SET category='Standard' where "Feature count" BETWEEN 10 AND 20;
update TEMP_RENT_FACT_L2 SET category='Luxurious' where "Feature count">20;

alter table TEMP_RENT_FACT_L2 ADD scale_type varchar(20);

update TEMP_RENT_FACT_L2 SET scale_type='Extra small' where property_no_of_bedrooms<=1;
update TEMP_RENT_FACT_L2 SET scale_type='Small' where property_no_of_bedrooms BETWEEN 2 AND 3;
update TEMP_RENT_FACT_L2 SET scale_type='Medium' where property_no_of_bedrooms BETWEEN 4 AND 6;
update TEMP_RENT_FACT_L2 SET scale_type='Large' where property_no_of_bedrooms BETWEEN 7 AND 10;
update TEMP_RENT_FACT_L2 SET scale_type='Extra large' where property_no_of_bedrooms>10;

alter table TEMP_RENT_FACT_L2 ADD period varchar(20);

update TEMP_RENT_FACT_L2 SET period='Short' where Months<6;
update TEMP_RENT_FACT_L2 SET period='Medium' where Months BETWEEN 6 AND 12;
update TEMP_RENT_FACT_L2 SET period='Long' where Months>12;



/*CREATING RENT FACT*/    
create table RENT_FACT_L2 AS 
    select property_id,property_type,years as rented_year,category,scale_type as scale_id,period as period_id ,suburb, state_code, count(rent_id) AS total_rent,sum(price) AS total_rental_fee
    from TEMP_RENT_FACT_L2 
    group by (property_id,property_type,years,category,scale_type,period,suburb, state_code);

/*------------------------------SALE--------------------------------*/

/*DROPPING SALE DIMENSION TABLES*/

--PROPERTY_TYPE_L2 (SHARED DIMESNION) ALREADY CREATED--
drop table SALES_YEAR_L2;
drop table property_feature_dim_l2;
/*DROPPING SALE FACT TABLES*/
drop table TEMP_SALE_FACT_L2;
drop table SALE_FACT_L2;

/*CREATING PROPERTY FEATURE  DIMENSION TABLE*/
create table property_feature_dim_l2 AS select property_id, feature_code from property_feature;

/*CREATING SALE YEAR DIMENSION TABLE*/
CREATE TABLE SALES_YEAR_L2 
AS SELECT DISTINCT(to_char(sale_date,'yyyy')) as year_of_sales FROM SALE
WHERE NOT (to_char(sale_date,'yyyy')) is null;

/*CREATING TEMP SALE FACT TABLE*/
CREATE TABLE TEMP_SALE_FACT_L2 AS 
select s.property_id, p.property_type,to_char(s.sale_date,'yyyy') as sale_year, s.price from sale s 
JOIN property p ON s.property_id=p.property_id
JOIN monre.address ad on ad.address_id=p.address_id
JOIN postcode pc ON pc.postcode=ad.postcode
WHERE NOT s.client_person_id IS NULL;

/*CREATING SALE FACT TABLE*/
CREATE TABLE SALE_FACT_L2 
AS SELECT property_id, property_type,sale_year, SUM(price) as total_sales_price, COUNT(property_id) as total_sales
FROM TEMP_SALE_FACT_L2 
GROUP BY property_id,property_type,sale_year;



/*------------------------------ADVERTISEMENT--------------------------------*/

/*DROPPING ADVERTISEMENT DIMENSION TABLES*/
drop table ADVERT_DIM_L2;
drop table PROPERTY_ADVERT_DATE_DIM_L2;

/*DROPPING ADVERTISEMENT FACT TABLE*/
drop table TEMP_ADVERTISEMENT_FACT_L2;
drop table ADVERTISEMENT_FACT_L2;

/*CREATING ADVERTISEMENT DIMENSION*/
CREATE TABLE ADVERT_DIM_L2 
AS SELECT advert_id,advert_name FROM ADVERTISEMENT;


/*CREATING PROPERTY ADVERTISEMENT DATE DIMENSION*/
CREATE TABLE PROPERTY_ADVERT_DATE_DIM_L2 
AS SELECT DISTINCT 
TO_CHAR(property_date_added,'Mon')||'_'||TO_CHAR(property_date_added,'yyyy') AS date_id, 
TO_CHAR(property_date_added,'mm')as  month,
TO_CHAR(property_date_added,'yyyy') AS year 
FROM PROPERTY;

/*CREATING TEMP ADVERTISEMENT FACT*/
CREATE TABLE TEMP_ADVERTISEMENT_FACT_L2 AS select p.property_id,pd.property_date_added,a.advert_id
from advertisement a join property_advert p ON a.advert_id=p.advert_id
join property pd ON p.property_id=pd.property_id 
group by p.property_id,pd.property_date_added,a.advert_id;

/*CREATING ADVERTISEMENT FACT*/
CREATE TABLE ADVERTISEMENT_FACT_L2 
AS SELECT TO_CHAR(property_date_added,'Mon')||'_'||TO_CHAR(property_date_added,'yyyy') as date_id, advert_id,
COUNT(property_id) as total_properties 
from TEMP_ADVERTISEMENT_FACT_L2
group by TO_CHAR(property_date_added,'Mon')||'_'||TO_CHAR(property_date_added,'yyyy'),advert_id;


/*------------------------------AGENT--------------------------------*/

/*DROPPING AGENT DIMENSION TABLES*/
drop table AGENT_DIM_L2;
drop table AGENT_OFFICE_DIM_L2;
drop table OFFICE_DIM_L2;
drop table AGENT_OFFICE_SIZE_DIM_L2;
drop table GENDER_DIM_L2;

/*DROPPING AGENT FACT TABLES*/
drop table TEMP_AGENT_FACT_L2;
drop table AGENT_FACT_L2;

/*CREATING GENDER DIMENSION*/
CREATE TABLE GENDER_DIM_L2
AS SELECT DISTINCT gender 
FROM PERSON;

/*CREATING AGENT DIMENSION*/
CREATE TABLE AGENT_DIM_L2 
AS SELECT DISTINCT(ag.person_id) as agent_person_id, 
p.title||'.'||p.first_name||' '||p.last_name AS agent_name 
FROM Agent ag JOIN PERSON p ON ag.person_id=p.person_id;
    
/*CREATING AGENT_OFFICE DIMENSION*/
CREATE TABLE AGENT_OFFICE_DIM_L2 
AS SELECT person_id as agent_person_id, office_id 
FROM AGENT_OFFICE;

/*CREATING OFFICE DIMENSION*/
CREATE TABLE OFFICE_DIM_L2 
AS select office_id,office_name 
FROM OFFICE;

/*CREATING AGENT_OFFICE_SIZE DIMENSION*/
CREATE TABLE AGENT_OFFICE_SIZE_DIM_L2 
(office_size_id VARCHAR2(50), office_size_desc VARCHAR2(70));
INSERT INTO AGENT_OFFICE_SIZE_DIM_L2 VALUES('SMALL','< 4 Employees');
INSERT INTO AGENT_OFFICE_SIZE_DIM_L2 VALUES('MEDIUM',' 4-12 employees');
INSERT INTO AGENT_OFFICE_SIZE_DIM_L2 VALUES('LARGE','> 12 employees');


/*CREATING TEMP AGENT FACT*/
Create table TEMP_AGENT_FACT_L2 AS 
    select person_id,gender,salary,suburb,state_code,sum(price) as total_agent_worth from (
        select a.person_id,pe.gender,a.salary,ad.suburb,pc.state_code, s.price from agent a
            left join sale s ON a.person_id=s.agent_person_id
            left join property p ON s.property_id=p.property_id 
            left join address ad ON p.address_id=ad.address_id
            left join postcode pc ON pc.postcode = ad.postcode 
            left join agent_office ao ON a.person_id=ao.person_id
            left join person pe ON a.person_id=pe.person_id
        union 
        select a.person_id,pe.gender,a.salary,ad.suburb, pc.state_code, r.price*(r.rent_end_date-r.rent_start_date)/7 from agent a
            left join rent r ON a.person_id=r.agent_person_id
            left join property p ON r.property_id=p.property_id 
            left join address ad ON p.address_id=ad.address_id
            left join postcode pc ON pc.postcode = ad.postcode
            left join agent_office ao ON a.person_id=ao.person_id
            left join person pe ON a.person_id=pe.person_id
        )
    where price is NOT NULL 
    group by person_id,gender,suburb,state_code, salary ORDER BY SUM(price) DESC;

alter table TEMP_AGENT_FACT_L2 ADD office_size varchar(10);
select a.person_id from TEMP_AGENT_FACT_L2 a join agent_office_bridge_dim b ON a.person_id =b.person_id where b.office_id in (select office_id from agent_office group by office_id having count(person_id)<4);
update TEMP_AGENT_FACT_L2 SET office_size='Small' where person_id in (select a.person_id from TEMP_AGENT_FACT_L2 a join agent_office b ON a.person_id =b.person_id where b.office_id in (select office_id from agent_office group by office_id having count(person_id)<4));
update TEMP_AGENT_FACT_L2 SET office_size='Medium' where person_id in (select a.person_id from TEMP_AGENT_FACT_L2 a join agent_office b ON a.person_id =b.person_id where b.office_id in (select office_id from agent_office group by office_id having count(person_id) between 4 and 12));
update TEMP_AGENT_FACT_L2 SET office_size='Big' where person_id in (select a.person_id from TEMP_AGENT_FACT_L2 a join agent_office b ON a.person_id =b.person_id where b.office_id in (select office_id from agent_office group by office_id having count(person_id)>12));

/*CREATING AGENT FACT TABLE*/
CREATE TABLE AGENT_FACT_L2 
AS SELECT person_id as agent_person_id,gender,suburb,state_code, office_size as office_type, sum(salary) as total_salary ,
sum(total_agent_worth) as total_agent_worth ,count( distinct person_id) as total_agents
from TEMP_AGENT_FACT_L2 
group by (person_id,gender,suburb, state_code, office_size);


/*----------------------------------------------------LEVEL 0 AGGREGATION VERSION 2 -----------------------------------*/
/*------------------------------VISIT--------------------------------*/

/*DROPPING VISIT DIMENSION TABLES*/
drop table SEASON_DIM_L0;
drop table VISIT_CLIENT_DIM_L0;
drop table VISIT_CLIENT_DIM_SCD_L0;

/*DROPPING VISIT FACT TABLES*/
drop table TEMP_VISIT_FACT_L0;
drop table VISIT_FACT_L0;

/*Creating table SEASON DIMENSION */
CREATE TABLE SEASON_DIM_L0(
season_id VARCHAR(10),
season_desc VARCHAR(20)
);

INSERT INTO SEASON_DIM_L0 VALUES('Autumn', 'Mar, Apr, May');
INSERT INTO SEASON_DIM_L0 VALUES('Winter', 'Jun, Jul, Aug');
INSERT INTO SEASON_DIM_L0 VALUES('Spring', 'Sep, Oct, Nov');
INSERT INTO SEASON_DIM_L0 VALUES('Summer', 'Dec, Jan, Feb');

/*Creating table VISIT CLIENT DIMENSION */
CREATE TABLE VISIT_CLIENT_DIM_L0 
AS SELECT DISTINCT client_person_id, property_id FROM VISIT;

/*Creating table VISIT CLIENT SCD DIMENSION */
CREATE TABLE VISIT_CLIENT_DIM_SCD_L0 
AS SELECT client_person_id, property_id, visit_date FROM VISIT;

/*Creating table TEMP VISIT FACT TABLE */
CREATE TABLE TEMP_VISIT_FACT_L0 
AS SELECT client_person_id, property_id, visit_date FROM VISIT;

/*Altering table temp visit fact level-0 */
ALTER TABLE TEMP_VISIT_FACT_L0 add season_id varchar(10);

UPDATE TEMP_VISIT_FACT_L0 set season_id =
CASE  
      WHEN to_char(visit_date,'mm') IN (12,1,2) THEN 'SUMMER'
      WHEN to_char(visit_date,'mm') IN (3,4,5)  THEN 'AUTUMN'
      WHEN to_char(visit_date,'mm') IN (6,7,8)  THEN 'WINTER'
      WHEN to_char(visit_date,'mm') IN (9,10,11)THEN 'SPRING'
END;


/*creating a Visit Fact Level-0 */
CREATE TABLE VISIT_FACT_L0 
AS SELECT client_person_id, property_id, season_id, count(visit_date) as total_visits
FROM TEMP_VISIT_FACT_L0 
GROUP BY client_person_id, property_id, season_id;

select * from VISIT_FACT_L0;

/*------------------------------CLIENT--------------------------------*/

/*DROPPING CLIENT DIMENSION TABLES*/
drop table CLIENT_DIM_L0;
drop table CLIENT_YEAR_DIM_L0;
drop table BUDGET_DIM_L0;
drop table CLIENT_WISH_DIM_L0;
drop table FEATURE_DIM_L0;

/*DROPPING CLIENT FACT TABLES*/
drop table TEMP_CLIENT_FACT_L0;
drop table CLIENT_FACT_L0;

/*CREATING CLIENT DIMENSION*/
CREATE TABLE CLIENT_DIM_L0 
AS SELECT DISTINCT person_id as client_person_id FROM CLIENT;



/*CREATING CLIENT YEAR DIMENSION*/
CREATE TABLE CLIENT_YEAR_DIM_L0 AS
SELECT DISTINCT year FROM (
SELECT to_char(rent_start_date,'yyyy') AS year FROM rent
UNION
SELECT to_char(sale_date,'yyyy') AS year FROM sale
UNION
SELECT to_char(visit_date,'yyyy') AS year FROM visit
)
WHERE NOT year IS NULL;

/*CREATING BUDGET DIMENSION*/
CREATE TABLE BUDGET_DIM_L0 (
budget_id VARCHAR(20),
budget_desc VARCHAR(20));
INSERT INTO BUDGET_DIM_L0 VALUES('LOW', '$0 TO $1000');
INSERT INTO BUDGET_DIM_L0 VALUES('MEDIUM', '$1001 TO $100000');
INSERT INTO BUDGET_DIM_L0 Values('HIGH', '$100001 TO $10000000');

/*CREATING FEATURE DIMENSION*/
CREATE TABLE FEATURE_DIM_L0 
AS SELECT feature_code as feature_code, feature_description as feature_desc 
FROM FEATURE;

/*CREATING CLIENT_WISHLIST DIMENSION*/
CREATE TABLE CLIENT_WISH_DIM_L0 
AS SELECT person_id as client_person_id, feature_code  FROM CLIENT_WISH;

/*CREATING TEMP_CLIENT_FACT_L0 DIMENSION*/
CREATE TABLE TEMP_CLIENT_FACT_L0 
AS
SELECT person_id, max_budget, MIN(year) as year FROM(
SELECT person_id, max_budget, to_char(rent_start_date,'yyyy') AS year FROM client c JOIN rent r ON c.person_id=r.client_person_id
UNION
SELECT person_id, max_budget, to_char(sale_date,'yyyy')  AS year FROM client c JOIN sale s ON c.person_id=s.client_person_id
UNION
SELECT person_id, max_budget, to_char(visit_date,'yyyy') AS year FROM client c JOIN visit v ON c.person_id=v.client_person_id)
GROUP BY  person_id, max_budget;



ALTER TABLE TEMP_CLIENT_FACT_L0 
ADD budget_id VARCHAR(10);
UPDATE TEMP_CLIENT_FACT_L0 SET budget_id='LOW' WHERE max_budget BETWEEN 0 AND 1000;
UPDATE TEMP_CLIENT_FACT_L0 SET budget_id='MEDIUM' WHERE max_budget BETWEEN 1001 AND 100000;
UPDATE TEMP_CLIENT_FACT_L0 SET budget_id='HIGH' WHERE max_budget BETWEEN 100001 And 10000000;

/*CREATING CLIENT_FACT_L0 DIMENSION*/
CREATE TABLE CLIENT_FACT_L0 
AS SELECT DISTINCT(person_id) as client_person_id, budget_id, year, COUNT(person_id) as Total_Clients 
FROM TEMP_CLIENT_FACT_L0
GROUP BY person_id, budget_id, year;



/*------------------------------RENT--------------------------------*/

/*DROPPING RENT DIMENSION TABLES*/
drop table RENTED_YEAR_DIM_L0;
drop table RENT_TIME_PERIOD_DIM_L0;
drop table PROPERTY_FEATURE_CATEGORY_DIM_L0;
drop table PROPERTY_SCALE_DIM_L0;
drop table PROPERTY_DIM_L0;
drop table RENT_PROPERTY_SCD_DIM_L0;
drop table PROPERTY_TYPE_DIM_L0;


/*DROPPING RENT FACT TABLES*/
drop table TEMP_RENT_FACT_L0;
drop table RENT_FACT_L0;

/*CREATING PROPERTY_SCALE_DIMENSION*/
CREATE TABLE PROPERTY_SCALE_DIM_L0 
(scale_id VARCHAR2(40), scale_type_desc VARCHAR2(50));
INSERT INTO PROPERTY_SCALE_DIM_L0 VALUES('EXTRA SMALL','<=1 Bedrooms');
INSERT INTO PROPERTY_SCALE_DIM_L0 VALUES('SMALL','2-3 Bedrooms');
INSERT INTO PROPERTY_SCALE_DIM_L0 VALUES('MEDIUM','3-6 Bedrooms');
INSERT INTO PROPERTY_SCALE_DIM_L0 VALUES('LARGE','6-10 Bedrooms');
INSERT INTO PROPERTY_SCALE_DIM_L0 VALUES('EXTRA LARGE','>10 Bedrooms');

/*CREATING RENT_TIME_PERIOD_DIMENSION*/
CREATE TABLE RENT_TIME_PERIOD_DIM_L0 
(period_id VARCHAR2(50), period_desc VARCHAR2(50));

INSERT INTO RENT_TIME_PERIOD_DIM_L0 VALUES('SHORT','<6 months');
INSERT INTO RENT_TIME_PERIOD_DIM_L0 VALUES('MEDIUM','6-12 months');
INSERT INTO RENT_TIME_PERIOD_DIM_L0 VALUES('LONG','>12 months');

/*CREATING RENTED_YEAR_DIMENSION*/
CREATE TABLE RENTED_YEAR_DIM_L0 
AS SELECT DISTINCT to_char(rent_start_date,'yyyy') AS year FROM RENT 
WHERE NOT (to_char(rent_start_date,'yyyy')) is NULL;


/*CREATING PROPERTY_FEATURE_CATEGORY_DIMENSION*/
CREATE TABLE PROPERTY_FEATURE_CATEGORY_DIM_L0 
(category_id VARCHAR2(40), category_desc VARCHAR(50));
INSERT INTO PROPERTY_FEATURE_CATEGORY_DIM_L0 VALUES('VERY BASIC','<10 Features');
INSERT INTO PROPERTY_FEATURE_CATEGORY_DIM_L0 VALUES('STANDARD','10-20 Features');
INSERT INTO PROPERTY_FEATURE_CATEGORY_DIM_L0 Values('LUXURIOUS','>20 Features');

/*CREATING PROPERTY_TYPE_DIMENSION*/
CREATE TABLE PROPERTY_TYPE_DIM_L0 
AS SELECT DISTINCT property_type FROM PROPERTY;

/*CREATING PROPERTY_DIMENSION*/
CREATE TABLE PROPERTY_DIM_L0 
AS SELECT pr.property_id,a.suburb,p.state_code 
FROM property pr
JOIN address a ON pr.address_id=a.address_id
JOIN postcode p ON a.postcode=p.postcode;

/*CREATING RENT PROPERTY SCD_DIMENSION*/    
CREATE TABLE RENT_PROPERTY_SCD_DIM_L0
AS SELECT rent_start_date, rent_end_date, property_id, price 
FROM rent WHERE NOT rent_start_date IS NULL;

/*CREATING TEMP RENT FACT*/    
CREATE TABLE TEMP_RENT_FACT_L0 
AS SELECT rent_id, r.property_id, COUNT(feature_code) AS "Feature count", property_type, floor(months_between(TO_DATE(rent_end_date,'dd-mm-yyyy'),TO_DATE(rent_start_date,'dd-mm-yyyy'))) AS Months,
    to_char(rent_start_date,'yyyy') AS year, price*((TO_DATE(rent_end_date,'dd-mm-yyyy')-TO_DATE(rent_start_date,'dd-mm-yyyy'))/7) AS price, p.property_no_of_bedrooms
    from rent r 
    join property p ON r.property_id=p.property_id 
    join property_feature pf ON p.property_id=pf.property_id 
    join address ad ON ad.address_id=p.address_id 
    join postcode pc ON ad.postcode=pc.postcode
    where NOT r.rent_start_date IS NULL
    group by (rent_id, r.property_id, property_type, months_between(TO_DATE(rent_end_date,'dd-mm-yyyy'),TO_DATE(rent_start_date,'dd-mm-yyyy')),
        to_char(rent_start_date,'yyyy'), price*((TO_DATE(rent_end_date,'dd-mm-yyyy')-TO_DATE(rent_start_date,'dd-mm-yyyy'))/7), p.property_no_of_bedrooms);
        
alter table TEMP_RENT_FACT_L0 ADD category VARCHAR(20); 

update TEMP_RENT_FACT_L0 SET category='Very basic' where "Feature count"<10;
update TEMP_RENT_FACT_L0 SET category='Standard' where "Feature count" between 10 and 20;
update TEMP_RENT_FACT_L0 SET category='Luxurious' where "Feature count">20;

alter table TEMP_RENT_FACT_L0 ADD scale_type VARCHAR(20);

update TEMP_RENT_FACT_L0 SET scale_type='Extra small' where property_no_of_bedrooms<=1;
update TEMP_RENT_FACT_L0 SET scale_type='Small' where property_no_of_bedrooms BETWEEN 2 AND 3;
update TEMP_RENT_FACT_L0 SET scale_type='Medium' where property_no_of_bedrooms BETWEEN 4 AND 6;
update TEMP_RENT_FACT_L0 SET scale_type='Large' where property_no_of_bedrooms BETWEEN 7 AND 10;
update TEMP_RENT_FACT_L0 SET scale_type='Extra large' where property_no_of_bedrooms>10;

alter table TEMP_RENT_FACT_L0 ADD period VARCHAR(20);

update TEMP_RENT_FACT_L0 SET period='Short' where Months<6;
update TEMP_RENT_FACT_L0 SET period='Medium' where Months BETWEEN 6 AND 12;
update TEMP_RENT_FACT_L0 SET period='Long' where Months>12;

/*CREATING RENT FACT*/    
create table RENT_FACT_L0 AS 
select property_id, property_type, year as year, category, scale_type as scale_id, period as period_id, COUNT(rent_id) AS "Total Number of Rent", SUM(price) AS "Total Rental Fees" 
from TEMP_RENT_FACT_L0 
group by (property_id, property_type, year, category, scale_type, period);


/*------------------------------SALE--------------------------------*/

/*DROPPING SALE DIMENSION TABLES*/

--PROPERTY_TYPE_L0 (SHARED DIMESNION) ALREADY CREATED--
drop table SALES_YEAR_L0;
drop table property_feature_dim_l0;
/*DROPPING SALE FACT TABLES*/
drop table TEMP_SALE_FACT_L0;
drop table SALE_FACT_L0;

/*CREATING PROPERTY FEATURE  DIMENSION TABLE*/
create table property_feature_dim_l0 AS select property_id, feature_code from property_feature;

/*CREATING SALE YEAR DIMENSION TABLE*/
CREATE TABLE SALES_YEAR_L0 
AS SELECT DISTINCT(to_char(sale_date,'yyyy')) as year_of_sales FROM SALE
WHERE NOT (to_char(sale_date,'yyyy')) is null;

/*CREATING TEMP SALE FACT TABLE*/
CREATE TABLE TEMP_SALE_FACT_L0 AS 
select s.property_id, p.property_type,to_char(s.sale_date,'yyyy') as sale_year, s.price from sale s 
JOIN property p ON s.property_id=p.property_id
JOIN monre.address ad on ad.address_id=p.address_id
JOIN postcode pc ON pc.postcode=ad.postcode
WHERE NOT s.client_person_id IS NULL;

/*CREATING SALE FACT TABLE*/
CREATE TABLE SALE_FACT_L0 
AS SELECT property_id, property_type,sale_year, SUM(price) as total_sales_price, COUNT(property_id) as total_sales
FROM TEMP_SALE_FACT_L0 
GROUP BY property_id,property_type,sale_year;





/*------------------------------ADVERTISEMENT--------------------------------*/

/*DROPPING ADVERTISEMENT DIMENSION TABLES*/
drop table ADVERT_DIM_L0;
drop table PROPERTY_ADVERT_DIM_L0;
drop table PROPERTY_ADVERT_DATE_DIM_L0;
--PROPERTY TABLE (SHARED DIMESNION) ALREADY CREATED--

/*DROPPING ADVERTISEMENT FACT TABLE*/
drop table TEMP_ADVERTISEMENT_FACT_L0;
drop table ADVERTISEMENT_FACT_L0;

/*CREATING ADVERTISEMENT DIMENSION*/
CREATE TABLE ADVERT_DIM_L0 
AS SELECT advert_id,advert_name FROM ADVERTISEMENT;

/*CREATING PROPERTY_ADVERT DIMENSION*/
CREATE TABLE PROPERTY_ADVERT_DIM_L0 
AS SELECT property_id,advert_id FROM PROPERTY_ADVERT;

/*CREATING PROPERTY ADVERTISEMENT DATE DIMENSION*/
CREATE TABLE PROPERTY_ADVERT_DATE_DIM_L0 
AS SELECT DISTINCT 
TO_CHAR(property_date_added,'Mon')||'_'||TO_CHAR(property_date_added,'yyyy') AS date_id, 
TO_CHAR(property_date_added,'mm')as  month,
TO_CHAR(property_date_added,'yyyy') AS year 
FROM PROPERTY;

/*CREATING TEMP ADVERTISEMENT FACT*/
CREATE TABLE TEMP_ADVERTISEMENT_FACT_L0 AS select p.property_id,pd.property_date_added,a.advert_name 
from advertisement a join property_advert p ON a.advert_id=p.advert_id
join property pd ON p.property_id=pd.property_id 
group by p.property_id,pd.property_date_added,a.advert_name;

/*CREATING ADVERTISEMENT FACT*/
CREATE TABLE ADVERTISEMENT_FACT_L0 
AS select property_id, TO_CHAR(property_date_added,'Mon')||'_'||TO_CHAR(property_date_added,'yyyy') as date_id, 
COUNT(property_id) as total_properties 
from TEMP_ADVERTISEMENT_FACT_L0
group by property_id, TO_CHAR(property_date_added,'Mon')||'_'||TO_CHAR(property_date_added,'yyyy');



/*------------------------------AGENT--------------------------------*/

/*DROPPING AGENT DIMENSION TABLES*/
drop table AGENT_DIM_L0;
drop table AGENT_OFFICE_DIM_L0;
drop table OFFICE_DIM_L0;
drop table AGENT_OFFICE_SIZE_DIM_L0;
drop table GENDER_DIM_L0;

/*DROPPING AGENT FACT TABLES*/
drop table TEMP_AGENT_L0;
drop table AGENT_FACT_L0;

/*CREATING GENDER DIMENSION*/
CREATE TABLE GENDER_DIM_L0 
AS SELECT DISTINCT gender 
FROM PERSON;

/*CREATING AGENT DIMENSION*/
CREATE TABLE AGENT_DIM_L0 
AS SELECT DISTINCT(ag.person_id) as agent_person_id, 
p.title||'.'||p.first_name||' '||p.last_name AS agent_name 
FROM Agent ag JOIN PERSON p ON ag.person_id=p.person_id;
    
/*CREATING AGENT_OFFICE DIMENSION*/
CREATE TABLE AGENT_OFFICE_DIM_L0 
AS SELECT person_id as agent_person_id, office_id 
FROM AGENT_OFFICE;

/*CREATING OFFICE DIMENSION*/
CREATE TABLE OFFICE_DIM_L0 
AS select office_id,office_name 
FROM OFFICE;

/*CREATING AGENT_OFFICE_SIZE DIMENSION*/
CREATE TABLE AGENT_OFFICE_SIZE_DIM_L0 
(office_size_id VARCHAR2(50), office_size_desc VARCHAR2(70));
INSERT INTO AGENT_OFFICE_SIZE_DIM_L0 VALUES('SMALL','< 4 Employees');
INSERT INTO AGENT_OFFICE_SIZE_DIM_L0 VALUES('MEDIUM',' 4-12 employees');
INSERT INTO AGENT_OFFICE_SIZE_DIM_L0 VALUES('LARGE','> 12 employees');


/*CREATING TEMP AGENT FACT*/
CREATE TABLE TEMP_AGENT_L0 
AS SELECT person_id, gender, property_id, salary,sum(price) as total_agent_worth, count(person_id) as total_agents 
FROM 
(
select a.person_id, pe.gender, a.salary, p.property_id, s.price from agent a
LEFT JOIN SALE s ON a.person_id=s.agent_person_id
LEFT JOIN PROPERTY p ON s.property_id=p.property_id 
LEFT JOIN ADDRESS ad ON p.address_id=ad.address_id 
LEFT JOIN AGENT_OFFICE ao ON a.person_id=ao.person_id
LEFT JOIN PERSON pe ON a.person_id=pe.person_id     
union 
select a.person_id, pe.gender, a.salary, p.property_id, r.price*(r.rent_end_date-r.rent_start_date)/7 from agent a
left join rent r ON a.person_id=r.agent_person_id
left join property p ON r.property_id=p.property_id 
left join address ad ON p.address_id=ad.address_id
left join agent_office ao ON a.person_id=ao.person_id
left join person pe ON a.person_id=pe.person_id
)
where price IS NOT NULL 
group by person_id, gender, property_id, salary ORDER BY SUM(price) DESC;

ALTER TABLE TEMP_AGENT_L0 
ADD office_size_id varchar(10);

UPDATE TEMP_AGENT_L0 SET office_size_id='SMALL' 
WHERE person_id in 
(select a.person_id from TEMP_AGENT_L0 a join agent_office b ON a.person_id =b.person_id where b.office_id in (select office_id from agent_office group by office_id having count(person_id)<4));
update TEMP_AGENT_L0 set office_size_id='Medium' where person_id in 
(select a.person_id from TEMP_AGENT_L0 a join agent_office b ON a.person_id =b.person_id where b.office_id in (select office_id from agent_office group by office_id having count(person_id) between 4 and 12));
update TEMP_AGENT_L0 set office_size_id='Big' where person_id in 
(select a.person_id from TEMP_AGENT_L0 a join agent_office b ON a.person_id =b.person_id where b.office_id in (select office_id from agent_office group by office_id having count(person_id)>12));
    
/*CREATING AGENT FACT TABLE*/
CREATE TABLE AGENT_FACT_L0 AS 
SELECT  person_id as agent_person_id, gender, property_id, office_size_id, sum(salary) as total_Salary,
SUM(total_agent_worth) as total_agent_worth, count(total_agents) as total_agents
FROM TEMP_AGENT_L0 
GROUP BY person_id, gender, property_id, office_size_id;


/*--------------------SELECT STATEMENTS--------------------------*/
SELECT * FROM SEASON_DIM_L2;
SELECT * FROM VISIT_CLIENT_DIM_L2;
SELECT * FROM VISIT_CLIENT_DIM_SCD_L2;
SELECT * FROM CLIENT_DIM_L2;
SELECT * FROM CLIENT_YEAR_DIM_L2;
SELECT * FROM BUDGET_DIM_L2;
SELECT * FROM CLIENT_WISH_DIM_L2;
SELECT * FROM LOCATION_DIM_L2;
SELECT * FROM RENTED_YEAR_DIM_L2;
SELECT * FROM RENT_TIME_PERIOD_DIM_L2;
SELECT * FROM PROPERTY_FEATURE_CATEGORY_DIM_L2;
SELECT * FROM PROPERTY_SCALE_DIM_L2;
SELECT * FROM PROPERTY_DIM_L2;
SELECT * FROM RENT_PROPERTY_SCD_DIM_L2;
SELECT * FROM PROPERTY_TYPE_DIM_L2;
SELECT * FROM SALES_YEAR_L2;
select * from property_feature_dim_l2;
SELECT * FROM ADVERT_DIM_L2;
SELECT * FROM PROPERTY_ADVERT_DIM_L2;
SELECT * FROM PROPERTY_ADVERT_DATE_DIM_L2;
SELECT * FROM AGENT_DIM_L2;
SELECT * FROM AGENT_OFFICE_DIM_L2;
SELECT * FROM OFFICE_DIM_L2;
SELECT * FROM AGENT_OFFICE_SIZE_DIM_L2;
SELECT * FROM GENDER_DIM_L2;
*/
SELECT * FROM TEMP_VISIT_FACT_L2;
SELECT * FROM temp_SALE_FACT_L2;
SELECT * FROM TEMP_ADVERTISEMENT_FACT_L2;
SELECT * FROM TEMP_AGENT_FACT_L2;
SELECT * FROM RENT_FACT_L2;
SELECT * FROM CLIENT_FACT_L2;


SELECT * FROM SEASON_DIM_L0;
SELECT * FROM VISIT_CLIENT_DIM_L0;
SELECT * FROM VISIT_CLIENT_DIM_SCD_L0;
SELECT * FROM CLIENT_DIM_L0;
SELECT * FROM CLIENT_YEAR_DIM_L0;
SELECT * FROM BUDGET_DIM_L0;
SELECT * FROM CLIENT_WISH_DIM_L0;
SELECT * FROM FEATURE_DIM_L0;
SELECT * FROM RENTED_YEAR_DIM_L0;
SELECT * FROM RENT_TIME_PERIOD_DIM_L0;
SELECT * FROM PROPERTY_FEATURE_CATEGORY_DIM_L0;
SELECT * FROM PROPERTY_SCALE_DIM_L0;
SELECT * FROM PROPERTY_DIM_L0;
SELECT * FROM RENT_PROPERTY_SCD_DIM_L0;
SELECT * FROM PROPERTY_TYPE_DIM_L0;
SELECT * FROM SALES_YEAR_L0;
SELECT * FROM ADVERT_DIM_L0;
SELECT * FROM PROPERTY_ADVERT_DIM_L0;
SELECT * FROM PROPERTY_ADVERT_DATE_DIM_L0;
SELECT * FROM AGENT_DIM_L0;
SELECT * FROM AGENT_OFFICE_DIM_L0;
SELECT * FROM OFFICE_DIM_L0;
SELECT * FROM AGENT_OFFICE_SIZE_DIM_L0;
SELECT * FROM GENDER_DIM_L0;
SELECT * FROM  property_feature_dim_l0 ;

SELECT * FROM TEMP_VISIT_FACT_L0;
SELECT * FROM TEMP_SALE_FACT_L0;
SELECT * FROM ADVERTISEMENT_FACT_L0;
SELECT * FROM TEMP_AGENT_L0;
SELECT * FROM RENT_FACT_L0;
SELECT * FROM CLIENT_FACT_L0;