"""
FastAPI backend for the Diabetes Prediction app.

Run with:
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Make sure diabetes_model.joblib and scaler.joblib exist
(run `python train_model.py` first if not).
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import numpy as np
import joblib
import os

MODEL_PATH = "diabetes_model.joblib"
SCALER_PATH = "scaler.joblib"

app = FastAPI(title="Diabetes Prediction API", version="1.0.0")

# Allow the Flutter app (web/mobile/desktop) to call this API from any origin.
# For a real production app, restrict allow_origins to your actual frontend domain.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = None
scaler = None


@app.on_event("startup")
def load_artifacts():
    global model, scaler
    if not os.path.exists(MODEL_PATH) or not os.path.exists(SCALER_PATH):
        raise RuntimeError(
            "Model files not found. Run `python train_model.py` first."
        )
    model = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)


class PatientData(BaseModel):
    pregnancies: float = Field(..., ge=0, description="Number of pregnancies")
    glucose: float = Field(..., ge=0, description="Plasma glucose concentration")
    blood_pressure: float = Field(..., ge=0, description="Diastolic blood pressure (mm Hg)")
    skin_thickness: float = Field(..., ge=0, description="Triceps skin fold thickness (mm)")
    insulin: float = Field(..., ge=0, description="2-Hour serum insulin (mu U/ml)")
    bmi: float = Field(..., ge=0, description="Body mass index")
    diabetes_pedigree_function: float = Field(..., ge=0, description="Diabetes pedigree function")
    age: float = Field(..., ge=0, description="Age in years")

    class Config:
        json_schema_extra = {
            "example": {
                "pregnancies": 2,
                "glucose": 130,
                "blood_pressure": 80,
                "skin_thickness": 25,
                "insulin": 100,
                "bmi": 28.5,
                "diabetes_pedigree_function": 0.5,
                "age": 35,
            }
        }


class PredictionResponse(BaseModel):
    prediction: int  # 0 = no diabetes, 1 = diabetes
    probability: float  # probability of class 1 (diabetes)
    risk_level: str


@app.get("/")
def root():
    return {"status": "ok", "message": "Diabetes Prediction API is running"}


@app.get("/health")
def health_check():
    return {"status": "healthy", "model_loaded": model is not None}


@app.post("/predict", response_model=PredictionResponse)
def predict(data: PatientData):
    if model is None or scaler is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    features = np.array([[
        data.pregnancies,
        data.glucose,
        data.blood_pressure,
        data.skin_thickness,
        data.insulin,
        data.bmi,
        data.diabetes_pedigree_function,
        data.age,
    ]])

    features_scaled = scaler.transform(features)

    pred = int(model.predict(features_scaled)[0])
    proba = float(model.predict_proba(features_scaled)[0][1])

    if proba < 0.3:
        risk_level = "Low"
    elif proba < 0.6:
        risk_level = "Moderate"
    else:
        risk_level = "High"

    return PredictionResponse(
        prediction=pred,
        probability=round(proba, 4),
        risk_level=risk_level,
    )
