
--Creating Feature_dim1 table
drop table feature_dim1 cascade constraints purge;
create table feature_dim1 as
select distinct feature_code, feature_description from feature group by feature_code, feature_description;

--Creating Season_dim1 table
drop table season_dim1 cascade constraints purge;
CREATE TABLE SEASON_DIM1
(
SEASON_ID VARCHAR(10),
Season_desc VARCHAR(50)
);

--Inserting Initial values into season_dim1
INSERT INTO SEASON_DIM1 VALUES ( 'AUTUMN', 'MAR-MAY' );
INSERT INTO SEASON_DIM1 VALUES ( 'SUMMER', 'DEC-FEB' );
INSERT INTO SEASON_DIM1 VALUES ( 'SPRING', 'SEP-NOV' );
INSERT INTO SEASON_DIM1 VALUES ( 'WINTER', 'JUN-AUG' );

--Creating property_dim1 from temporary dimension table for property
drop table property_dim1 cascade constraints purge;
create table property_dim1 as 
select property_id from property;

--Creating state_dim1 table
drop table state_dim1 cascade constraints purge;
create table state_dim1 as
select distinct * from state;

--Creating Propertytype_dim1 table
drop table propertytype_dim1 cascade constraints purge;
create table propertytype_dim1 as
select distinct property_type from property;

--Creating Propertyfeature_dim1
drop table propertyfeature_dim1 cascade constraints purge;
create table propertyfeature_dim1 as 
select * from property_feature;

--Creating time_dim2 table with respect to sale_date
drop table time_dim2 cascade constraints purge;
create table time_dim2 as
select distinct to_char(sale_date,'yyyy') as client_year from sale where sale_date is not null;

--creating salestempfact1 table
drop table salestempfact1 cascade constraints purge;
create table salestempfact1 as
select distinct s.property_id,
pa.state_code,
p.property_type,
to_char(s.sale_date,'yyyy') as client_year,
s.sale_date,
sum(s.price) as Total_sales,
count(distinct(s.sale_id)) as No_of_sale,
count(distinct(s.property_id)) as No_of_property
from property p, sale s, postcode pa, address a 
where s.property_id = p.property_id(+) and --property_ids present in the sale table is needed in the salesfact
a.postcode=pa.postcode and
a.address_id = p.address_id and s.sale_date is not null
group by s.property_id, p.property_type, pa.state_code, s.sale_date, to_char(s.sale_date,'yyyy');

--select * from salestempfact1;

--Altering salestempfact1 table to input season_id
ALTER TABLE salestempfact1
ADD 
season_id VARCHAR2(20);



-- UPDATING SEASON_ID in salestempfact1 according to sale_date
UPDATE salestempfact1 SET
SEASON_ID= 'WINTER'
WHERE TO_CHAR(sale_date,'MM') >= '06'
AND TO_CHAR(sale_date,'MM') <= '08';

UPDATE salestempfact1 SET
SEASON_ID='SPRING'
WHERE TO_CHAR(sale_DATE,'MM') >= '09'
AND TO_CHAR(sale_DATE,'MM') <= '11';

UPDATE salestempfact1 SET
SEASON_ID='AUTUMN'
WHERE TO_CHAR(sale_DATE,'MM') >= '03'
AND TO_CHAR(sale_DATE,'MM') <= '04';

UPDATE salestempfact1 SET
SEASON_ID = 'SUMMER'
WHERE SEASON_ID IS NULL;



--Creating salesfact1 from salestempfact1
drop table salesfact1 cascade constraints purge;
create table salesfact1 as
select property_id,
property_type,
client_year,
state_code,
season_id,
sum(Total_sales) as total_sales,
sum(No_of_sale) as no_of_sale,
sum(No_of_property) as no_of_property from salestempfact1
group by
property_id, property_type, state_code, season_id, client_year;

--Checking for correctness of the fact table with the Opertational database
/*
select * from salesfact1;
select sum(total_sales) from salesfact1;
select sum(price) from sale where sale_date is not null;
select sum(no_of_property) from salesfact1;
select sum(no_of_sale) from salesfact1;
select count(property_id) from sale where sale_date is not null;
select count(no_of_property) from salesfact1;
select count(*) from sale;
*/
--
--
-- END OF SALES FACT TABLE
--
--

