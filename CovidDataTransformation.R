## Fetching data for California from the database and ordering chronologically
library(dplyr);library(data.table)

cali = dbGetQuery(con, "
                  SELECT 
                    Province_State,
                    Last_Update,
                    Confirmed,
                    Deaths,
                    Recovered,
                    Active,
                    Incident_Rate,
                    Total_Test_Results,
                    Case_Fatality_Ratio,
                    Testing_Rate,
                    People_Tested,
                    Mortality_Rate
                  FROM 
                    daily_reports 
                  WHERE 
                    Province_State = 'California'
                  ORDER BY 
                    last_update
                  ")

## Aggregating data from covidtracking to fill in missing data

cali = as.data.table(cali)
cali$last_update = as.Date(cali$last_update)

CA_history = fread("california-history.csv", header = T)
CA_history = as.data.table(CA_history)
CA_history$last_update = as.Date(CA_history$last_update, format = "%m/%d/%Y")
CA_history = CA_history[last_update >= "2020-04-12"]
CA_history = CA_history[order(last_update)]

## JHU has data missing for two days, these rows will be removed from the covidtracking data

CA_history = CA_history[(CA_history$last_update %in% cali$last_update) == TRUE]

## Filling in missing data in JHU data table with covidtracking state data and appending new columns

cali$total_test_results = CA_history$totalTestResults
cali = cali %>% mutate(Hospitalized_Currently = CA_history$hospitalizedCurrently,
                In_ICU_Currently = CA_history$inIcuCurrently,
                Negative_Test_Result = CA_history$negative,
                Daily_Neg_Increase = CA_history$negativeIncrease,
                Positive_Test_Result = CA_history$positive,
                Daily_Pos_Increase = CA_history$positiveIncrease,
                Test_Results_Increase = CA_history$totalTestResultsIncrease,
                case_fatality_ratio = (deaths*100)/confirmed,
                mortality_rate = NULL,
                people_tested = NULL,
                recovered = NULL)


## Discovered inconsistency in reported cumulative deaths; since JHU aggregates counts from many sources,
## the cumulative death count updated on 2020-09-21 is less than the count reported the previous day.

cali[last_update == "2020-09-21"] = cali %>% filter(last_update == "2020-09-21") %>% mutate(deaths = 15018)

## Creating new features from data to reflect daily change over time.

## Daily increases or decreases compared to previous day records.

daily_change = cali %>% 
  select(last_update, confirmed, deaths, active, total_test_results, Daily_Neg_Increase, 
         Daily_Pos_Increase, Hospitalized_Currently, In_ICU_Currently) %>%
  mutate(Increase_Deaths = (deaths-lag(deaths)),
         Increase_Test_Results = total_test_results-lag(total_test_results),
         Increase_Confirmed_Cases = confirmed - lag(confirmed),
         Change_Active_Cases = active-lag(active),
         Daily_Hospitalizations_Change = Hospitalized_Currently-lag(Hospitalized_Currently),
         Daily_ICU_Change = In_ICU_Currently - lag(In_ICU_Currently),
         Daily_Change_Deaths = Increase_Deaths-lag(Increase_Deaths),
         Daily_Change_Test_Results = Increase_Test_Results-lag(Increase_Test_Results),
         Daily_Change_Confirmed_Cases = Increase_Confirmed_Cases - lag(Increase_Confirmed_Cases),
         Daily_Change_Active_Cases = Change_Active_Cases - lag(Change_Active_Cases)) %>%
  select(last_update, Increase_Deaths, Increase_Test_Results, Increase_Confirmed_Cases,
         Change_Active_Cases, Daily_Hospitalizations_Change, Daily_ICU_Change,
         Daily_Change_Deaths, Daily_Change_Test_Results, Daily_Change_Confirmed_Cases,
         Daily_Change_Active_Cases)

## Daily percent increases in total number of deaths, confirmed cases, and testing results.

daily_percent_increase_in_cumulative_totals = cali %>%
  select(last_update, deaths, confirmed, total_test_results) %>%
  mutate(Daily_Percent_Increase_Cumulative_Deaths = 
           (deaths - lag(deaths))/lag(deaths)*100,
         Daily_Percent_Increase_Cumulative_Confirmed_Cases =
           (confirmed - lag(confirmed))/lag(confirmed)*100,
         Daily_Percent_Increase_Cumulative_Testing =
           (total_test_results-lag(total_test_results))/lag(total_test_results)*100) %>%
  select(last_update, Daily_Percent_Increase_Cumulative_Deaths, Daily_Percent_Increase_Cumulative_Confirmed_Cases,
         Daily_Percent_Increase_Cumulative_Testing)

