import joblib

model = joblib.load("model.pkl")

def predict(data):

    features = [[
        data["throughput"],
        data["sinr"],
        data["prb"]
    ]]

    prediction = model.predict(features)

    return {
        "beam": int(prediction[0])
    }
