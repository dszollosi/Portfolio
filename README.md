# Portfolio Project - Efficient Help

![alt text](https://github.com/dszollosi/Portfolio/blob/main/etc/uc.png)


## Setting up the stage

Imagine that an international charity organization called Efficient Help approaches us for support. Their objective is to help people in developing countries to improve their life expectancy but as their name suggests they want to do this efficiently. The mortality rate<sup>1</sup> is a good measure to detect places of the world where people would need help and also later to measure the effect of their actions. However, if the selected country is difficult to reach or traverse the resources are used up by the logistics. 

<sup>1</sup> Mortality rate is expressed in units of deaths per 100,000 individuals per year; thus, a mortality rate of 950 (out of 100,000) in a population of 100,000 would mean 950 deaths per year in that entire population, or 0.95% out of the total.

## The question

**Which country should Efficient Help go to help?**

The selected place should have a
  * high mortality rate indicating the need of help and the possible room for improvement
  * sea shore or be flat enough to easily travel through

## The data

To answer the question we need data. On one hand country level [mortality rate](https://public.tableau.com/app/sample-data/IHME_GBD_2010_MORTALITY_AGE_SPECIFIC_BY_COUNTRY_1970_2010.csv). On the other hand, [terrain ruggedness](https://diegopuga.org/data/rugged/) will tell us how rugged a country is and also wheter it is reachable from the sea. Terrain ruggedness alone is not sufficient as a rugged but small country is still relatively cheap to travel through due to small distances so we also include country [size data](https://ourworldindata.org/grapher/land-area-km)


## Importing and cleaning

All data sets are csv files, easily imported in SQL Server and cleaned as decribed in the [SQL query file](Portfolio_SQLQuery.sql). The countr size data will be imported directly to Power BI

## Import to Power BI

The prepared data tables are then used in Power BI to create a report.

1 connect to the SQL Server
2 import country size data as AREA
3 build data model

In the MORTALITY table the age categories are repeated many times and also an ID column which can be used for sorting and filtering would be good. Let's normalize the Age_Group. The AgeKey=0 will be the all ages group. The AREA table contains many rows for non-country entities like a region of multiple countries *etc.* which we do not need here. Moreover, size data is given for many year from 1961 to 2024. We filter it to years present in the MORTALITY data.
The relationshp between the MORTALITY and RUGGEDNESS table need to be established through the country isocode. Since the country name is also stored in the RUGGEDNESS table we do not need to have it in the MORTALITY table repeated many times. 
To relate the AREA table to the MORTALITY table we devise a new ID column from the country code and the year.
By that we arriver to a nice start-schema data model.

4 Build visuals

We will need a couple of visuals to help decision making. First of all a table showing countries with mortality rate in decreasing order, these are our prime candidates.


![alt text](https://github.com/dszollosi/Portfolio/blob/main/screeshots/report_v0.png)
