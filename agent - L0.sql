drop table Agent_Info_Dim;
drop table agent_office_bridge_dim;
drop table Office_Dim;
drop table agent_office_size_Dim;
drop table property_dim;

create table Agent_Info_Dim as select Distinct(a.Person_Id),
p.title||' '||p.first_name||' '||p.last_name as "Agent Name" 
from monre.Agent a join monre.person p on a.person_id=p.person_id;

create table agent_office_bridge_dim as select Person_Id,office_id from monre.agent_office;

create table Office_Dim as select office_id,office_name from monre.Office;

create table agent_office_size_Dim (office_type varchar2(30),office_Description varchar2(40));

insert into agent_office_size_Dim values('Small','< 4 employees');

insert into agent_office_size_Dim values('Medium',' 4-12 employees');

insert into agent_office_size_Dim values('Large','> 12 employees');

create table property_dim as select p.property_id,a.suburb,po.state_code from monre.property p
 join monre.address a on p.address_id=a.address_id
 join MONRE.postcode po on a.postcode=po.postcode;

drop table agent_tempfact;

create table agent_tempfact as select person_id,gender,property_id,salary,sum(price) "Total Worth",count(person_id) "Total Agents" from (
select a.person_id,pe.gender,a.salary,p.property_id,s.price from monre.agent a
left join monre.sale s on a.person_id=s.agent_person_id
left join monre.property p on s.property_id=p.property_id 
left join monre.address ad on p.address_id=ad.address_id 
left join MONRE.agent_office ao on a.person_id=ao.person_id
left join monre.person pe on a.person_id=pe.person_id
union 
select a.person_id,pe.gender,a.salary,p.property_id,r.price*(r.rent_end_date-r.rent_start_date)/7 from monre.agent a
left join monre.rent r on a.person_id=r.agent_person_id
left join monre.property p on r.property_id=p.property_id 
left join monre.address ad on p.address_id=ad.address_id
left join MONRE.agent_office ao on a.person_id=ao.person_id
left join monre.person pe on a.person_id=pe.person_id
)
where price is not null 
group by person_id,gender,property_id,salary order by sum(price) desc;

alter table agent_tempfact add office_size varchar(10);

select a.person_id from agent_tempfact a join agent_office_bridge_dim b on a.person_id =b.person_id 
where b.office_id in (select office_id from monre.agent_office group by office_id having count(person_id)<4);

update agent_tempfact set office_size='Small' 
where person_id in (select a.person_id from agent_tempfact a 
join agent_office_bridge_dim b on a.person_id =b.person_id 
where b.office_id in (select office_id from monre.agent_office 
group by office_id having count(person_id)<4));

update agent_tempfact set office_size='Medium' where person_id in (select a.person_id from agent_tempfact a join agent_office_bridge_dim b on a.person_id =b.person_id where b.office_id in (select office_id from monre.agent_office group by office_id having count(person_id) between 4 and 12));
update agent_tempfact set office_size='Big' where person_id in (select a.person_id from agent_tempfact a join agent_office_bridge_dim b on a.person_id =b.person_id where b.office_id in (select office_id from monre.agent_office group by office_id having count(person_id)>12));

 

select * from agent_tempfact;

create table agent_fact as select person_id,gender,property_id,office_size,sum(salary) "Total Salary",sum("Total Worth") "Total Worth",sum("Total Agents") "Total Agents"
from agent_tempfact group by (person_id,gender,property_id,office_size);


select avg("Total Salary") "Average Salary" from agent_fact a 
join agent_office_bridge_dim b on a.person_id=b.person_id 
join office_dim o on b.office_id=o.office_id where o.office_name like '%Ray White%' order by a.person_id;


select b."Agent Name" from agent_fact a
join property_dim p on a.property_id=p.property_id
join agent_info_dim b on a.person_id=b.person_id
where p.suburb='Melbourne' and "Total Worth" is not null
group by b."Agent Name" order by sum("Total Worth") desc fetch next 3 rows only;

select count(distinct("Agent Name")) "Total Female Agents" from agent_fact a join agent_info_dim b on a.person_id=b.person_id  where gender='Female' and office_size='Medium';


