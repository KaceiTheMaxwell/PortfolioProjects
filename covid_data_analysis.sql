/* 
=============================================================================================================
Health Data: COVID-19
=============================================================================================================

Purpose:
 - This project demonstrates simple data analysis of health data including creating tables and views

*/

-- covid vaccinations data
--SELECT *
--FROM PortfolioProject.dbo.CovidVax
-- WHERE continent IS NOT NULL

-- Global covid deaths data
SELECT location, date, population, total_cases, new_cases, total_deaths, new_deaths
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Let us examine the total cases vs total deaths; death rate - the percentage of people who died that were infected

-- This shows the likelihood of death from contracting COVID in your country.
SELECT location, date, total_cases, total_deaths, ((total_deaths * 100)/total_cases) AS deathrate
FROM PortfolioProject.dbo.CovidDeaths
--WHERE continent IS NOT NULL
WHERE location like '%states%'
ORDER BY location, date

-- Let us examine the total cases vs population

-- This shows the percentages of population who died, and those who contracted the virus
SELECT location, date, total_cases, total_deaths, population, ((total_deaths * 100)/population) AS popdied, ((total_cases * 100)/population) AS popcases
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
ORDER BY popcases DESC

-- Which countries had the highest infection rate compared to their population?

-- To find this out, we can look at the maximum number of infection count [the max() function] and this maximum number as compared to the 
-- countries' populations.

SELECT location, population, max(total_cases) AS HighestInfectionCount, max(((total_cases * 100)/population)) AS HighestPopCases
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY HighestPopCases DESC

-- Which countries had the highest death rate compared to their population?

-- To find this out, we can look at the maximum number of death count [the max() function] and this maximum number as compared to the 
-- countries' populations.

SELECT location, population, max(cast(total_deaths AS int)) AS TotalDeathCount
--max(cast((total_deaths/population) AS int)*100) AS HighestPopDeaths
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

SELECT location, population, max(cast(total_deaths AS int)) AS TotalDeathCount, (max(cast(total_deaths AS int)*100)/population) AS HighestPopDeaths
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

-- Now, let's us examine each continents' death count per population

-- Note that this data is incomplete as North America only show data for USA
SELECT continent, max(cast(total_deaths AS int)) AS TotalDeathCount
--max(cast((total_deaths/population) AS int)*100) AS HighestPopDeaths
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- How many new cases, and deaths, developed daily across the globe? 
-- What is the corresponding ratio of new deaths to new cases?

-- For this answer, examine the sum (SUM) of the new cases (new_cases) each day (GROUP BY) regardless of location.
SELECT date, SUM(new_cases) AS dailynewcases, SUM(CAST(new_deaths AS int)) AS dailynewdeaths, 
(SUM(CAST(new_deaths AS int))/SUM(new_cases)*100) AS ratio_newdeaths_to_newcases
-- ratio as a percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date, dailynewcases

-- extra: global covid death percentage

SELECT SUM(new_cases) AS dailynewcases, SUM(CAST(new_deaths AS int)) AS dailynewdeaths, 
(SUM(CAST(new_deaths AS int))/SUM(new_cases)*100) AS globalcoviddeaths_percent
-- ratio as a percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY dailynewcases


-- Now let us examine the covid vaccination data

-- What amount of the total global population was vaccinated each day? New vaccination (daily) count

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths AS deaths
	JOIN PortfolioProject.dbo.CovidVax AS vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL
ORDER BY deaths.location, deaths.date

-- How did the daily new vaccination totals (SUM) change over time for each location (PARTITION BY location and date)?

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as local_daily_vax
FROM PortfolioProject.dbo.CovidDeaths AS deaths
	JOIN PortfolioProject.dbo.CovidVax AS vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL 
--AND deaths.location like '%states%'
ORDER BY deaths.location, deaths.date

-- How did global new vaccination rate change in relation to the locations' populations?
-- Option 1: Use CTE method

WITH Pop_vs_Vax (continent, location, date, population, new_vaccinations, local_daily_vax)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as local_daily_vax
FROM PortfolioProject.dbo.CovidDeaths AS deaths
	JOIN PortfolioProject.dbo.CovidVax AS vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL 
--AND deaths.location like '%states%'
-- ORDER BY deaths.location, deaths.date
)

SELECT *, (local_daily_vax/population)*100 AS percent_daily_vax
FROM Pop_vs_Vax

-- Option 2: Temp table

DROP TABLE IF exists #Percent_Pop_Vax

CREATE TABLE #Percent_Pop_Vax

(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
local_daily_vax numeric
)

INSERT INTO #Percent_Pop_Vax

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as local_daily_vax
FROM PortfolioProject.dbo.CovidDeaths AS deaths
	JOIN PortfolioProject.dbo.CovidVax AS vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
-- WHERE deaths.continent IS NOT NULL 
--AND deaths.location like '%states%'
-- ORDER BY deaths.location, deaths.date

SELECT *, (local_daily_vax/population)*100 AS percent_daily_vax
FROM #Percent_Pop_Vax

-- Creating VIEW store data for visualization (permanent data stored for later)

CREATE VIEW Percent_Pop_Vax AS

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vax.new_vaccinations,
SUM(CAST(vax.new_vaccinations AS int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) as local_daily_vax
FROM PortfolioProject.dbo.CovidDeaths AS deaths
	JOIN PortfolioProject.dbo.CovidVax AS vax
	ON deaths.location = vax.location
	AND deaths.date = vax.date
WHERE deaths.continent IS NOT NULL 
--AND deaths.location like '%states%'
-- ORDER BY deaths.location, deaths.date

SELECT *
FROM Percent_Pop_Vax
