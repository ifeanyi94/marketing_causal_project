import pandas as pd
import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset
import joblib
import boto3
from sklearn.preprocessing import MinMaxScaler

# Load data
X = pd.read_csv("r_models/output/surrogate_train_data.csv")[['received_campaign', 'spend']]
y = pd.read_csv("r_models/output/surrogate_labels.csv")['predicted_spend']

# Normalize 'spend' to [0, 1]
scaler = MinMaxScaler()
X['spend'] = scaler.fit_transform(X[['spend']])

# Save the scaler for later use in inference
joblib.dump(scaler, "python_models/spend_scaler.pkl")

# Prepare tensors
X_tensor = torch.tensor(X.values, dtype=torch.float32)
y_tensor = torch.tensor(y.values, dtype=torch.float32).unsqueeze(1)

dataset = TensorDataset(X_tensor, y_tensor)
loader = DataLoader(dataset, batch_size=32, shuffle=True)

# Define model


model = SimpleNN()
loss_fn = nn.MSELoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.01)

# Train loop
for epoch in range(100):
    for xb, yb in loader:
        pred = model(xb)
        loss = loss_fn(pred, yb)
        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

# Save model and feature names
torch.save(model.state_dict(), "python_models/surrogate_nn.pth")
joblib.dump(X.columns.tolist(), "python_models/feature_columns.pkl")

# Upload to S3
s3 = boto3.client('s3')
s3.upload_file("python_models/surrogate_nn.pth", "marketing-causal-data", "models/surrogate_nn.pth")
s3.upload_file("python_models/feature_columns.pkl", "marketing-causal-data", "models/feature_columns.pkl")
s3.upload_file("python_models/spend_scaler.pkl", "marketing-causal-data", "models/spend_scaler.pkl")
