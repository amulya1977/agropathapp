import pickle
import numpy as np
import pandas as pd
import httpx
import asyncio  # <-- Added this import
from fastapi import APIRouter, HTTPException
import models

router = APIRouter(tags=['Prediction'])
WEATHER_API_KEY = "d9c25f037b42454a7940d18aaec416ac"  # Your key

# --- Load ML Model and Data on Startup ---
try:
    with open('crop_model.pkl', 'rb') as model_file:
        model = pickle.load(model_file)
    soil_df = pd.read_csv('soil_data.csv')
    print("✅ Model and soil data loaded successfully.")
except FileNotFoundError:
    model, soil_df = None, None
    print("⚠️ FATAL ERROR: 'crop_model.pkl' or 'soil_data.csv' not found.")
except Exception as e:
    model, soil_df = None, None
    print(f"⚠️ FATAL WARNING: Could not load model/data: {e}")

def normalize_district(name: str) -> str:
    """Cleans and standardizes the district name."""
    name = str(name).lower().replace(" division", "").strip()
    mapping = {"allahabad": "prayagraj"}
    return mapping.get(name, name)

@router.post("/predict_from_location")
async def predict_from_location(location_data: models.LocationData):
    if model is None or soil_df is None:
        raise HTTPException(status_code=503, detail="Server model is not configured.")

    lat, lon = location_data.latitude, location_data.longitude
    district_from_app = normalize_district(location_data.district)
    print(f"Request for: Lat={lat}, Lon={lon}, District='{district_from_app}'")

    # Use a single client session for all API calls for efficiency
    async with httpx.AsyncClient() as client:
        # --- Fetch Weather Data (with Fallback) ---
        try:
            weather_url = f"http://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={WEATHER_API_KEY}&units=metric"
            weather_response = await client.get(weather_url, timeout=30.0)
            weather_response.raise_for_status()
            weather_res = weather_response.json()
            temperature, humidity = weather_res['main']['temp'], weather_res['main']['humidity']
            rainfall = weather_res.get('rain', {}).get('1h', 100)
        except Exception as e:
            print(f"--- WEATHER API FAILED, USING DEFAULTS ---\nError: {e}")
            temperature, humidity, rainfall = 28.0, 60.0, 100.0

        # --- Fetch Soil Data (with separate calls for each property) ---
        try:
            # 1. Define URLs for each property separately
            nitrogen_url = f"https://rest.isric.org/soilgrids/v2.0/properties/query?lon={lon}&lat={lat}&property=nitrogen&depth=0-5cm&value=mean"
            ph_url = f"https://rest.isric.org/soilgrids/v2.0/properties/query?lon={lon}&lat={lat}&property=phh2o&depth=0-5cm&value=mean"

            # 2. Make two separate, asynchronous requests concurrently
            nitrogen_response_task = client.get(nitrogen_url, timeout=60.0)
            ph_response_task = client.get(ph_url, timeout=60.0)

            nitrogen_response, ph_response = await asyncio.gather(
                nitrogen_response_task,
                ph_response_task
            )

            # 3. Check both responses for errors
            nitrogen_response.raise_for_status()
            ph_response.raise_for_status()
            nitrogen_res = nitrogen_response.json()
            ph_res = ph_response.json()

            # Helper function to parse the soil property from a response
            def get_soil_property(response, prop_name, default_value):
                try:
                    mean_value = response["properties"]["layers"][0]["depths"][0]["values"]["mean"]
                    return mean_value if mean_value is not None else default_value
                except (KeyError, IndexError, TypeError):
                    print(f"⚠️ Could not parse '{prop_name}'. Using default.")
                    return default_value

            # 5. Extract values and perform calculations
            n_val = get_soil_property(nitrogen_res, 'nitrogen', 7)
            ph_val = get_soil_property(ph_res, 'phh2o', 70)
            n = float(n_val) * 2.24  # Unit conversion
            ph = float(ph_val) / 10.0 # Unit conversion
            print("✅ --- SoilGrids API Success ---")
            print(f"Fetched values: Nitrogen={round(n, 2)} kg/ha, pH={round(ph, 2)}")

        except httpx.HTTPStatusError as e:
            print(f"--- SOILGRIDS API FAILED (HTTP Error) ---\nError: {e}\nResponse: {e.response.text}")
            n, ph = 40.0, 7.0
        except Exception as e:
            print(f"--- SOILGRIDS API FAILED (General Error), USING DEFAULTS ---\nError: {e}")
            n, ph = 40.0, 7.0

    # --- Look up local P and K data from CSV ---
    found_rows = soil_df[soil_df["DISTRICT"].str.lower() == district_from_app]
    if found_rows.empty:
        raise HTTPException(status_code=404, detail=f"Your district ('{location_data.district}') is not in our local soil database.")
    p, k = float(found_rows.iloc[0]['P']), float(found_rows.iloc[0]['K'])

    # --- Final Prediction (Get Top 3 Crops) ---
    feature_names = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall']
    prediction_data = pd.DataFrame([[n, p, k, temperature, humidity, ph, rainfall]], columns=feature_names)

    # Use predict_proba to get the probabilities for all crops
    probabilities = model.predict_proba(prediction_data)[0]

    # Get the indices of the top 3 probabilities in descending order
    top_3_indices = np.argsort(probabilities)[-3:][::-1]

    # Map these indices to the actual crop names
    top_3_crops = [model.classes_[i] for i in top_3_indices]

    # --- Return the final response ---
    return {
        "temperature": round(temperature, 2),
        "humidity": round(humidity, 2),
        "rainfall": round(rainfall, 2),
        "nitrogen": round(n, 2),
        "phosphorus": round(p, 2),
        "potassium": round(k, 2),
        "ph": round(ph, 2),
        "recommended_crops": top_3_crops  # Changed to return the list of 3 crops
    }