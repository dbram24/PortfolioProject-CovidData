-- Skills used: Joins, Aggregate Functions, Temp Tables, Views, Converting Data Types, Window Functions

SELECT location, date, total_cases, new_cases, total_deaths, population FROM covid_deaths
ORDER BY location, date;

-- Looking at Total Cases vs Total Deaths in United States
-- Shows likelihood of dying if you contract Covid in the U.S.
SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS death_percentage
FROM covid_deaths
WHERE location ILIKE '%states%'
ORDER BY location, date;

ALTER TABLE covid_deaths
ALTER COLUMN total_cases TYPE DOUBLE PRECISION;

ALTER TABLE covid_deaths
ALTER COLUMN total_deaths TYPE DOUBLE PRECISION;

-- Looking at Total Cases vs Population
-- Shows what percentage of U.S. population contracted covid
SELECT location, date, total_cases, population, ((total_cases/population)*100) AS infection_percentage
FROM covid_deaths
WHERE location ILIKE '%states%'
ORDER BY location, date;

-- Looking at countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS max_infection_percentage
FROM covid_deaths
GROUP BY location, population
HAVING MAX((total_cases/population)*100) IS NOT NULL
ORDER BY max_infection_percentage DESC;

-- Showing countries with highest death counts
SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL -- To remove continent groupings
GROUP BY location
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY total_death_count DESC;

-- Showing continents with highest death counts
SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NULL -- To include continent groupings
GROUP BY location
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY total_death_count DESC;

-- Number of new cases & deaths globally per day
SELECT date, SUM(new_cases) AS new_cases_globally, SUM(new_deaths) AS new_deaths_globally
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

--- Join covid_deaths and covid_vax tables
SELECT * FROM covid_deaths
JOIN covid_vax
ON covid_deaths.location = covid_vax.location AND covid_deaths.date = covid_vax.date;

-- Looking at New Cases vs. New Vaccinations globally
SELECT covid_deaths.date, SUM(new_cases) AS global_new_cases, SUM(new_vaccinations) AS global_new_vax 
FROM covid_deaths
JOIN covid_vax
ON covid_deaths.location = covid_vax.location AND covid_deaths.date = covid_vax.date
WHERE covid_deaths.continent IS NOT NULL
GROUP BY covid_deaths.date
ORDER BY covid_deaths.date;

-- Looking at Total Cases, New Vaccinations, and Death Percentage
SELECT covid_deaths.date, SUM(total_cases) AS global_cases, SUM(new_vaccinations) AS global_new_vax, (SUM(total_deaths)/SUM(total_cases)*100) AS death_percentage
FROM covid_deaths
JOIN covid_vax
ON covid_deaths.location = covid_vax.location AND covid_deaths.date = covid_vax.date
WHERE covid_deaths.continent IS NOT NULL
GROUP BY covid_deaths.date
ORDER BY covid_deaths.date;


-- Total Population vs Vaccinations
-- Gives a rolling count of people who have received at least one vax based on country
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vax.new_vaccinations,
SUM(covid_vax.new_vaccinations) OVER (PARTITION BY covid_deaths.location ORDER BY covid_deaths.location, covid_deaths.date) AS rolling_people_vaccinated
FROM covid_deaths
JOIN covid_vax
ON covid_deaths.location = covid_vax.location AND covid_deaths.date = covid_vax.date
WHERE covid_deaths.continent IS NOT NULL
ORDER BY covid_deaths.location, covid_deaths.date;

-- Creating a temp table to do calculations on previous query

CREATE TABLE percent_population_vaccinated
(
	continent varchar(250),
	location varchar(250),
	date DATE,
	population BIGINT,
	new_vaccinations BIGINT,
	rolling_people_vaccinated BIGINT
);

INSERT INTO percent_population_vaccinated
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vax.new_vaccinations,
SUM(covid_vax.new_vaccinations) OVER (PARTITION BY covid_deaths.location ORDER BY covid_deaths.location, covid_deaths.date) AS rolling_people_vaccinated
FROM covid_deaths
JOIN covid_vax
ON covid_deaths.location = covid_vax.location AND covid_deaths.date = covid_vax.date
WHERE covid_deaths.continent IS NOT NULL
ORDER BY covid_deaths.location, covid_deaths.date;

SELECT *, (CAST(rolling_people_vaccinated AS DOUBLE PRECISION)/CAST(population AS DOUBLE PRECISION)) * 100 AS percent_vaccinated
FROM percent_population_vaccinated
WHERE location ILIKE '%states%';

-- Storing rolling people vaccinated query as a view for visualizations
CREATE VIEW RollingPopulationVaccinated AS
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vax.new_vaccinations,
SUM(covid_vax.new_vaccinations) OVER (PARTITION BY covid_deaths.location ORDER BY covid_deaths.location, covid_deaths.date) AS rolling_people_vaccinated
FROM covid_deaths
JOIN covid_vax
ON covid_deaths.location = covid_vax.location AND covid_deaths.date = covid_vax.date
WHERE covid_deaths.continent IS NOT NULL
ORDER BY covid_deaths.location, covid_deaths.date;