--Creating time_dim1 using union to add 5 different dates in one time dimension
drop table time_dim1 cascade constraints purge;
create table time_dim1 as
select distinct to_char(property_date_added,'yyyymmdd') as time_id,
to_char(property_date_added,'yyyy') as year, 
to_char(property_date_added,'mm') as month,
to_char(property_date_added,'dd') as day from property 
union
select distinct to_char(visit_date,'yyyymmdd') as time_id,
to_char(visit_date,'yyyy') as year,
to_char(visit_date,'mm') as month,
to_char(visit_date,'dd') as day from visit
union
select distinct to_char(sale_date,'yyyymmdd') as time_id,
to_char(sale_date,'yyyy') as year,
to_char(sale_date,'mm') as month,
to_char(sale_date,'dd') as day from sale
union
select distinct to_char(rent_start_date,'yyyymmdd') as time_id,
to_char(rent_start_date,'yyyy') as year,
to_char(rent_start_date,'mm') as month,
to_char(rent_start_date,'dd') as day from rent
union
select distinct to_char(rent_end_date,'yyyymmdd') as time_id,
to_char(rent_end_date,'yyyy') as year,
to_char(rent_end_date,'mm') as month,
to_char(rent_end_date,'dd') as day from rent;

--Create Advert_dim1 table
drop table advert_dim1 cascade constraints purge;
create table advert_dim1 as
select * from advertisement;

--Creating advertisementfact1 table 
drop table advertisementfact1 cascade constraints purge;
create table advertisementfact1 as 
select a.advert_id, to_char(p.property_date_added,'YYYYMMDD') as time_id, count(pa.property_id) as no_of_properties
from property p, property_advert pa, advertisement a
where p.property_id = pa.property_id and a.advert_id = pa.advert_id(+) --requires all advert_ids from the advertisement table hence the left outer join
group by a.advert_id, to_char(p.property_date_added,'YYYYMMDD');

--Checking for correctness of the fact table with the Opertational database
--select sum(no_of_properties) from advertisementfact1;
--select * from advertisementfact1;
--select count(*) from property_advert;
--
--
-- END OF ADVERTISEMENT_FACT TABLE
--
--
-- Creating rentalperiod_dim1 table
drop table rentalperiod_dim1 cascade constraints;
create table rentalperiod_dim1 (rental_period varchar(20), 
rental_desc varchar(50));

--Inserting initial dimention values and their description

insert into rentalperiod_dim1 values ('Short','< 6 months');
insert into rentalperiod_dim1 values ('Medium','6-12 months');
insert into rentalperiod_dim1 values ('Big','> 12 months');

--Creating suburb_dim1 table
drop table suburb_dim1 cascade constraints purge;
create table suburb_dim1 as 
select distinct suburb from address;

--Creating slowly changing dimension propertyrenthistory_dim1
drop table propertyrenthistory_dim1 cascade constraints purge;
create table propertyrenthistory_dim1 as
select property_id, rent_start_date, rent_end_date, price from rent;

--Creating Propertyscale_dim1 table
drop table propertyscale_dim1 cascade constraints purge;
create table propertyscale_dim1 (property_scale Varchar(15),
scale_desc varchar(15));

--Inserting initial property_scale values and their description
insert into propertyscale_dim1 values ('Extra Small','<= 1 Bedroom');
insert into propertyscale_dim1 values ('Small','2-3 Bedrooms');
insert into propertyscale_dim1 values ('Medium','3-6 Bedrooms');
insert into propertyscale_dim1 values ('Large','6-10 Bedrooms');
insert into propertyscale_dim1 values ('Extra Large','> 10 Bedrooms');

--Creating Featurecategory_dim table
drop table featurecategory_dim1 cascade constraints;
create table featurecategory_dim1 (featurecategory_id Varchar(15),
category_desc varchar(15));

--Inserting initial categories and their description as given
insert into featurecategory_dim1 values ('Basic','< 10 features');
insert into featurecategory_dim1 values ('Standard','10-20 features');
insert into featurecategory_dim1 values ('Luxurious','> 20 features');

