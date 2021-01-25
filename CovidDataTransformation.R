## Fetching data for California from the database and ordering chronologically
library(dplyr);library(data.table)

cali = dbGetQuery(con, "
                  SELECT
	                  last_update,
	                  confirmed,
                	  deaths,
	                  incident_rate,
	                  total_test_results,
	                  case_fatality_ratio,
	                  testing_rate
                  FROM
                  	daily_reports_ca
                  WHERE
	                  province_state = 'California'
                  ORDER BY
	                  last_update ASC
                  ")

CA_history = dbGetQuery(con, "
                        SELECT
                          date,
	                        hospitalizedcurrently,
	                        inicucurrently,
	                        negative,
                        	positive,
	                        totaltestresults,
	                        totaltestresultsincrease
                        FROM
	                        ca_history
                        WHERE
	                        date >= '2020-04-12'
                        ORDER BY
	                        date ASC")

## Aggregating data from covidtracking to fill in missing data and insert new columns

cali = as.data.table(cali)
cali$last_update = as.Date(cali$last_update)

CA_history = as.data.table(CA_history)
CA_history$last_update = as.Date(CA_history$last_update, format = "%m/%d/%Y")
CA_history = CA_history[last_update >= "2020-04-12"]
CA_history = CA_history[order(last_update)]

## JHU has some inconsistencies in reporting data for 2020-04-23, this row will be removed from the 
## covidtracking data to avoid any possible misinformation 

CA_history = CA_history[(CA_history$date %in% cali$last_update) == TRUE]

## JHU is one day ahead of covidtracking in reporting data, so I will just remove the most recent 
## update from the JHU dataset. 

cali = cali[(cali$last_update %in% CA_history$date) == TRUE]

## Filling in missing data in JHU data table with covidtracking state data and appending new columns

cali$total_test_results = CA_history$totaltestresults
cali = cali %>% mutate(Hospitalized_Currently = CA_history$hospitalizedcurrently,
                In_ICU_Currently = CA_history$inicucurrently,
                Negative_Test_Result = CA_history$negative,
                Daily_Neg_Increase = CA_history$negativeincrease,
                Positive_Test_Result = CA_history$positive,
                Daily_Pos_Increase = CA_history$positiveincrease,
                Increase_Test_Results = CA_history$totaltestresultsincrease,
                case_fatality_ratio = (deaths*100)/confirmed)


## Discovered inconsistency in reported cumulative deaths; since JHU aggregates counts from many sources,
## the cumulative death count updated on 2020-09-21 is less than the count reported the previous day.

cali[last_update == "2020-09-21"] = cali %>% filter(last_update == "2020-09-21") %>% mutate(deaths = 15018)

## Creating new features from data to reflect daily change over time.

## Daily increases compared to the previous day for deaths and confirmed cases.

cali = cali %>% 
  mutate(Increase_Deaths = 
           deaths-lag(deaths),
         Increase_Confirmed_Cases = 
           confirmed - lag(confirmed))

## Daily percent increases in total number of deaths, confirmed cases, and testing results.

cali = cali %>%
  mutate(Percent_Increase_Deaths = 
           (deaths - lag(deaths))/lag(deaths)*100,
         Percent_Increase_Cases =
           (confirmed - lag(confirmed))/lag(confirmed)*100,
         Percent_Increase_Testing =
           (total_test_results-lag(total_test_results))/lag(total_test_results)*100)

## Creating a metric for the national average testing rate for comparison

covid_df = dbGetQuery(con, "
                      SELECT
                        province_state,
                        last_update,
                        testing_rate
                      FROM
                        daily_reports_ca
                      WHERE 
                        province_state not in ('Grand Princess','Diamond Princess')
                        AND last_update >= '04-12-2020'
                      ORDER BY 
                        last_update ASC
                      ")

covid_df$last_update = as.Date(covid_df$last_update)
covid_df = covid_df[(covid_df$last_update %in% cali$last_update) == TRUE]

Daily_Avg_TestingRate = covid_df %>% 
  group_by(last_update) %>% 
  filter(province_state != 'California') %>%
  mutate(Daily_Avg_TestingRate = mean(testing_rate, na.rm = T))

cali$Daily_Avg_TestingRate = unique(Daily_Avg_TestingRate$Daily_Avg_TestingRate)

write.csv(cali, "CA_updated_COVID_data.csv")



