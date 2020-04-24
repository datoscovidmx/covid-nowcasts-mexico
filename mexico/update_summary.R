
# Packages -----------------------------------------------------------------
require(EpiNow)
require(NCoVUtils)
require(furrr)
require(future)
require(dplyr)
require(tidyr)
require(magrittr)

# Summarise results -------------------------------------------------------

EpiNow::regional_summary(results_dir = "mexico/regional",
                         summary_dir = "mexico/regional-summary",
                         target_date = "latest",
                         region_scale = "State"
)

