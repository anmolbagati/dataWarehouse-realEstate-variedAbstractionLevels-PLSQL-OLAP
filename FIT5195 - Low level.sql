--Creating dimension tables for making rentfact table
-- Creating rentalperiod_dim table
drop table rentalperiod_dim cascade constraints purge;
create table rentalperiod_dim (rental_period varchar(20), 
rental_desc varchar(50));

insert into rentalperiod_dim values ('Short','< 6 months');
insert into rentalperiod_dim values ('Medium','6-12 months');
insert into rentalperiod_dim values ('Big','> 12 months');

--Creating suburb_dim table
drop table suburb_dim cascade constraints purge;
create table suburb_dim as 
select distinct suburb from address;

--Creating property_dim table
drop table property_dim CASCADE constraints purge;
create table property_dim as 
select property_id from property;

--Creating Propertyfeature_dim
drop table propertyfeature_dim cascade constraints purge;
create table propertyfeature_dim as 
select * from property_feature;


--Creating slowly changing dimension propertyrenthistory_dim
drop table propertyrenthistory_dim cascade constraints purge;
create table propertyrenthistory_dim as
select property_id, rent_start_date, rent_end_date, price from rent;

--Creating state_dim table
drop table state_dim cascade constraints purge;
create table state_dim as
select distinct * from state;

--Creating Propertytype_dim table
drop table propertytype_dim cascade constraints purge;
create table propertytype_dim as
select distinct property_type from property;
--select * from propertytype_dim;
--select * from suburb_dim;

--Creating Featurecategory_dim table
drop table featurecategory_dim cascade constraints;
create table featurecategory_dim (featurecategory_id Varchar(15),
category_desc varchar(15));

insert into featurecategory_dim values ('Basic','< 10 features');
insert into featurecategory_dim values ('Standard','10-20 features');
insert into featurecategory_dim values ('Luxurious','> 20 features');

--Creating Propertyscale_dim table
drop table propertyscale_dim cascade constraints purge;
create table propertyscale_dim (property_scale Varchar(15),
scale_desc varchar(15));

insert into propertyscale_dim values ('Extra Small','<= 1 Bedroom');
insert into propertyscale_dim values ('Small','2-3 Bedrooms');
insert into propertyscale_dim values ('Medium','3-6 Bedrooms');
insert into propertyscale_dim values ('Large','6-10 Bedrooms');
insert into propertyscale_dim values ('Extra Large','> 10 Bedrooms');

--Creating Rentstart_dim table 
drop table rentstart_dim cascade constraints purge;
create table rentstart_dim as
select distinct to_char(rent_start_date,'yyyyMMDD') as rentstart_id,
to_char(rent_start_date,'yyyy') as rentstart_year,
to_char(rent_start_date,'MM') as rentstart_month,
to_char(rent_start_date,'dd') as rentstart_date from rent where rent_start_date is not null;
--select * from rentstart_dim;

--Creating Rentend_dim table 
drop table rentend_dim cascade constraints purge;
create table rentend_dim as
select distinct to_char(rent_end_date,'yyyyMon') as rentend_id,
to_char(rent_end_date,'yyyy') as rentend_year,
to_char(rent_end_date,'Mon') as rentend_month,
to_char(rent_end_date,'dd') as rentend_date from rent where rent_end_date is not null;

--select * from rentend_dim;

--Creatimg season_dim table
drop table SEASON_DIM cascade constraints purge;
CREATE TABLE SEASON_DIM
(
SEASON_ID VARCHAR(10),
Season_desc VARCHAR(50)
);
INSERT INTO SEASON_DIM VALUES ( 'AUTUMN', 'MAR-MAY' );
INSERT INTO SEASON_DIM VALUES ( 'SUMMER', 'DEC-FEB' );
INSERT INTO SEASON_DIM VALUES ( 'SPRING', 'SEP-NOV' );
INSERT INTO SEASON_DIM VALUES ( 'WINTER', 'JUN-AUG' );

--Select * from season_dim;

--purge recyclebin;

