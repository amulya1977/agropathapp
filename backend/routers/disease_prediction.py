# routers/disease_prediction.py
import tensorflow as tf
import numpy as np
from fastapi import APIRouter, UploadFile, File, HTTPException
from PIL import Image
import io
import json

router = APIRouter(tags=['Disease Prediction'])

# --- 1. LOAD THE TRAINED MODEL, CLASS NAMES, AND CURES DATA ---
try:
    model = tf.keras.models.load_model('plant_disease_model.keras')

    with open('class_names.txt', 'r') as f:
        class_names = [line.strip() for line in f.readlines()]

    with open('remedies.json', 'r') as f:
        remedies = json.load(f)

    # --- TEMPORARY DEBUGGING STEP ---
    # This will print all the keys from your JSON file to the console.
    print("\n--- AVAILABLE REMEDY KEYS ---")
    print(list(remedies.keys()))
    print("-----------------------------\n")
    # --------------------------------

    print("✅ Disease model, class names, and remedies data loaded successfully.")

except FileNotFoundError:
    model, class_names, remedies = None, None, None
    print("⚠️ FATAL ERROR: A required file ('plant_disease_model.keras', 'class_names.txt', or 'remedies.json') was not found.")
except Exception as e:
    model, class_names, remedies = None, None, None
    print(f"⚠️ FATAL WARNING: Could not load disease model or data: {e}")


# --- 2. IMAGE PREPROCESSING FUNCTION (No changes here) ---
def preprocess_image(image_bytes: bytes):
    try:
        img = Image.open(io.BytesIO(image_bytes))
        img = img.resize((128, 128))
        img_array = tf.keras.preprocessing.image.img_to_array(img)
        img_array = tf.expand_dims(img_array, 0)
        return img_array
    except Exception as e:
        print(f"Error preprocessing image: {e}")
        return None


# --- 3. THE PREDICTION ENDPOINT ---
@router.post("/predict-disease")
async def predict_disease(file: UploadFile = File(...)):
    if model is None or class_names is None or remedies is None:
        raise HTTPException(status_code=503, detail="Server model is not configured. Check server logs.")

    image_bytes = await file.read()
    processed_image = preprocess_image(image_bytes)
    if processed_image is None:
        raise HTTPException(status_code=400, detail="Invalid or corrupt image file.")

    predictions = model.predict(processed_image)
    score = tf.nn.softmax(predictions[0])
    predicted_class = class_names[np.argmax(score)]
    confidence = 100 * np.max(score)

    # This line is crucial for debugging
    print(f"--- PREDICTION CHECK ---")
    print(f"Model predicted key: '{predicted_class}'")
    print("------------------------")

    management_info = remedies.get(predicted_class, "Management information not available.")

    return {
        "predicted_disease": predicted_class,
        "confidence_percent": f"{confidence:.2f}",
        "management_info": management_info,
        "disclaimer": remedies.get("general_disclaimer")
    }