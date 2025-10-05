# train_disease_model.py
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import matplotlib.pyplot as plt
import os

# --- 1. SETUP AND DATA LOADING ---

IMG_HEIGHT = 128
IMG_WIDTH = 128
BATCH_SIZE = 32

# Use a raw string for the path to avoid errors
# dataset_path = r'C:\Users\Amulya\Downloads\archive (10)\PlantVillage'
dataset_path=r'C:\Users\Amulya\Downloads\archive (8)\New Plant Diseases Dataset(Augmented)\New Plant Diseases Dataset(Augmented)\train'

if not os.path.exists(dataset_path):
    print(f"ERROR: Dataset path not found at '{dataset_path}'")
else:
    print("✅ Dataset found.")

    # --- THIS IS THE CORRECTED PART ---
    # Load data directly from the main dataset folder and split it
    # into training (80%) and validation (20%) sets.
    train_ds = tf.keras.utils.image_dataset_from_directory(
      dataset_path, # Load from the root folder
      validation_split=0.2,
      subset="training",
      seed=123,
      image_size=(IMG_HEIGHT, IMG_WIDTH),
      batch_size=BATCH_SIZE)

    val_ds = tf.keras.utils.image_dataset_from_directory(
      dataset_path, # Load from the root folder
      validation_split=0.2,
      subset="validation",
      seed=123,
      image_size=(IMG_HEIGHT, IMG_WIDTH),
      batch_size=BATCH_SIZE)
    # ------------------------------------

    class_names = train_ds.class_names
    print(f"\nFound {len(class_names)} classes.")
    print(class_names[:5])

    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

    # --- 2. BUILD THE DEEP LEARNING MODEL (CNN) ---
    num_classes = len(class_names)
    model = keras.Sequential([
      layers.Rescaling(1./255, input_shape=(IMG_HEIGHT, IMG_WIDTH, 3)),
      layers.Conv2D(16, 3, padding='same', activation='relu'),
      layers.MaxPooling2D(),
      layers.Conv2D(32, 3, padding='same', activation='relu'),
      layers.MaxPooling2D(),
      layers.Conv2D(64, 3, padding='same', activation='relu'),
      layers.MaxPooling2D(),
      layers.Dropout(0.2),
      layers.Flatten(),
      layers.Dense(128, activation='relu'),
      layers.Dense(num_classes, activation='softmax')
    ])

    # --- 3. COMPILE AND TRAIN THE MODEL ---
    model.compile(optimizer='adam',
                  loss=tf.keras.losses.SparseCategoricalCrossentropy(),
                  metrics=['accuracy'])
    model.summary()
    print("\n--- Starting Model Training ---")
    epochs = 10
    history = model.fit(
      train_ds,
      validation_data=val_ds,
      epochs=epochs
    )
    print("--- Model Training Finished ---")

    # --- 4. SAVE THE TRAINED MODEL ---
    model.save('plant_disease_model.keras')
    with open('class_names.txt', 'w') as f:
        for item in class_names:
            f.write("%s\n" % item)
    print("\n✅ Model saved as 'plant_disease_model.keras'")
    print("✅ Class names saved as 'class_names.txt'")