--Creating renttempfact table
drop table renttempfact cascade constraints purge;
create table renttempfact as
select a.suburb,
re.property_id,
p.property_type,
re.rent_start_date,
re.rent_end_date,
count(distinct(pf.feature_code)) as no_of_features,
to_char(re.rent_start_date,'yyyymmdd') as rentstart_id,
to_char(re.rent_end_date,'yyyymmdd') as rentend_id,
po.state_code,
p.property_no_of_bedrooms,
sum(((re.rent_end_date - re.rent_start_date)/7)*(re.price)) as Total_rent,
count(distinct(re.rent_id)) as No_of_rent,
count(distinct(re.property_id)) as No_of_property
from address a, property p, rent re, postcode po, property_feature pf
where a.address_id = p.address_id and
re.property_id = p.property_id(+) and
p.property_id = pf.property_id(+) and
po.postcode = a.postcode and rent_start_date is not null
group by a.suburb,
re.property_id,
re.rent_id,
p.property_type,
re.rent_start_date,
re.rent_end_date,
po.state_code,
p.property_no_of_bedrooms,
to_char(re.rent_start_date,'yyyymmdd'),
to_char(re.rent_end_date,'yyyymmdd');

--select count(*) from renttempfact;
--select * from renttempfact where property_id =3000;

--Altering and updating renttempfact table
ALTER TABLE renttempfact
ADD (
rental_period VARCHAR2(20),
season_id VARCHAR2(20),
property_scale varchar(15),
featurecategory_id varchar(15),
rental_difference number(4),
rental_fees number(10)
);

--Finding out the months for which properties were rented using months_between function.
update renttempfact set
rental_difference = months_between (rent_end_date, rent_start_date);

-- dividing rent by total features
update renttempfact set
rental_fees = total_rent/no_of_features
where no_of_features > 0;

update renttempfact set
rental_fees = total_rent
where no_of_features = 0;

--updating featurecategory_id table
update renttempfact set
featurecategory_id = 'Basic'
where no_of_features < 10;

update renttempfact set
featurecategory_id = 'Standard'
where no_of_features >= 10 and no_of_features <= 20;

update renttempfact set
featurecategory_id = 'Luxurious'
where no_of_features > 20;

-- UPDATING RENTAL_PERIOD
update renttempfact set
rental_period = 'Short'
where rental_difference <= 6;

update renttempfact set
rental_period = 'Medium'
where rental_difference > 6 and rental_difference < 12;

update renttempfact set
rental_period = 'Big'
where rental_difference >= 12 ;

-- UPDATING SEASON_ID
UPDATE renttempfact SET
SEASON_ID= 'WINTER'
WHERE TO_CHAR(rent_start_date,'MM') >= '06'
AND TO_CHAR(rent_start_date,'MM') <= '08';

UPDATE renttempfact SET
SEASON_ID='SPRING'
WHERE TO_CHAR(RENT_START_DATE,'MM') >= '09'
AND TO_CHAR(RENT_START_DATE,'MM') <= '11';

UPDATE renttempfact SET
SEASON_ID='AUTUMN'
WHERE TO_CHAR(RENT_START_DATE,'MM') >= '03'
AND TO_CHAR(RENT_START_DATE,'MM') <= '04';

UPDATE renttempfact SET
SEASON_ID = 'SUMMER'
WHERE SEASON_ID IS NULL;

-- UPDATING PROPERTY_SCALE
update renttempfact set
property_scale = 'Extra Small'
where property_no_of_bedrooms <= 1;

update renttempfact set
property_scale = 'Small'
where property_no_of_bedrooms >= 2 and property_no_of_bedrooms < 3;

update renttempfact set
property_scale = 'Medium'
where property_no_of_bedrooms >= 3 and property_no_of_bedrooms < 6;

update renttempfact set
property_scale = 'Large'
where property_no_of_bedrooms >= 6 and property_no_of_bedrooms < 10;

update renttempfact set
property_scale = 'Extra Large'
where property_no_of_bedrooms >= 10;

