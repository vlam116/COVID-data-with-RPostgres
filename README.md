# **Reporting COVID-19 in California**
A small project integrating a PostgreSQL database with R and exporting wrangled data to Power BI for consumption. Tracking key metrics of the COVID-19 epidemic in the state of California using data provided from official sources. 

# **Data Sources**
* JHU CSSE COVID-19 Data : https://github.com/CSSEGISandData/COVID-19
* The COVID Tracking Project: https://covidtracking.com/data/state/california
* Covid Act Now: https://covidactnow.org/us/california-ca/?s=1559499

# **Metrics**
* Cumulative and/or daily totals for the following:
    * Deaths
    * Test results
    * Confirmed cases
    * Hospitalizations, ICU admissions
* Testing Rate (test results per 100,000 persons)
* Incident Rate (cases per 100,000 persons)
* Case Fatality Ratio (deaths per 100 cases)

# **Report Production and Reproducibility**
All data used to generate the example report made available in this repository can be downloaded or extracted from the above data sources. The code provided showcasing how to connect RStudio to an existing database assumes an SQL server is **already** set up by the user. In my case, I set up a PostgreSQL database server on my Windows machine and used the odbc and DBI packages in R to connect to the database.   

Once R is connected to a SQL database, DBI offers support for writing SQL queries in R. The results of the query can be stored in an R object and the data can be prepared for the analysis stage. Data can also be written from R directly into the database. 

Currently, one script reads in the data downloaded from the JHU CSSE repository and COVID Tracking Project website and writes it to my database. The other queries only the data I need and performs further filtering, manipulation, aggregation, and mathematic transformations to output a final data table for analysis. This data table is exported as a csv and loaded into Power BI where the end report is generated.

# **Project Status** 
Currently the report is not updated daily. The updating process consists of downloading the latest JHU repository and COVID Tracking Project data, running the data through the script and refreshing the data on Power BI.  



