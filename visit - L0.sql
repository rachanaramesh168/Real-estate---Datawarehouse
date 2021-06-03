drop table season_dim;
create table season_dim(
season_id varchar(10),
interval varchar(20)
);

insert into season_dim values('Summer','dec-feb');
insert into season_dim values('Autumn','mar-may');
insert into season_dim values('Winter','jun-aug');
insert into season_dim values('Spring','sep-nov');

create table visit_dim_scd as select client_person_id,property_id,visit_date from monre.visit;

create table visit_dim as select distinct client_person_id, property_id from monre.visit;

create table visit_tempfact as select client_person_id,property_id,visit_date from monre.visit;

alter table visit_tempfact add season_id varchar(10);

update visit_tempfact set season_id ='Summer' where to_char(visit_date,'mon') in ('dec','jan','feb');

update visit_tempfact set season_id ='Autumn' where to_char(visit_date,'mon') in ('mar','apr','may');

update visit_tempfact set season_id ='Winter' where to_char(visit_date,'mon') in ('jun','jul','aug');

update visit_tempfact set season_id ='Spring' where to_char(visit_date,'mon') in ('sep','oct','nov');

create table visit_fact as select client_person_id,property_id,
season_id,count(visit_date) "Total number of Visits" 
from visit_tempfact 
group by client_person_id,property_id,season_id;

select sum("Total number of Visits") "Total number of Visits",season_id 
from visit_fact where season_id='Autumn' group by season_id;

commit;