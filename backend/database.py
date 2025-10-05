# database.py
import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv() # Load variables from .env file

MONGO_URI = os.getenv("MONGO_DATABASE_URI", "mongodb://localhost:27017/farmerapp")

try:
    client = MongoClient(MONGO_URI)
    db = client.get_database() # The database name is in your URI
    # Get the users collection
    user_collection = db.get_collection("users")
    print("MongoDB connection successful!")
except Exception as e:
    print(f"MongoDB connection failed: {e}")
    print("Using in-memory storage for development...")
    # For development, we'll use a simple in-memory storage
    user_collection = None