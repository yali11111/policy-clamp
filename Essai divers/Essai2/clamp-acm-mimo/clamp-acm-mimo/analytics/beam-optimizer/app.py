from fastapi import FastAPI
from inference import predict

app = FastAPI()

@app.post("/predict")
def prediction(data: dict):
    return predict(data)
