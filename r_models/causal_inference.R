# r_models/causal_inference.R
source("r_models/dependencies.R")
library(readr)
library(dplyr)
library(lubridate)

# Download data from S3
obj <- aws.s3::get_object(
    object = "raw/simulated_users.csv",
    bucket = "marketing-causal-data",
    region = "us-east-1"
)

df <- read_csv(rawToChar(obj))

# Clean and prepare time-series data
df <- df %>%
  mutate(date = signup_date) %>%
  group_by(date, received_campaign) %>%
  summarise(avg_spend = mean(spend), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = received_campaign, values_from = avg_spend, names_prefix = "group_") %>%
  arrange(date)

# Fill NA with interpolation (optional)
df <- df %>%
  mutate(group_0 = zoo::na.approx(group_0, na.rm = FALSE),
         group_1 = zoo::na.approx(group_1, na.rm = FALSE)) %>%
  na.omit()

# Fit CausalImpact
pre_period <- c(1, floor(nrow(df) * 0.5))
post_period <- c(pre_period[2] + 1, nrow(df))

ts_data <- cbind(df$group_1, df$group_0)
impact <- CausalImpact(ts_data, pre_period, post_period)

# Plot and save results
pdf("r_models/output/causal_impact_plot.pdf")
plot(impact)
dev.off()

writeLines(capture.output(summary(impact)), "r_models/output/causal_impact_summary.txt")

# Concept	Meaning
# group_0	The control group (users who did NOT get the campaign)
# group_1	The treatment group (users who DID get the campaign)
# Pre-period (time)	The time window before the campaign starts (first half of the time series) (contains group_0 and group_1)
# Post-period (time)	The time window after the campaign starts (second half of the time series) (contains group 1 only)