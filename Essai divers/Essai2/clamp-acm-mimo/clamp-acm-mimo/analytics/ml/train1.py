import pandas as pd
import joblib

from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# Exemple de données
data = {
    "throughput": [500, 480, 550, 600, 430, 520, 580, 460],
    "sinr":       [22, 18, 25, 28, 15, 23, 27, 17],
    "prb":        [65, 82, 60, 55, 90, 70, 58, 88],
    "beam":       [12, 8, 14, 15, 5, 13, 16, 7]
}

df = pd.DataFrame(data)

X = df[["throughput", "sinr", "prb"]]
y = df["beam"]

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42
)

model = RandomForestClassifier(
    n_estimators=100,
    random_state=42
)

model.fit(X_train, y_train)

prediction = model.predict(X_test)

print("Accuracy :", accuracy_score(y_test, prediction))

joblib.dump(model, "model1.pkl")

print("Model saved as model1.pkl")
