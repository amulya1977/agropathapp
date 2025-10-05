import httpx
import asyncio
import pandas as pd

WEATHER_API_KEY = "d9c25f037b42454a7940d18aaec416ac" # Your key

async def get_measured_nutrients_from_location(lat: float, lon: float, district: str) -> dict:
    """
    Fetches weather and soil data from external APIs and local CSV.
    This is the refactored logic from your original recommendation router.
    Returns a dictionary of measured nutrient and climate values.
    """
    # Use a single client session for efficiency
    async with httpx.AsyncClient() as client:
        # --- Fetch Weather Data (with Fallback) ---
        try:
            weather_url = f"http://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={WEATHER_API_KEY}&units=metric"
            weather_res = (await client.get(weather_url, timeout=30.0)).json()
            temperature, humidity = weather_res['main']['temp'], weather_res['main']['humidity']
            rainfall = weather_res.get('rain', {}).get('1h', 100)
        except Exception:
            temperature, humidity, rainfall = 28.0, 60.0, 100.0

        # --- Fetch Soil N and pH from SoilGrids API ---
        try:
            nitrogen_url = f"https://rest.isric.org/soilgrids/v2.0/properties/query?lon={lon}&lat={lat}&property=nitrogen&depth=0-5cm&value=mean"
            ph_url = f"https://rest.isric.org/soilgrids/v2.0/properties/query?lon={lon}&lat={lat}&property=phh2o&depth=0-5cm&value=mean"

            n_task = client.get(nitrogen_url, timeout=60.0)
            ph_task = client.get(ph_url, timeout=60.0)
            n_res, ph_res = await asyncio.gather(n_task, ph_task)

            n_val = n_res.json()["properties"]["layers"][0]["depths"][0]["values"]["mean"]
            ph_val = ph_res.json()["properties"]["layers"][0]["depths"][0]["values"]["mean"]

            n = float(n_val) * 2.24  # Unit conversion
            ph = float(ph_val) / 10.0 # Unit conversion
        except Exception:
            n, ph = 40.0, 7.0

    # --- Look up local P and K data from CSV ---
    try:
        soil_df = pd.read_csv('data/soil_data.csv') # Assuming soil_data.csv is your local P and K source
        found_rows = soil_df[soil_df["DISTRICT"].str.lower() == district.lower()]
        p, k = float(found_rows.iloc[0]['P']), float(found_rows.iloc[0]['K'])
    except Exception:
        p, k = 45.0, 45.0 # Fallback values

    return {
        "N": n, "P": p, "K": k, "ph": ph,
        "temperature": temperature, "humidity": humidity, "rainfall": rainfall
    }
