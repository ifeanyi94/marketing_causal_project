# r_models/dependencies.R

install_if_missing <- function(pkgs) {
  for (pkg in pkgs) {
    if (!require(pkg, character.only = TRUE)) {
      install.packages(pkg, dependencies = TRUE)
      library(pkg, character.only = TRUE)
    }
  }
}

required_packages <- c("aws.s3", "CausalImpact", "brms", "survival", "ggplot2", "readr", "dplyr", "lubridate")
install_if_missing(required_packages)

# AWS S3 setup - Load from environment variables (stored in ~/.Renviron or globally)
# Do NOT hardcode secrets!
Sys.setenv(
  AWS_ACCESS_KEY_ID = Sys.getenv("AWS_ACCESS_KEY_ID"),
  AWS_SECRET_ACCESS_KEY = Sys.getenv("AWS_SECRET_ACCESS_KEY"),
  AWS_DEFAULT_REGION = Sys.getenv("AWS_DEFAULT_REGION")
)