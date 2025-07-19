# r_models/survival_model.R
source("r_models/dependencies.R")
library(readr)
library(survival)
library(ggplot2)

# Load data
obj <- aws.s3::get_object(
    object = "raw/simulated_users.csv",
    bucket = "marketing-causal-data",
    region = "us-east-1"
)
df <- read_csv(rawToChar(obj))

# Prepare survival object
df <- df %>% mutate(event = 1)  # assuming everyone eventually churned

surv_obj <- Surv(time = df$churn_days, event = df$event)

# Fit Kaplan-Meier curve by campaign
fit <- survfit(surv_obj ~ received_campaign, data = df)

# Save plot
png("r_models/output/survival_plot.png")
plot(fit, col = c("red", "blue"), lty = 1:2, main = "User Churn Survival by Campaign")
legend("bottomleft", legend = c("No Campaign", "Received Campaign"), col = c("red", "blue"), lty = 1:2)
dev.off()
file.copy("r_models/output/survival_plot.png", "dashboard/www/survival_plot.png", overwrite = TRUE)

# Optional: Cox model
cox <- coxph(surv_obj ~ received_campaign, data = df)
writeLines(capture.output(summary(cox)), "r_models/output/cox_summary.txt")
