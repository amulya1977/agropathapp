# 🌱 AgroPath: Integrated Smart Agricultural Decision Support System

[![Python](https://img.shields.io/badge/Python-3.8%2B-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.68%2B-green)](https://fastapi.tiangolo.com/)
[![TensorFlow](https://img.shields.io/badge/TensorFlow-2.x-orange)](https://www.tensorflow.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

**AgroPath** is an integrated, AI-driven decision-support platform designed to provide farmers with accurate, localized, and actionable guidance. By combining real-time weather data, global soil datasets, and image-based disease detection, AgroPath aims to increase farm productivity and reduce risks associated with unpredictable weather and soil degradation.

---

## 📑 Table of Contents
- [Problem Statement](#-problem-statement)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Installation & Setup](#-installation--setup)
- [API Documentation](#-api-documentation)
- [Machine Learning Models](#-machine-learning-models)
- [Roadmap](#-roadmap)
- [Contributors](#-contributors)

---

## 🚩 Problem Statement
Farmers in India often rely on traditional knowledge or guesswork, leading to suboptimal crop selection and imprecise fertilization. Key challenges include:
* **Unpredictable Weather:** Difficulty in planning sowing and harvesting due to climate variability.
* **Soil Degradation:** Incorrect fertilizer usage reducing long-term fertility.
* **Disease Management:** Late identification of plant diseases leading to yield loss and high pesticide costs.
* **Information Gap:** Lack of localized advisory services in native languages.

---

## 🚀 Key Features

### 1. 🌾 Crop Recommendation
Recommends the top-3 most suitable crops for a specific geographical location to maximize ROI.
- **Logic:** Uses a **Random Forest Classifier** trained on a 7-dimensional feature vector (N, P, K, Temperature, Humidity, pH, Rainfall).
- **Data Source:** Aggregates real-time weather (OpenWeatherMap) and global soil proxies (SoilGrids).
- **Output:** Ranked list of crops by suitability probability.

### 2. 🧪 Fertilizer Recommendation
Promotes nutrient-use efficiency by calculating precise nutrient gaps.
- **Logic:** Rule-based algorithm that compares measured soil NPK values against scientifically determined ideal crop requirements.
- **Output:** Identifies the primary nutrient deficiency and suggests a specific commercial fertilizer (e.g., Nitrogen deficiency → Urea).

### 3. 🍃 Disease Prediction
Provides immediate, non-invasive diagnosis of plant diseases from leaf images.
- **Logic:** **Convolutional Neural Network (CNN)** (Transfer Learning approach) processing 128x128 images.
- **Output:** Predicted disease class, confidence score, and actionable management remedies.

### 4. 📍 Location Service (Core Engine)
A centralized service acting as the "Single Source of Truth" for all environmental data.
- **Functionality:** Abstracts external API complexities, handles concurrent fetching, and performs unit normalization (e.g., converting Nitrogen to kg/ha).
- **Resilience:** Implements fallbacks for low-connectivity environments to ensure robust data collection.

---

## 🏗 System Architecture

AgroPath utilizes a microservices-oriented architecture powered by **FastAPI** for high-performance, asynchronous operations.

### Workflow
1.  **Client:** Sends GPS coordinates or Image via REST API.
2.  **Location Service:** Concurrently fetches data from **OpenWeatherMap** (Weather) and **SoilGrids** (Soil N, pH).
3.  **Local Lookup:** Retrieves P (Phosphorus) and K (Potassium) values from localized CSV datasets.
4.  **Processing:**
    * **Crop:** Random Forest Inference on normalized features.
    * **Disease:** CNN Image Processing (Resizing, Normalization, Softmax).
5.  **Response:** JSON output with recommendations and quantitative transparency.

---

## 🛠 Tech Stack

| Domain | Technologies Used |
| :--- | :--- |
| **Backend API** | Python, FastAPI, Uvicorn, Asyncio |
| **Machine Learning** | Scikit-Learn (Random Forest) |
| **Deep Learning** | TensorFlow, Keras (CNN) |
| **External APIs** | OpenWeatherMap, SoilGrids |
| **Mobile App** | Flutter (Dart) |
| **Data Handling** | Pandas, NumPy, Local CSV Lookups |

---

## 💻 Installation & Setup

### Prerequisites
- Python 3.8+
- API Key for OpenWeatherMap

### Steps
1. **Clone the repository**
   ```bash
   git clone [https://github.com/your-username/agropath.git](https://github.com/your-username/agropath.git)
   cd agropath
2.**Create a Virtual Environment**

