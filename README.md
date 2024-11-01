# Portfolio Project - Efficient Help

## Setting up the stage

Imagine that an international charity organization called Efficient Help approaches us for support. Their objective is to help people in developing countries to improve their life expectancy but as their name suggests they want to do this efficiently. The mortality rate<sup>1</sup> is a good measure to detect places of the world where people would need help and also later to measure the effect of their actions. However, if the selected country is difficult to reach or traverse the resources are used up by the logistics. 

<sup>1</sup> Mortality rate is expressed in units of deaths per 100,000 individuals per year; thus, a mortality rate of 950 (out of 100,000) in a population of 100,000 would mean 950 deaths per year in that entire population, or 0.95% out of the total.

## The question

**Which country should Efficient Help go to?**

The selected place should have a
  * high mortality rate indicating the need of help and the possible room for improvement
  * sea shore or be flat enough to easily travel through

## The data

To answer the question we need data. On one hand country level [mortality rate](https://public.tableau.com/app/sample-data/IHME_GBD_2010_MORTALITY_AGE_SPECIFIC_BY_COUNTRY_1970_2010.csv). On the other hand, [terrain ruggedness](https://diegopuga.org/data/rugged/) will tell us how rugged a country is and also wheter it is reachable from the sea. 


## Importing and cleaning

All data sets are csv files, easily imported into SQL Server and cleaned and preprocessed as decribed in the [SQL query file](Portfolio_SQLQuery.sql). 

## Import to Power BI

The prepared data tables are then used in Power BI to create a report.

1. connect to the SQL Server
2. build data model

In the MORTALITY table the age categories are repeated many times and also an ID column which can be used for sorting and filtering would be good. Let's normalize the Age_Group. The AgeKey=0 will be the all ages group. 
The relationshp between the MORTALITY and RUGGEDNESS table need to be established through the country isocode. Since the country name is also stored in the RUGGEDNESS table we do not need to have it in the MORTALITY table repeated many times thereby reduce the size of the table. 
By that we arriver to a nice start-schema data model.

![alt text](https://github.com/dszollosi/Portfolio/blob/main/screeshots/data_model_v0.png)


3. Build visuals

We will need a couple of visuals to help decision making. First of all a table showing countries with mortality rate in decreasing order, these are our prime candidates. Next we want to know how rugged are our top candidates and whether they have a coast nearby. We add some slicers to specify the year of the data to the most recent one and that we are interesed a combined mortality for both sexes and all age groups. Haiti is the most prominent candidate. 
Let's have a closer look to Haiti to see how the mortality changed over time. For that purpose a separate table is created by the follwoing DAX expression and used it as input for a visualizations.

```
Top Candidate = 
VAR top_mortality = CALCULATE(MAX(MORTALITY[DeathRate]),
    MORTALITY[AgeKey] = 0, 
    MORTALITY[Sex] = "Both",
    MORTALITY[Year] = 2010)
VAR top_country_code = CALCULATE(MAX(MORTALITY[Country_Code]),
    MORTALITY[DeathRate] = top_mortality)
RETURN
    FILTER(MORTALITY,MORTALITY[Country_Code] = top_country_code )

```

The mortality have even increased in the past so Haiti is definitely a good place for support. Moreover, the age group analysis tells that children are the most at risk.  


![alt text](https://github.com/dszollosi/Portfolio/blob/main/screeshots/report_v1.png)