--Creating Rentstart_dim1 table 
/*
create table rentstart_dim1 as
select distinct to_char(rent_start_date,'yyyyMondd') as rentstart_id,
to_char(rent_start_date,'yyyy') as rentstart_year,
to_char(rent_start_date,'Mon') as rentstart_month,
to_char(rent_start_date,'dd') as rentstart_date from rent;
*/

--purge recyclebin;

--Creating renttempfact1 table
drop table renttempfact1 cascade constraints purge;
create table renttempfact1 as
select a.suburb,
re.property_id,
p.property_type,
re.rent_start_date,
re.rent_end_date,
count(distinct(pf.feature_code)) as no_of_features,
po.state_code,
p.property_no_of_bedrooms,
to_char(re.rent_start_date,'yyyymmdd') as time_id,
sum(((re.rent_end_date - re.rent_start_date)/7)*(re.price)) as Total_rent,
count(distinct(re.rent_id)) as No_of_rent,
count(distinct(re.property_id)) as No_of_property
from address a, property p, rent re, postcode po, property_feature pf
where a.address_id = p.address_id and
re.property_id = p.property_id(+) and -- we need all properties from rent table hence the left outer join
p.property_id = pf.property_id(+) and -- all property_id values should be from the property table to checking for features
po.postcode = a.postcode and rent_start_date is not null 
group by a.suburb, re.property_id, re.rent_id, p.property_type, re.rent_start_date, 
re.rent_end_date, po.state_code, p.property_no_of_bedrooms, to_char(re.rent_start_date,'yyyymmdd'), re.rent_start_date, 
'yyyymmdd', to_char(re.rent_end_date,'yyyymmdd'), re.rent_end_date, 'yyyymmdd', to_char(re.rent_start_date,'yyyymmdd');

--Select count(*) from renttempfact1;

--Altering and updating renttempfact1 table
ALTER TABLE renttempfact1
ADD (
rental_period VARCHAR2(20),
season_id VARCHAR2(20),
property_scale varchar(15),
featurecategory_id varchar(15),
rental_difference number(4),
rental_fees number(10)
);



--Finding out the months for which properties were rented using months_between function.

update renttempfact1 set
rental_difference = months_between (rent_end_date, rent_start_date);

-- Dividing rent by total features
update renttempfact1 set
rental_fees = total_rent/no_of_features
where no_of_features > 0;

update renttempfact1 set
rental_fees = total_rent
where no_of_features = 0;

--updating featurecategory_id table
update renttempfact1 set
featurecategory_id = 'Basic'
where no_of_features < 10;

update renttempfact1 set
featurecategory_id = 'Standard'
where no_of_features >= 10 and no_of_features <= 20;

update renttempfact1 set
featurecategory_id = 'Luxurious'
where no_of_features > 20;

-- UPDATING RENTAL_PERIOD based on the rental_difference
update renttempfact1 set
rental_period = 'Short'
where rental_difference <= 6;

update renttempfact1 set
rental_period = 'Medium'
where rental_difference > 6 and rental_difference < 12;

update renttempfact1 set
rental_period = 'Big'
where rental_difference >= 12 ;



-- UPDATING SEASON_ID based on rent_start_date
UPDATE renttempfact1 SET
SEASON_ID= 'WINTER'
WHERE TO_CHAR(rent_start_date,'MM') >= '06'
AND TO_CHAR(rent_start_date,'MM') <= '08';

UPDATE renttempfact1 SET
SEASON_ID='SPRING'
WHERE TO_CHAR(RENT_START_DATE,'MM') >= '09'
AND TO_CHAR(RENT_START_DATE,'MM') <= '11';

UPDATE renttempfact1 SET
SEASON_ID='AUTUMN'
WHERE TO_CHAR(RENT_START_DATE,'MM') >= '03'
AND TO_CHAR(RENT_START_DATE,'MM') <= '04';

UPDATE renttempfact1 SET
SEASON_ID = 'SUMMER'
WHERE SEASON_ID IS NULL;



-- UPDATING PROPERTY_SCALE based on property_no_of_bedrooms

update renttempfact1 set
property_scale = 'Extra Small'
where property_no_of_bedrooms <= 1;