--Creating rentfact table
drop table rentfact cascade constraints purge;
create table rentfact as
select suburb,
property_id,
rental_period,
property_scale,
featurecategory_id,
rentstart_id,
rentend_id,
property_type,
state_code,
season_id,
rental_fees,
No_of_rent,
No_of_property
from renttempfact;

--select * from rentfact where property_id = 3000;
--select * from rent where property_id = 2965;
--select sum(no_of_property) from rentfact;
--select count(*) from rent where rent_start_date is not null;
--Both counts are equal hence rentfact is accurate
--
--
--
--END OF RENT FACT TABLE
--
--

--Creating salesdate_dim
drop table salesdate_dim cascade constraints purge; 
create table salesdate_dim as 
select distinct to_char(sale_date,'yyyymm') as saledate_id,
to_char(sale_date,'yyyy') as saledate_year,
to_char(sale_date,'mm') as saledate_month,
to_char(sale_date,'dd') as saledate_day from sale;

--Creating salestempfact table
drop table salestempfact cascade constraints purge;
create table salestempfact as
select p.property_id,
p.property_type,
pa.state_code,
to_char(s.sale_date,'yyyy') as client_year,
s.sale_date,
to_char(s.sale_date,'yyyymm') as saledate_id,
sum(s.price) as Total_sales,
count(s.sale_id) as No_of_sale,
count(s.property_id) as No_of_property
from property p, sale s, postcode pa, address a 
where p.property_id = s.property_id and
a.postcode=pa.postcode and sale_date is not null and
a.address_id = p.address_id
group by p.property_id, p.property_type, pa.state_code, s.sale_date, to_char(s.sale_date,'yyyy'), 
to_char(s.sale_date,'yyyymm');

--select count(*) from salestempfact;

--Altering and updating season_id in salestempfact table
ALTER TABLE salestempfact
ADD 
season_id VARCHAR2(20);

-- UPDATING SEASON_ID in salestempfact
UPDATE salestempfact SET
SEASON_ID= 'WINTER'
WHERE TO_CHAR(sale_date,'MM') >= '06'
AND TO_CHAR(sale_date,'MM') <= '08';

UPDATE salestempfact SET
SEASON_ID='SPRING'
WHERE TO_CHAR(sale_DATE,'MM') >= '09'
AND TO_CHAR(sale_DATE,'MM') <= '11';

UPDATE salestempfact SET
SEASON_ID='AUTUMN'
WHERE TO_CHAR(sale_DATE,'MM') >= '03'
AND TO_CHAR(sale_DATE,'MM') <= '04';

UPDATE salestempfact SET
SEASON_ID = 'SUMMER'
WHERE SEASON_ID IS NULL;

--select count(*) from salestempfact;

--Creating salesfact from salestempfact
drop table salesfact cascade constraints purge;
create table salesfact as
select property_id,
property_type,
state_code,
saledate_id,
client_year,
season_id,
Total_sales,
No_of_sale,
No_of_property from salestempfact;

--select * from salesfact;
--select count(*) from salesfact;
--select count(*) from sale where sale_date is not null;
--Both the counts are saem hence sale fact is accurate
--
--
--END OF SALES FACT TABLE
--
--
--select client_person_id as client_id, agent_person_id as agent_id, property_id from visit;

--Creating visitdate_dim
drop table visitdate_dim cascade constraints purge;
create table visitdate_dim as
select distinct to_char(visit_date, 'yyyymmday') as visit_date,
to_char(visit_date,'yyyy') as Year,
to_char(visit_date,'Mon') as Month,
to_char(visit_date,'day') as Day
from visit;

--Creating visittime_dim
drop table visittime_dim cascade constraints purge;
create table visittime_dim as
select to_char(visit_date, 'hh:mi') as visit_time,
to_char(visit_date,'hh') as hour,
to_char(visit_date,'mi') as Minute
from visit;

--Creating client_dim table
drop table client_dim cascade constraints purge;
create table client_dim as
select person_id as client_id,
min_budget, max_budget from client;

--Creating agent_dim table
drop table agent_dim cascade constraints purge;
create table agent_dim as
select person_id as agent_id,
salary from agent;

