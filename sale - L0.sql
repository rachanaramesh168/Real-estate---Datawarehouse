select * from monre.property;
select * from monre.feature;
select * from monre.property_feature;

create table property_feature_dim as select property_id,feature_code from monre.property_feature;
create table feature_dim as select feature_code,feature_description from monre.feature;
select * from location_dim;
select * from property_type_dim;
 
 select * from monre.postcode;
 create table sale_tempfact as select s.property_id,p.property_type,a.suburb||', '||pc.state_code as location_id,s.price from monre.sale s 
 join monre.property p on s.property_id=p.property_id
 join monre.address a on a.address_id=p.address_id
 join monre.postcode pc on pc.postcode=a.postcode;
 
 select * from sale_tempfact;
 
 create table sale_fact as select property_id,property_type,location_id,sum(price) "Total Price",count(property_id) "Number of Sales" from 
 sale_tempfact group by property_id,property_type,location_id;
 
 select avg("Total Price") "Average Sales",l.state_code from sale_fact s 
 join location_dim l on s.location_id=l.location_id where l.state_code='NSW' or l.state_code='VIC'
 group by l.state_code;
 
 select sum("Number of Sales") from sale_fact s 
 join property_dim pd on s.property_id=pd.property_id
 join property_feature_dim pfd on pd.property_id=pfd.property_id
 join feature_dim fd on fd.feature_code=pfd.feature_code
 where s.property_type ='Townhouse' and fd.feature_description='Air conditioning' and fd.feature_description='Security';
 
 select * from feature_dim where feature_description='Security';
 
 select * from monre.sale s 
 join monre.property p on s.property_id=p.property_id
 join monre.property_feature pf on p.property_id=pf.property_id
 join monre.feature f on f.feature_code=pf.feature_code
 where p.property_type ='Townhouse' and f.feature_description='Security'
 and f.feature_description='Air conditioning';
 
 