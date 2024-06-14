use portfolio_project ;

--select *
--from covid_deaths
--order by 3,4 ;

--select *
--from covid_vaccination
--order by 3,4 ;

--select the data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from covid_deaths
order by 1,2 ;

-- looking at total cases vs total deaths
-- shows estimated number if you contract covid in your country

select location, date, total_cases, total_deaths, (convert(float,total_deaths)/NULLIF(convert(float,total_cases),0))*100 as death_percentage
from covid_deaths
where location like 'india'
order by 1,2 ;

-- looking at total cases vs population
-- shows what percent of people got infected

select location, date, population, total_cases, (convert(float,total_cases)/NULLIF(convert(float,population),0))*100 as infection_percentage
from covid_deaths
-- where location like 'india'
order by 1,2 ;

-- looking at highest infection rate compared to popultation

select location, population, max(total_cases) as highest_infection_rate, max((convert(float,total_cases)/NULLIF(convert(float,population),0)))*100 as infection_percentage
from covid_deaths
-- where location like 'india'
group by location, population
order by infection_percentage desc ;

-- showing highest death count per population

select location, population, max(cast(total_deaths as int)) as total_death_count -- max((convert(float,total_deaths)/NULLIF(convert(float,population),0)))*100 as death_percentage
from covid_deaths
-- where location like 'india'
where continent is not null
group by location, population
order by total_death_count desc ;

-- Let's break things down by continent

-- showing continents with highest death counts per population

select continent, max(cast(total_deaths as int)) as total_death_count
from covid_deaths
-- where location like 'india'
where continent is not null
group by continent
order by total_death_count desc ;

 -- Global Numbers

 select SUM(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths
 from covid_deaths
 where continent is not null
 order by 1,2 ;

 select d.continent, d.location, d.date,v.new_vaccinations, sum(convert(float,v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rolling_people_vaccinated
 from covid_deaths d
 join covid_vaccination v on d.location = v.location and d.date = v.date
 where d.continent is not null
 order by 1,2,3 ;

 -- Use CTE 
 with PopvsVac (continent,location,date,population,new_vaccinations,rolling_people_vaccinated ) as
 (
 select d.continent, d.location, d.date,d.population,v.new_vaccinations, sum(convert(float,v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rolling_people_vaccinated
 from covid_deaths d
 join covid_vaccination v on d.location = v.location and d.date = v.date
 where d.continent is not null
 -- order by 2,3
 )
 select *, (rolling_people_vaccinated / population) * 100
 from PopvsVac ;

 -- Temp Table
 drop table if exists percent_population_vaccinated
 create table percent_population_vaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
rolling_people_vaccinated numeric)

insert into percent_population_vaccinated
select d.continent, d.location, d.date,d.population,v.new_vaccinations, sum(convert(float,v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rolling_people_vaccinated
 from covid_deaths d
 join covid_vaccination v on d.location = v.location and d.date = v.date
 where d.continent is not null
 order by 2,3

  select *, (rolling_people_vaccinated / population) * 100
 from percent_population_vaccinated ;

 -- create view to store data for visualization

 create view percent_people_vaccinated as
 select d.continent, d.location, d.date,d.population,v.new_vaccinations, sum(convert(float,v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rolling_people_vaccinated
 from covid_deaths d
 join covid_vaccination v on d.location = v.location and d.date = v.date
 where d.continent is not null
 -- order by 2,3 ;

 select *
 from percent_people_vaccinated