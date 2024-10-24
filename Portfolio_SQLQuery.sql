-- import data by the import flat file wizard
-- for proper handling of commas and periods in the numbers let's just import as varchar

-- check whether everything was loaded properly

SELECT *
FROM PortfolioDatabase..MORTALITY

SELECT *
FROM PortfolioDatabase..RUGGEDNESS


-- convert the Number_of_Deaths and Death_rate colums to integer and float, respectively
-- for that, first I need to remove the comma and than convert

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
-- Moreover, at an age range given in years it should end on the last day of the given year e.g. age of 2 means 3*365-1 day as range end
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


-- We can combine the MORTALITY data with the RUGGEDNESS by the country code
-- What we want is a country with a high mortality rate, near the coast and low ruggedness

SELECT TOP(10) mort.Country_Name, mort.DeathRate , rug.rugged AS DifficultyToTraverse, rug.dist_coast * 1000 AS DistanceToCoast
FROM PortfolioDatabase..MORTALITY AS mort
INNER JOIN PortfolioDatabase..RUGGEDNESS as rug
	ON mort.Country_Code = rug.isocode
WHERE mort.Year = 2010 AND Sex = 'Both' AND mort.Age_Group = 'All ages'
ORDER BY mort.DeathRate DESC , rug.rugged ASC , rug.dist_coast ASC

