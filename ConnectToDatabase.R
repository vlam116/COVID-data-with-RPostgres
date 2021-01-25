library(purrr);library(dplyr);library(DBI);library(RPostgres);library(data.table);library(odbc)

## Demonstrating how to connect and write data to postgres database. 

covid_df = list.files(pattern = "*.csv") %>% map_df(~fread(., quote = FALSE))
ca_df = fread("california-history.csv")

colnames(covid_df) = tolower(colnames(covid_df))
colnames(ca_df) = tolower(colnames(ca_df))

con <- DBI::dbConnect(odbc::odbc(),
Driver   = "PostgreSQL ANSI(x64)",
Server   = "localhost",
Database = "COVID",
UID      = rstudioapi::askForPassword("Database user"),
PWD      = rstudioapi::askForPassword("Database password"),
Port     = 5432)

## Writing R data.table object to the postgres database as two tables named "daily_reports" and "ca_history".

dbWriteTable(con, "daily_reports_ca", covid_df, overwrite = TRUE)
dbWriteTable(con, "ca_history", ca_df, overwrite = TRUE)

dbDisconnect(con)

