create table property_feature_category_dim (category_id varchar(20), description varchar(20));
insert into property_feature_category_dim values('Very basic','<10');
insert into property_feature_category_dim values('Standard','10-20');
insert into property_feature_category_dim values('Luxurious','>20');
create table property_scale_dim (scale_id varchar(20), description varchar(20));
insert into property_scale_dim values('Extra small','<=1');
insert into property_scale_dim values('Small','2-3');
insert into property_scale_dim values('Medium','3-6');
insert into property_scale_dim values('Large','6-10');
insert into property_scale_dim values('Extra large','>10');
create table property_type_dim as select distinct property_type from MonRe.property;
create table rent_time_period_dim (period_id varchar(20), description varchar(20));
insert into rent_time_period_dim values('Short','<6');
insert into rent_time_period_dim values('Medium','6-12');
insert into rent_time_period_dim values('Long','>12');
create table rent_time_dim as select distinct to_char(rent_start_date,'yyyy') as year from MonRe.rent;
create table rent_location_dim as select distinct a.suburb||', '||p.state_code as Location_id ,a.suburb,p.state_code from Monre.address a join Monre.postcode p on a.postcode=p.postcode;
drop table rent_temp_fact;
create table rent_temp_fact as select rent_id,r.property_id,count(feature_code) as "Feature count",property_type,floor(months_between(to_date(rent_end_date,'dd-mm-yyyy'),to_date(rent_start_date,'dd-mm-yyyy'))) as Months,to_char(rent_start_date,'yyyy') as years,price*((to_date(rent_end_date,'dd-mm-yyyy')-to_date(rent_start_date,'dd-mm-yyyy'))/7)as price,p.property_no_of_bedrooms 
,a.suburb||', '||pc.state_code as Location_id from monre.rent r join monre.property p on r.property_id=p.property_id join monre.property_feature pf on p.property_id=pf.property_id join monre.address a on a.address_id=p.address_id join monre.postcode pc on a.postcode=pc.postcode
group by r.property_id,rent_id,property_type,months_between(to_date(rent_end_date,'dd-mm-yyyy'),to_date(rent_start_date,'dd-mm-yyyy')),to_char(rent_start_date,'yyyy'),price*((to_date(rent_end_date,'dd-mm-yyyy')-to_date(rent_start_date,'dd-mm-yyyy'))/7),p.property_no_of_bedrooms,a.suburb||', '||pc.state_code;


select * from rent_temp_fact;
alter table rent_temp_fact add category_id varchar(20); 
alter table rent_temp_fact add scale_id varchar(20);
alter table rent_temp_fact add period_id varchar(20);
update rent_temp_fact set category_id='Very basic' where "Feature count"<10;
update rent_temp_fact set category_id='Standard' where "Feature count" between 10 and 20;
update rent_temp_fact set category_id='Luxurious' where "Feature count">20;
update rent_temp_fact set scale_id='Extra small' where property_no_of_bedrooms<=1;
update rent_temp_fact set scale_id='Small' where property_no_of_bedrooms between 2 and 3;
update rent_temp_fact set scale_id='Medium' where property_no_of_bedrooms between 3 and 6;
update rent_temp_fact set scale_id='Large' where property_no_of_bedrooms between 6 and 10;
update rent_temp_fact set scale_id='Extra large' where property_no_of_bedrooms>10;
update rent_temp_fact set period_id='Short' where Months<6;
update rent_temp_fact set period_id='Medium' where Months between 6 and 12;
update rent_temp_fact set period_id='Long' where Months>12;

--drop table rent_fact;
create table rent_fact as select rent_id,property_type,years,location_id,category_id,scale_id,period_id,count(rent_id) as "Total Number of Rent",sum(price) as "Total Rental Fees" 
from rent_temp_fact group by (rent_id,property_type,years,location_id,category_id,scale_id,period_id);
select * from rent_fact;
--select price from monre.rent r 
--join monre.property p on r.property_id=p.property_id 
--join monre.address a on p.address_id=a.address_id 
--join monre.postcode pc on a.postcode=pc.postcode 
--where to_char(rent_start_date,'yyyy')=2019 and
--a.suburb='South Yarra' and
--state_code='VIC';
--select property_type,years,location_id,category_id,scale_id,period_id,count(rent_id) as "Total Number of Rent",sum(price) as "Total Rental Fees" 
--from rent_temp_fact group by (rent_id,property_type,years,location_id,category_id,scale_id,period_id);
--drop table rent_fact_lv2;
select sum("Total Rental Fees")/sum("Total Number of Rent") as "Average Rental Fees",property_type,years from rent_fact where location_id='South Yarra, VIC' and property_type like '%Apartment%' and years=2019 group by property_type,years;

create table rent_fact_lv2 as select property_type,years,location_id,category_id,scale_id,period_id,count(rent_id) as "Total Number of Rent",sum(price) as "Total Rental Fees" 
from rent_temp_fact group by (property_type,years,location_id,category_id,scale_id,period_id);
select sum("Total Rental Fees")/sum("Total Number of Rent") as "Average Rental Fees",property_type,years from rent_fact_lv2 where location_id='South Yarra, VIC' and property_type like '%Apartment%' and years=2019 group by property_type,years;

commit;