# Packages -----------------------------------------------------------------
# Nuevas deps de:
# https://github.com/epiforecasts/covid-global/blob/master/update_nowcasts.R


require(EpiNow, quietly = TRUE)
require(NCoVUtils, quietly = TRUE)
require(furrr, quietly = TRUE)
require(future, quietly = TRUE)
require(dplyr, quietly = TRUE)
require(tidyr, quietly = TRUE)
require(magrittr, quietly = TRUE)
require(forecastHybrid, quietly = TRUE)

#require(data.table, quietly = TRUE) 
#require(future, quietly = TRUE)
#require(forecastHybrid, quietly = TRUE)
#require(EpiNow, quietly = TRUE)
#require(NCoVUtils, quietly = TRUE)
#require(dplyr, quietly = TRUE)
#require(tidyr, quietly = TRUE)
## Required for forecasting
# require(forecastHybrid, quietly = TRUE)
# OLD DEPS
#require(EpiNow, quietly = TRUE)
#require(NCoVUtils, quietly = TRUE)
#require(furrr, quietly = TRUE)
#require(future, quietly = TRUE)
#require(magrittr, quietly = TRUE)
#require(future.apply, quietly = TRUE)
#require(fable, quietly = TRUE)
#require(fabletools, quietly = TRUE)
#require(feasts, quietly = TRUE)
#require(urca, quietly = TRUE)


# Get cases ---------------------------------------------------------------

NCoVUtils::reset_cache()

#Update con archivo de Wallace

cases <- readr::read_csv('/home/covid/casos_240720.txt') %>%
  dplyr::rename( confirm = cases ) %>%
  dplyr::filter(region == 'SONORA' | region == "VERACRUZ" | region == "JALISCO") %>%
  dplyr::filter( confirm > 0 ) 
  

#cases %>% View()


delay_defs <- readRDS("delays.rds")

# Set up cores -----------------------------------------------------
if (!interactive()){
  options(future.fork.enable = TRUE)
}

future::plan("multiprocess", workers = round(future::availableCores() / 3))

# Run pipeline ----------------------------------------------------

EpiNow::regional_rt_pipeline(
  cases = cases,
  delay_defs = delay_defs,
  target_folder = "mexico/regional",
  horizon = 14,
  nowcast_lag = 10,
  approx_delay = TRUE,
  report_forecast = TRUE,
  verbose = TRUE,
  forecast_model = function(y, ...){EpiSoon::forecastHybrid_model(
    y = y[max(1, length(y) - 21):length(y)],
    model_params = list(models = "aefz", weights = "equal"),
    forecast_params = list(PI.combination = "mean"), ...)}
)


# Summarise results -------------------------------------------------------

EpiNow::regional_summary(results_dir = "mexico/regional",
                         summary_dir = "mexico/regional-summary",
                         target_date = "latest",
                         region_scale = "State"
)