update renttempfact1 set
property_scale = 'Small'
where property_no_of_bedrooms >= 2 and property_no_of_bedrooms < 3;

update renttempfact1 set
property_scale = 'Medium'
where property_no_of_bedrooms >= 3 and property_no_of_bedrooms < 6;

update renttempfact1 set
property_scale = 'Large'
where property_no_of_bedrooms >= 6 and property_no_of_bedrooms < 10;

update renttempfact1 set
property_scale = 'Extra Large'
where property_no_of_bedrooms >= 10;



--Creating rentfact table from renttempfact1 table
drop table rentfact1 cascade constraints purge;
create table rentfact1 as
select suburb,
property_id,
featurecategory_id,
rental_period,
property_scale,
time_id,
property_type,
state_code,
season_id,
rental_fees,
No_of_rent,
No_of_property
from renttempfact1;

--select * from rentfact1;
--
--
--END OF RENT FACT
--
--
/*
select * from rentfact1;
select * from rent order by property_id;
select count(*) from rentfact1;
select * from rent order by property_id;
select * from rent where rent_start_date is null;
select sum(rental_fees) from rentfact1;
select sum(price) from rent where rent_start_date is not null;
select count(property_id) from rent where rent_start_date is not null;
select count(no_of_property) from rentfact1;
select count(no_of_rent) from rentfact1;
select count(*) from rent where rent_start_date is not null;
*/

/*
--Creating visitdate_dim1
create table visitdate_dim1 as
select to_char(visit_date, 'yyyymmdd') as visit_date,
to_char(visit_date,'yyyy') as Year,
to_char(visit_date,'mm') as Month,
to_char(visit_date,'dd') as Day
from visit;
*/

--Creating temporary visitfact table called visittempfact
drop table visittempfact1 cascade constraints purge;
create table visittempfact1 as
select 
visit_date,
to_char(visit_date,'YYYYMONDAY') as time_id,
count(distinct(property_id)) as no_of_properties,
count(*) as Total_no_of_visit
from visit 
where visit_date is not null
group by 
visit_date,
to_char(visit_date,'YYYYMONDAY')
;
--select * from visittempfact1;

--Alter visittempfact1 to insert season_id
ALTER TABLE visittempfact1
ADD 
season_id VARCHAR2(20);


--select * from visittempfact1;

-- UPDATING SEASON_ID in visittempfact1 based on visit_date
UPDATE visittempfact1 SET
SEASON_ID= 'WINTER'
WHERE to_char(visit_date,'MM') >= '06'
AND TO_CHAR(visit_date,'MM') <='08';

UPDATE visittempfact1 SET
SEASON_ID='SPRING'
WHERE TO_CHAR(visit_DATE,'MM') >= '09'
AND TO_CHAR(visit_DATE,'MM') <= '11';

UPDATE visittempfact1 SET
SEASON_ID='AUTUMN'
WHERE TO_CHAR(visit_DATE,'MM') >= '03'
AND TO_CHAR(visit_DATE,'MM') <= '04';

UPDATE visittempfact1 SET
SEASON_ID = 'SUMMER'
WHERE SEASON_ID IS NULL;

--select count(*) from visittempfact1;


--Creating visitfact1 table from visittempfact1
drop table visitfact1 cascade constraints purge;
create table visitfact1 as
select 
time_id,
season_id,
count(no_of_properties) as no_of_properties,
sum(Total_no_of_visit) as total_no_of_visits
from visittempfact1
group by time_id, season_id;
--
--
--END OF VISIT FACT
--
--
/*
select count(distinct(property_id)) from visit;
select * from visitfact1;
select count(*) from visitfact1;
select count(*) from visit;
select sum(no_of_properties) from visitfact1;
select sum(total_no_of_visits) from visitfact1;
*/

--Creating tempoffice_dim1 table
drop table tempoffice_dim1 cascade constraints purge;
create table tempoffice_dim1 as
select distinct o.office_id, o.office_name, count (distinct (ao.person_id)) as no_of_employees
from office o, agent_office ao 
where o.office_id = ao.office_id
group by o.office_id, o.office_name;

--Altering tempoffice_dim1 to add office_size as an attribute
alter table tempoffice_dim1 add 
(office_size varchar(20));

