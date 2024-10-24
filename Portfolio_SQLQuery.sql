-- import data by the import flat file wizard
-- for proper handling of commas and periods in the numbers let's just import as varchar

-- check whether everything was loaded properly

SELECT *
FROM PortfolioDatabase..MORTALITY

SELECT *
FROM PortfolioDatabase..CONTINENT

-- convert the Number_of_Deaths and Death_rate colums to integer and float, respectively
-- for that, first I need to remove the dash and than convert

SELECT Number_of_Deaths, Death_Rate_Per_100_000 , CONVERT(int,REPLACE(Number_of_Deaths,',','')), CONVERT(float,REPLACE(Death_Rate_Per_100_000,',','')) 
FROM PortfolioDatabase..MORTALITY

-- this looks good, add the new columns to the table as DeathNum and DeathRate

ALTER TABLE PortfolioDatabase..MORTALITY
ADD DeathNum int NULL, DeathRate float NULL

-- and fill in the values

UPDATE PortfolioDatabase..MORTALITY
SET DeathNum = CONVERT(int,REPLACE(Number_of_Deaths,',','')), DeathRate = CONVERT(float,REPLACE(Death_Rate_Per_100_000,',',''))
FROM PortfolioDatabase..MORTALITY

-- the Age_Group column is currently in various units: days and years and given by range instead of a number. 
-- Lets turn everything into days unit (taking a year as 365 days) and separate the beginning and the end to allow fine grain selection afterwards.
-- However, there are exceptions like lines of All ages or the age category above 80
-- Moreover, at an age range given in years it should and on the last day of the given year e.g. age of 2 means 3*365-1 day as range end
-- Here I assume no one live longer than 50000 days (~137 years) 
-- First the beginning columns as AgeDaysStart, the query starts to be lengthy so put it in a CTE

ALTER TABLE PortfolioDatabase..MORTALITY
ADD AgeDaysStart int NULL

WITH CTE_AgeDaysStart AS (
SELECT Age_Group, 
CASE
	WHEN Age_Group = 'All ages' -- I use here that first met condition returns the output
		THEN 0
	WHEN Age_Group = '80+ years'
		THEN 80*365
	WHEN Age_Group LIKE '%years%'
		THEN SUBSTRING(Age_Group,1,CHARINDEX('-',Age_Group) - 1) * 365
	ELSE SUBSTRING(Age_Group,1,CHARINDEX('-',Age_Group) - 1)
	END AS ADS
FROM PortfolioDatabase..MORTALITY )
UPDATE PortfolioDatabase..MORTALITY
SET AgeDaysStart = ADS
FROM CTE_AgeDaysStart
WHERE PortfolioDatabase..MORTALITY.Age_Group = CTE_AgeDaysStart.Age_Group

-- then the AgeDaysEnd

ALTER TABLE PortfolioDatabase..MORTALITY
ADD AgeDaysEnd int NULL

WITH CTE_AgeDaysEnd AS (
SELECT Age_Group, 
CASE
	WHEN Age_Group = 'All ages' -- I make an advantage from the first met condition returns the output
		THEN 50000
	WHEN Age_Group = '80+ years'
		THEN 50000
	WHEN Age_Group LIKE '%years%'
		THEN SUBSTRING(Age_Group,CHARINDEX('-',Age_Group) + 1,CHARINDEX(' ',Age_Group) - CHARINDEX('-',Age_Group) - 1) * 365 + 364
	ELSE SUBSTRING(Age_Group,CHARINDEX('-',Age_Group) + 1,CHARINDEX(' ',Age_Group) - CHARINDEX('-',Age_Group) - 1)
	END AS ADE
FROM PortfolioDatabase..MORTALITY )
UPDATE PortfolioDatabase..MORTALITY
SET AgeDaysEnd = ADE
FROM CTE_AgeDaysEnd
WHERE PortfolioDatabase..MORTALITY.Age_Group = CTE_AgeDaysEnd.Age_Group

-- Let's check what have been done.

