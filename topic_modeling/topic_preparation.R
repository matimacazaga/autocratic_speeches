# ----------------------------------------------------------------------------------------------
# ---------------------------------------- Preparation -----------------------------------------
# ----------------------------------------------------------------------------------------------

# Install and load required packages
os <- Sys.info()[["sysname"]] # Get operating system information
itype <- ifelse(os == "Linux", "source", "binary") # Set corresponding installation type
packages_required <- c(
  "stringi", "tidyverse"
)
not_installed <- packages_required[!packages_required %in%
                                     installed.packages()[, "Package"]]
if (length(not_installed) > 0) {
  lapply(
    not_installed,
    install.packages,
    repos = "http://cran.us.r-project.org",
    dependencies = TRUE,
    type = itype
  )
}
lapply(packages_required, library, character.only = TRUE)

# set working directory (to folder where this code file is saved)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# ----------------------------------------------------------------------------------------------
# --------------------------------------- Prepare data ----------------------------------------- 
# ----------------------------------------------------------------------------------------------

# load data
df <- read_delim('../data/df.csv', delim = ',')
# inspect parsing problems
problems(df)

# plot histogram of tweets per year
hist(df %>% pull(Year))

