--CLEANING ADDRESS TABLE
select * from MonRE.Address;
select count(*) from (select address_id, count(*) from MONRE.address group by address_id having count(*)>1);

--Checking for Null values in attributes 
select * from monre.address where suburb is null;
select * from monre.address where street is null;
select * from monre.address where address_id is null;
select * from monre.address where postcode is null;

--Checking for foreign key validity and presence of that key value in the parent table
select * from MonRE.address where postcode NOT IN (select postcode from monre.postcode);

--Creating Address table for OP DB
drop table address cascade constraints;
create table address as
select * from monre.address;

select count(*) from address;

--CLEANING ADVERTISEMENT TABLE
select * from MonRE.Advertisement;
select count(*) from (select advert_id, count(*) from MONRE.advertisement group by advert_id having count(*)>1);

--Checking for Null values in attributes 
select * from monre.advertisement where advert_id is null;
select * from monre.advertisement where advert_name is null;

--Creating Advertisement table for OP DB
drop table advertisement cascade constraints;
create table advertisement as
select * from monre.advertisement;

select count(*) from advertisement;

--CLEANING AGENT TABLE
select * from MonRE.Agent;
select count(*) from (select person_id, count(*) from MONRE.agent group by person_id having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.agent where person_id is null;
select * from monre.agent where salary is null;

--Checking for foreign key validity and presence of that key value in the parent table
--Person_id 6997 not in person table but present in agent table. Delete after making Operational DB
select * from MonRE.agent where person_id NOT IN (select person_id from monre.person);

--checking if salary is 0 or negative
select * from monre.agent where salary <= -1;

--Creating Agent table for OP DB
drop table agent cascade constraints;
create table agent as
select * from monre.agent where salary >= 0 and person_id IN (select person_id from person);

commit;

select count(*) from agent;

--CLEANING AGENT_OFFICE TABLE
select * from MonRE.Agent_Office;
select count(*) from (select person_id, office_id, count(*) from MONRE.agent_office group by person_id, office_id having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.agent_office where person_id is null;
select * from monre.agent_office where office_id is null;

--Checking for foreign key validity and presence of that key value in the parent table
--person_id 6997 is not in the person table but exists in the agent_office table
select * from MonRE.agent_office where person_id NOT IN (select person_id from monre.person);

--Checking for foreign key validity and presence of that key value in the parent table
select * from MonRE.agent_office where person_id NOT IN (select person_id from MONRE.agent);
select * from MonRE.agent_office where office_id NOT IN (select office_id from MONRE.office);

--Creating Agent_office table for OP DB
drop table agent_office cascade constraints;
create table agent_office as
select * from monre.agent_office where person_id IN (select person_id from person);

select count(*) from agent_office;


--CLEANING CLIENT_WISH TABLE
select * from MonRE.Client_Wish;
select count(*) from (select person_id, feature_code, count(*) from MONRE.client_wish group by person_id, feature_code having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.client_wish where person_id is null;
select * from monre.client_wish where feature_code is null;

--Checking for foreign key validity and presence of that key value in the parent table
select * from MonRE.client_wish where person_id NOT IN ( select person_id from monre.client);

--Creating Client_wish table for OP DB
drop table client_wish cascade constraints;
create table client_wish as
select * from monre.client_wish;

select count(*) from client_wish;

--CLEANING FEATURE TABLE
select * from MonRE.Feature;
select count(*) from (select feature_code, count(*) from MONRE.feature group by feature_code having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.feature where feature_description is null;
select * from monre.feature where feature_code is null;

--Creating Feature table for OP DB
drop table feature cascade constraints;
create table feature as
select * from monre.feature;

select count(*) from feature;

--CLEANING OFFICE TABLE
select * from MonRE.Office;
select count(*) from (select office_id, count(*) from MONRE.office group by office_id having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.office where office_id is null;
select * from monre.office where office_name is null;

--Creating Office table for OP DB
drop table office cascade constraints;
create table office as
select * from monre.office;

select count(*) from office;

--CLEANING PERSON TABLE
select count(*) from MonRE.Person;
select * from MonRE.Person;

--person_id 6995 has repeated entries
select count(*) from (select person_id, count(*) from MONRE.person group by person_id having count(*)>1);
select count(*), person_id from monre.person group by person_id having count(*)>1;
select * from monre.person where person_id = '6995';

--Checking for Null values in attributes 
select * from MONRE.person where person_id is null;
select * from monre.person where title is null;
select * from monre.person where first_name is null;
select * from monre.person where last_name is null;
select * from monre.person where gender is null;
select * from monre.person where address_id is null;
select * from monre.person where phone_no is null;
select * from monre.person where email is null;

-- Use distinct while making the table to avoid redundant Entries
select distinct(person_id) from monre.person;

--Checking for foreign key validity and presence of that key value in the parent table
--Person id 7001 has an address_id thats not present in the address table
select * from MonRE.person where address_id NOT IN (select address_id from monre.address);

--Creating Person table for OP DB USING DISTINCT and not in to remove person id 7001 from the table
drop table person cascade constraints;
create table person as
select distinct person_id, title, first_name, last_name, gender, address_id, phone_no, email from monre.person
where address_id IN (select address_id from monre.address);

select * from person where person_id ='7001';
select count(*) from person;

-- Updating gender and title discrepencies
UPDATE person
SET title='Mr' 
WHERE gender='Male' and title='Mrs';

UPDATE person
SET title='Mrs' 
WHERE gender='Female' and title = 'Mr';

--CLEANING CLIENT TABLE
select * from MonRE.Client;
select count(*) from (select person_id, count(*) from MONRE.client group by person_id having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.client where person_id is null;
select * from monre.client where min_budget is null;
select * from monre.client where max_budget is null;

--checking is min_budget is lower than max_budget
select * from monre.client where min_budget> max_budget;

--Checking for foreign key validity and presence of that key value in the parent table
--Person_id 7000 not in person table but present in client table. Delete after making Operational DB
select * from MonRE.client where person_id NOT IN (select person_id from person);
select count(*) from client;
--Creating Client table for OP DB
drop table client cascade constraints;
create table client as
select * from monre.client where min_budget < max_budget and person_id IN (select person_id from person);

select count(*) from client;
select * from client where person_id ='7000';
commit;


--CLEANING POSTCODE TABLE
select * from MonRE.Postcode;
select count(*) from MonRE.Postcode;
select count(*) from (select postcode, count(*) from MONRE.postcode group by postcode having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.postcode where postcode is null;
select * from monre.postcode where state_code is null;

--Checking for foreign key validity and presence of that key value in the parent table
select * from MonRE.postcode where state_code NOT IN (select state_code from monre.state);

--Creating POSTCODE table for OP DB
drop table postcode cascade constraints;
create table postcode as
select * from monre.postcode;

select count(*) from postcode;

--CLEANING PROPERTY TABLE
-- 4 and 16 repeated entries of 2 different property_id
select * from MonRE.Property;
select count(*) from (select property_id, count(*) from MONRE.property group by property_id having count(*)>1);
select count(*), property_id from monre.property group by property_id having count(*)>1;
select * from monre.property where property_id = '6177' or property_id = '6179' order by property_id;

--Checking for Null values in attributes 
select * from MONRE.property where property_id is null;
select * from monre.property where property_date_added is null;
select * from MONRE.property where address_id is null;
select * from monre.property where property_type is null;
select * from MONRE.property where property_no_of_bedrooms is null;
select * from monre.property where property_no_of_bathrooms is null;
select * from MONRE.property where property_no_of_garages is null;
select * from monre.property where property_size is null;
select * from MONRE.property where property_description is null;

--Checking for foreign key validity and presence of that key value in the parent table
select * from MonRE.property where address_id NOT IN (select address_id from monre.address);

--Creating Property table for OP DB USING DISTINCT
drop table property cascade constraints;
create table property as
select distinct property_id, property_date_added, address_id, property_type, property_no_of_bedrooms, 
property_no_of_bathrooms, property_no_of_garages, property_size, property_description from monre.property;

select count(*) from property;

--CLEANING PROPERTY_ADVERT TABLE
select * from MonRE.Property_Advert;
select count(*) from (select property_id, advert_id, count(*) from MONRE.property_advert group by property_id, advert_id having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.property_advert where property_id is null;
select * from monre.property_advert where advert_id is null;
select * from MONRE.property_advert where agent_person_id is null;
select * from monre.property_advert where cost is null;

--Checking for foreign key validity and presence of that key value in the parent table
select * from MonRE.property_advert where property_id NOT IN (select property_id from MONRE.property);
select * from MonRE.property_advert where advert_id NOT IN (select advert_id from MONRE.advertisement);
select * from MonRE.property_advert where agent_person_id NOT IN (select person_id from MONRE.agent);

--Creating PROPERTY_ADVERT table for OP DB
drop table property_advert cascade constraints;
create table property_advert as
select * from monre.property_advert;

select count(*) from property_advert;

--CLEANING PROPERTY_FEATURE TABLE
select * from MonRE.Property_Feature;
select count(*) from (select property_id, feature_code, count(*) from MONRE.property_feature group by property_id, feature_code having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.property_feature where property_id is null;
select * from monre.property_feature where feature_code is null;

--Checking for foreign key validity and presence of that key value in the parent table
select * from MonRE.property_feature where feature_code NOT IN ( select feature_code from monre.feature);
select * from MonRE.property_feature where property_id NOT IN (select property_id from MONRE.property);

--Creating PROPERTY_FEATURE table for OP DB
drop table property_feature cascade constraints;
create table property_feature as
select * from monre.property_feature;

select count(*) from property_feature;

--CLEANING RENT TABLE
select * from MonRE.Rent;
select count(*) from (select rent_id, count(*) from MONRE.rent group by rent_id having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.rent where rent_id is null;
select * from monre.rent where agent_person_id is null;
select * from MONRE.rent where property_id is null;
select * from monre.rent where client_person_id is null;
select * from MONRE.rent where rent_start_date is null;
select * from monre.rent where rent_end_date is null;
select * from monre.rent where price is null;

--Checking for foreign key validity and presence of that key value in the parent table
-- agent_person_id 6002 is present in rent but not in agent table
select * from MonRE.rent where agent_person_id NOT IN ( select person_id from monre.agent);

-- clent_person_id 6001 is present in rent but not in client table
select * from MonRE.rent where client_person_id NOT IN ( select person_id from monre.client);


select * from MonRE.rent where property_id NOT IN ( select property_id from monre.property);

--Checking if start_date is before the end_date. 1 discrepency detected
SELECT * FROM monre.rent WHERE rent_start_date > rent_end_date;
--Checking if there is only 1 entry with the combination of agent and client ids
SELECT * FROM monre.rent WHERE agent_person_id ='6002' and client_person_id ='6001';

--Creating Rent table for OP DB
drop table rent cascade constraints;
create table rent as
((select * from monre.rent) minus (select * from monre.rent where (rent_start_date > rent_end_date) or agent_person_id NOT IN (select person_id from monre.person) or client_person_id NOT IN (select person_id from monre.person) or property_id NOT IN (select property_id from monre.property) ));

select count(*) from rent;

--CLEANING SALE TABLE
select * from MonRE.Sale;
select count(*) from (select sale_id, count(*) from MONRE.sale group by sale_id having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.sale where sale_id is null;
select * from monre.sale where agent_person_id is null;
select * from MONRE.sale where sale_date is null;
select * from monre.sale where client_person_id is null;

--Checking for foreign key validity and presence of that key value in the parent table

select * from MonRE.sale where agent_person_id NOT IN ( select person_id from monre.agent);

select * from MonRE.sale where client_person_id NOT IN ( select person_id from monre.client);

--Creating Sale table for OP DB
drop table sale cascade constraints;
create table sale as
select * from monre.sale;

select count(*) from sale;

--CLEANING STATE TABLE
select * from MonRE.State;
select count(*) from (select state_code, count(*) from MONRE.state group by state_code having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.state where state_code is null;
select * from monre.state where state_name is null;

--Creating State table for OP DB
drop table state cascade constraints;
create table state as
select * from monre.state minus (select * from monre.state where state_code is null);

select count(*) from state;

commit;

select * from state;

--CLEANING VISIT TABLE
select * from MonRE.Visit;
select count(*) from MonRE.Visit;
select count(*) from (select client_person_id, agent_person_id, property_id, visit_date, count(*) from MONRE.visit 
group by client_person_id, agent_person_id, property_id, visit_date 
having count(*)>1);

--Checking for Null values in attributes 
select * from MONRE.visit where client_person_id is null;
select * from monre.visit where agent_person_id is null;
select * from MONRE.visit where property_id is null;
select * from monre.visit where visit_date is null;
select * from monre.visit where duration is null;


--Checking for foreign key validity and presence of that key value in the parent table
--Property_id 5741 has agent and client ids absent from the client and agent tables.
--person_id 6000 and 6001 are not present in their agent client tables. 
select * from MonRE.visit where client_person_id NOT IN ( select person_id from monre.client);
select * from MonRE.visit where agent_person_id NOT IN ( select person_id from monre.agent);
select * from MonRE.visit where property_id NOT IN ( select property_id from monre.property);
select to_char(visit_date ,'yyyy') as visit_date from monre.visit where client_person_id = '6000';

--Creating Visit table for OP DB
drop table visit cascade constraints;
create table visit as
((select * from monre.visit) minus (select * from monre.visit where agent_person_id NOT IN (select person_id from monre.agent) or client_person_id NOT IN (select person_id from monre.client) or property_id NOT IN (select property_id from monre.property) or visit_date in (select visit_date from monre.visit where visit_date > sysdate)));

select count(*) from visit;