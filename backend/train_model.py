# train_model.py

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
import pickle

# --- 1. Load the Dataset ---
# Load the data from the CSV file into a pandas DataFrame.
df = pd.read_csv('Crop_recommendation.csv')

# --- 2. Prepare the Data ---
# Separate the features (input variables) from the target (the crop label).
# 'X' will contain all columns except 'label'.
# 'y' will contain only the 'label' column.
X = df.drop('label', axis=1)
y = df['label']

# --- 3. Split Data into Training and Testing Sets ---
# We split the data to train the model on 80% of it and test its performance on the remaining 20%.
# This helps us understand how well the model will perform on new, unseen data.
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# --- 4. Initialize and Train the Random Forest Model ---
# We create an instance of the Random Forest Classifier.
# n_estimators=100 means it will use 100 individual decision trees.
model = RandomForestClassifier(n_estimators=100, random_state=42)

# We train the model using our training data.
print("Training the model...")
model.fit(X_train, y_train)
print("Model training complete.")

# --- 5. Evaluate the Model's Performance ---
# We make predictions on the test set.
y_pred = model.predict(X_test)

# We calculate the accuracy by comparing the model's predictions to the actual labels.
accuracy = accuracy_score(y_test, y_pred)
print(f"Model Accuracy on the test set: {accuracy * 100:.2f}%")

# --- 6. Save the Trained Model ---
# Finally, we save the trained model to a file using pickle.
# The 'wb' means we are writing in binary mode.
with open('crop_model.pkl', 'wb') as model_file:
    pickle.dump(model, model_file)

print("\nModel saved successfully as 'crop_model.pkl'")
print("This file is now ready to be used by your FastAPI backend.")