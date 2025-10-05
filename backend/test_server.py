# test_weather.py
import requests

# --- Use the same key as your main app ---
WEATHER_API_KEY = "d9c25f037b42454a7940d18aaec416ac"
lat = 25.4358  # Prayagraj
lon = 81.8463

url = f"http://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={WEATHER_API_KEY}&units=metric"

print(f"Attempting to call API at:\n{url}\n")

try:
    # We will wait up to 20 seconds for a response
    response = requests.get(url, timeout=20)

    print(f"Status Code: {response.status_code}")
    print("\n--- API RESPONSE ---")
    print(response.json())
    print("--------------------")

except requests.exceptions.Timeout:
    print("\n--- ERROR ---")
    print("The request timed out. This is likely the problem in your main app.")
    print("--------------------")

except Exception as e:
    print(f"\n--- AN ERROR OCCURRED ---\n{e}\n--------------------")