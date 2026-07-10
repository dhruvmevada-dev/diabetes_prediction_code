"""
Trains an XGBoost classifier on the Pima Indians Diabetes dataset
and saves the model + scaler to disk for the FastAPI app to load.

Run once: python train_model.py
"""
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report
import xgboost as xgb
import joblib

COLUMNS = [
    "Pregnancies", "Glucose", "BloodPressure", "SkinThickness",
    "Insulin", "BMI", "DiabetesPedigreeFunction", "Age", "Outcome"
]

def main():
    df = pd.read_csv("diabetes.csv", header=0, names=COLUMNS)

    # Some columns use 0 as a placeholder for "missing" in this dataset.
    # Replace those zeros with the column median (0 is biologically impossible
    # for these fields, except Pregnancies).
    zero_as_missing = ["Glucose", "BloodPressure", "SkinThickness", "Insulin", "BMI"]
    for col in zero_as_missing:
        median_val = df.loc[df[col] != 0, col].median()
        df[col] = df[col].replace(0, median_val)

    X = df[COLUMNS[:-1]]
    y = df["Outcome"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    model = xgb.XGBClassifier(
        n_estimators=200,
        max_depth=4,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        eval_metric="logloss",
        random_state=42,
    )
    model.fit(X_train_scaled, y_train)

    preds = model.predict(X_test_scaled)
    acc = accuracy_score(y_test, preds)
    print(f"Test accuracy: {acc:.3f}")
    print(classification_report(y_test, preds))

    joblib.dump(model, "diabetes_model.joblib")
    joblib.dump(scaler, "scaler.joblib")
    print("Saved diabetes_model.joblib and scaler.joblib")

if __name__ == "__main__":
    main()
