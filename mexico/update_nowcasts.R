# Packages -----------------------------------------------------------------

require(EpiNow, quietly = TRUE)
require(NCoVUtils, quietly = TRUE)
require(furrr, quietly = TRUE)
require(future, quietly = TRUE)
require(dplyr, quietly = TRUE)
require(tidyr, quietly = TRUE)
require(magrittr, quietly = TRUE)
require(future.apply, quietly = TRUE)
require(fable, quietly = TRUE)
require(fabletools, quietly = TRUE)
require(feasts, quietly = TRUE)
require(urca, quietly = TRUE)

# Get cases ---------------------------------------------------------------

###  Mexico (Regional)
get_mexico_regional_cases <- function() {
  #Updated 2020-04-28 
  path <- "https://raw.githubusercontent.com/marianarf/covid19_mexico_analysis/master/latest.csv"
  
  #Set up cache
  ch <- memoise::cache_filesystem(".cache2")
  mem_read <- memoise::memoise(readr::read_csv, cache = ch)
  #mem_read <- memoise::memoise(readr::read_csv)
  
  cases <- mem_read(path) %>%
    #Quitar acentos en los nombres de los estados
    dplyr::mutate(Region=stringi::stri_trans_general(str = Region, id = "Latin-ASCII")) %>%
    
    #Se les olvido lo de CDMX
    #dplyr::mutate(Region = ifelse(Region == "DISTRITO FEDERAL" , "CIUDAD DE MEXICO", Region)) %>%
    
    # Usamos Date_Confirmed, nuev formato
    dplyr::mutate(date=as.Date(Date_Confirmed, format = "%d-%m-%Y")) %>%
    
    #Fix de MDY para pendientes de 14-04, 15-04 y 16-04
    #dplyr::mutate(date2 = as.Date.numeric(
    #  ifelse( is.na(date), 
    #          as.Date(Date_Confirmed, format = "%m-%d-%Y"), date ),
    #  origin="1970-01-01")) %>%
    #dplyr::mutate(date = date2 ) %>%
    
    #Crear columna local o importado
    dplyr::mutate(import_status = ifelse(Origin == "Local" , "local", "imported")) %>%
    dplyr::group_by(Region, import_status, date) %>%
    
    ## Sumar los casos individuales para obtener los nuevos casos del día por región
    ## Si hubiera recuperados del dia, aqui hay que quitarlos
    dplyr::summarize(day_cases = n()) %>% 
    
    #Limpieza final
    filter(!is.na(Region) & Region != "Region" ) %>%
    
    dplyr::select(date, Region, import_status, day_cases) %>%
    dplyr::group_by(Region, import_status) %>%
    dplyr::rename(cases = day_cases)
  #dplyr::mutate(cases = cumsum(day_cases))
  
  return(cases)
}

# Get cases ---------------------------------------------------------------

NCoVUtils::reset_cache()

# Opcion directo desde archivo subido
# Se quita el primer registro porque sale negativo por el shift
cases <- readr::read_csv('/home/covid/casos_130520.txt') %>% 
  dplyr::filter( cases > 0 )

#cases <- get_mexico_regional_cases() %>% 
#  dplyr::filter(import_status  == "local") %>%
#  dplyr::rename(region = Region)

#cases %>% View()

# Region codes para el mapita
#region_codes <- cases %>%
#  dplyr::select(region, region_code = fips) %>%
#  unique()

#saveRDS(region_codes, "united-states/data/region_codes.rds")

# Get linelist ------------------------------------------------------------