--Creating visittempfact table
drop table visittempfact cascade constraints purge;
create table visittempfact as
select to_char(visit_date,'yyyymonday') as visit_date1,
visit_date,
to_char(visit_date,'hh:mi') as visit_time,
property_id,
agent_person_id as agent_id,
client_person_id as client_id,
count(property_id) as Total_no_of_visit
from visit 
where visit_date is not null
group by client_person_id, agent_person_id, property_id, visit_date;

--Altering visittempfact table for season_id
ALTER TABLE visittempfact
ADD 
season_id VARCHAR2(20);

--select * from visittempfact;

-- UPDATING SEASON_ID in visittempfact
UPDATE visittempfact SET
SEASON_ID= 'WINTER'
WHERE to_char(visit_date,'MM') >= '06'
AND TO_CHAR(visit_date,'MM') <='08';

UPDATE visittempfact SET
SEASON_ID='SPRING'
WHERE TO_CHAR(visit_DATE,'MM') >= '09'
AND TO_CHAR(visit_DATE,'MM') <= '11';

UPDATE visittempfact SET
SEASON_ID='AUTUMN'
WHERE TO_CHAR(visit_DATE,'MM') >= '03'
AND TO_CHAR(visit_DATE,'MM') <= '04';

UPDATE visittempfact SET
SEASON_ID = 'SUMMER'
WHERE SEASON_ID IS NULL;

--select count(*) from visittempfact;
--Creating visitfact table
drop table visitfact cascade constraints purge;
create table visitfact as
select client_id, agent_id,
property_id,
visit_date,
visit_time,
season_id,
total_no_of_visit
from visittempfact;


--select count(*) from visitfact;
--select count(*) from visit where visit_date is not null;
--Both the counts are the same hence visit fact is accurate 
--
--END OF VISIT FACT
--
--


--Gender Dim--
drop table gender_dim cascade constraints purge;
create table gender_dim as 
select distinct gender from person;

--Clientwishlist Dim--
drop table clientwishlist_dim cascade constraints purge;
create table clientwishlist_dim as 
select * from client_wish; 

--Creating feature_dim
Drop table feature_dim cascade constraints purge;
create table feature_dim as select distinct feature_code, feature_description from feature;

--Creating budgetcategory_dim table
Drop table budgetcategory_dim cascade constraints purge;
create table budgetcategory_dim (budgetcategory_id varchar(20), budgetcategory_desc varchar(50));

insert into budgetcategory_dim values ('Low','0 to 1000');
insert into budgetcategory_dim values ('Medium','1001 to 100000');
insert into budgetcategory_dim values ('High','100001 to 10000000');

--Creating time_dim table with respect to sale_date
drop table time_dim cascade constraints purge;
create table time_dim as 
select distinct to_char(sale_date,'yyyy') as client_year from sale where sale_date is not null;

--Select * from time_dim;

-- Creating Clienttempfact table --
Drop table clienttempfact cascade constraints purge;
Create table clienttempfact as select 
p.gender, 
c.person_id as client_id,
c.max_budget, 
to_char(s.sale_date,'yyyy') as client_year,
count(c.person_id) as total_no_of_clients
from person p, client c, sale s
where c.person_id=p.person_id(+) and c.person_id = s.client_person_id(+) 
group by p.gender, c.person_id, c.max_budget, to_char(s.sale_date,'yyyy')
union
select 
p.gender, 
c.person_id as client_id,
c.max_budget, 
to_char(r.rent_start_date,'yyyy') as client_year,
count(distinct(c.person_id)) as total_no_of_clients
from person p, client c, rent r
where c.person_id = p.person_id(+) and c.person_id = r.client_person_id(+) and p.gender is not null and r.rent_start_date is not null
group by p.gender, c.person_id, c.max_budget, to_char(r.rent_start_date,'yyyy')
union
select 
p.gender, 
c.person_id as client_id,
c.max_budget, 
to_char(v.visit_date,'yyyy') as client_year,
count(distinct(c.person_id)) as total_no_of_clients
from person p, client c, visit v
where c.person_id=p.person_id(+) and c.person_id = v.client_person_id (+) and p.gender is not null and v.visit_date is not null
group by p.gender, c.person_id, c.max_budget, to_char(v.visit_date,'yyyy');

