create database project_ev;

SELECT * FROM project_ev.dim_date;
SELECT * FROM project_ev.electric_vehicle_sales_by_makers;
SELECT * FROM project_ev.electric_vehicle_sales_by_state;

-- 1. List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.
-- Top 3 makers for FY 23-24
WITH total_num as (
select	
	ev.maker,
    dd.fiscal_year,
    sum(ev.electric_vehicles_sold) as total_vehicle_sold,
    dense_rank() over(partition by fiscal_year order by sum(ev.electric_vehicles_sold)desc) as ranking
from project_ev.electric_vehicle_sales_by_makers ev
inner join project_ev.dim_date dd on
ev.date = dd.date
where vehicle_category = '2-Wheelers' and fiscal_year in ('2023','2024')
group by maker, fiscal_year
ORDER BY fiscal_year
)
select 
	maker,
    fiscal_year,
    total_vehicle_sold,
    ranking
from total_num
where ranking <=3;

-- Bottom 3 makers for 2023 and 2024
WITH total_num as (
select	
	ev.maker,
    dd.fiscal_year,
    sum(ev.electric_vehicles_sold) as total_vehicle_sold,
    dense_rank() over(partition by fiscal_year order by sum(ev.electric_vehicles_sold)asc) as ranking
from project_ev.electric_vehicle_sales_by_makers ev
inner join project_ev.dim_date dd on
ev.date = dd.date
where vehicle_category = '2-Wheelers' and fiscal_year in ('2023','2024')
group by maker, fiscal_year
ORDER BY fiscal_year
)
select 
	maker,
    fiscal_year,
    total_vehicle_sold,
    ranking
from total_num
where ranking <=3;

-- 2. Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024.

SELECT * FROM project_ev.dim_date;
SELECT * FROM project_ev.electric_vehicle_sales_by_makers;
SELECT * FROM project_ev.electric_vehicle_sales_by_state;

-- top 5 state 2-wheeler EV sales in FY 2024.
select 
	ev.state,
    (sum(ev.electric_vehicles_sold)/sum(ev.total_vehicles_sold))*100 as penetration_rate
from project_ev.electric_vehicle_sales_by_state as ev
inner join project_ev.dim_date as dd on
ev.date = dd.date
where vehicle_category = "2-Wheelers" and fiscal_year = "2024"
group by state
order by penetration_rate desc
LIMIT 5;

-- top 5 state 4-wheeler EV sales in FY 2024.
select 
	ev.state,
    (sum(ev.electric_vehicles_sold)/sum(ev.total_vehicles_sold))*100 as penetration_rate
from project_ev.electric_vehicle_sales_by_state as ev
inner join project_ev.dim_date as dd on
ev.date = dd.date
where vehicle_category = "4-Wheelers" and fiscal_year = "2024"
group by state
order by penetration_rate desc
LIMIT 5;

-- 3. List the states with negative penetration (decline) in EV sales from 2022 to 2024?

SELECT * FROM project_ev.dim_date;
SELECT * FROM project_ev.electric_vehicle_sales_by_makers;
SELECT * FROM project_ev.electric_vehicle_sales_by_state;

select 
	ev.state,
    (sum(case when fiscal_year = '2022' then electric_vehicles_sold ELSE 0 END)) AS sale_2022,
    (sum(case when fiscal_year = '2024' then electric_vehicles_sold ELSE 0 END)) AS sale_2024
from project_ev.electric_vehicle_sales_by_state ev
inner join project_ev.dim_date as dd on
ev.date = dd.date
where fiscal_year in ('2022','2024')
group by state
order by state;

-- 4. What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?

SELECT * FROM project_ev.dim_date;
SELECT * FROM project_ev.electric_vehicle_sales_by_makers;
SELECT * FROM project_ev.electric_vehicle_sales_by_state;
    
with cte as (    
select 
	ev.maker
from project_ev.electric_vehicle_sales_by_makers ev
inner join project_ev.dim_date dd on 
dd.date = ev.date
where vehicle_category = "4-Wheelers"
group by maker
order by sum(electric_vehicles_sold) desc
limit 5
)
select 
	maker,
    fiscal_year,
    quarter,
    sum(electric_vehicles_sold) as total_sales
from project_ev.electric_vehicle_sales_by_makers ev
inner join project_ev.dim_date dd on
dd.date = ev.date
where vehicle_category = "4-Wheelers" and maker in (select maker from cte)
group by maker,fiscal_year,quarter
order by maker,fiscal_year,quarter;

-- 5. How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024?

SELECT * FROM project_ev.dim_date;
SELECT * FROM project_ev.electric_vehicle_sales_by_makers;
SELECT * FROM project_ev.electric_vehicle_sales_by_state;

select 
	state,
    sum(electric_vehicles_sold) as ev_sales,
    (sum(electric_vehicles_sold)/ sum(total_vehicles_sold))*100 as penetration_rates
from project_ev.electric_vehicle_sales_by_state ev
inner join project_ev.dim_date dd on
ev.date = dd.date
where fiscal_year = '2024' and state in ('Delhi','Karnataka')
group by state;

