Goal:
Predict individual-level causal uplift:

"How much more would a user spend if they receive the campaign vs if they don't?"

Workflow Overview
1️⃣ Causal Inference in R (Bayesian Modeling)
File: bayesian_model.R

Method: Bayesian regression or probabilistic modeling

Purpose: Generate counterfactual predictions for spend:

surrogate_labels.csv → Predicted spend (posterior means or medians)

surrogate_train_data.csv → Input features (e.g., campaign assignment, past spending, etc.)

This gives you the "ground truth" counterfactuals needed to train a surrogate model.

2️⃣ Surrogate Model Training in Python
File: surrogate_model.py

Model: SimpleNN()

Built with PyTorch

Structure:

makefile

Input: [received_campaign (0/1), past_spend (scaled)]
Layers: Linear → ReLU → Linear
Output: predicted_spend
Training Data:

surrogate_train_data.csv → Features

surrogate_labels.csv → Labels (predicted spend from Bayesian model)

Purpose:
Learn a fast, differentiable approximation of the Bayesian model
(Neural network replaces slow Bayesian inference for deployment)

Output:

surrogate_nn.pth → Saved model weights

feature_columns.pkl → Column order for consistency

spend_scaler.pkl → MinMaxScaler for spend normalization

3️⃣ Batch Scoring with the Surrogate Model
File: batch_uplift.py

Workflow:

Load SimpleNN() + weights

Normalize new user spend using spend_scaler.pkl

For each user:

Predict future spend with campaign (campaign=1)

Predict future spend without campaign (campaign=0)

Compute uplift = treated spend – control spend

Save predictions to uplift_predictions.csv

Why Use This Setup?
Step	Purpose
Bayesian Model (R)	Causal inference with uncertainty modeling
Surrogate NN (Python)	Fast real-time predictions, portable, deployable
Batch Scoring	Apply model to new users and compute individual uplift

Current Result Interpretation
The model is now more sensitive to past spending because of the correct scaling.

Weights show the model is learning more from both the campaign flag and the normalized spend.

Summary:
File	Role
bayesian_model.R	Create causal estimates (offline)
surrogate_model.py	Train neural net on causal estimates
batch_uplift.py	Score new users for uplift using neural net