SELECT * 
FROM PortfolioDatabase..MORTALITY

-- Now do some easy queryies like:
-- Where is the highest and lowest Death rate?

SELECT TOP(1) Country_Name, Year, MAX(DeathRate) AS MaximalDeathRate
FROM PortfolioDatabase..MORTALITY
WHERE Age_Group = 'All ages' AND Sex = 'Both'
GROUP BY Country_Name, Year
ORDER BY MAX(DeathRate) DESC

SELECT TOP(1) Country_Name, Year, MIN(DeathRate) AS MinimalDeathRate
FROM PortfolioDatabase..MORTALITY
WHERE Age_Group = 'All ages' AND Sex = 'Both'
GROUP BY Country_Name, Year
ORDER BY MIN(DeathRate) ASC

-- How many people died world wide in 2000 between the age of 10 and 25 years

SELECT SUM(DeathNum)
FROM PortfolioDatabase..MORTALITY
WHERE Sex = 'Both' AND Year = 2000 AND AgeDaysStart >= 10 * 365 AND AgeDaysEnd < 25 * 365

-- Let's do some continent related queries, for that the CONTINENT table is also used
-- but are all the countries in the MORTALITY table matched?

SELECT COUNT(Country_Name) AS TotalRowCount
FROM PortfolioDatabase..MORTALITY

SELECT COUNT(Country_Name) AS JoinedRowCount
FROM PortfolioDatabase..MORTALITY AS mort
INNER JOIN PortfolioDatabase..CONTINENT as cont
	ON mort.Country_Name = cont.country

-- Of course not, which are the missed cases

SELECT mort.Country_Name
FROM PortfolioDatabase..MORTALITY AS mort
FULL JOIN PortfolioDatabase..CONTINENT as cont
	ON mort.Country_Name = cont.country
WHERE cont.country IS NULL
GROUP BY mort.Country_Name


-- Using a more fuzzy matching

SELECT mort.Country_Name
FROM PortfolioDatabase..MORTALITY AS mort
FULL JOIN PortfolioDatabase..CONTINENT as cont
	ON mort.Country_Name LIKE CONCAT('%', cont.country, '%')
WHERE cont.country IS NULL
GROUP BY mort.Country_Name

-- this is now just ten cases which is the easiest to fix by hand
-- use the country name in the MORTALITY database and update the CONTINENT

UPDATE PortfolioDatabase..CONTINENT
SET country = 'Lao People''s Democratic Republic'
WHERE country = 'Laos'

UPDATE PortfolioDatabase..CONTINENT
SET country = 'Macedonia, the Former Yugoslav Republic of'
WHERE country = 'North Macedonia'

UPDATE PortfolioDatabase..CONTINENT
SET country = 'Occupied Palestinian Territory'
WHERE country = 'Palestine'

UPDATE PortfolioDatabase..CONTINENT
SET country = 'Viet Nam'
WHERE country = 'Vietnam'

UPDATE PortfolioDatabase..CONTINENT
SET country = 'Cote d''Ivoire'
WHERE country = 'Ivory Coast'

UPDATE PortfolioDatabase..CONTINENT
SET country = 'Congo, the Democratic Republic of the'
WHERE country = 'DR Congo'

UPDATE PortfolioDatabase..CONTINENT
SET country = 'Congo'
WHERE country = 'Republic of the Congo'

UPDATE PortfolioDatabase..CONTINENT
SET country = 'Korea, Republic of'
WHERE country = 'South Korea'

UPDATE PortfolioDatabase..CONTINENT
SET country = 'Korea, Democratic People''s Republic of'
WHERE country = 'North Korea'

-- at which continent is the average mortality the highest in 2010?

SELECT TOP(1) Age_Group, Sex, MIN(DeathRate)
FROM PortfolioDatabase..MORTALITY
WHERE Country_Name = 'Austria' AND Year = 2010 AND Sex != 'Both' 
GROUP BY Age_Group, Sex
ORDER BY MIN(DeathRate) ASC

