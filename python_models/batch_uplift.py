import torch
import joblib
import pandas as pd
from python_models.surrogate_model import SimpleNN

# Load model
model = SimpleNN()
model.load_state_dict(torch.load("python_models/surrogate_nn.pth"))
model.eval()

# Load feature names
feature_columns = joblib.load("python_models/feature_columns.pkl")

# Load scaler
scaler = joblib.load("python_models/spend_scaler.pkl")

# Create dummy users with past spending
users = pd.DataFrame({
    "user_id": [1, 2, 3, 4, 5],
    "spend": [118, 36, 74, 226, 389]
})

# Normalize 'spend'
users['spend'] = scaler.transform(users[['spend']])

# Predict for each user: campaign=1 and campaign=0
predictions = []

for _, row in users.iterrows():
    past_spending = row["spend"]

    # Prediction if campaign is sent
    x_treated = torch.tensor([[1, past_spending]], dtype=torch.float32)
    with torch.no_grad():
        pred_treated = model(x_treated).item()

    # Prediction if campaign is not sent
    x_control = torch.tensor([[0, past_spending]], dtype=torch.float32)
    with torch.no_grad():
        pred_control = model(x_control).item()

    uplift = pred_treated - pred_control

    predictions.append({
        "user_id": row["user_id"],
        "predicted_spend_treated": pred_treated,
        "predicted_spend_control": pred_control,
        "uplift": uplift
    })

# Save results
results = pd.DataFrame(predictions)
results.to_csv("python_models/uplift_predictions.csv", index=False)

print(results)
print(model.net[0].weight)
print(model.net[0].bias)

# File summary: this file loads the trained ML model (SimpleNN) and scaler, which normalizes past spending data, and predicts future spending under two scenarios: with and without a campaign. The results are saved to a CSV file (uplift_predictions.csv).

