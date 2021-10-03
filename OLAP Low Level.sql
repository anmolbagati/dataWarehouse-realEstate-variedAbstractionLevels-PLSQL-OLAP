--Report 1--
SELECT * FROM (
SELECT s.state_code,p.property_type,
SUM(sf.Total_sales) as SALES,
DENSE_RANK() OVER (ORDER BY SUM(sf.Total_sales) DESC)
AS custom_rank
FROM state_dim s, propertytype_dim p, salesfact sf
WHERE s.state_code=sf.state_code and p.property_type=sf.property_type and s.state_code ='NSW' 
GROUP BY s.state_code,p.property_type)
WHERE CUSTOM_RANK <=3
;

--Report 2--
SELECT *
FROM (
SELECT s.state_code,p.property_type,
SUM(sf.Total_sales) as SALES,
PERCENT_RANK() OVER (ORDER BY SUM(sf.Total_sales) DESC)
AS "PERCENT RANK"
FROM state_dim s, propertytype_dim p, salesfact sf
WHERE s.state_code=sf.state_code and p.property_type=sf.property_type and s.state_code ='NSW' 
GROUP BY s.state_code,p.property_type
) 
WHERE "PERCENT RANK" < 0.5;

-- Report 3--
SELECT s.state_code,p.property_type,
SUM(sf.Total_sales) as SALES,
DENSE_RANK() OVER (ORDER BY SUM(sf.Total_sales) DESC)
AS custom_rank
FROM state_dim s, propertytype_dim p, salesfact sf
WHERE s.state_code=sf.state_code and p.property_type=sf.property_type and s.state_code ='NSW' 
GROUP BY s.state_code,p.property_type;

--Report 4--
SELECT
    decode(GROUPING(s.suburb), 1, 'All_Suburbs', s.suburb) AS Suburb,
    decode(GROUPING(rs.rentstart_year), 1, 'All_Years', rs.rentstart_year) AS Year,
    decode(GROUPING(p.property_type), 1, 'All_Property_Types', p.property_type) AS "Property Type",
    SUM(r.rental_fees) AS "Total Rental Fees"
FROM
    rentstart_dim     rs,
    suburb_dim         s,
    propertytype_dim   p,
    rentfact          r
WHERE
    s.suburb = r.suburb
    AND rs.rentstart_id = r.rentstart_id
    AND p.property_type = r.property_type
GROUP BY CUBE
    ( s.suburb,
         rs.rentstart_year,
         p.property_type) ;

--REPORT 5--

   
SELECT
    decode(GROUPING(s.suburb), 1, 'All_Suburbs', s.suburb) AS Suburb,
    decode(GROUPING(rs.rentstart_year), 1, 'All_Years', rs.rentstart_year) AS Year,
    decode(GROUPING(p.property_type), 1, 'All_Property_Types', p.property_type) AS "Property Type",
    SUM(r.rental_fees) AS "Total Rental Fees"
FROM
    rentstart_dim     rs,
    suburb_dim         s,
    propertytype_dim   p,
    rentfact          r
WHERE
    s.suburb = r.suburb
    AND rs.rentstart_id = r.rentstart_id
    AND p.property_type = r.property_type
GROUP BY  s.suburb,
CUBE
         (rs.rentstart_year,
         p.property_type) ;

--Report 6--

SELECT
    decode(GROUPING(s.season_id), 1, 'All_Seasons', s.season_id) AS Season,
    decode(GROUPING(st.state_code), 1, 'All_States', st.state_code) AS State,
    decode(GROUPING(sf.property_type), 1, 'All_Property_type', sf.property_type) AS Property_type,
    SUM(sf.total_sales) AS "Total Sales"
FROM
    
    season_dim  s,
    State_dim  st,
    salesfact  sf,
    propertytype_dim p
WHERE
   s.season_id = sf.season_id
   AND st.state_code = sf.state_code
   AND p.property_type = sf.property_type
GROUP BY Rollup
    ( s.season_id,st.state_code,sf.property_type ) ;
    
