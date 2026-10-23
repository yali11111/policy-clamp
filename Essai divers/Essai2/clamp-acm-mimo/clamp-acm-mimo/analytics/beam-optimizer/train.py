import pandas as pd
from sklearn.ensemble import RandomForestClassifier
import joblib

dataset = pd.read_csv("dataset.csv")

X = dataset[
    ["throughput", "sinr", "prb"]
]

y = dataset["beam"]

model = RandomForestClassifier()

model.fit(X, y)

joblib.dump(model, "model.pkl")

print("Model saved.")
