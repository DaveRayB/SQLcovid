--location field contains countries and continents

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent LIKE '0'
ORDER BY 1,2
--EXEC sp_columns CovidVaccinations

SELECT *
FROM PortfolioProject..CovidVaccinations
WHERE continent LIKE '0'
ORDER BY 1,2




--Deaths vs cases, Percentage of deaths in the U.S. for infected
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths as numeric(9,0)) / CAST(total_cases as numeric(9,0)) * 100)    AS perc_of_deaths_per_cases--, population
FROM PortfolioProject..CovidDeaths
WHERE total_deaths > 0 AND total_cases > 0 AND location LIKE '%States'
ORDER BY 1,2


--Cases vs Population in the U.S.
SELECT location, date, total_cases,  population, (CAST(total_cases as numeric(11,0)) / CAST(population as numeric(11,0)) * 100)    AS perc_of_cases_per_poulation
FROM PortfolioProject..CovidDeaths
WHERE total_cases > 0 AND population > 0 AND location LIKE '%States'
ORDER BY 1,2

--highest number of total cases for each country and highest percentage of infection rate (cases vs population from query above)
SELECT location, MAX(total_cases) AS highest_num_cases, population, MAX((CAST(total_cases as numeric(11,0)) / CAST(population as numeric(11,0))) * 100) AS perc_of_cases_per_poulation
FROM PortfolioProject..CovidDeaths
WHERE total_cases > 0 AND population > 0
GROUP BY location, population 
ORDER BY perc_of_cases_per_poulation DESC

--show each countries population with highest death count
SELECT location, population, MAX(total_deaths) AS highest_death_count
FROM PortfolioProject..CovidDeaths
WHERE population > 0 AND continent NOT LIKE '0'  --technicality to remove continent locations
GROUP BY location, population
ORDER BY highest_death_count DESC

--show each continent with the highest death count but use the location column for results
SELECT location, MAX(total_deaths) AS highest_death_count
FROM PortfolioProject..CovidDeaths
WHERE population > 0 AND continent NOT LIKE '0'  --technicality to remove null locations
GROUP BY location
ORDER BY highest_death_count DESC


--join both tables
SELECT * 
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--rolling count of new vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Rolling_Count_Vac
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent NOT LIKE '0'
ORDER BY 2,3

--create a cte to for the query above
with PopvsVac (continent, location, date, population, new_vaccinations, Rolling_Count_Vac)
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Rolling_Count_Vac
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent NOT LIKE '0'
--ORDER BY 2,3
)

--test the new PopsVac cte
--SELECT *
--FROM PopvsVac

--Use the new cte to create a new column that shows the total (final rolling number) of vaccinations per population for each location
SELECT continent, location, date, population, new_vaccinations, CAST(MAX(Rolling_Count_Vac) as numeric(11,0)) / CAST(population as numeric(11,0))  * 100  AS total_vac_per_pop
FROM PopvsVac 
WHERE continent NOT LIKE '0' AND population > 0
GROUP BY continent, location, date, population, new_vaccinations
ORDER BY total_vac_per_pop


--create a view, a permanent table that will be used later for visualization
Create View PercentPopVac as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Rolling_Count_Vac
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent NOT LIKE '0'
--ORDER BY 2,3




------------------------------------------
--refined queries for the tableau project
------------------------------------------

--1 --death percentage
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(CAST(new_deaths as numeric(11,0))) / SUM(CAST(new_cases as numeric(11,0))) * 100 as total_deaths_per_total_cases
FROM PortfolioProject..CovidDeaths
--WHERE total_deaths > 0 AND total_cases > 0
--ORDER BY 1,2


--2
Select location, SUM(cast(new_deaths as numeric(11,0))) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null 
and location not in ('World', 'European Union', 'International','Upper middle income','High income','Europe','Asia','North America','Lower middle income','South America')
Group by location
order by TotalDeathCount desc



-- 3.
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max(CAST(total_cases as numeric(11,0)) / CAST(population as numeric(11,0)))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
WHERE population > 0
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max(CAST(total_cases as numeric(11,0))/CAST(population as numeric(11,0)))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
WHERE population > 0
Group by Location, Population, date
order by PercentPopulationInfected desc