-- Report 7--

SELECT
    decode(GROUPING(s.season_id), 1, 'All_Seasons', s.season_id) AS Season,
    decode(GROUPING(st.state_code), 1, 'All_States', st.state_code) AS State,
    decode(GROUPING(sf.property_type), 1, 'All_Property_type', sf.property_type) AS Property_type,
    SUM(sf.total_sales) AS "Total Sales"
FROM
    
    season_dim  s,
    State_dim  st,
    salesfact  sf,
    propertytype_dim p
WHERE
   s.season_id = sf.season_id
   AND st.state_code = sf.state_code
   AND p.property_type = sf.property_type
GROUP BY s.season_id,
Rollup
    ( st.state_code,sf.property_type ) ;
    
--Report 8--

select c.budgetcategory_id,c.client_year,
to_char (SUM(c.Total_no_of_clients), '9,999,999,999') AS Q_CLIENT,
TO_CHAR (SUM(SUM(c.Total_no_of_clients)) OVER
(ORDER BY c.budgetcategory_id,c.client_year 
ROWS UNBOUNDED PRECEDING),
'9,999,999,999') AS CUMMULATIVE_CLIENT
FROM time_dim t, budgetcategory_dim b, clientfact c
where 
c.client_year = t.client_year and 
c.budgetcategory_id = b.budgetcategory_id and
b.budgetcategory_id='High'
and t.client_year in ('2019', '2020')
GROUP BY c.budgetcategory_id,c.client_year; 


--select sum(total_no_of_clients) from clientfact;

--select * from rentfact;

--Report 9--
select r.state_code, rs.rentstart_year, to_char(sum(rental_fees), '9,999,999,999') as "Q rent",
to_char(AVG(SUM(rental_fees)) OVER(order by r.state_code, rs.rentstart_year
rows 2 preceding),'9,999,999,999') as three_year_moving_average
from
rentfact r, rentstart_dim rs
where r.rentstart_id=rs.rentstart_id and rs.rentstart_year in ('2018','2019','2020') and r.state_code in ('TAS','NSW','VIC')
group by r.state_code, rs.rentstart_year;

--Report 10--
select
r.property_type,
rs.rentstart_year,
to_char(sum(r.rental_fees),'9,999,999,999') as "Q Rent",
to_char(sum(sum(r.rental_fees)) over (
partition by r.property_type ORDER by
r.property_type, rs.rentstart_year
ROWS unbounded preceding),'9,999,999,999') as CUMMULATIVE_RENT
FROM
rentfact r, propertytype_dim p, rentstart_dim rs
where r.rentstart_id=rs.rentstart_id and
r.property_type= p.property_type
and rentstart_year in ('2019','2020')
group by r.property_type, rs.rentstart_year;


--Report 11--
Select sf.property_type, t.client_year as Sales_Year, s.state_code, 
to_char (sum(sf.total_sales)) as Sales,
Rank() over (partition by sf.property_type
order by sum (total_sales) desc) as Rank_by_property_type,
Rank() over (partition by t.client_year
order by sum (total_sales) desc) as Rank_by_year,
Rank() over (partition by s.state_code
order by sum (total_sales) desc) as Rank_by_state
From propertytype_dim1 p, time_dim t, state_dim s, salesfact sf
where
p.property_type=sf.property_type
and t.client_year=sf.client_year
and s.state_code=sf.state_code
group by sf.property_type,t.client_year, s.state_code;

--Report 12--
Select rf.property_type, s.season_id as season, 
to_char (sum(rf.rental_fees)) as Rental_fees,
Rank() over (partition by rf.property_type
order by sum (rf.rental_fees) desc) as Rank_by_property_type,
Rank() over (partition by s.season_id
order by sum (rf.rental_fees) desc) as Rank_by_season
From propertytype_dim p, season_dim s, rentfact rf
where
p.property_type=rf.property_type
and s.season_id=rf.season_id
group by rf.property_type,s.season_id;