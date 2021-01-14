## Fetching data for California from the database and ordering chronologically

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

## Creating new features from data to reflect daily change and percent change over time

cali = as.data.table(cali)

daily_change = cali %>% 
  select(last_update, confirmed, deaths, active, total_test_results, people_tested) %>%
  mutate(Daily_Deaths = (deaths-lag(deaths)),
         Daily_Tests = (people_tested-lag(people_tested)),
         Daily_Active_Cases = (active-lag(active)))

percent_daily_change = daily_change %>%
    select(last_update, Daily_Deaths, Daily_Active_Cases, Daily_Tests) %>%
    mutate(Percent_Change_Daily_Deaths = 
             ((Daily_Deaths-lag(Daily_Deaths))/lag(Daily_Deaths)*100),
           Percent_Change_Daily_Active_Cases = 
             (Daily_Active_Cases-lag(Daily_Active_Cases))/lag(Daily_Active_Cases)*100,
           Percent_Change_Daily_Testing =
             (Daily_Tests-lag(Daily_Tests))/lag(Daily_Tests)*100)

percent_cumulative_change = cali %>%
  select(last_update, deaths, active, people_tested) %>%
  mutate(Percent_Increase_Total_Deaths = 
           (deaths-lag(deaths))/lag(deaths)*100,
         Percent_Increase_Total_Active_Cases =
           (active-lag(active))/lag(active)*100,
         Percent_Increase_Total_Tests = 
           (people_tested-lag(people_tested))/lag(people_tested)*100)
