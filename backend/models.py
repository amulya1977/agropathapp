from pydantic import BaseModel, EmailStr

# --- Authentication Models ---
class UserCreate(BaseModel):
    fullName: str
    email: EmailStr
    password: str
    username: str
    mobile: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

# --- Crop Recommendation Models ---
class CropData(BaseModel):
    nitrogen: float
    phosphorus: float
    potassium: float
    temperature: float
    humidity: float
    ph: float
    rainfall: float

class WeatherRequest(BaseModel):
    lat: float
    lon: float

# --- Location Model for Full Prediction ---
# This defines the data structure for the /predict_from_location endpoint
class LocationData(BaseModel):
    latitude: float
    longitude: float
    district: str