--updating office_size attribute in tempoffice dimension table based on no_of_employees
update tempoffice_dim1
set office_size = 'Small'
where no_of_employees < 4;

update tempoffice_dim1
set office_size = 'Medium'
where no_of_employees >= 4 and no_of_employees <=12;

update tempoffice_dim1
set office_size = 'Big'
where no_of_employees > 12;

--select * from tempoffice_dim1;

--Creating office_dim1 from tempoffice_dim1 table
drop table office_dim1 cascade constraints purge;
create table office_dim1 as 
select office_id, office_name, office_size from 
tempoffice_dim1;

--Creating Gender_Dim1 table
drop table gender_dim1 cascade constraints purge;
create table gender_dim1 as select distinct gender from person;

--Creating agent_dim1 table 
drop table agent_dim1 cascade constraints purge;
create table agent_dim1 as
select distinct a.person_id,salary, 1/count(*) as weight_factor, 
listagg (ao.office_id,'_') within group (order by ao.office_id) as officelist  --to increase level of aggregation
from agent a, agent_office ao
where a.person_id = ao.person_id(+)
group by a.person_id,salary;

--select * from agent_dim1;
--select * from agent_office where person_id = 6;

--Creating officegrouplist_dim1 table
drop table officegrouplist_dim1 cascade constraints purge;
create table officegrouplist_dim1 as 
select distinct officelist, weight_factor 
from agent_dim1;

--select * from officegrouplist_dim1;

--Creating groupbridge table
drop table groupbridge cascade constraints purge;
create table groupbridge as
select distinct officeList, ao.office_ID
from agent_dim1 a, agent_office ao
where a.person_id = ao.person_Id;
--select * from groupbridge;

--Creating agentempfact1 
drop table agenttempfact1 cascade constraints purge;
Create Table agentTempFact1 As
Select p.gender, a.person_id, a.salary,
count(a.person_id) As no_of_agents
From person p, agent a
Where p.person_ID = a.person_ID
group by p.gender, a.person_id, a.salary;

--Creating agenttempfact2 from agenttempfact1
drop table agenttempfact2 cascade constraints purge;
create table agentTempFact2
as select *
from agentTempFact1;

--Altering agentempfact2 to add officelist
alter table agentTempFact2
add (officeList varchar(100));

--Updating value of officelist using listagg function
update agentTempFact2 T
set officeList = (
 select listagg(ao.office_Id, '_') within group -- to increase level of aggregation
 (order by ao.office_Id) as officeList
 from agent_office ao
 where t.person_id = ao.person_Id
);
--select * from agenttempfact2;

--Creating agentfact1 from agenttempfact2
drop table agentfact1 cascade constraints purge;
create table agentFact1
as select
 gender, officeList,
 sum(no_of_agents) as No_of_agents
from agentTempFact2
group by gender, officeList;

--select * from agentfact1 order by officelist;
--select * from agent_office where office_id = 1;
--select * from agentfact1;
--
--
-- END OF AGENT FACT TABLE
--
--
-- Creating clientdim1 table, which is a temporary dimension to add weightfactor and wishlist
DROP TABLE client_dim1 cascade constraints purge;
CREATE TABLE client_dim1 AS SELECT
listagg (cw.feature_code, '_') within group (order by cw.feature_code) as WishList, --Higher level of aggregation
c.person_id,c.min_budget,c.max_budget, 1.0/count(*) as weight_factor 
FROM  client c, client_wish cw
where c.person_id = cw.person_id(+)
group by c.person_id,c.min_budget,c.max_budget;

--select * from clientwishlist_dim1 where wishlist is not null;

--Creating clientwishlist_dim1 table from client_dim1
drop table clientwishlist_dim1 cascade constraints purge;
create table clientwishlist_DIM1 as select DISTINCT wishlist, weight_factor FROM
client_dim1;

--Creating budgetcategory_dim1 table
drop table budgetcategory_dim1 cascade constraints purge;
create table budgetcategory_dim1 (budgetcategory_id varchar(15), budgetcategory_description varchar(50));