get_international_linelist_custom <- function(countries = NULL, cities = NULL, provinces = NULL, clean = TRUE) {
  
  country <- NULL; city <- NULL; travel_history_location <- NULL;
  travel_history_dates <- NULL; date_confirmation <- NULL;
  date_onset_symptoms <- NULL; date_confirm <- NULL;
  date_onset <- NULL; report_delay <- NULL; import_status <- NULL;
  
  message("Downloading linelist data")
  
  
  ch <- memoise::cache_filesystem(".cache")
  
  url <- "https://raw.githubusercontent.com/beoutbreakprepared/nCoV2019/master/latest_data/latestdata.csv"
  
  mem_read <- memoise::memoise(readr::read_csv, cache = ch)
  linelist <- suppressWarnings(
    suppressMessages(
      try(R.utils::withTimeout(mem_read(url) %>%
                                 tibble::as_tibble(), timeout = 15, onTimeout = "error"),
          silent = TRUE)
    )
  )
  
  if (any(class(linelist) %in% "try-error")) {
    warning("Could not access linelist source. Using the NCoVUtils cache, this may not be up to date.
    See the git history to confirm last cache date.")
    
    url <- "https://raw.githubusercontent.com/epiforecasts/NCoVUtils/master/data-raw/linelist.csv"
    
    linelist <- suppressWarnings(
      suppressMessages(
        mem_read(url) %>%
          tibble::as_tibble()
      )
    )
  }
  
  if (!is.null(countries)) {
    linelist <- linelist %>%
      dplyr::filter(country %in% countries)
  }
  
  if (!is.null(cities)) {
    linelist <- linelist %>%
      dplyr::filter(city %in% cities)
  }
  
  if (!is.null(provinces)) {
    linelist <- linelist %>%
      dplyr::filter(province %in% provinces)
  }
  
  if (clean) {
    linelist <- linelist %>%
      dplyr::mutate(travel_history_location = ifelse(travel_history_location %in% "", NA, travel_history_location),
                    travel_history_dates = ifelse(travel_history_dates %in% "", NA, travel_history_dates)) %>%
      
      dplyr::mutate(import_status =
            
                    dplyr::if_else(!is.na(travel_history_location) | !is.na(travel_history_dates), "imported", "local"),
                    date_confirm = lubridate::dmy(date_confirmation),
                    date_onset = lubridate::dmy(date_onset_symptoms),
                    report_delay =
                      as.integer(as.Date(date_confirm) - as.Date(date_onset))) %>%
      
      dplyr::select(date_onset, date_confirm, report_delay, import_status, country) %>%
      tidyr::drop_na(date_confirm)
    
  }
  
  return(linelist)
  
}

## Version custom arreglada por 
#print("Custom international linelist... ")
#linelist <- get_international_linelist_custom(clean=TRUE)
#print("DONE")

#saveRDS(linelist,'')
#saveRDS(linelist, file = "/home/covid/my_linelist.rds")

print("Linelist procesada previamente...")
linelist <- readRDS("/home/covid/my_linelist.rds")
print("DONE Reading RDS")

#ll2 %>% View()


# Set up cores -----------------------------------------------------

if (!interactive()){
  print("Future.fork, enable=TRUE")
  options(future.fork.enable = TRUE)
}

future::plan("multiprocess", workers = future::availableCores())

data.table::setDTthreads(threads = 1)


# Run pipeline ----------------------------------------------------

EpiNow::regional_rt_pipeline(
  cases = cases,
  linelist = linelist,
  regional_delay = FALSE,
  target_folder = "mexico/regional",
  case_limit = 10,
  verbose = TRUE,

  horizon = 14,
  approx_delay = TRUE,
  report_forecast = TRUE,
  forecast_model = function(...) {
    EpiSoon::fable_model(model = fabletools::combination_model(fable::RW(y ~ drift()), fable::ETS(y), 
                                                               fable::NAIVE(y),
                                                               cmbn_args = list(weights = "inv_var")), ...)
  }
  
)

## Cambio merge_onsets a FALSE
#' @param linelist A dataframe of of cases (by row) containing the following variables:
#' `import_status` (values "local" and "imported"), `date_onset`, `date_confirm`, `report_delay`, and `region`. If a national linelist is not available a proxy linelist may be 
#' used but in this case `merge_onsets` should be set to `FALSE`.



# Summarise results -------------------------------------------------------

EpiNow::regional_summary(results_dir = "mexico/regional",
                         summary_dir = "mexico/regional-summary",
                         target_date = "latest",
                         region_scale = "State"
)
