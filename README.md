# Diabetes Risk Predictor

A minimal full-stack demo:
- **Backend**: FastAPI + XGBoost (trained on the Pima Indians Diabetes dataset)
- **Frontend**: Flutter (single form screen, calls the backend over HTTP)

```
diabetes_app/
├── backend/
│   ├── diabetes_raw.csv         # dataset (auto-downloaded)
│   ├── train_model.py           # trains XGBoost model, saves .joblib files
│   ├── main.py                  # FastAPI app (the API server)
│   ├── requirements.txt
│   ├── diabetes_model.joblib    # generated after training
│   └── scaler.joblib            # generated after training
└── frontend/
    └── diabetes_predictor/      # Flutter app
        ├── pubspec.yaml
        └── lib/
            ├── main.dart
            └── prediction_service.dart
```

## 1. Backend setup

```bash
cd backend
pip install -r requirements.txt

# Train the model (only needed once — creates diabetes_model.joblib + scaler.joblib)
python train_model.py

# Start the API server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Test it's working:
```bash
curl http://127.0.0.1:8000/health
# {"status":"healthy","model_loaded":true}

curl -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "pregnancies": 2, "glucose": 130, "blood_pressure": 80,
    "skin_thickness": 25, "insulin": 100, "bmi": 28.5,
    "diabetes_pedigree_function": 0.5, "age": 35
  }'
# {"prediction":1,"probability":0.71...,"risk_level":"Moderate"}
```

Interactive API docs are auto-generated at: **http://127.0.0.1:8000/docs**

## 2. Frontend setup

```bash
cd frontend/diabetes_predictor
flutter pub get
```

### Important: set the right backend URL

In `lib/prediction_service.dart`, update `baseUrl` depending on where you run the app:

| Target                          | baseUrl                          |
|----------------------------------|-----------------------------------|
| Flutter Web (Chrome) on same PC | `http://127.0.0.1:8000`          |
| Android Emulator                 | `http://10.0.2.2:8000`           |
| iOS Simulator                    | `http://127.0.0.1:8000`          |
| Physical phone (same Wi-Fi)      | `http://<your-computer-LAN-ip>:8000` (run backend with `--host 0.0.0.0`) |

### Run it

Easiest for a quick demo — run as a web app:
```bash
flutter run -d chrome
```

Or on a connected device/emulator:
```bash
flutter run
```

## How it works

1. User fills in 8 health metrics (Pregnancies, Glucose, Blood Pressure, Skin Thickness, Insulin, BMI, Diabetes Pedigree Function, Age) in the Flutter form.
2. Flutter sends a `POST /predict` request as JSON to the FastAPI backend.
3. FastAPI scales the inputs with the saved `StandardScaler` and feeds them into the trained `XGBClassifier`.
4. The API returns `prediction` (0/1), `probability`, and a human-readable `risk_level` (Low / Moderate / High).
5. The Flutter UI displays a color-coded result card.

## Notes

- This is a **demo model** trained on a small public dataset (768 records) — not for real medical use.
- CORS is wide open (`allow_origins=["*"]`) for ease of local development. Restrict this before deploying anywhere public.
- The model achieves ~75% test accuracy, which is in line with published results for this classic dataset.
