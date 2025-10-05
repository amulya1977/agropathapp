import pandas as pd
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

# --- NEW: Import the helper function from your new location_services file ---
from .location_services import get_measured_nutrients_from_location

# --- Data and Rules (updated for clarity) ---
fertilizer_rules = {
  "N_low": "Your soil has a Nitrogen deficiency. For a quick boost, apply **Urea**. If your soil also needs Phosphorus, **DAP** is a good choice.",
  "N_high": "Your soil has a high level of Nitrogen. Avoid Nitrogen-rich fertilizers for now. Focus on Phosphorus and Potassium if they are deficient.",
  "P_low": "Your soil has a Phosphorus deficiency. Apply **DAP (Di-Ammonium Phosphate)** or **SSP (Single Super Phosphate)** as a basal dose before sowing.",
  "P_high": "Your soil has a high level of Phosphorus. Avoid phosphate fertilizers like DAP for this season to prevent nutrient imbalance.",
  "K_low": "Your soil has a Potassium deficiency. Apply **MOP (Muriate of Potash)** to improve plant strength and disease resistance.",
  "K_high": "Your soil has a high level of Potassium. You do not need to add Potassium-based fertilizers in this cycle."
}

# --- Router Setup (no change) ---
router = APIRouter(
    prefix="/recommend",
    tags=["Recommendations"]
)

# --- NEW Pydantic Model for combined location and crop input ---
class FertilizerFromLocationInput(BaseModel):
    latitude: float
    longitude: float
    district: str
    crop_name: str


# --- NEW, MORE ADVANCED API ENDPOINT ---
@router.post("/fertilizer_from_location")
async def recommend_fertilizer_from_location(payload: FertilizerFromLocationInput):
    """
    Takes location and crop name, fetches measured NPK, compares it to ideal NPK,
    and returns a fertilizer recommendation.
    """
    try:
        # 1. Get MEASURED nutrient values
        measured_nutrients = await get_measured_nutrients_from_location(
            payload.latitude, payload.longitude, payload.district
        )
        measured_N = measured_nutrients["N"]
        measured_P = measured_nutrients["P"]
        measured_K = measured_nutrients["K"]

        # 2. Get IDEAL nutrient values from CSV
        ideal_df = pd.read_csv("data/fertilizer_recommendations.csv")
        ideal_row = ideal_df[ideal_df["Crop"].str.lower() == payload.crop_name.lower()]

        if ideal_row.empty:
            raise HTTPException(
                status_code=404,
                detail=f"Ideal fertilizer data for '{payload.crop_name}' not found in our database."
            )

        required_N, required_P, required_K = ideal_row.iloc[0][['N', 'P', 'K']]

        # 3. Compute nutrient gaps
        delta_N = required_N - measured_N
        delta_P = required_P - measured_P
        delta_K = required_K - measured_K

        deficiencies = {"N": delta_N, "P": delta_P, "K": delta_K}
        actual_deficiencies = {k: v for k, v in deficiencies.items() if v > 0}

        if not actual_deficiencies:
            recommendation = "Your location's soil appears to have adequate nutrients for this crop. No fertilizer is recommended at this time."
        else:
            primary_nutrient = max(actual_deficiencies, key=actual_deficiencies.get)
            recommendation = fertilizer_rules.get(f"{primary_nutrient}_low", "A nutrient deficiency was found, but no specific recommendation is available.")

        # --- FIX: Convert all NumPy numbers to standard Python floats before returning ---
        return {
            "recommendation": recommendation,
            "measured_N": round(float(measured_N), 2),   # <-- CONVERTED
            "measured_P": round(float(measured_P), 2),   # <-- CONVERTED
            "measured_K": round(float(measured_K), 2),   # <-- CONVERTED
            "ideal_N": round(float(required_N), 2),      # <-- CONVERTED
            "ideal_P": round(float(required_P), 2),      # <-- CONVERTED
            "ideal_K": round(float(required_K), 2),      # <-- CONVERTED
        }

    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected server error occurred: {str(e)}")


# --- Your original endpoint (can be kept for testing or removed) ---
class FertilizerByCropInput(BaseModel):
    crop_name: str

@router.post("/fertilizer_by_crop")
def recommend_fertilizer_by_crop_endpoint(payload: FertilizerByCropInput):
    """
    Recommends fertilizer based only on the crop name by comparing typical vs ideal soil data.
    """
    # This endpoint remains unchanged and uses the simpler, non-location-based logic.
    try:
        crop_name = payload.crop_name.lower()
        measured_df = pd.read_csv("data/crop_recommendation.csv")
        ideal_df = pd.read_csv("data/fertilizer_recommendations.csv")

        measured_row = measured_df[measured_df["label"].str.lower() == crop_name]
        if measured_row.empty:
            return {"error": f"Typical soil data for crop '{payload.crop_name}' not found."}
        measured_N, measured_P, measured_K = measured_row.iloc[0][['N', 'P', 'K']]

        ideal_row = ideal_df[ideal_df["Crop"].str.lower() == crop_name]
        if ideal_row.empty:
            return {"error": f"Ideal fertilizer data for crop '{payload.crop_name}' not found."}
        required_N, required_P, required_K = ideal_row.iloc[0][['N', 'P', 'K']]

        delta_N, delta_P, delta_K = required_N - measured_N, required_P - measured_P, required_K - measured_K
        deficiencies = {"N": delta_N, "P": delta_P, "K": delta_K}
        actual_deficiencies = {k: v for k, v in deficiencies.items() if v > 0}

        if not actual_deficiencies:
            recommendation = "Typical soil conditions for this crop are adequate. No fertilizer application is recommended."
            return {"recommendation": recommendation}

        primary_nutrient = max(actual_deficiencies, key=actual_deficiencies.get)
        recommendation = fertilizer_rules.get(f"{primary_nutrient}_low", "No specific recommendation available.")

        return {"recommendation": recommendation}
    except Exception as e:
        return {"error": f"An error occurred on the server: {str(e)}"}

