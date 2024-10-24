# Portfolio Project - Efficient Help

## Setting up the stage

Imagine that an international charity organization called Efficient Help approaches us for support. Their objective is to help people in developing countries to improve their life expectancy but as their name suggests they want to do this efficiently. The mortality rate<sup>1</sup> is a good measure to detect places of the world where people would need help and also later to measure the effect of their actions. However, if the selected country is difficult to reach or traverse the resources are used up by the logistics. 

## The question

**Which country should Efficient Help go to help?**

The selected place should have a
  * high mortality rate indicating the need of help and the possible room for improvement
  * sea shore or be flat enough to easily travel through

## The data

To answer the question we need data. On one hand country level [mortality rate](https://public.tableau.com/app/sample-data/IHME_GBD_2010_MORTALITY_AGE_SPECIFIC_BY_COUNTRY_1970_2010.csv). On the other hand, [terrain ruggedness](https://diegopuga.org/data/rugged/) will tell us how rugged a countr is and also wheter it is reachable from the sea.

## Importing and cleaning

Both data sets are csv files, easily imported in SQL Server and cleaned as decribed in the [SQL query file](Portfolio_SQLQuery.sql)