--After and update clienttempfact table 
Alter table clienttempfact add (budgetcategory_id VARCHAR(10));

-- update table clienttempfact to input budgetcategory_id
update clienttempfact set budgetcategory_id='Low' where max_budget>0 and max_budget<= 1000;
update clienttempfact set budgetcategory_id='Medium' where max_budget>1001 and max_budget<= 100000;
update clienttempfact set budgetcategory_id='High' where max_budget>100001 and max_budget<= 10000000;

--select count(*) from clienttempfact;

--Creating clientfact table from clienttempfact 
drop table clientfact cascade constraints purge;
create table clientfact as select budgetcategory_id, client_year, gender, client_id, total_no_of_clients from clienttempfact;

--select * from clientfact;
--select count(*) from clientfact;
--Both counts are the same hence clientfact is accurate
--
--
-- END OF CLIENT FACT TABLE
--
--
--Creating Adverttime_dim table
drop table adverttime_dim cascade constraints purge;
create table adverttime_dim as
select distinct to_char(property_date_added,'yyyymmdd') as adverttime_id,
to_char(property_date_added,'dd') as advert_day,
to_char(property_date_added,'mm') as advert_month,
to_char(property_date_added,'yyyy') as advert_year from property;

--Create Advert_dim table
drop table advert_dim cascade constraints purge;
create table advert_dim as
select * from advertisement;

--Creating final advertisement_fact table
drop table advertisement_fact cascade constraints purge;
create table advertisement_fact as 
select to_char(property_date_added,'YYYYMMDD') as adverttime_id, pa.property_id, a.advert_id,
count(distinct(pa.property_id)) as No_of_properties
from property p, property_advert pa, advertisement a
where p.property_id = pa.property_id and a.advert_id = pa.advert_id(+)
group by pa.property_id, to_char(property_date_added,'YYYYMMDD'), 
a.advert_id;

--select count(distinct(property_id)) from advertisement_fact;
--select sum(no_of_properties) from advertisement_fact;
--select count(distinct(property_id)) from property_advert;
--select count(*) from advertisement_fact;
--select count(*) from property_advert;
--
--
-- END OF ADVERTISEMENT_FACT TABLE
--
--
--Creating agentoffice_dim table
drop table agentoffice_dim cascade constraints purge;
create table agentoffice_dim as
select * from agent_office;

--Creating tempoffice_dim table
drop table tempoffice_dim cascade constraints purge;
create table tempoffice_dim as
select o.office_id, o.office_name, count(ao.person_id) as no_of_employees 
from office o, agent_office ao 
where o.office_id = ao.office_id 
group by o.office_id,o.office_name,ao.person_id;

alter table tempoffice_dim 
add (office_size Varchar(20)); 

update tempoffice_dim 
set office_size = 'Small'
where no_of_employees < 4;

update tempoffice_dim 
set office_size = 'Medium'
where no_of_employees >= 4 and no_of_employees <=12;

update tempoffice_dim 
set office_size = 'Big'
where no_of_employees > 12;

--select count(*)  from tempoffice_dim;
--select *  from tempoffice_dim;

--Creating office_dim from tempoffice_dim
drop table office_dim cascade constraints purge;
create table office_dim as
select office_id, office_name, office_size from tempoffice_dim;

--Creating agent_fact table
drop table agent_fact cascade constraints purge;
create table agent_fact as
select p.gender,
(a.person_id) as agent_id,
sum(a.salary) as total_salary,
count(distinct(a.person_id)) as no_of_agents
from agent a, person p
where a.person_id = p.person_id
group by p.gender, a.person_id;

--select sum(no_of_agents) from agent_fact;
--select count(*) from agent;

--
--
-- END OF AGENT FACT
--
--
commit;
/*
select * from agent_fact;


select * from clientfact;

select count(*) from agent;


select * from rentfact;

select * from salesfact;

select * from advertisement_fact;

select count(*) from property_advert;

select * from visitfact;
select count(*) from visit;

*/