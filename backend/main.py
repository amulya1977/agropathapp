# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
# 1. Import the new router along with the others
from routers import authentication, recommendation, disease_prediction, fertilizer_recommendation # <-- ADDED

app = FastAPI(
    title="AgroPath API",
    description="API for crop recommendation, disease prediction, and user auth.",
    version="1.0.0"
)

# CORS Middleware (no change)
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all the routers
app.include_router(authentication.router)
app.include_router(recommendation.router)
app.include_router(disease_prediction.router)
app.include_router(fertilizer_recommendation.router) # 2. Add the new router to the app <-- ADDED

@app.get("/")
def read_root():
    return {"message": "Welcome to the AgroPath API"}
