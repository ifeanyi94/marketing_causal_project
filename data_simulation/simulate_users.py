import pandas as pd
import numpy as np
import boto3
from io import StringIO

def simulate_data(n_users=1000, seed=42):
    np.random.seed(seed)
    users = pd.DataFrame({
        "user_id": np.arange(n_users),
        "signup_date": pd.to_datetime("2022-01-01") + pd.to_timedelta(np.random.randint(0, 365, n_users), unit="d"),
        "received_campaign": np.random.binomial(1, 0.5, n_users),
    })
    users["spend"] = np.random.gamma(2, 50, n_users) + 200 * users["received_campaign"]
    users["churn_days"] = np.random.exponential(30, n_users).astype(int)
    return users

def upload_to_s3(df, bucket, key):
    csv_buffer = StringIO()
    df.to_csv(csv_buffer, index=False)
    s3 = boto3.client('s3')
    s3.put_object(Bucket=bucket, Key=key, Body=csv_buffer.getvalue())

if __name__ == "__main__":
    df = simulate_data()
    upload_to_s3(df, "marketing-causal-data", "raw/simulated_users.csv")
