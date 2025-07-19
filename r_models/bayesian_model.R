# Bayesian regression with brms
library(brms)
library(readr)

brm_model <- brm(spend ~ received_campaign, data = df, family = gaussian(), iter = 2000, chains = 4)
saveRDS(brm_model, file = "r_models/output/brm_model.rds")


# Export training data for surrogate model
write_csv(df, "r_models/output/surrogate_train_data.csv")

# Generate predictions from the Bayesian model
df$predicted_spend <- posterior_predict(brm_model) %>% apply(2, mean)

# Save the labels (for surrogate model training)
write_csv(df %>% select(user_id, received_campaign, predicted_spend, churn_days), 
          "r_models/output/surrogate_labels.csv")