SELECT cont.continent, AVG(mort.DeathRate) AS AverageMortaility
FROM PortfolioDatabase..MORTALITY AS mort
FULL JOIN PortfolioDatabase..CONTINENT as cont
	ON mort.Country_Name LIKE CONCAT('%', cont.country, '%')
WHERE mort.Year = 2010 AND Sex = 'Both' AND cont.continent IS NOT NULL
GROUP BY cont.continent
ORDER BY AVG(mort.DeathRate) DESC

-- Let's include another data table that helps us determine the accessibility of a country: terrain ruggedness from
-- Nunn, N., & Puga, D. (2012). Ruggedness: The blessing of bad geography in Africa. Review of Economics and Statistics, 94(1), 20–36.
-- import as a falt file

SELECT * 
FROM PortfolioDatabase..RUGGEDNESS

-- We can combine the MORTALITY data with the RUGGEDNESS by the country code
-- What we want is a country with a high mortality rate, near the coast and low ruggedness

SELECT TOP(10) mort.Country_Name, mort.DeathRate , rug.rugged AS DifficultyToTraverse, rug.dist_coast * 1000 AS DistanceToCoast
FROM PortfolioDatabase..MORTALITY AS mort
INNER JOIN PortfolioDatabase..RUGGEDNESS as rug
	ON mort.Country_Code = rug.isocode
WHERE mort.Year = 2010 AND Sex = 'Both' AND mort.Age_Group = 'All ages'
ORDER BY mort.DeathRate DESC , rug.rugged ASC , rug.dist_coast ASC




-- create a temp table that translate one name to the other

DROP TABLE #COUNTRY2COUNTRY
SELECT mort.Country_Name, cont.country
INTO #COUNTRY2COUNTRY
FROM PortfolioDatabase..MORTALITY AS mort
FULL JOIN PortfolioDatabase..CONTINENT as cont
	ON mort.Country_Name LIKE CONCAT('%', cont.country, '%')
GROUP BY mort.Country_Name, cont.country 
ORDER BY mort.Country_Name, cont.country

SELECT *
FROM #COUNTRY2COUNTRY



-- Let's try to use the first word in the Countr_Name to match

SELECT mort.Country_Name
FROM PortfolioDatabase..MORTALITY AS mort
FULL JOIN PortfolioDatabase..CONTINENT as cont
	ON SUBSTRING(mort.Country_Name,1,CHARINDEX(' ',mort.Country_Name)-2) LIKE cont.country
WHERE cont.country IS NULL
GROUP BY mort.Country_Name


SELECT mort.Country_Name , 
CASE
	WHEN CHARINDEX(',',mort.Country_Name) != 0 
		THEN SUBSTRING(mort.Country_Name,1,CHARINDEX(',',mort.Country_Name)-1)
	WHEN CHARINDEX(' ',mort.Country_Name) != 0
		THEN SUBSTRING(mort.Country_Name,1,CHARINDEX(' ',mort.Country_Name)-1)
	ELSE mort.Country_Name
	END
FROM PortfolioDatabase..MORTALITY AS mort
GROUP BY mort.Country_Name
ORDER BY mort.Country_Name

SELECT *
FROM PortfolioDatabase..CONTINENT
WHERE country LIKE '%Palestin%'



-- Variables


-- Views


-- Stored procedure



-- At which age category is the DeathRate the lowest in Austria at 2010

SELECT TOP(1) Age_Group, Sex, MIN(DeathRate)
FROM PortfolioDatabase..MORTALITY
WHERE Country_Name = 'Austria' AND Year = 2010 AND Sex != 'Both' 
GROUP BY Age_Group, Sex
ORDER BY MIN(DeathRate) ASC





-- What are the numbers of a particular country?

SELECT *
FROM PortfolioDatabase..MORTALITY
WHERE Country_Name = 'Austria'

SELECT *
FROM PortfolioDatabase..MORTALITY
WHERE DeathRate > 100000
