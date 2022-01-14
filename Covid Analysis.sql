/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- data that we are going to be starting with
select Location, date, total_cases, new_cases, total_deaths,population 
from PortfolioProjects..coviddeaths$
where continent is not null
order by 1,2;

-- total cases vs total deaths
-- shows likelihood of dying if you contract covid in your country
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from PortfolioProjects..coviddeaths$
where Location='India' and continent is not null
order by 1,2;

-- total cases vs population 
-- shows percentage of population infected with covid
select Location, date, total_cases, population, (total_cases/population)*100 as percentage_affected
from PortfolioProjects..coviddeaths$
where continent is not null
order by 1,2;


-- countries with highest percentage affected per population
select 
	Location, population, max(total_cases) as highest_affected_count,
	(max(total_cases)/population)*100 as percentage_affected
from PortfolioProjects..coviddeaths$
where continent is not null
Group by Location, population
order by percentage_affected DESC

-- countries with highest death count per population
select 
	Location, population, max(cast(total_deaths as int)) as highest_death_count,
	(max(total_deaths)/population)*100 as percentage_dead
from PortfolioProjects..coviddeaths$
where continent is not null
Group by Location, population
order by highest_death_count DESC

-- BREAK BY CONTINENTS

-- continents with highest death count
select 
	continent, max(cast (total_deaths as int)) as highest_death_count
from PortfolioProjects..coviddeaths$
where continent is not null
group by continent 
order by 1;

-- BREAK BY GLOBAL NUMBERS

-- global death percentage per day
select 
	date, sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
	(sum(cast(new_deaths as int))/sum(new_cases))*100 as death_percentage
from PortfolioProjects..coviddeaths$
where continent is not null
group by date
order by 1,2;

-- USING DEATH AND VACCINATION TABLE

-- total population vs vaccinations
-- shows percentage of population with atleast one vaccine
select 
	death.continent, death.location, death.date, 
	death.population, vaccines.new_vaccinations,
	sum(convert(bigint,vaccines.new_vaccinations)) over 
	(partition by death.location order by death.location, death.date) 
	as rolling_vaccinations
from PortfolioProjects..coviddeaths$ as death
join PortfolioProjects..covidvaccines$ as vaccines
	on death.location = vaccines.location 
	and death.date = vaccines.date
where death.continent is not null
order by 2,3;

-- using cte to perform calculations

with popvsvac(continent, location, date, population, new_vaccinations,rolling_vaccinations)
as
(
select 
	death.continent, death.location, death.date, 
	death.population, vaccines.new_vaccinations,
	sum(convert(bigint,vaccines.new_vaccinations)) over 
	(partition by death.location order by death.location, death.date) 
	as rolling_vaccinations
from PortfolioProjects..coviddeaths$ as death
join PortfolioProjects..covidvaccines$ as vaccines
	on death.location = vaccines.location 
	and death.date = vaccines.date
where death.continent is not null
)
select *, (rolling_vaccinations/population)*100 as percentage_vaccinated
from popvsvac; 

-- total percent vaccinated per country

with popvsvac(continent, location, population, new_vaccinations,total_vaccinations)
as
(
select 
	death.continent, death.location, death.population, vaccines.new_vaccinations,
	sum(convert(bigint,vaccines.new_vaccinations)) over 
	(partition by death.location order by death.location, death.date) 
	as total_vaccinations
from PortfolioProjects..coviddeaths$ as death
join PortfolioProjects..covidvaccines$ as vaccines
	on death.location = vaccines.location 
	and death.date = vaccines.date
where death.continent is not null
)
select location, population, (max(total_vaccinations)/population)*100 as percentage_vaccinated
from popvsvac
group by location, population
order by percentage_vaccinated DESC

-- total vaccinated per continent
with popvsvac(continent, location, population, new_vaccinations,total_vaccinations)
as
(
select 
	death.continent, death.location, death.population, vaccines.new_vaccinations,
	sum(convert(bigint,vaccines.new_vaccinations)) over 
	(partition by death.location order by death.location, death.date) 
	as total_vaccinations
from PortfolioProjects..coviddeaths$ as death
join PortfolioProjects..covidvaccines$ as vaccines
	on death.location = vaccines.location 
	and death.date = vaccines.date
where death.continent is not null
)
select continent, max(total_vaccinations) as total_vaccinated
from popvsvac
group by continent
order by total_vaccinated DESC

-- CREATING VIEWS FOR LATER VISUALIZATIONS

create view RollingPeopleVaccinated as
select 
	death.continent, death.location, death.date, 
	death.population, vaccines.new_vaccinations,
	sum(convert(bigint,vaccines.new_vaccinations)) over 
	(partition by death.location order by death.location, death.date) 
	as total_vaccinations
from PortfolioProjects..coviddeaths$ as death
join PortfolioProjects..covidvaccines$ as vaccines
	on death.location = vaccines.location 
	and death.date = vaccines.date
where death.continent is not null

create view [ContinentDeath] as 
select 
	continent, max(cast (total_deaths as int)) as highest_death_count
from PortfolioProjects..coviddeaths$
where continent is not null
group by continent 
