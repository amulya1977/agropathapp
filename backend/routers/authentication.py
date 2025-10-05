# routers/authentication.py
print("--- SUCCESS: The authentication file is being loaded by the server. ---")
from fastapi import APIRouter, HTTPException, status
import models, database, hashing, jwt_handler

router = APIRouter(
    tags=['Authentication']
)

# In-memory storage for development when MongoDB is not available
in_memory_users = []

# routers/authentication.py

@router.post("/signup", status_code=status.HTTP_201_CREATED)
def signup(user: models.UserCreate):
    # Check if user already exists
    # The incorrect 'if' statement has been removed.
    if database.user_collection.find_one({"email": user.email}):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Hash the password
    hashed_password = hashing.Hash.hash_password(user.password)

    new_user = {
        "fullName": user.fullName,
        "email": user.email,
        "password": hashed_password,
        "username": user.username,
        "mobile": user.mobile
    }

    database.user_collection.insert_one(new_user)
    return {"message": "User created successfully"}


# routers/authentication.py

@router.post("/login")
def login(user_credentials: models.UserLogin):
    # The incorrect 'if' statement has been removed.
    user = database.user_collection.find_one({"email": user_credentials.email})

    # Check if user exists
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid credentials"
        )

    # Check if password is correct
    if not hashing.Hash.verify_password(user_credentials.password, user["password"]):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid credentials"
        )

    # Create a JWT token
    access_token = jwt_handler.create_access_token(
        data={"sub": user["email"]}
    )

    return {"access_token": access_token, "token_type": "bearer"}