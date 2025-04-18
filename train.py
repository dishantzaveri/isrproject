import pandas as pd
import pickle
from prophet import Prophet
import os

ticker = "AAPL"
csv_path = os.path.join("db", "NASDAQ", "market_data", f"{ticker}.csv")
df = pd.read_csv(csv_path)

df = df.rename(columns={"Date": "ds", "Close": "y"})
df['ds'] = pd.to_datetime(df['ds'], utc=True, errors='coerce').dt.tz_convert(None)

# Keep only valid rows
df = df[['ds', 'y']].dropna()

model = Prophet()
model.fit(df)

output_dir = os.path.join("db", "pickle")
os.makedirs(output_dir, exist_ok=True)

with open(os.path.join(output_dir, f"{ticker}.pkl"), "wb") as f:
    pickle.dump(model, f)

print(f" Prophet model trained and saved as {ticker}.pkl")
