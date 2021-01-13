library(purrr);library(dplyr);library(DBI);library(RPostgres);library(data.table);library(odbc)

#covid_df = list.files(pattern = "*.csv") %>% map_df(~fread(.))

con <- DBI::dbConnect(odbc::odbc(),
Driver   = "PostgreSQL ANSI(x64)",
Server   = "localhost",
Database = "COVID",
UID      = rstudioapi::askForPassword("Database user"),
PWD      = rstudioapi::askForPassword("Database password"),
Port     = 5432)

#dbWriteTable(con, "daily_reports", covid_df)