--Inserting initial budgetcategory_id values in dimension table
insert into budgetcategory_dim1 values ('Low','0 to 1000');
insert into budgetcategory_dim1 values ('Medium','1001 to 100000');
insert into budgetcategory_dim1 values ('High','100001 to 10000000');


--Creating wishBridge table
drop table wishbridge cascade constraints purge;
CREATE TABLE wishbridge AS SELECT DISTINCT
wishlist,
feature_code
FROM client_dim1 cd, client_wish cw
WHERE cd.person_id = cw.person_id;

--SELECT * FROM wishbridge;

--Creating clienttempfact1 table
DROP TABLE clienttempfact1 cascade constraints purge;
CREATE TABLE clienttempfact1 AS SELECT
p.gender, c.person_id, c.max_budget, 
to_char(s.sale_date, 'yyyy') as client_year,
COUNT(distinct(c.person_id)) AS no_of_clients
FROM client   c, person   p, sale s
WHERE c.person_id = p.person_id (+) and p.person_id = s.client_person_id(+) and gender is not null and sale_date is not null
GROUP BY p.gender, c.person_id, c.max_budget, to_char(s.sale_date, 'yyyy')
UNION
SELECT
p.gender, c.person_id, c.max_budget, 
to_char(s.rent_start_date, 'yyyy') as client_year,
COUNT(distinct(c.person_id)) AS no_of_clients
FROM client   c, person   p, rent s
WHERE c.person_id = p.person_id (+) and p.person_id = s.client_person_id(+) and gender is not null and rent_start_date is not null
GROUP BY p.gender, c.person_id, c.max_budget, to_char(s.rent_start_date, 'yyyy')
UNION
SELECT
p.gender, c.person_id, c.max_budget, 
to_char(s.visit_date, 'yyyy') as client_year,
COUNT(distinct(c.person_id)) AS no_of_clients
FROM client   c, person   p, visit s
WHERE c.person_id = p.person_id (+) and p.person_id = s.client_person_id(+) and gender is not null and visit_date is not null
GROUP BY p.gender, c.person_id, c.max_budget, to_char(s.visit_date, 'yyyy');

--SELECT  * FROM clienttempfact1;

--Altering clienttempfact1 to add budgetcategory_id
ALTER TABLE clienttempfact1 ADD (budgetcategory_id VARCHAR2(10));

--Updating budgetcategory_id based on max_budet from client table
UPDATE clienttempfact1 
SET budgetcategory_id = 'Low'
WHERE max_budget <= 1000;

UPDATE clienttempfact1
SET budgetcategory_id = 'Medium'
WHERE max_budget >= 1001 AND max_budget <= 100000;

UPDATE clienttempfact1
SET budgetcategory_id = 'High'
WHERE max_budget >= 100001;

--select * from clienttempfact1;
--Creating clienttempfact2 from clienttempfact1
drop table clienttempfact2 cascade constraints purge;
CREATE TABLE clienttempfact2 AS
SELECT distinct person_id, gender, max_budget, client_year, budgetcategory_id, no_of_clients
FROM clienttempfact1 where client_year is not null;

--SELECT  * FROM clienttempfact2;
--SELECT sum(no_of_clients) from clienttempfact2;

--Adding wishlist to clienttempfact2
ALTER TABLE clienttempfact2 ADD (wishlist VARCHAR(200));

--updating wishlist values using feature_code
UPDATE clienttempfact2 c
SET wishlist = ( SELECT LISTAGG(cw.feature_code, '_') WITHIN GROUP (ORDER BY cw.feature_code) AS wishlist
FROM client_wish cw WHERE c.person_id = cw.person_id (+));

--select sum(no_of_clients) from clienttempfact2;

--Creating clientfact1 from clienttempfact2
drop table clientfact1 cascade constraints purge;
CREATE TABLE clientfact1 AS
SELECT gender, client_year, budgetcategory_id, wishlist,
SUM(no_of_clients) AS total_no_of_clients
FROM clienttempfact2
GROUP BY gender, budgetcategory_id, wishlist, client_year;

/*
select * from clientfact1; 
select sum(total_no_of_clients) from clientfact1;
--select sum(total_no_of_clients) from clientfact1;
select count(distinct (person_id)) from client_wish;
*/
commit;