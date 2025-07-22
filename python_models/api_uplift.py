# Import libraries
import torch
import joblib
from fastapi import FastAPI
from pydantic import BaseModel
from python_models.surrogate_model import SimpleNN
import subprocess
from fastapi.responses import FileResponse


# Load the trained surrogate model (SimpleNN is defined in surrogate_model.py)
model = SimpleNN()
model.load_state_dict(torch.load("python_models/surrogate_nn.pth")) 
model.eval()  # Set the model to evaluation mode (no gradients)

# Load the same scaler used during training to normalize 'spend'
scaler = joblib.load("python_models/spend_scaler.pkl")

# Create FastAPI app
app = FastAPI(title="Uplift Model API")

# ---------------------------
# Define INPUT schema:
# ---------------------------
class UserFeatures(BaseModel):
    user_id: int    # Customer ID (for tracking)
    spend: float    # This is the customer's **PAST spending** before the campaign

# ---------------------------
# Define OUTPUT schema:
# ---------------------------
class UpliftPrediction(BaseModel):
    user_id: int
    predicted_spend_treated: float   # Model's estimate of FUTURE spend if campaign is sent
    predicted_spend_control: float   # Model's estimate of FUTURE spend if campaign is NOT sent
    uplift: float                    # Difference between treated and control (causal effect)

# ---------------------------
# Define the API endpoint:
# ---------------------------
@app.post("/predict_uplift", response_model=UpliftPrediction)
def predict_uplift(user: UserFeatures):
    """
    Given a user's past spending, predict the future spend under:
    - Treatment (campaign sent)
    - Control (no campaign sent)
    """

    # Normalize the user's past spend using the same scaler as in training
    # This ensures the model input is in the [0,1] range
    scaled_spend = scaler.transform([[user.spend]])[0][0]

    # Prepare model inputs for both scenarios:
    # Scenario 1: Campaign sent (received_campaign=1)
    x_treated = torch.tensor([[1, scaled_spend]], dtype=torch.float32)

    # Scenario 2: Campaign not sent (received_campaign=0)
    x_control = torch.tensor([[0, scaled_spend]], dtype=torch.float32)

    # Run model inference for both
    with torch.no_grad():  # Disable gradient tracking (faster and safer for inference)
        pred_treated = model(x_treated).item()
        pred_control = model(x_control).item()

    # Calculate uplift = effect of the campaign
    uplift = pred_treated - pred_control

    # Return structured response
    return UpliftPrediction(
        user_id=user.user_id,
        predicted_spend_treated=pred_treated,
        predicted_spend_control=pred_control,
        uplift=uplift
    )

@app.get("/causal_impact_summary")
def get_causal_impact_summary():
    subprocess.run(["Rscript", "r_models/causal_inference.R"], check=True)
    return FileResponse("r_models/output/causal_impact_summary.txt")

@app.get("/survival_plot")
def get_survival_plot():
    subprocess.run(["Rscript", "r_models/survival_model.R"], check=True)
    # return FileResponse("r_models/output/survival_plot.pdf", media_type="application/pdf")
    return FileResponse("dashboard/www/survival_plot.png", media_type="image/png")

# api_uplift.py is a FastAPI service.  Run the FastAPI app using: uvicorn api_uplift:app --reload
# This command starts the server and allows you to test the API at http://http://127.0.0.1:8000/docs
# This components loads the trained ML model (Neural Net [ SimpleNN]) to analyse predicted spend.
# The API accepts past spend and returns predicted spending (if the user receives the campaign or not)
#Def Model weights: Numeric parameters that are learned while training the model. Weights are stored in the models state_dicionary.
#Def serialization: A data structure (such as ML models state_dict) that has been converted to a format that can be transfered over nextworks or stored in files.import subprocess
from fastapi.responses import FileResponse