select * from monre.advertisement;
select * from monre.property;
select * from monre.property_advert;
select * from monre.sale;

select * from property_dim;
select * from property_advert_dim;
select * from property_date_dim;
drop table property_date_dim;

create table property_advert_dim as select property_id,advert_id from monre.property_advert;
create table advert_dim as select advert_id,advert_name from monre.advertisement;
create table property_date_dim as select distinct to_char(property_date_added,'Month')||' '||
to_char(property_date_added,'yyyy') date_id,to_char(property_date_added,'Month') month,
to_char(property_date_added,'yyyy') year from monre.property;

create table advertisement_tempfact as select p.property_id,pd.property_date_added,a.advert_name 
from monre.advertisement a join monre.property_advert p on a.advert_id=p.advert_id
join monre.property pd on p.property_id=pd.property_id 
group by p.property_id,pd.property_date_added,a.advert_name;

select sum("Total number of Properties") from advertisement_fact;
select * from property_dim;

create table advertisement_fact as select property_id,to_char(property_date_added,'Month')||' '||
to_char(property_date_added,'yyyy') date_id, count(property_id) "Total number of Properties" 
from advertisement_tempfact
group by property_id,to_char(property_date_added,'Month')||' '||
to_char(property_date_added,'yyyy');

select sum("Total number of Properties") "Total number of Properties",d.month,d.year from advertisement_fact a
join property_dim pd on a.property_id=pd.property_id
join property_advert_dim pa on a.property_id=pa.property_id
join advert_dim ad on pa.advert_id=ad.advert_id
join property_date_dim d on a.date_id=d.date_id
where ad.advert_name like '%Sale%' and d.month like '%April%' and d.year='2020'
group by d.month,d.year;