-- 6. List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.

SELECT * FROM project_ev.dim_date;
SELECT * FROM project_ev.electric_vehicle_sales_by_makers;
SELECT * FROM project_ev.electric_vehicle_sales_by_state;

with top5maker as (
select 
	maker
from project_ev.electric_vehicle_sales_by_makers ev
-- inner join project_ev.dim_date dd on
-- ev.date = dd.date
where vehicle_category = "4-Wheelers"
group by maker
order by sum(electric_vehicles_sold) desc
limit 5)

SELECT
  maker,
  POWER(
    (SUM(CASE WHEN dd.fiscal_year = "2024" THEN ev.electric_vehicles_sold ELSE 0 END) /
     SUM(CASE WHEN dd.fiscal_year = "2022" THEN ev.electric_vehicles_sold ELSE 0 END)
    ), 0.5) - 1 AS CAGR
FROM project_ev.electric_vehicle_sales_by_makers ev
JOIN project_ev.dim_date dd ON dd.date = ev.date
WHERE vehicle_category = "4-Wheelers"
  AND maker IN (SELECT maker FROM top5maker)
GROUP BY maker
ORDER BY CAGR DESC;

-- 7. List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.

SELECT * FROM project_ev.dim_date;
SELECT * FROM project_ev.electric_vehicle_sales_by_makers;
SELECT * FROM project_ev.electric_vehicle_sales_by_state;

with top10states as (
select 
	ev.state
from project_ev.electric_vehicle_sales_by_state ev
-- inner join project_ev.dim_date dd on
-- ev.date = dd.date
group by state
order by sum(electric_vehicles_sold) desc
limit 10)
select 
	state,
    power((sum(case when dd.fiscal_year = '2024' then ev.electric_vehicles_sold else 0 end)/
    sum(case when dd.fiscal_year = '2022' then ev.electric_vehicles_sold else 0 end)),0.5) -1 as CAGR
from project_ev.electric_vehicle_sales_by_state ev
inner join project_ev.dim_date dd on
ev.date = dd.date
where state in (select state from top10states)
group by state
order by CAGR desc;

-- 8. What are the peak and low season months for EV sales based on the data from 2022 to 2024?

SELECT * FROM project_ev.dim_date;
SELECT * FROM project_ev.electric_vehicle_sales_by_makers;
SELECT * FROM project_ev.electric_vehicle_sales_by_state;

select
	MONTH(date) as months,
    DATE_FORMAT(date, 'MMMM') as monthnames,
    sum(electric_vehicles_sold) as total_ev_sales
from project_ev.electric_vehicle_sales_by_makers
group by months, monthnames
order by months;

-- 9. What is the projected number of EV sales (including 2-wheelers and 4-wheelers) for the top 10 states by penetration rate in 2030, based on the compounded annual growth rate (CAGR) from previous years?

SELECT * FROM project_ev.dim_date;
SELECT * FROM project_ev.electric_vehicle_sales_by_makers;
SELECT * FROM project_ev.electric_vehicle_sales_by_state;

WITH t10sp AS
(SELECT 
    state,
    round((sum(electric_vehicles_sold)/sum(total_vehicles_sold))*100,2) as penetration_rate
FROM project_ev.electric_vehicle_sales_by_state ev 
group by state
order by penetration_rate desc
limit 10),

CAGR_CTE AS
(select
	state,
    round(power((SUM(CASE WHEN d.fiscal_year = "2024" THEN ev.electric_vehicles_sold ELSE 0 END) / 
     SUM(CASE WHEN d.fiscal_year = "2022" THEN ev.electric_vehicles_sold ELSE 0 END)),0.5) - 1,2) AS CAGR
From project_ev.electric_vehicle_sales_by_state ev 
JOIN project_ev.dim_date d 
ON d.date=ev.date 
WHERE state in (select state from t10sp)
group by state
Order by CAGR desc),
sales22 AS
(select
	t10sp.state,
    sum(ev.electric_vehicles_sold) as sales_2022
FROM project_ev.electric_vehicle_sales_by_state ev 
JOIN project_ev.dim_date d ON d.date=ev.date
JOIN t10sp on ev.state=t10sp.state
WHERE fiscal_year="2022"
group by t10sp.state)

select
	sales22.state,
    sales_2022,
    CAGR_CTE.CAGR,
    round(sales_2022*power(1+ CAGR,8),2) AS projection_2030
from sales22 
JOIN CAGR_CTE ON sales22.state=CAGR_CTE.state
group by state
order by projection_2030 desc;

-- Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price.
SELECT 
	vehicle_category,fiscal_year,
	CASE
		WHEN vehicle_category="2-Wheelers" THEN sum(electric_vehicles_sold*85000)
        ELSE sum(electric_vehicles_sold*1500000)
        END AS revenue
FROM project_ev.electric_vehicle_sales_by_state ev 
JOIN project_ev.dim_date d 
ON d.date=ev.date
group by vehicle_category,fiscal_year
order by vehicle_category,fiscal_year;